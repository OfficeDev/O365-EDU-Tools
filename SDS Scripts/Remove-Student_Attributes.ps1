<#
.Synopsis
This script is designed to get all SDS students, and removes all recently deprecated student attributes. No other object types or attributes are modified with this script.

.Example
.\Remove-Student_Attributes.ps1
#>

#Connect to Azure AD
Connect-AzureAD

$ExtID = "73eb1ff2-0bb6-4d2f-9944-3414b1906869"

#Get all users in the tenant
$Users = Get-AzureADUser -All:$true

#Start Foreach Loop
ForEach ($User in $Users) {
    #Set Variables 
    $DN = $User.DisplayName
    $Ext = $User | Select-Object -ExpandProperty ExtensionProperty

    #Determine if Student
    if ($Ext.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType -like "Student") {

        #Let the Admin know Student was found for processing
        write-host -ForegroundColor green "Removing Sensitive Attributes for $DN"

        #Remove each of the deprecated attributes 
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_Gender
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_ResidenceCountry
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_ResidenceZip
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_ResidenceState
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_ResidenceCity
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_ResidenceAddress
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_MailingCountry
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_MailingZip
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_MailingState
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_MailingCity
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_MailingAddress
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_FederalRace
        Remove-AzureADUserExtension -ObjectId $ExtID -ExtensionName extension_fe2174665583431c953114ff7268b7b3_Education_EnglishLanguageLearnersStatus
    }
}

write-host -ForegroundColor green "Script Complete"