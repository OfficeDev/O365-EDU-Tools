<#
Script Name:
Get-All_Sections_and_Membership_Counts.ps1

Synopsis:
This script is designed to get all SDS sections, and their respective membership counts. The script will then export the results to a CSV files called Get-All_Sections_and_Membership_Counts.csv, into the c:\temp directory. No other object types are exported with this script.

Syntax Examples and Options:
.\Get-All_Sections_and_Membership_Counts.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/13/206 - First Draft

#>


#Build the Array
$Results = @()

#Get all Groups from SDS
$Groups = Get-MsolGroup -All | ? {$_.EmailAddress –like “Section_*”}

#Start Foreach Loop
Foreach ($Group in $Groups) {

#Mark variables for export
$Name = $Group.DisplayName
$ObjID = $Group.objectID
$Alias = $Group.EmailAddress
$Members = Get-MsolGroupMember -GroupObjectID $ObjID
$Count = ($Members).count

	#Create the PS object
        $AUObj = New-Object PSObject

	#Add each member to be exported against each group
        $AUObj | Add-Member NoteProperty -Name GroupName -Value $Name
        $AUObj | Add-Member NoteProperty -Name EmailAddress -Value $Alias
        $AUObj | Add-Member NoteProperty -Name ObjectID -Value $ObjID
        $AUObj | Add-Member NoteProperty -Name MemberCount -Value $Count
        
	#Add the members to the Results Array
	$Results += $AUObj
}

#Export the Results
$Results | Export-Csv "C:\temp\Get-All_Sections_and_Membership_Counts.csv” -NoTypeInformation

