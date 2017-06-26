<#

  Script Name: 
  Remove-Sections.ps1

  Synopsis: 
  This script is designed to Remove unused Sections created by SDS from an O365 tenant, based on the usage report SDS   generates. This script requires a PowerShell connection to Azure AD before executing.

  Syntax Examples and Options: 
  .\Remove-Sections.ps1 -SectionUsageReport "C:\SectionUsage.csv"

  Written By: 
  Mihir Patel

  Change Log: 
  Version 1.0, 06/19/2017 - First Draft

#>

[CmdletBinding()]

Param ([Parameter(Mandatory = $true, ValueFromPipeline = $true)] [string]$SectionUsageReport)

#Connect
Connect-MsolService

#Read Section Ids from the CSV file
$SectionInfo = Import-Csv $SectionUsageReport
$GroupIds = $SectionInfo | ? { $_."Usage.HasFiles" -eq "FALSE" } | % { $_.GraphId }

#Start Foreach loop
Foreach ($GroupId in $GroupIds) {

    #Get the O365 Group
    $Group = Get-MsolGroup -ObjectId $GroupId

    #Create variable for removal
    $DN = $Group.DisplayName
    
    #Write progress to screen
    Write-host -ForegroundColor green "Removing Group $DN"

    #Remove the Group
    Remove-MsolGroup -ObjectId $GroupId -Force
}

#Script is complete
Write-host -ForegroundColor Green "Script Complete"
