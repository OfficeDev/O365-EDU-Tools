<#
Script Name:
Set-Some_Sections_as_Hidden.ps1

Synopsis:
This script is designed to import a CSV file that contains sections in the simple format noted below. The CSV should reside in the c:\temp directory, and be called Section.CSV file. Once imported, this script will hide any section from the GAL contained the CSV file.

CSV Format:		Section.csv Example:

HeaderRow		PrimarySmtpAddress
--------------		------------------
<smtp_address1>		group1@contoso.com
<smtp_address2>		group2@contoso.com
<smtp_address3>		group3@contoso.com


Syntax Examples and Options:
.\Set-Some_Sections_as_Hidden.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/06/2016 - First Draft
#>

#Connect to Azure and Exchange Online
$Cred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $Cred -Authentication Basic -AllowRedirection
Import-PSSession $Session
Connect-MsolService -credential $cred

#Get All Sections potentially in the GAL
$Sections = Import-CSV C:\temp\Section.csv 

#Run Foreach loop against each section
Foreach ($Section in $Sections) {

	#Tag the variable for use in the set cmd
	$Addr = $Section.PrimarySmtpAddress
	
	#Get the DisplayName of the group for the progress display
	$Group2 = Get-UnifiedGroup -Identity $Addr
	$DN = $Section.Displayname
	
	#Write Progress
	Write-Host -foregroundcolor green "Setting hidden attribute on group $DN"

	#Set the group as hidden
	Set-UnifiedGroup -Identity $Addr -HiddenFromAddressListsEnabled $true -warningaction:silentlycontinue
}

Write-Host -foregroundcolor green "Script Complete"
