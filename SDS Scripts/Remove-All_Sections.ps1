<#
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
