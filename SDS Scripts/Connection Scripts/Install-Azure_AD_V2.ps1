<#
Script Name:
Install-Azure_AD_V2.ps1

Synopsis:
This script is designed to install the Azure AD Preview Module for PowerShell. 

Syntax Examples:
.\Install-Azure_AD_V2.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 09/24/2018 - First Draft
#>

#Connect to AAD and ExO
Write-Host -Foregroundcolor green "Installing the AzureADPreview Module for PowerShell"
Install-Module -Name AzureADPreview
