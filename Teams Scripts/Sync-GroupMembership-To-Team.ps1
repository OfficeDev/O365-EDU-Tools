<#
.Synopsis
    If Teachers/Students do not appear in a Team but the memberships are correct in Azure Active Directory, this script will make sure that the Team memberships matches AAD.

    This script can be run by giving it one identifier of the Team/Group that should have memberships synced:
        o	SIS ID - of the Section
        o	Mail Nickname of the AAD Group 
        o	Email Address of the AAD Group 
        o	Group ID of the AAD Group

.Requirements
    Install the Microsoft.Graph.Authentication PowerShell modules, version 0.9.1 or better.

    For machine setup, the PowerShell script may need to be launched in Administrator mode

.Example
    -For a given SIS Id:
    .\Sync-GroupMembership-To-Team.ps1 -sisId "008200123"
    -For a given mailNickname:
    .\Sync-GroupMembership-To-Team.ps1 -mailNickname "Section_008200123"
    -For a given emailAddress:
    .\Sync-GroupMembership-To-Team.ps1 -emailAddress "Section_008200123@demoschool.onmicrosoft.com"
    -For a given groupId:
    .\Sync-GroupMembership-To-Team.ps1 -groupId "e77144f7-a42c-4124-856e-bf6312a5ed2f"
#>

Param (
    [Parameter(Mandatory = $false)][string]$sisId,
    [Parameter(Mandatory = $false)][string]$emailAddress,
    [Parameter(Mandatory = $false)][string]$mailNickname,
    [Parameter(Mandatory = $false)][string]$groupId)

function Initialize() {
    import-module Microsoft.Graph.Authentication -MinimumVersion 0.9.1
    Write-Output "If prompted, please use a tenant admin-account to grant access to 'TeamMember.ReadWrite.All', 'Group.Read.All' and 'Directory.AccessAsUser.All' privileges"
    connect-graph -scopes TeamMember.ReadWrite.All,Group.Read.All,Directory.AccessAsUser.All
}

# invoke-GraphRequest
#    -Method POST
#    -Uri https://graph.microsoft.com/beta/teams/{groupId}/members
#    -body '{
#        "@odata.type":"#microsoft.graph.aadUserConversationMember",
#        "roles":["owner"],
#        "user@odata.bind":"https://graph.microsoft.com/beta/users/{userId}"
#        } '
#    -Headers @{"Content-Type"="application/json"}
function Add-TeamUser($groupId, $memberId, $role, $logFilePath) {
    $uri = "https://graph.microsoft.com/beta/teams/$groupId/members"
    $requestBody = '{
        "@odata.type":"#microsoft.graph.aadUserConversationMember",
        "roles":["' + $role +'"],
        "user@odata.bind":"https://graph.microsoft.com/beta/users(''' + $memberId +''')"
    }'

    $result = invoke-graphrequest -Method POST -Uri $uri -body $requestBody -ContentType "application/json" -SkipHttpErrorCheck
    if ($result -ne $null -and $result.ContainsKey("error")) {
        if ($result.error.message.Contains("You do not have permission to perform this operation"))
        {
            write-output "User $memberId cannot be added to $groupId. They do not have an appropriate licenses." | out-file $logFilePath -Append
            write-host "User $memberId cannot be added to $groupId. They do not have an appropriate licenses."
        }
        else {
            write-output "Error encountered processing $memberId for team $groupId - $($result.error.message)." | out-file $logFilePath -Append
            write-host "Error encountered processing $memberId for team $groupId - $($result.error.message)."
        }
    }
}

function Remove-OwnersFromMembers($members, $groupOwners) {
    $groupOwnersById = @{}
    $groupOwners | % {$groupOwnersById.Add($_.id, $_)}
    $filteredMembers = $members | ? {-not $groupOwnersById.ContainsKey($_.id)}
    return $filteredMembers
}

function Refresh-TeamMembers($groupId, $groupOwners, $logFilePath) {
    $members = Get-Members-ForGroup $groupId
    $filteredMembers = Remove-OwnersFromMembers $members $groupOwners
    Write-host "Processing $($filteredMembers.Count) members."
    Refresh-TeamUsers $groupId $filteredMembers "member" $logFilePath
}

function Set-TeamOwners($groupId, $groupOwners, $logFilePath) {
    Write-host "Processing $($groupOwners.Count) owners."
    Refresh-TeamUsers $groupId $groupOwners "owner" $logFilePath
}

function Refresh-TeamUsers($groupId, $users, $role, $logFilePath) {
    foreach ($user in $users) {
        Try {
            Write-Output "Attempting to add $role $($user.displayName), $($user.id)" | Out-File $logFilePath -Append

            Add-TeamUser $groupId $user.id $role $logFilePath

            Start-Sleep -Seconds 0.5
        }
        Catch {
            $user.id | Out-File $logFilePath -Append
            Write-Output ($_.Exception) | Format-List -force | Out-File $logFilePath -Append
        }
    }
}

# Function "getData" is expected to be of the form:
# function func($currentUrl) { // Get Graph response; return response }
# return the data to be aggregate
function PageAll-GraphRequest($initialUrl, $logFilePath) {
    $result = @()

    $currentUrl = $initialUrl

    while ($currentUrl -ne $null) {
        $response = invoke-graphrequest -Method GET -Uri $currentUrl -ContentType "application/json"
        $result += $response.value
        $currentUrl = $response.'@odata.nextLink'
    }
    return $result
}

$groupSelectClause = "`$select=id,mailNickname,emailAddress,displayName,resourceProvisioningOptions"

function Get-TeamByGroupId($groupId) {
    $result = invoke-graphrequest -Method GET -Uri "https://graph.microsoft.com/beta/teams/$groupId/?`$select=id,isMembershipLimitedToOwners,displayName" -ContentType "application/json" -SkipHttpErrorCheck
    return $result
}

function Check-IsTeamFromResult($teamResult) {
    return ($teamResult -ne $null -and (-Not $teamResult.ContainsKey("error")))
}

function Check-IsTeamUnlocked($teamResult) {
    return -not $teamResult.isMembershipLimitedToOwners
}

function Get-Owners-ForGroup($groupId) {
    $initialOwnersUri = "https://graph.microsoft.com/beta/groups/$groupId/owners"
    $unfilteredOwners = PageAll-GraphRequest $initialOwnersUri $logFilePath
    $filteredOwners = $unfilteredOwners | Where-Object { $_."@odata.type" -eq "#microsoft.graph.user" }
    return $filteredOwners
}

function Get-Members-ForGroup($groupId) {
    $initialMembersUri = "https://graph.microsoft.com/beta/groups/$groupId/members"
    $unfilteredMembers = PageAll-GraphRequest $initialMembersUri $logFilePath
    $filteredMembers = $unfilteredMembers | Where-Object { $_."@odata.type" -eq "#microsoft.graph.user" }
    return $filteredMembers
}

function Get-SingleObjectId($uri) {
    $result = invoke-graphrequest -method GET -Uri $searchResultUri -ContentType "application/json"
    return $result.value[0].id
}

function Get-GroupIdForSisId($sisId) {
    return Get-GroupIdForMailNickname("Section_$sisId")
}

function Get-GroupIdForEmailAddress($emailAddress) {
    $searchResultUri = "https://graph.microsoft.com/beta/groups/?`$filter=mail+eq+'$emailAddress'&$groupSelectClause"
    return Get-SingleObjectId $searchResultUri
}

function Get-GroupIdForMailNickname($mailNickname) {
    $searchResultUri = "https://graph.microsoft.com/beta/groups/?`$filter=mailNickName+eq+'$mailNickname'&$groupSelectClause"
    return Get-SingleObjectId $searchResultUri
}

function Execute($sisId, $emailAddress, $mailNickname, $groupId, $logFilePath) {
    $processedTeams = $null

    Initialize

    if ($groupId -eq "") {
        if ($sisId -ne "") {
            $groupId = Get-GroupIdForSisId $sisId
        }
        elseif ($emailAddress -ne "") {
            $groupId = Get-GroupIdForEmailAddress $emailAddress
        }
        elseif ($mailNickname -ne "") {
            $groupId = Get-GroupIdForMailNickname $mailNickname
        }
    }

    $teamResult = Get-TeamByGroupId $groupId

    if (-not (Check-IsTeamFromResult $teamResult)) {
        write-error "Specified group $groupId is not a Team"
        exit
    }
    Write-host "Processing '$($teamResult.displayName).'"

    Write-host "Retrieving group owners."
    $groupOwners = Get-Owners-ForGroup $groupId
    Set-TeamOwners $groupId $groupOwners $logFilePath

    if (Check-IsTeamUnlocked $teamResult) {
        Refresh-TeamMembers $groupId $groupOwners $logFilePath
    }
    else {
        Write-host "Team $($team.displayName) is not unlocked; only owners have been synchronized."
    }
    
    Write-host "Script Complete."
}

$logFilePath = ".\Sync-GroupMembership-To-Team.log"

if ($sisId -eq "" -and $emailAddress -eq "" -and $mailNickname -eq "" -and $groupId -eq "") {
    Write-Error "One of -sisId, -emailAddress, -mailNickname, or -groupId must be specified."
    exit
}

try {
    Execute $sisId $emailAddress $mailNickname $groupId $logFilePath
}
catch {
    Write-Error "Terminal Error occurred in processing."
    write-error $_
    Write-output "Terminal error: exception: $($_.Exception)" | out-file $logFilePath -append
}

Write-Output "Please run 'disconnect-graph' if you are finished making changes."