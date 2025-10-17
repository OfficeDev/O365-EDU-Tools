<#
.SYNOPSIS
    Export-Class_Membership_for_Restrictions.ps1 is designed to export each section/group synced through SDS, and provide a user to class mapping for every user and class in the organization. This output will be used to stamp the acceptance permissions on each of the respective mailboxes.

.Description
    The script will interact with Microsoft online resources using the Graph module. Once connected, the script will get the GroupMembers. A folder will be created in the same directory as the script itself containing log file and a csv file with the data previously mentioned.

.PARAMETER outFolder
    Path where to put the log and csv file with the fetched users.

.PARAMETER graphVersion
    The version of the Graph API.

.EXAMPLE
    .\Export-Class_Membership_for_Restrictions.ps1

.NOTES
***This script may take a while.***

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
#>

Param(
    [switch] $PPE = $false,
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\SDS_Class_Membership",
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    # Parameter to specify whether to download the script with common functions or not
    [switch] $skipDownloadCommonFunctions
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

$logFilePath = "$outFolder\Export-Class_Membership_for_Restrictions.log"

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0) {
    mkdir $outFolder | Out-Null;
}

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

function Get-Groups($graphEndPoint, $refreshToken, $method, $graphScopes, $logFilePath) {

    $groupsUri = "$graphEndPoint/$graphVersion/groups"

    $groups = PageAll-GraphRequest $groupsUri $refreshToken $method $graphScopes $logFilePath | Where-Object  {$_.mail -like "*Section_*"}
    
    return $groups
}

function Get-GroupMembers($groupList, $graphEndPoint, $refreshToken, $method, $graphScopes, $logFilePath){
    #Build the Array
    $Results = @()
    $index = 1
    
    foreach ($group in $groupList) {
        $name = $group.displayName
        $id = $group.Id
        $addr = $group.mail
        Write-Output "[$(get-date -Format G)] Processing Memberships for Group `"$($group.displayName)`" [$($group.Id)] from directory" | out-file $logFilePath -Append
        Write-Progress -Activity "Processing Memberships for Group..." -Status "Progress ->" -PercentComplete ($index/$groupList.count*100)
        $groupMembersUri = $graphEndPoint + "/$graphVersion/groups/" + $group.Id + '/members'
        $groupMembers = PageAll-GraphRequest $groupMembersUri $refreshToken $method $graphScopes $logFilePath

        foreach ($groupMember in $groupMembers) {
            if ($groupMember.id) {
                $AUObj = New-Object PSObject
                $AUObj | Add-Member NoteProperty -Name GroupDisplayName -Value $name
                $AUObj | Add-Member NoteProperty -Name GroupObjectID -Value $id
                $AUObj | Add-Member NoteProperty -Name GroupEmailAddress -Value $addr
                $AUObj | Add-Member NoteProperty -Name MemberDisplayName -Value $groupMember.displayName
                $AUObj | Add-Member NoteProperty -Name MemberObjectID -Value $groupMember.id
                $AUObj | Add-Member NoteProperty -Name MemberPrimarySMTPAddress -Value $groupMember.mail
                $Results += $AUObj
            }
        }
        $index++
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
    Get-Help -Name .\Export-Class_Membership_for_Restrictions.ps1 -Full | Out-String | Write-Error    
    throw
}

$refreshToken = Initialize $graphScopes

$groupList = Get-Groups $graphEndPoint $refreshToken 'GET' $graphScopes $logFilePath

$groupMembersList = Get-GroupMembers $groupList $graphEndPoint $refreshToken 'GET' $graphScopes $logFilePath

$groupMembersList | Export-Csv "$outFolder\Export-Class_Membership_for_Restrictions.csv" -NoTypeInformation

Write-Output "`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"