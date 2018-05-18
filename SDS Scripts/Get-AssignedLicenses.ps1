<#
Script Name:
Get-AssignedLicenses.ps1

Synopsis:
This script is designed to export all users and their assigned licenses within an O365 tenant. The result of this script will be a CSV file exported to the c:\temp directory of the local machine, called Assignments.csv. The output of this file can then be used to run the Set-Minors.ps1 script. This script requires a powershell connection to Azure AD, before running this script.

Syntax Examples and Options:
.\Get-AssignedLicenses.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 05/18/2018 - First Draft
#>


#Connect to Azure AD
Write-Host -ForegroundColor Green "Please enter your Global Administrator Username and Password"
Write-Host "`n"
Connect-AzureAD


#Build the Assignments Array
$Assignments = @()


#Get All User in AAD
Write-Host -ForegroundColor Green "Getting All Users in Azure Active Directory with an assigned license"
Write-Host "`n"
$AllUsers = Get-AzureADUser -All $true | ? {$_.AssignedLicenses -ne $null}


#Start foreach loop for all users with licenses
Foreach ($User in $AllUsers) {
$ObjectID = $User.ObjectID
Write-host "`n"
Write-Host -ForegroundColor Green "Getting Assigned Licenses for $DN"
$AssignedLicenses = (Get-AzureADUser -objectid $user.objectid | select -ExpandProperty assignedlicenses).skuid
$UPN = $User.userprincipalname
$DN = $User.Displayname
$OBJ = $User.ObjectID


#Start foreach loop for all assigned skus
Foreach ($License in $AssignedLicenses) {
Write-host "$DN is assigned the SkuID $License"


#Creating new PS Object for each Sku
$StudentObj = New-Object PSObject
$StudentObj | Add-Member NoteProperty -Name UserPrincipalName -Value $UPN
$StudentObj | Add-Member NoteProperty -Name DisplayName -Value $DN
$StudentObj | Add-Member NoteProperty -Name ObjectID -Value $OBJ
$StudentObj | Add-Member NoteProperty -Name SkuID -Value $License


#Adding the row to the Assignemnts Array
$Assignments += $StudentObj
	}
}


#Exporting the Assignments Array to CSV
Write-Host "`n"
Write-Host -ForegroundColor Green "Exporting the License Assignments to the c:\temp\Assignments.csv file"
$Assignments | Export-CSV c:\temp\Assignments.csv -notype
Write-Host "`n"
Write-Host -ForegroundColor Green "Script is complete"
