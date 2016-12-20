<#
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

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

