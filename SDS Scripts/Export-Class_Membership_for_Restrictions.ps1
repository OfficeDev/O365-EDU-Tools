<#
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

Script Name:
Export-Class_Membership_for_Restrictions.ps1

Synopsis:
This script is designed to export each section/group synced through SDS, and provide a user to class mapping for every user and class in the organization. This output will be used to stamp the acceptance permissions on each of the respective mailboxes. 

Syntax Examples and Options:
.\Export-Class_Membership_for_Restrictions.ps1 

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/14/2016 - First Draft

#> 

#Build the Array
$Results = @()

#Get all Administrative Units
$Groups = Get-MsolGroup -All | ? {$_.emailaddress -like "*Section_*"}

#Start Foreach Loop against every AU
Foreach ($Group in $Groups) {

    #Set Variables for each Group
    $DN = $Group.DisplayName
    $GroupObjectID = $Group.ObjectID
    $Addr = $Group.EmailAddress
    Write-Host -ForegroundColor Green "Exporting data for group $DN"

    #Get Memberships for each Group
    $GroupMember = Get-MsolGroupMember -GroupObjectID $GroupObjectID
    $Total = $GroupMember.Count
    $RemoveNull = $Total-1

    #Loop Through each member and enter each as a line into our export
    For($i=0;$i -le $RemoveNull;$i++)
        {
        $AUObj = New-Object PSObject
        $AUObj | Add-Member NoteProperty -Name GroupDisplayName -Value $DN
        $AUObj | Add-Member NoteProperty -Name GroupObjectID -Value $GroupObjectID
	$AUObj | Add-Member NoteProperty -Name GroupEmailAddress -Value $Addr
        $AUObj | Add-Member NoteProperty -Name MemberDisplayName -Value $GroupMember[$i].DisplayName
        $AUObj | Add-Member NoteProperty -Name MemberObjectID -Value $GroupMember[$i].ObjectId
        $AUObj | Add-Member NoteProperty -Name MemberPrimarySMTPAddress -Value $GroupMember[$i].EmailAddress
        $Results += $AUObj
        } 
}

#Export the Results
$Results | Export-Csv "C:\temp\Export-Class_Membership_for_Restrictions.csv” -NoTypeInformation

