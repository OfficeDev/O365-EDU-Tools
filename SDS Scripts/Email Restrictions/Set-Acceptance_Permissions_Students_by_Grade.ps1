<#
.Synopsis
This script is designed to add the Grade_x DDL to the acceptance permissions on each of the user's mailbox, for the users within the scope of this script. After running this script, only members of the Grade_x DDL will be able to email that particular user. In order to run this script successfully, you must run the New-DDL_for_Students_by_Grade.ps1 to create and populate the DDLs to be used here.

.Example
.\Set-Acceptance_Permissions_Students_by_Grade.ps1

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

    $initialUri = "$graphEndPoint/$graphVersion/users?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'&`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_Grade"
		        
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

#Get list of students from graph request
$Students = Get-Students

#Set Global Variables
$DDL1 = Get-DynamicDistributionGroup Grade_1
$DDL2 = Get-DynamicDistributionGroup Grade_2
$DDL3 = Get-DynamicDistributionGroup Grade_3
$DDL4 = Get-DynamicDistributionGroup Grade_4
$DDL5 = Get-DynamicDistributionGroup Grade_5
$DDL6 = Get-DynamicDistributionGroup Grade_6
$DDL7 = Get-DynamicDistributionGroup Grade_7
$DDL8 = Get-DynamicDistributionGroup Grade_8
$DDL9 = Get-DynamicDistributionGroup Grade_9
$DDL10 = Get-DynamicDistributionGroup Grade_10
$DDL11 = Get-DynamicDistributionGroup Grade_11
$DDL12 = Get-DynamicDistributionGroup Grade_12
$DDLkg = Get-DynamicDistributionGroup Grade_kg

$DDA1 = $DDL1.PrimarySmtpAddress
$DDA2 = $DDL2.PrimarySmtpAddress
$DDA3 = $DDL3.PrimarySmtpAddress
$DDA4 = $DDL4.PrimarySmtpAddress
$DDA5 = $DDL5.PrimarySmtpAddress
$DDA6 = $DDL6.PrimarySmtpAddress
$DDA7 = $DDL7.PrimarySmtpAddress
$DDA8 = $DDL8.PrimarySmtpAddress
$DDA9 = $DDL9.PrimarySmtpAddress
$DDA10 = $DDL10.PrimarySmtpAddress
$DDA11 = $DDL11.PrimarySmtpAddress
$DDA12 = $DDL12.PrimarySmtpAddress
$DDAk = $DDLkg.PrimarySmtpAddress

$DDN1 = $DDL1.DisplayName
$DDN2 = $DDL2.DisplayName
$DDN3 = $DDL3.DisplayName
$DDN4 = $DDL4.DisplayName
$DDN5 = $DDL5.DisplayName
$DDN6 = $DDL6.DisplayName
$DDN7 = $DDL7.DisplayName
$DDN8 = $DDL8.DisplayName
$DDN9 = $DDL9.DisplayName
$DDN10 = $DDL10.DisplayName
$DDN11 = $DDL11.DisplayName
$DDN12 = $DDL12.DisplayName
$DDNk = $DDLkg.DisplayName

#Start Foreach loop against the initial export
Foreach ($Student in $Students) {

	#Set user variables
	$DN = $Student.displayName
	$ObjID = $Student.id

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "1") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN1 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA1}
	}

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "2") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN2 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA2}
	}

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "3") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN3 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA3}
	}

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "4") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN4 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA4}
	}

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "5") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN5 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA5}
	}

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "6") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN6 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA6}
	}

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "7") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN7 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA7}
	}

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "8") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN8 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA8}
	}

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "9") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN9 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA9}
	}

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "10") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN10 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA10}
	}

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "11") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN11 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA11}
	}

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "12") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN12 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA12}
	}

	If ($Student.extension_fe2174665583431c953114ff7268b7b3_Education_Grade -eq "kg") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDNk to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDAk}
	}

}

Write-Output "`n`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"
