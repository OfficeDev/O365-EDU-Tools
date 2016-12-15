<#
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

Script Name:
Set-Acceptance_Permissions_All_Teachers.ps1

Synopsis:
This script is designed to add the All_Teachers DDL to the acceptance permissions on each of the user's mailbox, within the scope of this script. After running this script, only members of the All_Teachers DDL will be able to email that particular user. In order to run their script successfully, you must run the New-DDL_for_All_Teachers.ps1 to create and populate the DDL to be used here.

Syntax Examples and Options:
.\Set-Acceptance_Permissions_All_Teachers.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/14/2016 - First Draft

#>

#Get all student users
$Users = Get-MsolUser -All | ? {$_.Department -eq "Student"}

#Set some Gloabl Variables
$DDL = Get-DynamicDistributionGroup All_Teachers
$DDA = $DDL.PrimarySmtpAddress
$DDN = $DDL.DisplayName

#Start Foearch loop against the initial export
Foreach ($User in $Users) {

	#Set some variables
	$DN = $User.DisplayName
	$ObjID = $User.ObjectID

	#Write Progress
	Write-Host -ForegroundColor Green "Adding $DDN to $DN acceptance list"

	#Set the permissions
	Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA}
}
