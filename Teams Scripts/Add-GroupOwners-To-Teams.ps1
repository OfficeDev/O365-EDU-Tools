<#
.Synopsis
    Resolves sync issues between Azure Active Directory (AAD) and the Teams internal directory where owners who were present in AAD could not
    always see the Team.  This script works for SDS created Teams.  The script will find all owners of a Team in AAD and then add those users
    to the Team directly using the beta/teams/<id>/members Microsoft Graph endpoint.

    Depending on the number of groups SDS has created that have been provisioned, the processing for All SDS teams could take several hours.
    It is recomended to only process a single teacher's classes instead.

.Requirements
    Install the Microsoft.Graph.Authentication PowerShell modules, version 0.9.1 or better.

    For machine setup, the PowerShell script may need to be launched in Administrator mode

.Example
    -For a specific user
    .\Add-Group-Owners-To-Teams.ps1 -EducatorUPN john.smith@school.edu
    -For all SDS Teams
    .\Add-Group-Owners-To-Teams.ps1
    -Include archived teams.
    .\Add-Group-Owners-To-Teams.ps1 -includeArchived
#>

Param (
    [Parameter(Mandatory = $false)][string]$EducatorUPN,
    [Parameter(Mandatory = $false)][Switch]$includeArchived)

function Initialize() {
    import-module Microsoft.Graph.Authentication -MinimumVersion 0.9.1
    Write-Output "If prompted, please use a tenant admin-account to grant access to 'TeamMember.ReadWrite.All', 'Group.Read.All' and 'Directory.AccessAsUser.All' privileges"
    Refresh-Token
}

$lastRefreshed = $null
function Refresh-Token() {
    if ($lastRefreshed -eq $null -or (get-date - $lastRefreshed).Minutes -gt 10) {
        connect-graph -scopes TeamMember.ReadWrite.All,Group.Read.All,Directory.AccessAsUser.All
        $lastRefreshed = get-date
    }
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

function Refresh-TeamOwners($groupId, $logFilePath) {
    $TeamOwners = Get-Owners-ForGroup $groupId
    foreach ($owner in $TeamOwners) {
        Try {
            Write-Output "Attempting to add owner $($owner.displayName), $($owner.id)" | Out-File $logFilePath -Append

            Add-TeamUser $groupId $owner.id "owner" $logFilePath

            Start-Sleep -Seconds 0.5
        }
        Catch {
            write-output "Owner $($owner.id) failed." | Out-File $logFilePath -Append
            write-output $_ | out-file $logFilePath -Append
            Write-Output ($_.Exception) | Format-List -force | Out-File $logFilePath -Append
        }
    }
}

function Refresh-AllTeamsOwners($SDSTeams, $logFilePath) {
    $i = 0
    $processedTeams = @()

    ForEach ($team in $SDSTeams) {
        Refresh-Token
        Write-Progress "Processing teams..." -Status "Progress" -PercentComplete (($i / $SDSTeams.count) * 100)
        Write-Output "Processing team $($team.displayName)" | Out-File $logFilePath -Append
        try {
            Refresh-TeamOwners $team.id $logFilePath
        }
        catch {
            Write-Output "Error processing team $($team.displayName)" | Out-File $logFilePath -Append
            $team.GroupId | Out-File $logFilePath -Append
            Write-Output ($_.Exception) | Format-List -force | Out-File $logFilePath -Append
        }
        $processedTeams = [array]$processedTeams + [array]$team

        $i ++
    }

    return $processedTeams
}

# Function "getData" is expected to be of the form:
# function func($currentUrl) { // Get Graph response; return response }
# return the data to be aggregate
function PageAll-GraphRequest($initialUrl, $logFilePath) {
    $result = @()

    $currentUrl = $initialUrl
    while ($currentUrl -ne $null) {
        Refresh-Token
        $response = invoke-graphrequest -Method GET -Uri $currentUrl -ContentType "application/json"
        $result += $response.value
        $currentUrl = $response.'@odata.nextLink'
    }
    return $result
}

$groupSelectClause = "`$select=id,mailNickname,emailAddress,displayName,resourceProvisioningOptions"

function Check-Team($group, $includeArchived) {
    if (($group.resourceProvisioningOptions -ne $null) -and $group.resourceProvisioningOptions.Contains("Team") -and $group.mailNickname.StartsWith("Section_")) {
        try {
            Refresh-Token
            $groupId = $group.id
            $result = invoke-graphrequest -Method GET -Uri "https://graph.microsoft.com/beta/teams/$groupId/?`$select=id,isArchived" -ContentType "application/json" -SkipHttpErrorCheck
            return ($result -ne $null -and (-Not $result.ContainsKey("error")) -and ($result.isArchived -eq $false -or $includeArchived))
        }
        catch {
            return $false
        }
    }
}

function Get-SDSTeams($includeArchived, $logFilePath) {
    $initialSDSGroupUri = "https://graph.microsoft.com/beta/groups?`$filter=groupTypes/any(c:c+eq+'Unified')+and+startswith(mailNickname,'Section_')+and+resourceProvisioningOptions/Any(x:x+eq+'Team')&$groupSelectClause"
    $unfilteredSDSGroups = PageAll-GraphRequest $initialSDSGroupUri $logFilePath
    write-output "Retrieve $($unfilteredSDSGroups.Count) groups." | out-file $logFilePath -Append
    $i = 0
    $filteredSDSTeams = $unfilteredSDSGroups | Where-Object { (Write-Progress "Validating groups..." -Status "Progress" -PercentComplete (($i++ / $unfilteredSDSGroups.count) * 100)) -or (Check-Team $_ $includeArchived) }
    write-output "Filtered to $($filteredSDSTeams.Count) groups." | out-file $logFilePath -Append
    return $filteredSDSTeams
}

function Get-SDSTeams-ForUser($EducatorUPN, $logFilePath) {
    $initialOwnedObjectsUri = "https://graph.microsoft.com/beta/users/$EducatorUPN/ownedObjects?$groupSelectClause"
    $unfilteredOwnedGroups = PageAll-GraphRequest $initialOwnedObjectsUri $logFilePath
    $i = 0
    $filteredOwnedGroups =  $unfilteredOwnedGroups | Where-Object { (Write-Progress "Validating groups..." -Status "Progress" -PercentComplete (($i++ / $unfilteredOwnedGroups.count) * 100)) -or (Check-Team $_ $includeArchived) }
    return $filteredOwnedGroups
}

function Get-Owners-ForGroup($groupId) {
    $initialOwnersUri = "https://graph.microsoft.com/beta/groups/$groupId/owners"
    $unfilteredOwners = PageAll-GraphRequest $initialOwnersUri $logFilePath
    $filteredOwners = $unfilteredOwners | Where-Object { $_."@odata.type" -eq "#microsoft.graph.user" }
    return $filteredOwners
}

function Execute($EducatorUPN, $includeArchived, $recordedGroups, $logFilePath) {
    $processedTeams = $null

    Initialize
    
    if ($EducatorUPN -eq "") {
        Write-Host "Obtaining list of SDS Created Teams. Please wait..."
        Write-Output "Obtaining list of SDS Created Teams. Please wait..." | out-file $logFilePath -append

        $SDSTeams = Get-SDSTeams $includeArchived $logFilePath

        Write-Host "Identified $($SDSTeams.count) teams that are provisioned."
        Write-Output "Identified $($SDSTeams.count) teams that are provisioned." | Out-File $logFilePath -Append

        # Process Removal and addition of all team owners

        Write-Output "Processing addition of all owners for $($SDSTeams.count) Teams, please wait as this could take several hours..." | Out-File $logFilePath -Append
        Write-Host "Processing addition of all owners for $($SDSTeams.count) Teams, please wait as this could take several hours..."

        $processedTeams = Refresh-AllTeamsOwners $SDSTeams $logFilePath
    }
    else {
        Write-Output "Obtaining list of SDS Teams for user $($EducatorUPN), Please wait..." | Out-File $logFilePath -Append
        Write-Host "Obtaining list of SDS Teams for user $($EducatorUPN), Please wait..."
        $SDSTeams = Get-SDSTeams-ForUser $EducatorUPN $includeArchived $logFilePath

        Write-Output "Identified $($SDSTeams.count) teams that are provisioned." | Out-File $logFilePath -Append
        Write-Host "Identified $($SDSTeams.count) teams that are provisioned."

        # Process addition of all team owners

        Write-Output "Processing addition of all owners for $($SDSTeams.count) Teams, please wait as this could take several hours..." | Out-File $logFilePath -Append
        Write-Host "Processing addition of all owners for $($SDSTeams.count) Teams, please wait as this could take several hours..."

        $processedTeams = Refresh-AllTeamsOwners $SDSTeams $logFilePath
    }

    $processedTeams | Export-Csv -Path $recordedGroups -NoTypeInformation

    Write-Output "Script Complete." | Out-File $logFilePath -Append
    Write-Host "Script Complete."
}

$logFilePath = ".\Add-Group-Owners-To-Teams.log"
$recordedGroups = ".\Updated-Teams.csv"

try {
    Execute $EducatorUPN $includeArchived $recordedGroups $logFilePath
}
catch {
    Write-Error "Terminal Error occurred in processing."
    write-error $_
    Write-output "Terminal error: exception: $($_.Exception)" | out-file $logFilePath -append
}

Write-Output "Please run 'disconnect-graph' if you are finished making changes."