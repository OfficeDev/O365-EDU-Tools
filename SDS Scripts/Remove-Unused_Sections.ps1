<#

  Script Name: 
  Remove-Sections.ps1

  Synopsis: 
  This script is designed to Remove unused Sections created by SDS from an O365 tenant, based on the usage report SDS generates. This script requires a PowerShell connection to Azure AD before executing.
  Required PowerShell Module: https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0

  Syntax Examples and Options: 
  .\Remove-Sections.ps1 -SectionUsageReport "C:\SectionUsage.csv"

  Written By: 
  Mihir Patel

  Change Log: 
  Version 1.0, 06/19/2017 - First Draft
  Version 1.1, 08/01/2017 - Update to Soft Delete groups (Varun Menasina Chidananda)
#>

[CmdletBinding()]

Param ([Parameter(Mandatory = $true, ValueFromPipeline = $true)] [string]$SectionUsageReport)

#Connect
Connect-AzureAD

#Read Section Ids from the CSV file
$SectionInfo = Import-Csv $SectionUsageReport
$GroupIds = $SectionInfo | ? { $_."Usage.HasFiles" -eq "FALSE" } | % { $_.GraphId }

$logFilePath = "./remove-unused-sections.log"
$softDeletePrefix = "SoftDeleted_"
Echo "Starting script to remove all groups at $([System.DateTime]::UtcNow)" | Out-File $logFilePath -Append

#Start Foreach loop
Foreach ($GroupId in $GroupIds) {
    #Get the O365 Group
    $Group = Get-AzureADGroup -ObjectId $GroupId

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

#Script is complete
Echo "Finished removing $($GroupIds.Count) Sections at $([System.DateTime]::UtcNow)" | Out-File $logFilePath -Append
Write-host -ForegroundColor Green "Script Complete. Log: $logFilePath `n"
