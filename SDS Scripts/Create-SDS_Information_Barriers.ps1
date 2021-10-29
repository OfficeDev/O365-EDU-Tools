<#
Script Name:
Create-SDS_Information_Barriers.ps1

Synopsis:
This script is designed to create Information Barrier Policies for each SDS School AU and the 'All Teachers' Security Group created by SDS from an O365 tenant. It will read from Azure, create the organization segments needed, then create and apply the information barrier policies.  A folder will be created in the same directory as the script itself, and contain a log file which details the organization segments and information barrier policies created.  Nextlink in the log can be used for the skipToken script parameter to continue where the script left off in case it does not finish.  

Syntax Examples and Options:
.\Create-SDS_Information_Barriers.ps1

#>

Param (
    [switch] $PPE = $false,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory=$false)]
    [string] $OutFolder = ".\SDS_InformationBarriers",
    [Parameter(Mandatory=$false)]
    [switch] $downloadCommonFNs = $true
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

#checking parameter to download common.ps1 file for required common functions
if ($downloadCommonFNs){
    # Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose
        "Grabbed 'common.ps1' to currrent directory"
    } 
    catch {
        throw "Unable to download common.ps1"
    }
}
    
#import file with common functions
. .\common.ps1 

function Get-PrerequisiteHelp
{
    Write-Output @"
========================
 Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module and Exchange Online Management Module with commands 'Install-Module Microsoft.Graph' and 'Install-Module ExchangeOnlineManagement'

2. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes AdministrativeUnit.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All" to bring up a sign-in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up

3.  Ensure that All Teachers security group is enabled in SDS and exists in Azure Active Directory.  

4.  Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working and do the same for the Exchange Online Management Module.

(END)
========================
"@
}

function Create-InformationBarriersFromSchoolAUs {

    #preparing uri string
    $auSelectClause = "`$select=id,displayName,@data.type"

    $initialSDSSchoolAUsUri = "$graphEndPoint/beta/directory/administrativeUnits?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'School'&$auSelectClause"
        
    #getting AUs for all schools
    Write-Output "`nRetreiving SDS School Administrative Units"
    $checkedSDSSchoolAUsUri = TokenSkipCheck $initialSDSSchoolAUsUri
    
    do {
        $graphResponse = Invoke-GraphRequest -Method GET -Uri $checkedSDSSchoolAUsUri -ContentType "application/json"

        $allSchoolAUs = $graphResponse.value

        #write to school AU count to log
        Write-Output "[$(Get-Date -Format G)] Retrieve $($allSchoolAUs.count) school AUs." | Out-File $logFilePath -Append
        
        $i = 0 #counter for progress
        
        #looping through all school Aus
        foreach($au in $allSchoolAUs)
        {
            if ($au.id -ne $null)
            {
                Write-Host "Processing $($au.displayName)"

                #Creating Ogranization Segment from SDS School Administrative Unit for the Information Barrier
                try {
                    New-OrganizationSegment -Name $au.displayName -UserGroupFilter "AdministrativeUnits -eq '$($au.displayName)'" | Out-Null
                    Write-Output "[$(Get-Date -Format G)] Created organization segment $($au.displayName) from school AUs." | Out-File $logFilePath -Append
                }
                catch{
                    throw "Error creating Organization Segment for school au $($au.displayName)" 
                }

                #Creating Information Barrier Policies from SDS School Administrative Unit
                try {
                    New-InformationBarrierPolicy -Name "$($au.displayName) - IB" -AssignedSegment $au.displayName -SegmentsAllowed $au.displayName -State Active -Force | Out-Null
                    Write-Output "[$(Get-Date -Format G)] Created Information Barrier Policy $($au.displayName) from organizaiton segment" | Out-File $logFilePath -Append
                }
                catch {
                    throw "Error creating Information Barrier Policy for school au $($au.displayName)"
                }
            }
            $i++
            Write-Output "[$(Get-Date -Format G)] nextLink: $($graphResponse.'@odata.nextLink')" | Out-File $logFilePath -Append
            Write-Progress -Activity "`nCreating Ogranization Segments and Information Barrier Policies based from SDS School Administrative Units" -Status "Progress ->" -PercentComplete ($i/$allSchoolAUs.count*100)
        }
    } while($graphResponse.'@odata.nextLink')

    return 
}

function Create-InformationBarriersFromTeacherSG {

    #preparing uri string
    $grpTeacherSelectClause = "?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'AllTeachersSecurityGroup'&`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"

    $teacherSGUri = "$graphEndPoint/beta/groups$grpTeacherSelectClause"

    Write-Output "Creating Information Barrier Policy from 'All Teachers' Security Group`n"  

    try {
        $graphResponse = Invoke-GraphRequest -Method GET -Uri $teacherSGUri -ContentType "application/json"
        $teacherSG = $graphResponse.value
        
        #Write to school SG count to log
        Write-Output "[$(Get-Date -Format G)] Retrieved $($teacherSG.displayName)." | Out-File $logFilePath -Append
    }
    catch{
        throw "Could not retreive 'All Teachers' Security Group.  Please make sure that it is enabled in SDS."
    }

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

    return
}

# Main
$graphEndPoint = $GraphEndpointProd

if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
}

$activityName = "Creating information barrier policies"

$logFilePath = "$OutFolder\SDS_InformationBarriers.log"
$csvFilePath = "$OutFolder\SDS_InformationBarriers.csv"

#list used to request access to data
$graphscopes = "AdministrativeUnit.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All"

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

 # Create output folder if it does not exist
 if ((Test-Path $OutFolder) -eq 0)
 {
 	mkdir $OutFolder;
 }

Write-Host "`nActivity logged to file $csvFilePath `n" -ForegroundColor Green

# Get all AU's of Edu Object Type School
Write-Progress -Activity "Reading SDS" -Status "Fetching School Administrative Units"

Connect-Graph -scopes $graphscopes | Out-Null
Connect-IPPSSession | Out-Null

Create-InformationBarriersFromSchoolAUs
Create-InformationBarriersFromTeacherSG

Start-InformationBarrierPoliciesApplication | Out-Null

Write-Output "Done.  Please allow ~30 minutes for the system to start the process of applying Information Barrier Policies. `nUse Get-InformationBarrierPoliciesApplicationStatus to check the status"
Write-Output "`n`nPlease run 'Disconnect-Graph' and 'Disconnect-ExchangeOnline' if you are finished`n"