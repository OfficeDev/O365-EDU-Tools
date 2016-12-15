<#
Disclaimer: 
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages

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
