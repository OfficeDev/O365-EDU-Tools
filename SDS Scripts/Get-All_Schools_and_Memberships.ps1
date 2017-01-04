<#
Script Name:
Get-All_Schools_and_Memberships.ps1

Synopsis:
This script is designed to export all Schools and their respective members. The result of this script is a single CSV export in your c:\temp directory, called Get-All_Schools_and_Memberships.csv. This script first requires a PowerShell connection to Azure Active Directory. If you’re not familiar with connecting, run the Connect-Azure_AD_and_Exchange_Online.ps1. If you haven’t installed the Azure AD module or the MOSSIA, you won’t be able to connect. To install these pre-requisites, run the Install-AAD_Module_and_Sign_in_Assistant.ps1 first.

Syntax:
.\Get-All_Schools_and_Memberships.ps1 

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/05/2016 - First Draft
#>

#Build the Array
$Results = @()

#Get all Administrative Units
$AUs = Get-MsolAdministrativeUnit –All

#Start Foreach Loop against every AU
Foreach ($AU in $AUs) {

    #Set Variables for each AU
    $ObjID = $AU.objectID
    $Desc = $AU.description
    $DN = $AU.DisplayName

    #Get Memberships for each AU
    Write-Host -ForeGroundColor Green "Processing School $DN"
    $AUMember = Get-MsolAdministrativeUnitMember –AdministrativeUnitObjectID $ObjID -All
    $Total = $AUMember.Count
    $RemoveNull = $Total-1

    #Loop Through each member and enter each as a line into our export
    For($i=0;$i -le $RemoveNull;$i++)
        {
        $AUObj = New-Object PSObject
        $AUObj | Add-Member NoteProperty -Name DisplayName -Value $DN
        $AUObj | Add-Member NoteProperty -Name Description -Value $Desc
        $AUObj | Add-Member NoteProperty -Name AUObjectID -Value $ObjID
        $AUObj | Add-Member NoteProperty -Name MemberEmailAddress -Value $AUMember[$i].EmailAddress
        $AUObj | Add-Member NoteProperty -Name MemberObjectID -Value $AUMember[$i].ObjectID
        $Results += $AUObj
        } 
}

#Export the Results
$Results | Export-Csv "C:\temp\Get-All_Schools_and_Memberships.csv” -NoTypeInformation

#Script Complete
Write-Host -ForegroundColor Green "Script is complete"
