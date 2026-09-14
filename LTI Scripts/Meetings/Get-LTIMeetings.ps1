<#
.SYNOPSIS
    Finds all Microsoft 365 LTI meetings in a user's mailbox using the Graph API.

.DESCRIPTION
    Uses app-only (client credentials) auth to call the Graph Calendar API and
    retrieve Outlook events stamped with the LTI extended property
    'String {00020329-0000-0000-C000-000000000046} Name OfficeLtiMeetingsContextId'.

    Searches for one exact LTI context ID in a single mailbox, in members and
    owners of groups tagged with that context ID, or across all licensed users.
    Writes results to a timestamped CSV file.

.PARAMETER TenantId
    Tenant ID (GUID or domain) for the Entra ID directory.

.PARAMETER AppId
    App registration (client) ID. See NOTES for required Microsoft Graph
    application permissions.

.PARAMETER Secret
    Client secret value for the app registration.

.PARAMETER UserUpn
    UPN of a single mailbox to query. Omit to sweep all users in the tenant.

.PARAMETER LTIContextId
    Required. Returns events matching this exact LTI context ID.

.PARAMETER ScanGroupMembers
    Optional. Finds groups whose description is tagged with the LTI context ID,
    then scans the unique user members and owners of those groups instead of all
    licensed users. Requires GroupMember.Read.All or Group.Read.All application
    permission in addition to the calendar and user permissions.

.PARAMETER OrganizerOnly
    Optional. Defaults to true, returning only meetings organized by the mailbox
    user. Set to false with -OrganizerOnly:$false to include other meetings.

.PARAMETER CsvPath
    Optional full file path for the output CSV. Defaults to the script directory
    with a timestamped name.

.NOTES
        Required Microsoft Graph APPLICATION permissions (admin-consented):
            - Calendars.Read: Read calendar events from target mailboxes.
            - User.Read.All: Enumerate licensed users and read user mailbox identities.
            - GroupMember.Read.All: Search groups and read user members and owners when
                using -ScanGroupMembers. Group.Read.All can be used as a broader alternative.

.EXAMPLE
    .\Get-LTIMeetings.ps1 -TenantId "contoso.onmicrosoft.com" -AppId "..." -Secret "..." -LTIContextId "course-context-id" -UserUpn "teacher@contoso.com"
    # Scans one mailbox for the specified context ID

.EXAMPLE
    .\Get-LTIMeetings.ps1 -TenantId "contoso.onmicrosoft.com" -AppId "..." -Secret "..." -LTIContextId "course-context-id"
    # Scans all licensed users for the specified context ID

.EXAMPLE
    .\Get-LTIMeetings.ps1 -TenantId "contoso.onmicrosoft.com" -AppId "..." -Secret "..." -LTIContextId "course-context-id" -ScanGroupMembers
    # Scans only user members and owners of groups tagged with the context ID
#>

#Requires -Version 7.0

param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$AppId,

    [Parameter(Mandatory = $true)]
    [string]$Secret,

    [Parameter(Mandatory = $false)]
    [string]$UserUpn,

    [Parameter(Mandatory = $true)]
    [string]$LTIContextId,

    [Parameter(Mandatory = $false)]
    [switch]$ScanGroupMembers,

    [Parameter(Mandatory = $false)]
    [bool]$OrganizerOnly = $true,

    [Parameter(Mandatory = $false)]
    [string]$CsvPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSBoundParameters.ContainsKey('UserUpn') -and $PSBoundParameters.ContainsKey('ScanGroupMembers')) {
    throw 'The -UserUpn and -ScanGroupMembers parameters are mutually exclusive and cannot be supplied together.'
}

# ── Constants ────────────────────────────────────────────────────────────────

$PROP_ID   = "String {00020329-0000-0000-C000-000000000046} Name OfficeLtiMeetingsContextId"
$GRAPH_BASE = "https://graph.microsoft.com/v1.0"

# ── Output CSV path ──────────────────────────────────────────────────────────

if (-not $CsvPath) {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $CsvPath   = Join-Path $scriptDir "LTI_Meetings_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
}

# ── 1. Acquire app-only token ────────────────────────────────────────────────

$headers = $null
$tokenRefreshAt = [DateTimeOffset]::MinValue

function Update-GraphAccessToken {
    param([switch]$Force)

    if (-not $Force -and $null -ne $script:headers -and
        [DateTimeOffset]::UtcNow -lt $script:tokenRefreshAt) {
        return
    }

    Write-Host "Acquiring app-only token for tenant $TenantId..." -ForegroundColor Yellow

    $tokenBody = @{
        grant_type    = "client_credentials"
        client_id     = $AppId
        client_secret = $Secret
        scope         = "https://graph.microsoft.com/.default"
    }

    $tokenResponse = Invoke-RestMethod `
        -Uri    "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
        -Method POST `
        -Body   $tokenBody

    $expiresInSeconds = [int]$tokenResponse.expires_in
    $refreshBufferSeconds = [Math]::Min(300, [Math]::Floor($expiresInSeconds / 2))
    $script:tokenRefreshAt = [DateTimeOffset]::UtcNow.AddSeconds(
        $expiresInSeconds - $refreshBufferSeconds
    )
    $script:headers = @{
        Authorization    = "Bearer $($tokenResponse.access_token)"
        ConsistencyLevel = 'eventual'
    }
}

Update-GraphAccessToken
Write-Host "Connected as app $AppId" -ForegroundColor Green

# ── 2. Helper: page through Graph results ────────────────────────────────────

function Invoke-GraphGetAll {
    param([string]$Uri)
    $results = [System.Collections.Generic.List[object]]::new()
    $nextUri = $Uri
    while ($nextUri) {
        Update-GraphAccessToken
        try {
            $resp = Invoke-RestMethod -Uri $nextUri -Headers $script:headers -Method GET
        }
        catch {
            $statusCode = [int]$_.Exception.Response?.StatusCode
            if ($statusCode -ne 401) { throw }

            Write-Host "Graph token was rejected; refreshing and retrying..." -ForegroundColor Yellow
            Update-GraphAccessToken -Force
            $resp = Invoke-RestMethod -Uri $nextUri -Headers $script:headers -Method GET
        }
        if ($resp.value) { $results.AddRange([object[]]$resp.value) }
        $nextUri = $resp.PSObject.Properties['@odata.nextLink']?.Value
    }
    return $results
}

# ── 3. Resolve target mailboxes ──────────────────────────────────────────────

if ($UserUpn) {
    Write-Host "Querying single mailbox: $UserUpn" -ForegroundColor Cyan
    $mailboxes = @([PSCustomObject]@{
        id                = $UserUpn
        userPrincipalName = $UserUpn
        displayName       = $UserUpn
    })
} elseif ($ScanGroupMembers) {
    Write-Host "Finding groups tagged with LTI context ID: $LTIContextId" -ForegroundColor Cyan

    $groupSearch = [uri]::EscapeDataString("`"Description:contextId: $LTIContextId`"")
    $groupsUri = "$GRAPH_BASE/groups?`$search=$groupSearch&`$select=id,displayName,description&`$count=true&`$top=999"
    $candidateGroups = @(Invoke-GraphGetAll -Uri $groupsUri)
    $escapedContextId = [regex]::Escape($LTIContextId)
    $groups = @($candidateGroups | Where-Object {
        $_.description -match "(?i)contextId:\s*$escapedContextId(?:\s+and\s+issuerName:|\s*,|\s*$)"
    })

    Write-Host "Found $($groups.Count) matching group(s)" -ForegroundColor Green
    $mailboxesById = @{}

    foreach ($group in $groups) {
        Write-Host "  Reading members and owners: $($group.displayName)" -ForegroundColor Gray
        foreach ($relationship in @('members', 'owners')) {
            $peopleUri = "$GRAPH_BASE/groups/$($group.id)/$relationship/microsoft.graph.user?`$select=id,userPrincipalName,displayName&`$top=999"
            $people = @(Invoke-GraphGetAll -Uri $peopleUri)
            foreach ($person in $people) {
                if (-not $mailboxesById.ContainsKey($person.id)) {
                    $mailboxesById[$person.id] = $person
                }
            }
        }
    }

    $mailboxes = @($mailboxesById.Values | Sort-Object userPrincipalName, id)
    Write-Host "Found $($mailboxes.Count) unique user member(s) and owner(s) to scan" -ForegroundColor Green
} else {
    Write-Host "Enumerating all licensed users in the tenant..." -ForegroundColor Cyan
    $usersUri  = "$GRAPH_BASE/users?`$select=id,userPrincipalName,displayName,assignedLicenses&`$top=999"
    $allUsers  = @(Invoke-GraphGetAll -Uri $usersUri)
    # Keep only users with at least one license (likely have a mailbox)
    $mailboxes = $allUsers | Where-Object { $_.assignedLicenses.Count -gt 0 }
    Write-Host "Found $($mailboxes.Count) licensed user(s)" -ForegroundColor Green
}

# ── 4. Build event query URL ─────────────────────────────────────────────────

function Get-EventsUri {
    param([string]$UserId)

    $propFilter = [uri]::EscapeDataString("id eq '$PROP_ID'")
    $encodedUserId = [uri]::EscapeDataString($UserId)

    if ($LTIContextId) {
        # Server-side filter by context id — returns only matching events
        $contextFilter = [uri]::EscapeDataString(
            "singleValueExtendedProperties/any(ep: ep/id eq '$PROP_ID' and ep/value eq '$LTIContextId')"
        )
        return "$GRAPH_BASE/users/$encodedUserId/events?`$filter=$contextFilter&`$select=id,subject,start,end,organizer,isOrganizer,onlineMeeting&`$top=100"
    } else {
        # Expand extended property; filter client-side for non-empty array
        return "$GRAPH_BASE/users/$encodedUserId/events?`$expand=singleValueExtendedProperties(`$filter=$propFilter)&`$select=id,subject,start,end,organizer,isOrganizer,onlineMeeting,singleValueExtendedProperties&`$top=100&`$orderby=start/dateTime desc"
    }
}

# ── 5. Sweep mailboxes and collect LTI events ────────────────────────────────

$rows         = [System.Collections.Generic.List[PSCustomObject]]::new()
$accessDenied = [System.Collections.Generic.List[string]]::new()
$total        = $mailboxes.Count
$count        = 0

foreach ($mb in $mailboxes) {
    $count++
    $mailboxId = $mb.id
    $mailboxLabel = if ($mb.userPrincipalName) { $mb.userPrincipalName } else { $mailboxId }
    Write-Host "  [$count/$total] $mailboxLabel" -ForegroundColor Gray

    try {
        $uri    = Get-EventsUri -UserId $mailboxId
        $events = @(Invoke-GraphGetAll -Uri $uri)
        Write-Host "    Raw events returned: $($events.Count)" -ForegroundColor Gray

        foreach ($ev in $events) {
            if ($OrganizerOnly -and -not $ev.isOrganizer) { continue }

            $extendedProperties = @()
            $extendedPropertyValue =
                $ev.PSObject.Properties['singleValueExtendedProperties']?.Value
            if ($null -ne $extendedPropertyValue) {
                $extendedProperties = @($extendedPropertyValue)
            }

            # For expand queries, skip events with no LTI stamp
            if (-not $LTIContextId -and $extendedProperties.Count -eq 0) { continue }

            $ctxId = if ($LTIContextId) {
                $LTIContextId
            } else {
                $extendedProperties[0].value
            }

            $rows.Add([PSCustomObject]@{
                Mailbox        = $mailboxLabel
                Subject        = $ev.subject
                StartDateTime  = $ev.start.dateTime
                EndDateTime    = $ev.end.dateTime
                Organizer      = $ev.organizer.emailAddress.address
                IsOnlineMeeting= [bool]$ev.onlineMeeting
                LTIContextId   = $ctxId
                EventId        = $ev.id
            })
        }

        if ($rows.Count -gt 0) {
            Write-Host "    $($rows.Count) LTI meeting(s) found so far" -ForegroundColor Green
        }
    }
    catch {
        $msg = $_.Exception.Message
        if ($msg -match '403|Forbidden|Access.Denied|MailboxNotEnabled|ResourceNotFound') {
            Write-Warning "    Skipped ($msg)"
            $accessDenied.Add($mailboxLabel)
        } else {
            Write-Warning "    Error: $msg"
        }
    }
}

# ── 6. Write CSV ─────────────────────────────────────────────────────────────

if ($rows.Count -gt 0) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`n=== $($rows.Count) LTI meeting(s) written to: $CsvPath ===" -ForegroundColor Green
} else {
    Write-Host "`nNo LTI meetings found." -ForegroundColor Yellow
}

if ($accessDenied.Count -gt 0) {
    Write-Host "`nSkipped $($accessDenied.Count) mailbox(es) (no access / no mailbox)." -ForegroundColor Yellow
    Write-Host "Ensure the app has Calendars.Read APPLICATION permission (admin-consented)." -ForegroundColor Yellow
}
