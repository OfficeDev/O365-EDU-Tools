<#
Script Name:
Connect-Exchange_Online.ps1

Synopsis:
This script is designed to connect your PowerShell client to Exchange Online.

Syntax Examples:
.\Connect-Exchange_Online.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/09/2016 - First Draft
#>

#Connect to AAD and ExO
Write-Host -Foregroundcolor green "Enter your Exchange Admin credentials in the authentication prompt!"
$Cred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $Cred -Authentication Basic -AllowRedirection
Import-PSSession $Session -allowclobber
