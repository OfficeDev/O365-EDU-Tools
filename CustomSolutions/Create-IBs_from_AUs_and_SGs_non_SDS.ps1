<#
.SYNOPSIS
This script is designed to create Information Barrier Policies for each Administrative Units and Security Group not created by SDS from an O365 tenant. 

.DESCRIPTION
This script will read from Azure, and output the administrative units and security groups to CSVs.  Afterwards, you are prompted to confirm that you want to create the organization segments needed, then create and apply the information barrier policies.  A folder will be created in the same directory as the script itself and contains a log file which details the organization segments and information barrier policies created.  The rows of the csv files can be reduced to only target specific administrative units and security groups.  Nextlink in the log can be used for the skipToken script parameter to continue where the script left off in case it does not finish.  

.EXAMPLE
PS> .\Create-IBs_from_AUs_and_SGs_non_SDS.ps1

.NOTES
This script uses features required by Information Barriers version 3 or above enabled in your tenant.  Existing Organization Segments and Information Barriers created by a legacy version should be removed prior to upgrading.
#>

Param (
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\non_SDS_InformationBarriers",
    [Parameter(Mandatory=$false)]
    [switch] $downloadCommonFNs = $true,
    [Parameter(Mandatory=$false)]
    [switch] $PPE = $false
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

#Checking parameter to download common.ps1 file for required common functions
if ($downloadCommonFNs){
    #Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose
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

function Get-AdministrativeUnits {

    # Removes csv file unless link is provided to resume
    if ((Test-Path $csvFilePathAU) -and ($skipToken -eq "."))
    {
 	    Remove-Item $csvFilePathAU;
    }

    $pageCnt = 1 # Counts the number of pages of AUs retrieved
    $lastRefreshed = $null # Used for refreshing connection

    # Get all AU's
    Write-Progress -Activity "Reading AAD" -Status "Fetching AU's"

    do {
        $auList = @() # Array of objects for AUs

        # Check if need to renew connection
        $currentDT = Get-Date
        if ($lastRefreshed -eq $null -or (New-TimeSpan -Start $currentDT -End $lastRefreshed).Minutes -gt 10) {
            Connect-Graph -scope $graphScopes | Out-Null
            $lastRefreshed = Get-Date
        }

        $auUri = "$graphEndPoint/$graphVersion/directory/administrativeUnits?`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource"

        if ($skipToken -ne "." ) {
            $auUri = $skipToken
        }

        $auResponse = Invoke-Graphrequest -Uri $auUri -Method GET
        $aus = $auResponse.value
        
        $auCtr = 1 # Counter for AUs retrieved
        
        foreach ($au in $aus){
            if ( !($au.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource) ) { # Filtering out AU already with SDS attribute
                $auList += [pscustomobject]@{"AUObjectId"=$au.Id;"AUDisplayName"=$au.DisplayName;}
                $auCtr++
            }
        }

        Write-Progress -Activity "Retrieving AUs..." -Status "Retrieved $auCtr AUs from $pageCnt pages"
        
        # Write nextLink to log if need to restart from previous page
        Write-Output "[$(Get-Date -Format G)] Retrieved $pageCnt AU pages. nextLink: $($auResponse.'@odata.nextLink')" | Out-File $logFilePath -Append
        $pageCnt++

    } while ($auResponse.'@odata.nextLink')  

    $auList | Export-Csv $csvFilePathAU -Append -NotypeInformation

}

function Create-InformationBarriersFromAUs {
    
    $allAUs = Import-Csv $csvfilePathAU | Sort-Object * -Unique #Import school AUs retrieved and remove dupes if occurred from skipToken retry.  
    $i = 0 #Counter for progress of IB creation
        
    #Looping through all school AUs
    foreach($au in $allAUs)
    {
        if ($au.AUObjectId -ne $null)
        {
            Write-Host "Processing $($au.AUDisplayName)"

            #Creating Organization Segment from SDS School Administrative Unit for the Information Barrier
            try {
                New-OrganizationSegment -Name $au.AUDisplayName -UserGroupFilter "AdministrativeUnits -eq '$($au.AUDisplayName)'" -ErrorAction Stop | Out-Null
                Write-Output "[$(Get-Date -Format G)] Created organization segment $($au.AUDisplayName) from school AUs." | Out-File $logFilePath -Append
            }
            catch {
                Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
            }

            #Creating Information Barrier Policies from SDS School Administrative Unit
            try {
                New-InformationBarrierPolicy -Name "$($au.AUDisplayName) - IB" -AssignedSegment $au.AUDisplayName -SegmentsAllowed $au.AUDisplayName -State Active -Force -ErrorAction Stop | Out-Null
                Write-Output "[$(Get-Date -Format G)] Created Information Barrier Policy $($au.AUDisplayName) from Organization Segment" | Out-File $logFilePath -Append
            }
            catch {
                Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
            }
        }
        $i++
        Write-Progress -Activity "`nCreating Organization Segments and Information Barrier Policies based from SDS School Administrative Units" -Status "Progress ->" -PercentComplete ($i/$allAUs.count*100)
    }
    return
}

function Get-SecurityGroups {

    # Removes csv file unless link is provided to resume
    if ((Test-Path $csvFilePathSG) -and ($skipToken -eq "."))
    {
 	    Remove-Item $csvFilePathSG;
    }

 
    $pageCnt = 1 # Counts the number of pages of SGs retrieved
    $lastRefreshed = $null # Used for refreshing connection

    # Get all SG's
    Write-Progress -Activity "Reading AAD" -Status "Fetching security groups"

    do {
        $grpList = @() # Array of objects for SGs
        
        # Check if need to renew connection
        $currentDT = Get-Date
        if ($lastRefreshed -eq $null -or (New-TimeSpan -Start $currentDT -End $lastRefreshed).Minutes -gt 10) {
            Connect-Graph -scope $graphScopes | Out-Null
            $lastRefreshed = Get-Date
        }

        #preparing uri string
        $grpSelectClause = "`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"
        $grpUri = "$graphEndPoint/$graphVersion/groups?`$filter=securityEnabled%20eq%20true&$grpSelectClause"

        if ($skipToken -ne "." ) {
            $grpUri = $skipToken
        }

        $grpResponse = Invoke-Graphrequest -Uri $grpUri -Method GET
        $grps = $grpResponse.value
        
        $grpCtr = 1 # Counter for security groups retrieved
        
        foreach ($grp in $grps){
            if ( !($grp.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType) ) { # Filtering out security groups already with SDS attribute *note: SG's don't have sync source attribute
                $grpList += [pscustomobject]@{"GroupObjectId"=$grp.Id;"GroupDisplayName"=$grp.DisplayName}
                $grpCtr++
            }
        }

        Write-Progress -Activity "Retrieving security groups..." -Status "Retrieved $grpCtr security groups from $pageCnt pages"
        
        # Write nextLink to log if need to restart from previous page
        Write-Output "[$(Get-Date -Format G)] Retrieved $pageCnt security group pages. nextLink: $($grpResponse.'@odata.nextLink')" | Out-File $logFilePath -Append
        $pageCnt++

    } while ($grpResponse.'@odata.nextLink')  

    $grpList | Export-Csv $csvFilePathSG -Append -NotypeInformation

} 

function Create-InformationBarriersFromSG {

    $allSGs = Import-Csv $csvfilePathSG | Sort-Object * -Unique #Import school SGs retrieved and remove dupes if occurred from skipToken retry.  
    $i = 0 #Counter for progress of IB creation

    Write-Output "Creating Information Barrier Policy from Security Groups`n"  

    #Looping through all SGs
    foreach($grp in $allSGs)
    {
        if ($grp.GroupObjectId -ne $null)
        {
            Write-Host "Processing $($grp.AUDisplayName)"

            #Creating Organization Segment from Security Groups for the Information Barrier
            try {
                New-OrganizationSegment -Name $grp.displayName -UserGroupFilter "MemberOf -eq '$($grp.id)'" | Out-Null
                Write-Output "[$(Get-Date -Format G)] Created organization segment $($grp.displayName) from security group." | Out-File $logFilePath -Append
            }
            catch{
                Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
            }

            #Creating Information Barrier Policies from Security Groups
            try {
                New-InformationBarrierPolicy -Name "$($grp.displayName) - IB" -AssignedSegment $grp.displayName -SegmentsAllowed $sgrp.displayName -State Active -Force | Out-Null
                Write-Output "[$(Get-Date -Format G)] Created Information Barrier Policy $($grp.displayName) from organization segment" | Out-File $logFilePath -Append
            }
            catch {
                Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
            }
        }
        $i++
        Write-Progress -Activity "`nCreating Organization Segments and Information Barrier Policies based from SDS School Administrative Units" -Status "Progress ->" -PercentComplete ($i/$allSGs.count*100)
    }
    return
}

# Main
$graphEndPoint = $GraphEndpointProd

if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
}

$activityName = "Creating information barrier policies"

$logFilePath = "$outFolder\SDS_InformationBarriers.log"
$csvFilePathAU = "$outFolder\AdministrativeUnits.csv"
$csvFilePathSG = "$outFolder\SecurityGroups.csv"

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
 	mkdir $outFolder;
 }

Write-Host "`nActivity logged to file $logFilePath `n" -ForegroundColor Green

Connect-Graph -scopes $graphScopes | Out-Null
Connect-IPPSSession | Out-Null

Get-AdministrativeUnits

Write-Host "`nYou are about to create organization segments and information barrier policies from administrative units. `nIf you want to skip any administrative units, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
Write-Host "Proceed with creating organization segments and information barrier policies from administrative units logged in $csvFilePathAU (yes/no)?" -ForegroundColor Yellow
    
$choiceAUtoIB = Read-Host
if ($choiceAUtoIB -ieq "y" -or $choiceAUtoIB -ieq "yes") {
    Create-InformationBarriersFromAUs
}

Get-SecurityGroups

Write-Host "`nYou are about to create an organization segment and information barrier policy from security groups. `nIf you want to skip any security groups, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
Write-Host "Proceed with creating an organization segments and information barrier policy from security groups logged in $csvFilePathSG (yes/no)?" -ForegroundColor Yellow
$choiceSGtoIB = Read-Host
if ($choiceSGtoIB -ieq "y" -or $choiceSGtoIB -ieq "yes") {
    Create-InformationBarriersFromSG
}

Write-Host "`nProceed with starting the information barrier policies application (yes/no)?" -ForegroundColor Yellow
$choiceStartIB = Read-Host
if ($choiceStartIB -ieq "y" -or $choiceStartIB -ieq "yes") {
    Start-InformationBarrierPoliciesApplication | Out-Null
    Write-Output "Done.  Please allow ~30 minutes for the system to start the process of applying Information Barrier Policies. `nUse Get-InformationBarrierPoliciesApplicationStatus to check the status"
}

Write-Output "`n`nDone.  Please run 'Disconnect-Graph' and 'Disconnect-ExchangeOnline' if you are finished`n"