<#
Script Name:
Remove-Student_Attributes.ps1

Synopsis:
This script is designed to get all SDS students, and removes all recently depreceated student attributes. No other object types or attributes are modified with this script.

Syntax Examples and Options:
.\Remove-Student_Attributes.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 02/5/2019 - First Draft
#>

#Connect to Azure AD
Connect-AzureAD

#Get All Users in the Tenant
$Users = Get-AzureADUser -All:$true

#Start Foreach Loop
ForEach ($User in $Users) {
    #Set Variables 
    $ObjID = $User.ObjectId
    $DN = $User.DisplayName
    $UPN = $User.UserPrincipalName
    $Ext = $User | Select -ExpandProperty ExtensionProperty

#Determine if Student
if ($Ext.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType -like "Student") {

#Let the Admin know Student was found for processing
write-host -foregroundcolor green "Removing Sensitive Attributes for $DN"
$remove = " "

#Remove each of the deprecated attributes 
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_Gender -ExtensionValue $remove
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_ResidenceCountry -ExtensionValue $remove
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_ResidenceZip -ExtensionValue $remove
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_ResidenceState -ExtensionValue $remove
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_ResidenceCity -ExtensionValue $remove
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_ResidenceAddress -ExtensionValue $remove
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_MailingCountry -ExtensionValue $remove
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_MailingZip -ExtensionValue $remove
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_MailingState -ExtensionValue $remove
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_MailingCity -ExtensionValue $remove
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_MailingAddress -ExtensionValue $remove
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_FederalRace -ExtensionValue $remove
Set-AzureADUserExtension -ObjectId 73eb1ff2-0bb6-4d2f-9944-3414b1906869 -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_EnglishLanguageLearnersStatus -ExtensionValue $remove
}
}

write-host -foregroundcolor green "Script Complete"