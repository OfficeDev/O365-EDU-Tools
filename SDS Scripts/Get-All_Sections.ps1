<#
Script Name:
Get-All_Sections.ps1

Synopsis:
This script is designed to get all SDS sections, and export the default Azure AD attributes to a CSV files called Get-All_Sections.csv, into the c:\temp directory. No other object types are exported with this script.

Syntax Examples and Options:
.\Get-All_Sections.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/07/206 - First Draft

#>

$output = @()
$Groups = Get-MsolGroup –All | ? {$_.EmailAddress –like “Section_*”}
Foreach ($Group in $Groups) {

	#Display the group being processed
	$DN = $Group.DisplayName
	Write-Host -ForegroundColor Green "Processing Group $DN"

	#Create the PS Object
    	$userObj = New-Object PSObject

	#Add Members for Group Attributes
        $userObj | Add-Member NoteProperty -Name DisplayName -Value $Group.DisplayName
        $userObj | Add-Member NoteProperty -Name EmailAddress -Value $Group.EmailAddress
	$userObj | Add-Member NoteProperty -Name ObjectID -Value $Group.ObjectID
	$userObj | Add-Member NoteProperty -Name ValidationStatus -Value $Group.ValidationStatus

	#Add All Member Attributes to PS Object
	$output += $userObj
 	}

#Export the output array to CSV
$output | Export-csv c:\temp\Get-All_Sections.csv -NoTypeInformation

Write-host –ForegroundColor Green “Script Complete”
