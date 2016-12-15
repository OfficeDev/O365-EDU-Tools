<#
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

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
