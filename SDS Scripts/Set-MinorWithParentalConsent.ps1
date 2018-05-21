<#
Script Name:
Set-MinorWithParentalConsent.ps1

Synopsis:
This script is designed to import the students listed in the students.csv which was exported from the Get-StudentsByLicense.ps1 script. Once imported, this script will set the AgeGroup and ConsentProvidedForMinor attributes. The net result of setting those two attributes is the attribute of LegalAgeGroupClassification set to MinorWithParentalConsent. This script requires the Azure AD V2 module for powershell be installed and loaded, before running this script.

Syntax Examples and Options:
.\Set-MinorWithParentalConsent.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 05/18/2018 - First Draft
#>


#Connect to Azure AD
Write-Host -ForegroundColor Green "Please enter your Global Administrator Username and Password"
Write-Host "`n"
Connect-AzureAD


#import the student.csv you just exported
$Students = import-csv "c:\temp\students.csv"


Foreach ($Student in $Students) {
$OBJ = $Student.ObjectID
$DN = $Student.DisplayName
Write-Host -ForegroundColor Green "Setting attributes for $DN"
Set-AzureADUser -objectID $OBJ -AgeGroup minor -ConsentProvidedForMinor granted
}

Write-Host "`n"
Write-Host -ForegroundColor Green "Script Complete"

Write-Host "`n"
Write-Host -ForegroundColor Green "You can rerun the Get-StudentsByLicense.ps1 to confirm the attributes were set correctly."