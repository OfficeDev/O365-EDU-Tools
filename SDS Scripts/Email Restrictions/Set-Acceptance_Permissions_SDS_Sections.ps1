<#
.Synopsis
This script is designed to add each group/section which a student is a member of, to the acceptance permissions on the user's mailbox. After running this script, only the members of those groups/sections will be able to email that particular user.

.Example
PS> .\Set-Acceptance_Permissions_SDS_Sections.ps1

.Notes
========================
 Required Prerequisites
========================
1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph' and also install the Exchange Online PowerShell module with command 'Install-Module ExchangeOnlineManagement'
2. Make sure to download common.ps1 to the same folder of the script which has common functions needed.  https://github.com/OfficeDev/O365-EDU-Tools/blob/master/SDS%20Scripts/common.ps1
3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.
    
    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes User.Read.All, GroupMember.Read.All, Member.Read.Hidden, Group.Read.All, Directory.Read.All, AdministrativeUnit.Read.All" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials

	d. Execute: "connect-exchangeonline"

    e. Sign in with any tenant administrator credentials
    
    f. If you are returned to the PowerShell session without error, you are correctly set up

4. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working and do the same for the Exchange Online Management Module.

========================

#>

Param (
    [Parameter(Mandatory=$false)]
    [string] $skipToken = ".",
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\Export",
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    [switch] $PPE = $false,
    [switch] $downloadCommonFNs = $false
)

$graphEndpointProd = "https://graph.windows.net"
$graphEndpointPPE = "https://graph.ppe.windows.net"

$logFilePath = "$outFolder\Export.log"

$eduObjStudent = "Student"

#checking parameter to download common.ps1 file for required common functions
if ($downloadCommonFNs){
    # Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose
        "Grabbed 'common.ps1' to current directory"
    } 
    catch {
        throw "Unable to download common.ps1"
    }
}
    
#import file with common functions
. .\common.ps1

#Get All student users
function Get-Students
{
    return Get-Users $eduObjStudent
}

function Get-Users
{
    Param
    (
        $eduObjectType
    )

    $list = @()

    $initialUri = "$graphEndPoint/$graphVersion/users?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"
        
    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $users = PageAll-GraphRequest $checkedUri $refreshToken 'GET' $graphscopes $logFilePath

    foreach ($user in $users)
    {
        if ($null -ne $user.id)
        {
            $list += $user
        }
    }
    return $list
}

# Main
$graphEndPoint = $graphEndpointProd

if ($PPE)
{
    $graphEndPoint = $graphEndpointPPE
}

$graphScopes = "User.Read.All, GroupMember.Read.All, Member.Read.Hidden, Group.Read.All, Directory.Read.All, AdministrativeUnit.Read.All"

try 
{
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-Help -Name .\Set-Acceptance_Permissions_SDS_Sections.ps1 -Full | Out-String | Write-Error
    throw
}

try 
{
    Import-Module ExchangeOnlineManagement | Out-Null
}
catch
{
    Write-Error "Failed to load Exchange Online Management Module"
    Get-Help -Name .\Set-Acceptance_Permissions_SDS_Sections.ps1 -Full | Out-String | Write-Error
    throw
}

Initialize

#Import the CSV we exported
$Users = Import-Csv ".\SDS_Class_Membership\Export-Class_Membership_for_Restrictions.csv"

#Get list of students from graph request
$Students = Get-Students

#Start Foreach loop against the initial export
Foreach ($User in $Users) {

    #Set some variables
    $GDN = $User.GroupDisplayName
    $GEA = $User.GroupEmailAddress
    $MDN = $User.MemberDisplayName
    $MOID = $User.MemberObjectID

    #If Student id matches the MemberObjectID we will add group to the acceptance restrictions on the mailbox
    Foreach ($Student in $Students) {
        If ($Student.id -eq $MOID) {
    #Write Progress
    Write-Host -ForegroundColor Green "Adding $GDN to $MDN acceptance list"

    #Set the permissions
    Set-Mailbox -Identity $MOID -AcceptMessagesOnlyFromDLMembers @{add=$GEA}
        }
    }
}

Write-Output "`n`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"