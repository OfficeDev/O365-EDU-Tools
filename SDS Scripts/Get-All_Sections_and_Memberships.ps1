<#
Script Name:
Get-All_Sections_and_Memberships.ps1

Synopsis:
This script will export all O365 Groups and their respective memberships. The result will be a CSV file located in the C:\temp directory, called Get-All_Sections_and_Memberships.csv. To run this script, you will first need to establish a PowerShell connection to Azure AD and Exchange Online.

Syntax:
.\Get-All_Sections_and_Memberships.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/07/2016 - First Draft
#>

#Build the Array
$Results = @()

#Get all Administrative Units
$Groups = Get-UnifiedGroup -ResultSize Unlimited

#Start Foreach Loop against every AU
Foreach ($Group in $Groups) {

    #Set Variables for each Group
    $ExchGuid = $Group.ExchangeGuid
    $Guid = $Group.Guid
    $Name = $Group.Name
    $DN = $Group.DisplayName
    $Addr = $Group.PrimarySmtpAddress
    $Owner =  Get-UnifiedGroupLinks –Identity $Name -LinkType Owners

    #Progress Reporting
    Write-Host -ForegroundColor Green "Processing Group $DN"

    #Get Memberships for each Group
    $GroupMember = Get-UnifiedGroupLinks $Name -LinkType Members
    $Total = $GroupMember.Count
    $RemoveNull = $Total-1

    #Loop Through each member and enter each as a line into our export
    For($i=0;$i -le $RemoveNull;$i++)
        {
        $AUObj = New-Object PSObject
        $AUObj | Add-Member NoteProperty -Name MemberName -Value $GroupMember[$i].Name
        $AUObj | Add-Member NoteProperty -Name MemberDisplayName -Value $GroupMember[$i].DisplayName
        $AUObj | Add-Member NoteProperty -Name MemberSAMAccountName -Value $GroupMember[$i].SAMAccountName
        $AUObj | Add-Member NoteProperty -Name MemberPrimarySMTPAddress -Value $GroupMember[$i].PrimarySMTPAddress
        $AUObj | Add-Member NoteProperty -Name GroupDisplayName -Value $DN
        $AUObj | Add-Member NoteProperty -Name GroupName -Value $Name
        $AUObj | Add-Member NoteProperty -Name GroupExchangeGuid -Value $ExchGuid
        $AUObj | Add-Member NoteProperty -Name GroupGuid -Value $Guid
        $AUObj | Add-Member NoteProperty -Name GroupOwner -Value $Owner
	$AUObj | Add-Member NoteProperty -Name GroupAddress -Value $Addr
        $Results += $AUObj
        } 

}

#Export the Results
$Results | Export-Csv "C:\temp\Get-All_Sections_and_Memberships.csv” -NoTypeInformation

#Script Complete
Write-Host -ForegroundColor Green "Script is complete."
