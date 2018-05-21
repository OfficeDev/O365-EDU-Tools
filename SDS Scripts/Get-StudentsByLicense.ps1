<#
Script Name:
Get-StudentsByLicense.ps1

Synopsis:
This script is designed to export all stuents and their assigned licenses within an O365 tenant, to identify students from teachers based on the license assignment. The result of this script will be a CSV file exported to the c:\temp directory of the local machine, called students.csv. The output of this file can then be used to run the Set-MinorConsent.ps1 script. This script requires the AzureAD powershell module be installed and loaded, before running the script.

Syntax Examples and Options:
.\Get-StudentsByLicense.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 05/18/2018 - First Draft
#>


#Connect to Azure AD
Write-Host "`n"
Write-Host -ForegroundColor Green "Please enter your Global Administrator Username and Password"
Write-Host "`n"
Connect-AzureAD


#Build the Assignments Array
$Assignments = @()


#Build the Student Sku Array
$StudentSkus = @()
$AllSkus = Get-AzureADSubscribedSku
$StudentSkuIDs = ($AllSkus | ? {$_.skupartnumber -like "*student*"}).skuid
Write-Host -ForegroundColor Green "The Student Skus identified are listed below:"
Foreach ($Element in $StudentSkuIDs) {
$SkuPart = (Get-AzureADSubscribedSku | ? {$_.SkuID -eq $Element}).SkuPartNumber
Write-Host -ForegroundColor Green "SkuID ${Element} for License $SkuPart"
}
Write-Host "`n"


#Get All User in AAD
Write-Host -ForegroundColor Green "Getting All Users in Azure Active Directory with an assigned license"
Write-Host "`n"
$AllUsers = Get-AzureADUser -All $true | ? {$_.AssignedLicenses -ne $null}


#Start foreach loop for all users with licenses
Foreach ($User in $AllUsers) {
$ObjectID = $User.ObjectID
Write-host "`n"
Write-Host -ForegroundColor Green "Getting Assigned Licenses for $DN"
$GetUser = Get-AzureADUser -objectid $user.objectid
$AssignedLicenses = ($GetUser | select -ExpandProperty assignedlicenses).skuid


#Set Variables
$UPN = $User.userprincipalname
$DN = $User.Displayname
$OBJ = $User.ObjectID
$Age = $User.AgeGroup
$Consent = $User.ConsentProvidedForMinor
$Legal = $User.LegalAgeGroupClassification


#Start foreach loop for all assigned skus
Foreach ($License in $AssignedLicenses) {
Write-host "$DN is assigned the SkuID $License"


#Creating new PS Object for each Sku and adding to the array
If ($StudentSkuIDs -contains $License) {
$StudentObj = New-Object PSObject
$StudentObj | Add-Member NoteProperty -Name UserPrincipalName -Value $UPN
$StudentObj | Add-Member NoteProperty -Name DisplayName -Value $DN
$StudentObj | Add-Member NoteProperty -Name ObjectID -Value $OBJ
$StudentObj | Add-Member NoteProperty -Name SkuID -Value $License
$StudentObj | Add-Member NoteProperty -Name AgeGroup -Value $Age
$StudentObj | Add-Member NoteProperty -Name ConsentProvidedForMinor -Value $Consent
$StudentObj | Add-Member NoteProperty -Name LegalAgeGroupClassification -Value $Legal
$Assignments += $StudentObj
		}
	}
}


#Exporting the Assignments Array to CSV
Write-Host "`n"
Write-Host -ForegroundColor Green "Exporting the License Assignments to the c:\temp\Assignments.csv file"
$Assignments | Export-CSV c:\temp\Students.csv -notype
Write-Host "`n"
Write-Host -ForegroundColor Green "Script is complete"
Write-Host "`n"


Write-Host -ForegroundColor Green "Confirm each SkuID listed in the csv file matches the Student SkuIDs shown below:"
Foreach ($Element in $StudentSkuIDs) {
$SkuPart = (Get-AzureADSubscribedSku | ? {$_.SkuID -eq $Element}).SkuPartNumber
Write-Host -ForegroundColor Green "SkuID ${Element} for License $SkuPart"
}
Write-Host "`n"

