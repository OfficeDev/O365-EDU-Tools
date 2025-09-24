<#

Script Name:
Set-Email_Addresses_Expired.ps1

Synopsis:
This script is designed to get all classes in Exchange Online which have been Marked Expired by SDS. Each of these classes will have their primarySMTPAddress updated with the mailnickname attribute, which is appended with "Expmmyy_". Once the update is complete, PowerShell will generate a report in the c:\temp directory which details every expired class, and the currently set displayname and primary email address.

Syntax Examples and Options:
.\Set-Email_Addresses_Expired.ps1 

Written By: 
Bill Sluss

Change Log:
Version 1.0, 8/6/2018 - First Draft

========================
 Required Prerequisites
========================

1. Install current PowerShell version.

2. Install the Exchange Online Management Module with command 'Install-Module ExchangeOnlineManagement'

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session

    b. Type "Connect-ExchangeOnline"

    c. Sign in with any tenant administrator credentials.

    d. If you are returned to the PowerShell session without error, you are correctly set up

4. Retry this script. If you still get an error about failing to load the Exchange Online Management module, troubleshoot why 'Install-Module ExchangeOnlineManagement' isn't working.

#>

#Connect to Exchange Online
Connect-ExchangeOnline

#Get all Exp Groups
$ExpGroups = Get-UnifiedGroup -ResultSize unlimited | ? {$_.alias -like "Exp*"}

#Start Foreach Loop
Foreach ($Group in $ExpGroups) {

#Document the Group Being Processed, incase of errors
$DN = $Group.DisplayName
Write-Host -ForegroundColor Green “Updating Email Address for $DN”

#Set Variables
$Alias = $Group.Alias
$Current = ($Group.primarysmtpaddress).toString()
$Domain = $Current.Split("@")[1]
$New = (“$Alias” + “@” + “$Domain”).ToString()

#Update the PrimarySMTPAddress
Set-UnifiedGroup $Alias -PrimarySMTPAddress $New
}

#Export the Expired Group with the updated addresses
Write-Host -ForegroundColor Red “Generating a report to show all Exp Groups and their new PrimarySMTPAddresses”
$ExpGroups = Get-UnifiedGroup -ResultSize unlimited | ? {$_.alias -like "Exp*"} | select DisplayName, Alias, PrimarySmtpAddress
$ExpGroups | Export-CSV c:\temp\Expired_Groups.csv -notype

Write-Output "Please run 'Disconnect-ExchangeOnline' if you are finished making changes.`n"
