<#
Script Name:
Remove-All_Sections.ps1

Synopsis:
This script is designed to Remove all Sections created by SDS from an O365 tenant. 
This script requires a PowerShell connection to Azure AD using Connect-AzureAd cmdlet.
Help: https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0#connect-to-azure-ad

Syntax Examples and Options:
.\Remove-All_Sections.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/12/2016 - First Draft
Version 1.1, 08/01/2017 - Update to Soft Delete groups (Varun Menasina Chidananda)
#>

$logFilePath = "./remove-all-sections.log"
$softDeletePrefix = "SoftDeleted_"
Echo "Starting script to remove all groups at $([System.DateTime]::UtcNow)" | Out-File $logFilePath -Append

#Get all O365 Groups in a tenant with mail nickname starting with "Section_"
$Groups = Get-AzureADGroup -All $true | ? {$_.MailNickName -like "Section_*"}

Foreach ($Group in $Groups) {
	#Update group properties and delete
	$DifferentiatorSuffix = Get-Random -Minimum 100 -Maximum 999
	$NewDisplayName = $softDeletePrefix + $Group.DisplayName
	$NewMailNickName = $softDeletePrefix + $Group.MailNickName + $DifferentiatorSuffix
	
	$Log = "Soft deleting group $($Group.ObjectID) - [$($Group.MailNickName) / $($NewMailNickName)] - [$($Group.DisplayName) / $NewDisplayName]"
	Echo $Log | Out-File $logFilePath -Append
	Write-Host -ForegroundColor green "Removing Group $($Group.DisplayName)"
	
	Set-AzureADGroup -ObjectId $Group.ObjectID -MailNickName $NewMailNickName -DisplayName $NewDisplayName -ErrorAction Stop
	Remove-AzureADGroup -ObjectId $Group.ObjectID -ErrorAction Stop
}

Echo "Finished removing $($Groups.Count) Sections at $([System.DateTime]::UtcNow)" | Out-File $logFilePath -Append
Write-host -ForegroundColor Green "Script Complete. Log: $logFilePath `n"
