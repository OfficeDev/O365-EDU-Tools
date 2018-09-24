<#
Script Name:
Connect-Azure_AD_V1_and_Exchange_Online.ps1

Synopsis:
This script is designed to connect your PowerShell client to Azure AD and Exchange Online. This script requires you have already installed the Azure AD module for PowerShell. If you haven't, run the Install-AAD_Module_and_Sign_in_Assistant.ps1 included in this script repository.

Syntax Examples:
.\Connect-Azure_AD_V1_and_Exchange_Online.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/09/2016 - First Draft

#>

#Connect to AAD and ExO
Write-Host -Foregroundcolor green "Enter your Office 365 Global Admin credentials in the authentication prompt!"
$Cred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $Cred -Authentication Basic -AllowRedirection
Import-PSSession $Session -allowclobber
Connect-MsolService -credential $cred
