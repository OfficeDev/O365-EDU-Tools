<#
Script Name:
Set-Expired_Sections_as_Hidden.ps1

Synopsis:
This script is designed to Set all expired sections as hidden.

Syntax Examples and Options:
.\Set-Expired_Sections_as_Hidden.ps1

Written By:
Bill Sluss

Change Log:
Version 1.0, 8/9/2018 - First Draft
#>

#Connect to Azure and Exchange Online
$Cred = Get-Credential

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $Cred -Authentication Basic -AllowRedirection
Import-PSSession $Session

#Get All Sections potentially in the GAL
$Sections = get-UnifiedGroup | ? {$_.alias -like "Exp*"}

#Run Foreach loop against each section
Foreach ($Section in $Sections) {
	#Set the variable
	$DN = $Section.DisplayName
	$Addr = $Section.PrimarySmtpAddress

	#Write Progress
	Write-Host -foregroundcolor green "Setting Class Hidden - $DN"

	#Set the group as hidden
	Set-UnifiedGroup -Identity $Addr -HiddenFromAddressListsEnabled $true -warningaction:silentlycontinue
}

Write-Host -foregroundcolor green "Script Complete"