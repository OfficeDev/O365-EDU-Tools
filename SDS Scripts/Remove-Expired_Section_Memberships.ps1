<#
Script Name:
Remove-Expired_Section_Memberships.ps1

Synopsis:
This script is designed to get all SDS classes that have been marked Expired, and remove their members. All Expired classes and removals are displayed on screen.

Syntax Examples and Options:
.\Remove-Expired_Section_Memberships.ps1

Written By: 
Bill Sluss

Updates:
Daniel Baumgartner

Change Log:
Version 1.0, 8/08/206 - First Draft
Version 2.0, 6/10/2026 - Updated to Graph API, added progress bar, and added outfile.
#>

Connect-mggraph -scopes 'Group.ReadWrite.All' -NoWelcome
$outFile = '.\RemovedStudents.csv'

# Getting Expired Groups

$ExpiredGroups = get-mggroup -all | where {$_.MailNickname -match '^Exp[0-9]{4}'}
$count = $ExpiredGroups.count
Write-host -ForegroundColor Green "Found $Count Classes Marked Expired. Starting Cleanup - Removing Members"
$table = @()

# removing memberships
$i = 0
foreach ($group in $ExpiredGroups) {
    Write-Progress -Activity "Removing members for $($group.displayname)..." -Status "Processing($group.displayname)" -PercentComplete (($i/$count)*100)
    $groupId = $group.Id
    $GroupName = $group.DisplayName
    try {
        $owners = Get-MgGroupOwnerAsUser -GroupId $group.Id -All -ErrorAction Stop
        $ownerIds = @($owners | ForEach-Object { $_.Id })
        $members = Get-MgGroupMemberAsUser -GroupId $group.Id -All -ErrorAction Stop

        # Owners are also returned as members; remove only non-owner members.
        $membersToRemove = $members | Where-Object { $_.Id -and ($_.Id -notin $ownerIds) }

        foreach ($member in $membersToRemove) {
            Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $member.Id -ErrorAction Stop
            $memberId = $member.Id
            $MemberName = $member.DisplayName
            
            $row = [PSCustomObject]@{
                GroupId = $groupId
                GroupName = $GroupName
                MemberId = $memberId
                MemberName = $MemberName
            }
            $table += $row

        }
    }
    catch {
        Write-Warning "Couldn't process owners/members for group: $($group.DisplayName)"
    }

    $i++
}

$table | export-csv -path $outFile -NoTypeInformation

Write-Host 'Script complete. Disconnecting Graph.'
Disconnect-Graph