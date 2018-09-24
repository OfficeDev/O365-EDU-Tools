<#
Script Name:
Set-Acceptance_Permissions_SDS_Sections.ps1

Synopsis:
This script is designed to add each group/section which a student is a member of, to the acceptance permissions on the user's mailbox. After running this script, only the members of those groups/sections will be able to email that particular user.

Syntax Examples and Options:
.\Set-Acceptance_Permissions_SDS_Sections.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/14/2016 - First Draft

#>

#Import the CSV we exported
$Users = Import-Csv "C:\temp\Export-Class_Membership_for_Restrictions.csv”

#Start Foearch loop against the initial export
Foreach ($User in $Users) {

$GDN = $User.GroupDisplayName
$GEA = $User.GroupEmailAddress
$MDN = $User.MemberDisplayName
$MOID = $User.MemberObjectID

#Get Mailbox for each entery in the initial export
$GMBX = Get-MsolUser -ObjectId $MOID

#Query for Custom Attribute 1
$Student = $GMBX.department

#If Department is set to "Student" we will add group to the acceptance restrictions on the mailbox
If ($Student -eq "Student") {
Write-Host -ForegroundColor Green "Adding $GDN to $MDN acceptance list"
Set-Mailbox $MOID -AcceptMessagesOnlyFromDLMembers @{add=$GEA}
}
}
