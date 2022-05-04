<#
.SYNOPSIS
This script is designed to create Information Barrier Policies for each SDS School AU and the 'All Teachers' Security Group created by SDS from an O365 tenant. 

.DESCRIPTION
This script will read from Azure, and output the administrative units to a csv.  Afterwards, you are prompted to confirm that you want to create the organization segments needed, then create and apply the information barrier policies.  A folder will be created in the same directory as the script itself and contains a log file which details the organization segments and information barrier policies created.  Nextlink in the log can be used for the skipToken script parameter to continue where the script left off in case it does not finish.  

.EXAMPLE
PS> .\Create-SDS_Information_Barriers.ps1

.EXAMPLE
PS> .\Create-SDS_Information_Barriers.ps1 -upn "<global admin user principle name>"

The script uses the upn from Graph for Connect-IPPSSession.  The upn parameter is required if the user skips fetching Graph data. 

.NOTES
This script uses features required by Information Barriers version 3 or above enabled in your tenant.  Existing Organization Segments and Information Barriers created by a legacy version should be removed prior to upgrading.
#>

Param (
    [Parameter(Mandatory=$false)]
    [string] $upn,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\SDS_InformationBarriers",
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    [switch] $downloadCommonFNs = $true,
    [switch] $PPE = $false
)

$graphEndpointProd = "https://graph.microsoft.com"
$graphEndpointPPE = "https://graph.microsoft-ppe.com"

#Used for refreshing connection
$connectTypeGraph = "Graph"
$connectTypeIPPSSession = "IPPSSession"
$connectGraphDT = Get-Date -Date "1970-01-01T00:00:00"
$connectIPPSSessionDT = Get-Date -Date "1970-01-01T00:00:00"
$timeout = (New-Timespan -Hours 0 -Minutes 0 -Seconds 43200)
$pssOpt = new-PSSessionOption -IdleTimeout $timeout.TotalMilliseconds #-OpenTimeout 0 -CancelTimeout 0 -OperationTimeout 0 uncomment after testing

#Checking parameter to download common.ps1 file for required common functions
if ($downloadCommonFNs){
    #Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop
        "Grabbed 'common.ps1' to current directory"
    }
    catch {
        throw "Unable to download common.ps1"
    }
}
    
#Import file with common functions
. .\common.ps1 

function Get-PrerequisiteHelp
{
    Write-Output @"
========================
 Required Prerequisites
========================

1. This script uses features required by Information Barriers version 3 or above enabled in your tenant.  

    a.  Existing Organization Segments and Information Barriers created by a legacy version should be removed prior to upgrading.

2. Install Microsoft Graph Powershell Module and Exchange Online Management Module with commands 'Install-Module Microsoft.Graph' and 'Install-Module ExchangeOnlineManagement'

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes AdministrativeUnit.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All" to bring up a sign-in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up

4.  Ensure that All Teachers security group is enabled in SDS and exists in Azure Active Directory.  

5.  Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working and do the same for the Exchange Online Management Module.

(END)
========================
"@
}

function Set-Connection($connectDT, $connectionType) {
    #Check if need to renew connection
    $currentDT = Get-Date
    $lastRefreshedDT = $connectDT

    if ((New-TimeSpan -Start $lastRefreshedDT -End $currentDT).TotalMinutes -gt $timeout.TotalMinutes)
    {
        if ($connectionType -ieq $connectTypeIPPSSession)
        {
            $sessionIPPS = Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange" -and $_.State -eq "Opened"}
            
            if ($sessionIPPS)
            {
                Disconnect-ExchangeOnline -confirm:$false | Out-Null
            }

            if (!($upn))
            {
                Connect-IPPSSession -PSSessionOption $pssOpt | Out-Null
            }
            else
            {
                Connect-IPPSSession -PSSessionOption $pssOpt -UserPrincipalName $upn | Out-Null
            }
        }
        else
        {
            Connect-Graph -scopes $graphScopes | Out-Null

            if (!($upn)) #Get upn for Connect-IPPSSession to avoid entering again
            {
                $connectedGraphUser = Invoke-GraphRequest -method get -uri "$graphEndpoint/$graphVersion/me"
                $connectedGraphUPN = $connectedGraphUser.userPrincipalName
                $upn = $connectedGraphUPN
            }
        }
    }
    return Get-Date
}
function Get-AllSchoolAUs($connectDT) {

    #Remove temp csv file with school AUs if not resuming from last token
    if ((Test-Path $csvFilePath) -and ($skipToken -eq "."))
    {
 	    Remove-Item $csvFilePath;
    }

    #Preparing uri string
    $auSelectClause = "`$select=id,displayName"
    $initialSDSSchoolAUsUri = "$graphEndPoint/$graphVersion/directory/administrativeUnits?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'School'&$auSelectClause"
        
    #Getting AUs for all schools
    Write-Output "`nRetrieving SDS School Administrative Units`n"
    $currentUri = TokenSkipCheck $initialSDSSchoolAUsUri
    
    $pageCnt = 1 #Counts the number of pages of school AUs Retrieved

    #Get all AU's of Edu Object Type School
    do {
        $allSchoolAUs = @() #array of objects for pages of school AUs
        $connectDT = Set-Connection $connectDT $connectTypeGraph
        $graphResponse = Invoke-GraphRequest -Method GET -Uri $currentUri -ContentType "application/json"
        $schoolAUs = $graphResponse.value

        #Write school AU count to log
        Write-Output "[$(Get-Date -Format G)] Retrieved $($schoolAUs.count) school AUs in page $pageCnt" | Out-File $logFilePath -Append
    
        #Write school Aus found to temp csv file
        foreach($au in $schoolAUs)
        {
            #Create object required for export-csv and add to array
            $obj = [pscustomobject]@{"AUObjectId"=$au.id;"AUDisplayName"=$au.displayName;}
            $allSchoolAUs += $obj
        }
        
        $allSchoolAUs | Export-Csv -Path "$csvfilePath" -Append -NoTypeInformation

        #Write nextLink to log if need to restart from previous page
        Write-Output "[$(Get-Date -Format G)] nextLink: $($graphResponse.'@odata.nextLink')" | Out-File $logFilePath -Append
        $pageCnt++
        $currentUri = $graphResponse.'@odata.nextLink'
        Write-Progress -Activity "Reading SDS" -Status "Fetching School Administrative Units"

    } while($graphResponse.'@odata.nextLink')
    
    return $connectDT
}

function Create-OrganizationSegmentsFromSchoolAUs{}

function Create-InformationBarriersFromSchoolAUs($connectDT) {
    
    $allSchoolAUs = Import-Csv $csvfilePath | Sort-Object * -Unique #Import school AUs retrieved and remove dupes if occurred from skipToken retry.  
    $i = 0 #Counter for progress of IB creation

    #Looping through all school AUs
    $allSchoolAUs | foreach-object {
        if ($_.AUObjectId -ne $null)
        {
            $connectDT = "" #Set-Connection $connectDT $connectTypeIPPSSession uncomment after testing
            Write-Host "$i : Processing $($_.AUDisplayName)"
            
            #Creating Organization Segment from SDS School Administrative Unit for the Information Barrier
            try {
                Write-Output "[$(Get-Date -Format G)] Log start time" | Out-File $logFilePath -Append
                $startTime = Get-Date
                New-OrganizationSegment -Name $_.AUDisplayName -UserGroupFilter "AdministrativeUnits -eq '$($_.AUObjectId)'" -ErrorAction Stop | Out-Null
                $endTime = Get-Date
                $elapsedTime = $endTime - $startTime
                Write-Output "[$(Get-Date -Format G)] Created organization segment $($_.AUDisplayName) from school AUs in $elapsedTime" | Out-File $logFilePath -Append
                Write-Output "[$(Get-Date -Format G)] Log end time" | Out-File $logFilePath -Append
            }
            catch {
                Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
            }

            #Creating Information Barrier Policies from SDS School Administrative Unit
            try {
                Write-Output "[$(Get-Date -Format G)] Log start time" | Out-File $logFilePath -Append
                $startTime = Get-Date
                New-InformationBarrierPolicy -Name "$($_.AUDisplayName) - IB" -AssignedSegment $_.AUDisplayName -SegmentsAllowed $_.AUDisplayName -State Active -Force -ErrorAction Stop | Out-Null
                $endTime = Get-Date
                $elapsedTime = $endTime - $startTime
                Write-Output "[$(Get-Date -Format G)] Created Information Barrier Policy $($_.AUDisplayName) from Organization Segment in $elapsedTime" | Out-File $logFilePath -Append
                Write-Output "[$(Get-Date -Format G)] Log end time" | Out-File $logFilePath -Append
            }
            catch {
                Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
            }
        }
        $i++
        Write-Progress -Activity "`nCreating Organization Segments and Information Barrier Policies based from SDS School Administrative Units" -Status "Progress ->" -PercentComplete ($i/$allSchoolAUs.count*100)
    }
    return $connectDT
}

function Get-AllTeacherSG($connectDT){
    #preparing uri string
    $grpTeacherSelectClause = "?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'AllTeachersSecurityGroup'&`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"
    $teacherSGUri = "$graphEndPoint/$graphVersion/groups$grpTeacherSelectClause"

    $connectDT = Set-Connection $connectDT $connectTypeGraph

    try {
        $graphResponse = Invoke-GraphRequest -Method GET -Uri $teacherSGUri -ContentType "application/json"
        $teacherSG = $graphResponse.value
        
        #Write All Teachers security group retrieved to log
        Write-Output "[$(Get-Date -Format G)] Retrieved $($teacherSG.displayName)." | Out-File $logFilePath -Append
    }
    catch{
        Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
        throw "Could not retrieve 'All Teachers' Security Group.  Please make sure that it is enabled in SDS."
    }
    return $teacherSG
}

function Create-InformationBarriersFromTeacherSG($connectDT, $teacherSG) {
    
    Write-Host "Creating Information Barrier Policy from 'All Teachers' Security Group`n"  
    $connectDT = Set-Connection $connectDT $connectTypeIPPSSession

    try {
        New-OrganizationSegment -Name $teacherSG.displayName -UserGroupFilter "MemberOf -eq '$($teacherSG.id)'" | Out-Null
        Write-Output "[$(Get-Date -Format G)] Created organization segment $($teacherSG.displayName) from security group." | Out-File $logFilePath -Append
    }
    catch{
        throw "Error creating Organization Segment"
    }

    #Creating Information Barrier Policies from 'All Teachers' Security Group
    try {
        New-InformationBarrierPolicy -Name "$($teacherSG.displayName) - IB" -AssignedSegment $teacherSG.displayName -SegmentsAllowed $teacherSG.displayName -State Active -Force | Out-Null
        Write-Output "[$(Get-Date -Format G)] Created Information Barrier Policy $($teacherSG.displayName) from organization segment" | Out-File $logFilePath -Append
    }
    catch {
        throw "Error creating Information Barrier Policy for security group $($teacherSG.displayName)"
    }
    return $connectDT
}

# Main
$graphEndPoint = $graphEndpointProd

if ($PPE)
{
    $graphEndPoint = $graphEndpointPPE
}

$activityName = "Creating information barrier policies"

$logFilePath = "$outFolder\SDS_InformationBarriers.log"
$csvFilePath = "$outFolder\SDS_SchoolAUs.csv"

#List used to request access to data
$graphScopes = "AdministrativeUnit.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All"

try 
{
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-PrerequisiteHelp | Out-String | Write-Error
    throw
}

try 
{
    Import-Module ExchangeOnlineManagement | Out-Null
}
catch
{
    Write-Error "Failed to load Exchange Online Management Module for creating Information Barriers"
    Get-PrerequisiteHelp | Out-String | Write-Error
    throw
}

 #Create output folder if it does not exist
 if ((Test-Path $outFolder) -eq 0)
 {
 	mkdir $outFolder | Out-Null;
 }

Write-Host "`nActivity logged to file $logFilePath `n" -ForegroundColor Green

Write-Host "Proceed with fetching SDS school administrative units?  Skip if you want to use a previously generated $csvFilePath (yes/no)?" -ForegroundColor Yellow
$choiceSchoolAU = Read-Host
if ($choiceSchoolAU -ieq "y" -or $choiceSchoolAU -ieq "yes") {
    $connectGraphDT = Get-AllSchoolAUs $connectGraphDT
}

Write-Host "`nYou are about to create organization segments and information barrier policies from SDS school administrative units. `nIf you want to skip any administrative units, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
Write-Host "Proceed with creating organization segments and information barrier policies from SDS school administrative units logged in $csvFilePath (yes/no)?" -ForegroundColor Yellow
    
$choiceSchoolIB = Read-Host
if ($choiceSchoolIB -ieq "y" -or $choiceSchoolIB -ieq "yes") {
    Connect-IPPSSession -PSSessionOption $pssOpt -UserPrincipalName $upn #remove line after testing
    $connectIPPSSessionDT = Create-InformationBarriersFromSchoolAUs $connectIPPSSessionDT
}

Write-Host "`nYou are about to create an organization segment and information barrier policy from the 'All Teachers' Security Group. `nNote: You need to have the group created via a toggle in the SDS profile beforehand.`n" -ForegroundColor Yellow
Write-Host "Proceed with creating an organization segments and information barrier policy from the 'All Teachers' Security Group. (yes/no)?" -ForegroundColor Yellow
$choiceTeachersIB = Read-Host
if ($choiceTeachersIB -ieq "y" -or $choiceTeachersIB -ieq "yes") {
    $allTeacherSG = Get-AllTeacherSG $connectGraphDT
    $connectIPPSSessionDT = Create-InformationBarriersFromTeacherSG $connectIPPSSessionDT $allTeacherSG
}

Write-Host "`nProceed with starting the information barrier policies application (yes/no)?" -ForegroundColor Yellow
$choiceStartIB = Read-Host
if ($choiceStartIB -ieq "y" -or $choiceStartIB -ieq "yes") {
    $connectIPPSSessionDT = Set-Connection $connectIPPSSessionDT $connectTypeIPPSSession
    Start-InformationBarrierPoliciesApplication | Out-Null
    Write-Output "Done.  Please allow ~30 minutes for the system to start the process of applying Information Barrier Policies. `nUse Get-InformationBarrierPoliciesApplicationStatus to check the status"
}

Write-Output "`n`nDone.  Please run 'Disconnect-Graph' and 'Disconnect-ExchangeOnline' if you are finished`n"
