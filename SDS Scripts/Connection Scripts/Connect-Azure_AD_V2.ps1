<#
Script Name:
Connect-Azure_AD_V2.ps1

Synopsis:
This script is designed to connect your PowerShell client to Azure AD using the V1 MSOnline module. This script requires you have already installed the Azure AD module for PowerShell. If you haven't, run the Install-AzureADModule.ps1 included in this script repository.

Syntax Examples:
.\Connect-Azure_AD_V2.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 09/24/2018 - First Draft
#>

#Connect to AAD and ExO
Write-Host -Foregroundcolor green "Enter your Office 365 Global Admin credentials in the authentication prompt!"
$Cred = Get-Credential
Connect-AzureAD -credential $cred