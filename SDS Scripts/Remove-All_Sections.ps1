<#
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

Script Name:
Remove-All_Sections.ps1

Synopsis:
This script is designed to Remove all Sections created by SDS from an O365 tenant. This script requires a PowerShell connection to Azure AD.

Syntax Examples and Options:
.\Remove-All_Sections.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/12/2016 - First Draft

#>

#Get all O365 Groups in a tenant
$Groups = Get-MsolGroup –All | ? {$_.EmailAddress –like “Section_*”}

#Start Foreach loop
Foreach ($Group in $Groups) {

	#Create variable for removal
	$OBJID = $Group.ObjectID
	$DN = $Group.DisplayName
	
	#Write progress to screen
	Write-host –ForegroundColor green “Removing Group $DN”

	#Remove the Group
	Remove-MsolGroup -ObjectId $OBJID –force
}

#Script is complete
Write-host –ForegroundColor Green “Script Complete”
