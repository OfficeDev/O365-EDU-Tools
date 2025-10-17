<#
.Synopsis
This script is designed to add the All_Students DDL to the acceptance permissions on each of the user's mailbox, within the scope of this script. After running this script, only members of the All_Students DDL will be able to email that particular user. In order to run their script successfully, you must run the New-DDL_for_All_Students.ps1 to create and populate the DDL to be used here.

.Example
PS> .\Set-Acceptance_Permissions_All_Students.ps1

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

4. Ensure that you have a security group called "All_Students" in Azure Active Directory.

5. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working and do the same for the Exchange Online Management Module.

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
    Get-Help -Name .\Set-Acceptance_Permissions_All_Students.ps1 -Full | Out-String | Write-Error
    throw
}

try 
{
    Import-Module ExchangeOnlineManagement | Out-Null
}
catch
{
    Write-Error "Failed to load Exchange Online Management Module"
    Get-Help -Name .\Set-Acceptance_Permissions_All_Students.ps1 -Full | Out-String | Write-Error
    throw
}

Initialize

#Set some Global Variables
$DDL = Get-DynamicDistributionGroup All_Students
$DDA = $DDL.PrimarySmtpAddress
$DDN = $DDL.DisplayName

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0)
{
	mkdir $outFolder;
}

$Users = Get-Students

#Start Foreach loop against the initial export
Foreach ($User in $Users) {

	#Set some variables
	$DN = $User.DisplayName
    $ObjID = $User.userPrincipalName

	#Write Progress
	Write-Host -foregroundcolor green "Adding $DN to $DDN acceptance list"

	#Set the permissions
	Set-Mailbox -Identity $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA}
	
}

Write-Output "`n`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"