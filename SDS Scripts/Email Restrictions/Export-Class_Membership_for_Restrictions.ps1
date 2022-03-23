<#
Script Name:
Export-Class_Membership_for_Restrictions.ps1

Written By: 
Bill Sluss and adapted by Srestaluri Sarath

Change Log: 
Version 1.0, 12/12/2016 - First Draft
Version 2.0, 03/22/2022 - Updated script to use Graph API instead of ADAL
#>

<#
.SYNOPSIS
    Export-Class_Membership_for_Restrictions.ps1 is designed to export each section/group synced through SDS, and provide a user to class mapping for every user and class in the organization. This output will be used to stamp the acceptance permissions on each of the respective mailboxes.
.EXAMPLE    
    .\Export-Class_Membership_for_Restrictions.ps1
#>

Param(
    [switch] $PPE,
    [Parameter(Mandatory = $false)]
    [string] $OutFolder = ".",
    # Parameter to specify whether to download the script with common functions or not
    [switch] $skipDownloadCommonFunctions
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

$logFilePath = "$OutFolder\SDSGroups.log"

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
    
    d. If you are returned to the PowerShell sesion without error, you are correctly set up

4. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working

(END)
========================
"@
}

function Get-Groups($graphEndPoint, $refreshToken, $method, $graphScopes, $logFilePath) {

    $groupsUri = "$graphEndPoint/beta/groups"

    $groups = PageAll-GraphRequest $groupsUri $refreshToken $method $graphScopes $logFilePath | Where-Object  {$_.mail -like "*Section_*"}
    
    return $groups
}

function Get-GroupMembers($groupList, $graphEndPoint, $refreshToken, $method, $graphScopes, $logFilePath){
    #Build the Array
    $Results = @()
    
    foreach ($group in $groupList) {
        $DN = $group.displayName
        $GroupObjectID = $group.Id
        $Addr = $group.mail
        Write-Output "Processing Memberships for Group `"$($group.displayName)`" [$($group.Id)] from directory" | out-file $logFilePath -Append  
        Write-Host -ForegroundColor Green "Exporting data for group $DN"
        $groupMembersUri = $graphEndPoint + '/beta/groups/' + $group.Id + '/members'
        $groupMembers = PageAll-GraphRequest $groupMembersUri $refreshToken $method $graphScopes $logFilePath
        foreach($groupMember in $groupMembers){
            $AUObj = New-Object PSObject
            $AUObj | Add-Member NoteProperty -Name GroupDisplayName -Value $DN
            $AUObj | Add-Member NoteProperty -Name GroupObjectID -Value $GroupObjectID
            $AUObj | Add-Member NoteProperty -Name GroupEmailAddress -Value $Addr
            $AUObj | Add-Member NoteProperty -Name MemberDisplayName -Value $groupMember.displayName
            $AUObj | Add-Member NoteProperty -Name MemberObjectID -Value $groupMember.id
            $AUObj | Add-Member NoteProperty -Name MemberPrimarySMTPAddress -Value $groupMember.mail
            $Results += $AUObj
        }     
    }
    return $Results
}

# Main function
$graphEndPoint = $GraphEndpointProd

if ($PPE) {
    $graphEndPoint = $GraphEndpointPPE
}

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

$groupList = Get-Groups $graphEndPoint $refreshToken 'GET' $graphScopes $logFilePath

$groupMembersList = Get-GroupMembers $groupList $graphEndPoint $refreshToken 'GET' $graphScopes $logFilePath

$groupMembersList | Export-Csv "$OutFolder\Export-Class_Membership_for_Restrictions.csv" -NoTypeInformation

Write-Output "`nDone.`n"

Write-Output "Please run 'disconnect-graph' if you are finished making changes.`n"