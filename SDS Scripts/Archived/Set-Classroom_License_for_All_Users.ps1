<#
Script Name:
Set-Classroom_License_for_All_Users.ps1

Synopsis:
This script imports a list of users, and adds the Class Dashboard Preview license to each account in the csv. The users.csv must reside in the c:\temp directory, and be formatted as shown below. Only one column is needed, and should be populated with the UPN of the users you want to add license for. There are no switches or parameters needed to run this script.

CSV Format:
Userprincipalname
user1@contoso.com
user2@contoso.com
user3@contoso.com

Syntax Examples:
.\Set-Classroom_License_for_All_Users.ps1 

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/06/2016 - First Draft

#>

#Get All Users
$Users = Get-msoluser -all

#Start a foreach loop
Foreach ($User in $Users) {

#Set UPN as a variable
$upn = $user.userprincipalname

#Set AccountSku as a variable
$sku = (get-msolaccountsku | ? {$_.accountskuid -like "*CLASSDASH*"}).accountskuid

#Set Usage Location
Set-MsolUser -UserPrincipalName $upn -UsageLocation US

#Write progress to the screen
Write-Host -Foregroundcolor green "Adding Class Dashboard License to $upn"

#Add the Classroom license
Set-MsolUserLicense -UserPrincipalName $upn -addlicenses $sku -warningaction:silentlycontinue
}

write-host -foregroundcolor green "Script is Complete"
write-host -foregroundcolor green "Below is a summary of the licenses applied. The Classroom license is the CLASSDASH_PREVIEW license listed"
Get-MsolAccountSku
