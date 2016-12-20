<#
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

Script Name:
Set-All_Sections_as_Hidden.ps1

Synopsis:
This script is designed to connect to Azure AD and Exchange Online, get all SDS sections potentially in the GAL, and sets the Hidden From Address Lists parameter to true.

Syntax Examples and Options:
.\Set-All_Sections_as_Hidden.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/08/2016 - First Draft

#>

#Connect to Azure and Exchange Online
$Cred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $Cred -Authentication Basic -AllowRedirection
Import-PSSession $Session
Connect-MsolService -credential $cred

#Get All Sections potentially in the GAL
$Sections = Get-UnifiedGroup –ResultSize Unlimited | ? {$_.Name –like “Section_*”} 

#Run Foreach loop against each section
Foreach ($Section in $Sections) {

	#Tag the variable for use in the set cmd
	$Addr = $Section.PrimarySmtpAddress
	$DN = $Section.Displayname
	
	#Write Progress
	Write-Host -foregroundcolor green "Setting hidden attribute on group $DN"

	#Set the group as hidden
	Set-UnifiedGroup -Identity $Addr -HiddenFromAddressListsEnabled $true -warningaction:silentlycontinue
}

Write-Host -foregroundcolor green "Script Complete"