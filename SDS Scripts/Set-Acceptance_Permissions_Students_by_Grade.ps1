<#
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

Script Name:
Set-Acceptance_Permissions_Students_by_Grade.ps1

Synopsis:
This script is designed to add the Grade_x DDL to the acceptance permissions on each of the user's mailbox, for the users within the scope of this script. After running this script, only members of the Grade_x DDL will be able to email that particular user. In order to run this script successfully, you must run the New-DDL_for_Students_by_Grade.ps1 to create and populate the DDLs to be used here.

Syntax Examples and Options:
.\Set-Acceptance_Permissions_Students_by_Grade.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/14/2016 - First Draft

#>

#Import the CSV we exported
$Users = Get-MsolUser -All

#Set Global Vairbales
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
$DDLk = Get-DynamicDistributionGroup Grade_k

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
$DDAk = $DDLk.PrimarySmtpAddress

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
$DDNk = $DDLk.DisplayName

#Start Foearch loop against the initial export
Foreach ($User in $Users) {

	#set user variables
	$Dept = $User.department
	$DN = $User.DisplayName
	$ObjID = $User.ObjectID

	If ($Dept -eq "1") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN1 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA1}
	}

	If ($Dept -eq "2") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN2 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA2}
	}

	If ($Dept -eq "3") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN3 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA3}
	}

	If ($Dept -eq "4") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN4 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA4}
	}

	If ($Dept -eq "5") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN5 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA5}
	}

	If ($Dept -eq "6") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN6 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA6}
	}

	If ($Dept -eq "7") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN7 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA7}
	}

	If ($Dept -eq "8") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN8 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA8}
	}

	If ($Dept -eq "9") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN1 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA9}
	}

	If ($Dept -eq "10") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN10 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA10}
	}

	If ($Dept -eq "11") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN11 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA11}
	}

	If ($Dept -eq "12") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDN12 to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDA12}
	}

	If ($Dept -eq "k") {
		#Write Progress
		Write-Host -ForegroundColor Green "Adding $DDNk to $DN acceptance list"

		#Set the permissions
		Set-Mailbox $ObjID -AcceptMessagesOnlyFromDLMembers @{add=$DDAk}
	}

}

Write-Host -ForegroundColor Green "Script is complete."