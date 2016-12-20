<#
Disclaimer: 
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages

Script Name:
Connect-Azure_AD_and_Exchange_Online.ps1

Synopsis:
This script is designed to connect your PowerShell client to Azure AD and Exchange Online. This script requires you have already installed the Azure AD module for PowerShell. If you haven't, run the Install-AAD_Module_and_Sign_in_Assistant.ps1 included in this script repository.

Syntax Examples:
.\Connect-Azure_AD_and_Exchange_Online.ps1

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