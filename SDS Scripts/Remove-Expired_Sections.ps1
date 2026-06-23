<#
Script Name:
Remove-Expired_Sections.ps1

Synopsis:
This script is designed to get all SDS classes that have been marked Expired, and remove them from AAD. All Expired class removals are displayed on screen.

Syntax Examples and Options:
.\Remove-Expired_Sections.ps1

Written By: 
Bill Sluss

Updates:
Daniel Baumgartner

Change Log:
Version 1.0, 8/9/2018 - First Draft
Version 2.0 6/16/2026 - Updating to use Graph API
#>

Connect-mggraph -scopes 'Group.ReadWrite.All' -NoWelcome
$i = 0
$ExpiredGroups = get-mggroup -all | where {$_.MailNickname -match '^Exp[0-9]{4}'}
$Count = $ExpiredGroups.count
Write-host -ForegroundColor Green "Found $Count Classes Marked Expired. Starting Cleanup - Remove Sections"

Foreach ($Group in $ExpiredGroups) {
    Write-Progress -Activity "Removing $($group.displayname)..." -Status "Processing($group.displayname)" -PercentComplete (($i/$count)*100)
    $Obj = $Group.ID
    $DN = $Group.DisplayName
    Write-host -ForegroundColor Green "Removing $DN"
    Remove-MgGroup -GroupId $Obj

    $i++
}

#Export the output array to CSV
Write-host -ForegroundColor Green "Script Complete"
Disconnect-Graph