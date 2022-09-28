<#
Script Name:
Remove-All_Section_Memberships.ps1

Written By: 
Microsoft SDS Team, and adapted by Debashis Dwivedi

Change Log:
Version 1.0, 12/12/2016 - First Draft
Version 2.0, 09/22/2021 - Updated script to use Graph API instead of ADAL
#>

<#
.SYNOPSIS
    Remove-All_Section_Memberships.ps1 script is designed to Remove all Section Memberships created by SDS from an O365 tenant. The script sets up the connection to Azure, and then confirm you want to run the script with a "y". Once the script completes, a file will be created in the folder mentioned in OutFolder parameter (Default is same folder as the script itself).
.EXAMPLE    
    .\Remove-All_Section_Memberships.ps1 -RemoveObject "SectionGroupMemberships"
.EXAMPLE
    .\Remove-All_Section_Memberships.ps1 -RemoveObject "SectionGroups"
.EXAMPLE
    .\Remove-All_Section_Memberships.ps1 -RemoveObject "SchoolAUs"
.EXAMPLE
    .\Remove-All_Section_Memberships.ps1 -RemoveObject "SectionAUs"
#>

Param (
    [switch] $PPE,
    [Parameter(Mandatory = $true)]
    [ValidateSet("SectionGroupMemberships","SectionGroups","SchoolAUs","SectionAUs")]
    [string] $RemoveObject,
    [Parameter(Mandatory = $false)]
    [string] $OutFolder = ".",
    # Parameter to specify whether to download the script with common functions or not
    [switch] $skipDownloadCommonFunctions
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

$logFilePath = "$OutFolder\SDSSectionMemberships.log"

if ($skipDownloadCommonFunctions -eq $false) {
    # Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose
        "Grabbed 'common.ps1' to the directory alongside the executing script"
        Write-Output "[$(get-date -Format G)] Grabbed 'common.ps1' to the directory alongside the executing script. common.ps1 script contains common functions, which can be used by other SDS scripts" | out-file $logFilePath -Append

    } 
    catch {
        throw "Unable to download common.ps1"
    }
}

#import file with common functions
. .\common.ps1

function Get-PrerequisiteHelp {
    Write-Output @"
========================
 Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'. 
PowerShell 7 and later is the recommended PowerShell version for use with the Microsoft Graph PowerShell SDK on all platforms (https://docs.microsoft.com/en-us/graph/powershell/installation#supported-powershell-versions).

2. Make sure to download common.ps1 to the same folder of the script which has common functions needed.  https://github.com/OfficeDev/O365-EDU-Tools/blob/master/SDS%20Scripts/common.ps1
Command to download the function: Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes GroupMember.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up

4. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working

(END)
========================
"@
}

function Get-AdministrativeUnits($graphEndPoint, $eduObjectType, $refreshToken, $graphScopes, $logFilePath) {
    
    $adminstrativeUnitsUri = "$graphEndPoint/beta/directory/administrativeUnits?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"   
    
    $fileName = $eduObjectType + "-AUs.csv"
    $filePath = Join-Path $OutFolder $fileName
    
    $objectProperties = @()
    $objectProperties += @{N='Id';E={$_.Id}}, @{N='DisplayName';E={$_.DisplayName}}, @{N='Source ID';E={$_.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId}}
    
    PageAll-GraphRequest-WriteToFile $adminstrativeUnitsUri $refreshToken 'GET' $graphScopes $logFilePath $filePath $objectProperties $eduObjectType | out-null
    
    return $filePath
}

function Remove-AdministrativeUnits($auListFileName, $graphEndPoint, $refreshToken, $graphscopes) {
    Write-Host "WARNING: You are about to remove Administrative Units and its memberships created from SDS. `nIf you want to skip removing any AUs, edit $auListFileName file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all the AUs logged in $auListFileName (yes/no)?" -ForegroundColor White
    $choice = Read-Host

    if ($choice -ieq "y" -or $choice -ieq "yes") {
        Write-Progress -Activity $activityName -Status "Deleting Administrative Units"
        $auList = import-csv $auListFileName
        $auCount = $auList.Length
        $index = 1
        Foreach ($au in $auList) {
            if ($au.Id -ne $null) {
                Refresh-Token $refreshToken $graphscopes
                Write-Output "[$(get-date -Format G)] [$index/$auCount] Removing AU `"$($au.DisplayName)`" [$($au.Id)] from directory" | out-file $logFilePath -Append
                $removeUrl = $graphEndPoint + '/beta/administrativeUnits/' + $au.Id
                invoke-graphrequest -Method 'DELETE' -Uri $removeUrl -ContentType "application/json"
                $index++
            }
        }
    }
}

function Get-Groups($graphEndPoint, $eduObjectType, $refreshToken, $graphScopes, $logFilePath) {

    $groupsUri = "$graphEndPoint/beta/groups?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'%20and%20extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"
    
    $fileName = $eduObjectType + "-Groups.csv"
    $filePath = Join-Path $OutFolder $fileName
    
    $objectProperties = @()
    $objectProperties += @{N='Id';E={$_.Id}}, @{N='DisplayName';E={$_.DisplayName}}, @{N='Mail';E={$_.Mail}}, @{N='Source ID';E={$_.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId}}
    
    PageAll-GraphRequest-WriteToFile $groupsUri $refreshToken 'GET' $graphScopes $logFilePath $filePath $objectProperties $eduObjectType | out-null
    
    return $filePath
}

function Remove-Groups($groupListFileName, $graphEndPoint, $refreshToken, $graphScopes, $logFilePath) {
    Write-Host "WARNING: You are about to remove Groups and its memberships created from SDS. `nIf you want to skip removing any Groups, edit $groupListFileName file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all the Groups logged in $groupListFileName (yes/no)?" -ForegroundColor White
    $choice = Read-Host

    if ($choice -ieq "y" -or $choice -ieq "yes") {
        Write-Progress -Activity $activityName -Status "Deleting Groups"
        $groupList = import-csv $groupListFileName
        $groupCount = $groupList.Length
        $index = 1
        Foreach ($group in $groupList) {
            Write-Output "[$(get-date -Format G)] [$index/$groupCount] Removing Group `"$($group.DisplayName)`" [$($group.Id)] from directory" | out-file $logFilePath -Append
            $removeUrl = $graphEndPoint + '/beta/groups/' + $group.Id
            PageAll-GraphRequest $removeUrl $refreshToken 'DELETE' $graphScopes $logFilePath | Out-Null
            $index++
        }
    }
}

function Remove-GroupMembers($groupListFileName, $graphEndPoint, $refreshToken, $graphScopes, $logFilePath) {
    Write-Host "WARNING: You are about to remove Groups memberships created from SDS. `nIf you want to skip processing any Groups, edit $groupListFileName file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all Group Memberships logged in $groupListFileName (yes/no)?" -ForegroundColor White
    $choice = Read-Host

    if ($choice -ieq "y" -or $choice -ieq "yes") {
        Write-Progress -Activity $activityName -Status "Getting Group Memberships"
        $groupList = import-csv $groupListFileName
        $groupCount = $groupList.Length
        $index = 1
        $grpMemberSelectClause = "?`$select=id,email,displayName,@data.type,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource"

        Foreach ($group in $groupList) {
            Write-Output "[$(get-date -Format G)] [$index/$groupCount] Processing Memberships for Group `"$($group.DisplayName)`" [$($group.Id)]" | out-file $logFilePath -Append
            $groupMembersUri = $graphEndPoint + '/beta/groups/' + $group.Id + '/members' + $grpMemberSelectClause
            $groupMembers = PageAll-GraphRequest $groupMembersUri $refreshToken 'GET' $graphScopes $logFilePath
            Write-Output "[$(get-date -Format G)] Retrieve $($groupMembers.Count-1) groupMembers.`n" | out-file $logFilePath -Append
            Write-Progress -Activity $activityName -Status "Removing Group Memberships"
            Foreach ($member in $groupMembers) {
                $grpMemberType = $member.'@odata.type' #some members are users and some are groups
                if (($member.Id -ne $null) -and ($grpMemberType -eq '#microsoft.graph.user')) {
                    Write-Output "[$(get-date -Format G)] Removing User `"$($member.DisplayName)`" from Group `"$($group.DisplayName)`"" | out-file $logFilePath -Append
                    $removeUrl = $graphEndPoint + '/beta/groups/' + $group.Id + '/members/' + $member.Id + '/$ref'
                    PageAll-GraphRequest $removeUrl $refreshToken 'DELETE' $graphScopes $logFilePath | Out-Null
                }
            }

            $index++
        }
    }
}

# Main function
$graphEndPoint = $GraphEndpointProd

if ($PPE) {
    $graphEndPoint = $GraphEndpointPPE
}

$activityName = "Cleaning up SDS Objects in Directory"

#scopes used to request access to data
$graphScopes = "GroupMember.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All"

try {
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch {
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-PrerequisiteHelp | Out-String | Write-Error
    throw
}

# Create output folder if it does not exist
if ((Test-Path $OutFolder) -eq 0) {
    mkdir $OutFolder;
}
 
$refreshToken = Initialize $graphScopes
 
if ($RemoveObject -eq "SchoolAUs") {
    # Get all AUs of Edu Object Type School
    Write-Progress -Activity $activityName -Status "Fetching School Administrative Units"
    $OutputFileName = Get-AdministrativeUnits $graphEndPoint 'School' $refreshToken $graphScopes $logFilePath
    Write-Host "`nSchool Administrative Units logged to file $OutputFileName `n" -ForegroundColor Green

    # Delete School AUs
    Remove-AdministrativeUnits $OutputFileName $graphEndPoint $refreshToken $graphScopes
}

if ($RemoveObject -eq "SectionAUs") {
    # Get all AUs of Edu Object Type Section
    Write-Progress -Activity $activityName -Status "Fetching Section Administrative Units"
    $OutputFileName = Get-AdministrativeUnits $graphEndPoint 'Section' $refreshToken $graphScopes $logFilePath
    Write-Host "`nSection Administrative Units logged to file $OutputFileName `n" -ForegroundColor Green

    # Delete Section AUs
    Remove-AdministrativeUnits $OutputFileName $graphEndPoint $refreshToken $graphScopes
}

if ($RemoveObject -eq "SectionGroupMemberships" -or $RemoveObject -eq "SectionGroups") {
    # Get all Groups of Edu Object Type Section
    Write-Progress -Activity $activityName -Status "Fetching Section Groups"
    $OutputFileName = Get-Groups $graphEndPoint 'Section' $refreshToken $graphScopes $logFilePath
    Write-Host "`nSection Groups logged to file $OutputFileName `n" -ForegroundColor Green
    
    if ($RemoveObject -eq "SectionGroupMemberships") {
        Remove-GroupMembers $OutputFileName $graphEndPoint $refreshToken $graphScopes $logFilePath
    }

    if ($RemoveObject -eq "SectionGroups") {
        Remove-Groups $OutputFileName $graphEndPoint $refreshToken $graphScopes $logFilePath
    }
}

Write-Output "`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"