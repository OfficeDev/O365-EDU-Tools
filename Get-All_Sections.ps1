<#
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

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
