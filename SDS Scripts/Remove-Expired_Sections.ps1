<#
Script Name:
Remove-Expired_Sections.ps1

Synopsis:
This script is designed to get all SDS classes that have been marked Expired, and remove them from AAD. All Expired class removals are displayed on screen.

Syntax Examples and Options:
.\Remove-Expired_Sections.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 8/9/2018 - First Draft
#>

$Groups = Get-AzureADGroup -All:$true | ? {$_.DisplayName –like “Exp*”}
$Count = $Groups.count
Write-host –ForegroundColor Green “Found $Count Classes Marked Expired. Starting Cleanup - Remove Sections”

Foreach ($Group in $Groups) {
$Obj = $Group.objectID
$DN = $Group.DisplayName
Write-host –ForegroundColor Green “Removing $DN”
Remove-AzureADGroup -ObjectID $Obj
 		}

#Export the output array to CSV
Write-host –ForegroundColor Green “Script Complete”
