<#
Script Name:
Get-All_Users_With_and_Without_Classroom.ps1

Synopsis:
This script is designed to export all users within an O365 tenant, and break them into 2 lists. Users with Classroom and User without Classroom. The result of this script will be 2 CSV files in the C:\temp directory. The first file is called users_with_classroom.csv, and a second file called users_without_classroom.csv. This script requires a powershell connection to Azure AD, before running this script.

Syntax Examples and Options:
.\Get-All_Users_With_and_Without_Classroom.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/05/2016 - First Draft
#>

#Create the arrays
$HasClassroom = @()
$NoClassroom = @()

#Get All users in the tenant
$Users = Get-Msoluser -all

#Start the Foreach loop
Foreach ($User in $Users) {

#Set variables for each individual user
$DN = $user.displayname
$sku = (Get-msoluser -userprincipalname $user.userprincipalname).licenses.accountskuid

#Get the user details if they have Classroom and add them to the HasClassroom export
If ($sku -like "*CLASSDASH_Preview*"){
	write-host -foregroundcolor green "$DN has the Classroom license"
	$HasClassroom += New-Object PsObject -Property @{
        "Username"="$($User.DisplayName)";
        "UPN"="$($User.UserPrincipalName)";
        }
}

#Get the user details if they dont have Classroom and add them to the NoClassroom Export
If ($sku -notlike "*CLASSDASH_Preview*"){
	write-host -foregroundcolor red "$DN does not have the Classroom license"
	$NoClassroom += New-Object PsObject -Property @{
        "Username"="$($User.DisplayName)";
        "UPN"="$($User.UserPrincipalName)";
        }
}
}

#Export the results
$HasClassroom | Export-CSV C:\temp\Users_with_classroom.csv -NoTypeInformation
$NoClassroom | Export-CSV C:\temp\Users_without_classroom.csv -NoTypeInformation
