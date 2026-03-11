<#
.SYNOPSIS
    Lists Microsoft 365 groups connected to LMS courses via Microsoft OneDrive LTI / M365 LTI,
    then enumerates all files across each group's SharePoint document libraries.
    Writes a CSV row for every group, site, drive, and item — including those with no children.

.DESCRIPTION
    Uses Microsoft Graph PowerShell SDK cmdlets (with -All for automatic pagination) to:
      1. Retrieve groups created by the classic Microsoft OneDrive LTI or the Microsoft 365 LTI
         for the specified LMS platform (Canvas, Blackboard, Schoology, All).
      2. For each group, retrieve ALL SharePoint document libraries (drives) on the site.
      3. Recursively list all folders and files within each drive.
      4. Export results to a timestamped CSV file.

    Additionally, writes a row for:
      - Groups that have no SharePoint sites (site, drive, and item fields left empty)
      - Sites that have no drives (drive and item fields left empty)
      - Drives that have no child items (item fields left empty)

.NOTES
    Prerequisites:
      - PowerShell 7.0 or later
      - Microsoft Graph PowerShell SDK v2.x modules:
            Install-Module Microsoft.Graph.Authentication,
                           Microsoft.Graph.Groups,
                           Microsoft.Graph.Teams,
                           Microsoft.Graph.Sites,
                           Microsoft.Graph.Beta.Sites,
                           Microsoft.Graph.Files -Scope CurrentUser
      - An Entra ID app registration with Group.Read.All, Sites.Read.All,
        Files.Read.All APPLICATION permissions (admin-consented), plus a client secret.

.PARAMETER TenantId
    Tenant ID (GUID or *.onmicrosoft.com) for the Entra ID directory.

.PARAMETER AppId
    App registration (client) ID.

.PARAMETER Secret
    Client secret value for the app registration.

.PARAMETER LMS
    Which LMS platform to filter for: All, Canvas, Blackboard, Schoology.

.PARAMETER LTIApp
    Which LTI integration to query: All, OneDrive (classic OneDrive LTI), M365 (new M365 LTI).

.PARAMETER GroupId
    Optional filter to return only a specific group by its ID.

.PARAMETER LTIContextId
    Optional filter to return only a specific LTI context by its ID.

.PARAMETER CsvPath
    Optional full file path for the output CSV. If not specified, a file will be created in the script directory with a timestamped name.

.PARAMETER Overwrite
    If specified and the CsvPath file already exists, it will be overwritten without confirmation.

.PARAMETER GroupsOnly
    If specified, only groups will be retrieved along with basic site and drive info, but without any folder and files details.

.EXAMPLE
    .\Get-MicrosoftLTObjects.ps1 -TenantId "contoso.onmicrosoft.com" -AppId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -Secret "your-secret" -LMS "Canvas" -LTIApp "OneDrive"
#>

#Requires -Version 7.0
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Groups, Microsoft.Graph.Teams, Microsoft.Graph.Sites, Microsoft.Graph.Beta.Sites, Microsoft.Graph.Files

param(

    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$AppId,

    [Parameter(Mandatory = $true)]
    [string]$Secret,

    [Parameter(Mandatory = $false)]
    [ValidateSet('All', 'Canvas', 'Blackboard', 'Schoology')]
    [string]$LMS = "All",

    [Parameter(Mandatory = $false)]
    [ValidateSet('All', 'OneDrive', 'M365')]
    [string]$LTIApp = "All",

    [Parameter(Mandatory = $false)]
    [Alias("GroupId")]
    [string]$FilterGroupId, 

    [Parameter(Mandatory = $false)]
    [Alias("LTIContextId")]
    [string]$FilterLTIContextId ,  

    [Parameter(Mandatory = $false)]
    [string]$CsvPath,

    [Parameter(Mandatory = $false)]
    [switch]$Overwrite,

    [Parameter(Mandatory = $false)]
    [switch]$GroupsOnly
)


if ($FilterGroupId -or $FilterLTIContextId) {
    Write-Warning "Filtering by GroupID or LTIContextID: LMS and LTIApp parameters will be ignored, and only groups matching the specified GroupID or LTIContextId will be returned."
    $LTIApp = "All"
    $LMS = "All"
}

# -------------------------------------------------------------------
# 1. Connect to Microsoft Graph (app-only / client credentials)
#    The SDK handles token acquisition and automatic refresh.
# -------------------------------------------------------------------
if (-not $TenantId -or -not $AppId -or -not $Secret) {
    throw "TenantId, AppId, and Secret are all required."
}

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow

$secureSecret = ConvertTo-SecureString $Secret -AsPlainText -Force
$credential   = [System.Management.Automation.PSCredential]::new($AppId, $secureSecret)


if (Get-MgContext) {
    Disconnect-MgGraph
}
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $credential -NoWelcome -ErrorAction Stop -ContextScope Process
Write-Host "Connected as app $AppId in tenant $TenantId" -ForegroundColor Green

# check scopes to provide early feedback if permissions are insufficient for the query operations we need to perform

$requiredScopes = @(
    "Group.Read.All",
    "Member.Read.Hidden",
    "Sites.Read.All",
    "Files.Read.All",
    "Team.ReadBasic.All",
    "User.Read.All"
)

$grantedScopes = Get-MgContext | Select -ExpandProperty Scopes
$missingScopes = $requiredScopes | Where-Object { $_ -notin $grantedScopes }

if ($missingScopes) {
    Write-Warning "Missing required Graph scopes: $($missingScopes -join ', ')"
    exit 1
}

# -------------------------------------------------------------------
# 2. Retrieve LMS course groups created by the Microsoft LTI apps
# -------------------------------------------------------------------

function Get-LMSIssuerUrl {
    param([string]$LMS)
    switch ($LMS) {
        'Canvas'     { return 'https://canvas.instructure.com' }
        'Blackboard' { return 'https://blackboard.com' }
        'Schoology'  { return 'https://schoology.schoology.com' }
        default      { return '' }
    }
}

$commonFilter = "startsWith(DisplayName,'Course: ')"
$groupIdFilter = " and Id eq '$FilterGroupId'"
$commonSearch = 'Description:issuerName: '
$contextIdSearch = "Description:contextId: $FilterLTIContextId"

function Get-OldGroups {
    # OneDrive LTI groups: displayName starts with "Course: "

    if ($FilterLTIContextId) {
        $search = $contextIdSearch
    } else {
        $search = $commonSearch
        if ($LMS -ne 'All') { $search += $LMS }
    }
    $search = "`"$search`""

    $filter = $commonFilter
    if ($FilterGroupId) {
        $filter = $filter + $groupIdFilter
        $search = ""
    }

    Get-MgGroup -Filter $filter -Search $search `
        -ConsistencyLevel eventual -All `
        -Property Id, DisplayName, Description, CreatedDateTime, ResourceProvisioningOptions
}

function Get-NewGroups {
    # M365 LTI groups: displayName does NOT start with "Course: "
    
    if ($FilterLTIContextId) {
        $search = $contextIdSearch
    } else {
        $search = $commonSearch + (Get-LMSIssuerUrl -LMS $LMS)
    }
    $search = "`"$search`""

    $filter = "NOT($commonFilter)"
    if ($FilterGroupId) {
        $filter = $filter + $groupIdFilter
        $search = ""
    }

    Get-MgGroup -Filter $filter -Search $search `
        -ConsistencyLevel eventual -All `
        -Property Id, DisplayName, Description, CreatedDateTime, ResourceProvisioningOptions
}

Write-Host "`n=== Retrieving LMS Course Groups ===" -ForegroundColor Cyan

$oldGroups = $null
$newGroups = $null

if ($LTIApp -eq 'OneDrive' -or $LTIApp -eq 'All') {
    $oldGroups = @(Get-OldGroups)
    foreach ($g in $oldGroups) {
        $g | Add-Member -NotePropertyName 'App' -NotePropertyValue 'OneDriveLTI' -Force
    }
    Write-Host "Found $($oldGroups.Count) Microsoft OneDrive LTI groups"
}
if ($LTIApp -eq 'M365' -or $LTIApp -eq 'All') {
    $newGroups = @(Get-NewGroups)
    foreach ($g in $newGroups) {
        $g | Add-Member -NotePropertyName 'App' -NotePropertyValue 'M365LTI' -Force
    }
    Write-Host "Found $($newGroups.Count) Microsoft 365 LTI groups"
}

# Merge groups (avoid null-array merge bug)
if ($oldGroups.Count -gt 0 -and $newGroups.Count -gt 0) {
    $groups = $oldGroups + $newGroups
}
elseif ($oldGroups.Count -gt 0) {
    $groups = $oldGroups
}
elseif ($newGroups.Count -gt 0) {
    $groups = $newGroups
}
else {
    $groups = @()
}

if ($groups.Count -eq 0) {
    Write-Warning "No groups were found."
    return
}

Write-Host "`nFound $($groups.Count) total groups`n" -ForegroundColor Green
$groups | Format-Table DisplayName, Id, CreatedDateTime -AutoSize


# -------------------------------------------------------------------
# 3. Helper: parse group description
#    Format: "Group for course name: <Name>, contextId: <Id> and issuerName: <Issuer>"
# -------------------------------------------------------------------
function Parse-GroupDescription {
    param([string]$Description)

    $result = [PSCustomObject]@{
        CourseName = ''
        ContextId  = ''
        IssuerName = ''
    }

    if ($Description -match 'course name:\s*(.+?)\s*,\s*contextId:') {
        $result.CourseName = $Matches[1].Trim()
    }
    if ($Description -match 'contextId:\s*(.+?)\s+and\s+issuerName:') {
        $result.ContextId = $Matches[1].Trim()
    }
    if ($Description -match 'issuerName:\s*(.+)') {
        $result.IssuerName = $Matches[1].Trim()
    }

    return $result
}


# -------------------------------------------------------------------
# Helper: build a CSV row with shared column order
# -------------------------------------------------------------------
function New-CsvRow {
    param([hashtable]$Values)

    [PSCustomObject]@{
        AppName       = $Values['AppName']
        GroupId       = $Values['GroupId']
        GroupName     = $Values['GroupName']
        GroupCreated  = $Values['GroupCreated']
        GroupAdminUrl = $Values['GroupAdminUrl']
        IsTeam        = $Values['IsTeam']
        TeamArchived  = $Values['TeamArchived']
        OwnerCount    = $Values['OwnerCount']
        MemberCount   = $Values['MemberCount']
        LMSIssuerName = $Values['IssuerName']
        LTIContextId  = $Values['ContextId']
        CourseName    = $Values['CourseName']
        SiteId        = $Values['SiteId']
        SiteWebUrl    = $Values['SiteWebUrl']
        SiteStorageQuota = $Values['SiteStorageQuota']
        SiteStorageUsage = $Values['SiteStorageUsage']
        SiteArchiveStatus = $Values['SiteArchiveStatus']
        DriveCount    = $Values['DriveCount']   
        DriveId       = $Values['DriveId']
        DriveName     = $Values['DriveName']
        DriveSize     = $Values['DriveSize']
        ItemCount     = $Values['ItemCount']
        ItemName      = $Values['ItemName']
        ItemPath      = $Values['ItemPath']
        ItemType      = $Values['ItemType']
        ItemSize      = $Values['ItemSize']
        ItemCreated   = $Values['ItemCreated']
        ItemModified  = $Values['ItemModified']
        ItemWebUrl    = $Values['ItemWebUrl']
    }
}

function New-GroupOnlyCsvRow {
    param([hashtable]$Values)

    [PSCustomObject]@{
        AppName       = $Values['AppName']
        GroupId       = $Values['GroupId']
        GroupName     = $Values['GroupName']
        GroupCreated  = $Values['GroupCreated']
        GroupAdminUrl = $Values['GroupAdminUrl']
        IsTeam        = $Values['IsTeam']
        TeamArchived  = $Values['TeamArchived']
        OwnerCount    = $Values['OwnerCount']
        MemberCount   = $Values['MemberCount']
        LMSIssuerName = $Values['IssuerName']
        LTIContextId  = $Values['ContextId']
        CourseName    = $Values['CourseName']
        SiteId        = $Values['SiteId']
        SiteWebUrl    = $Values['SiteWebUrl']
        SiteStorageQuota = $Values['SiteStorageQuota']
        SiteStorageUsage = $Values['SiteStorageUsage']
        SiteArchiveStatus = $Values['SiteArchiveStatus']
        DriveCount    = $Values['DriveCount']
    }
}


# -------------------------------------------------------------------
# 4. Recursive drive enumeration using SDK cmdlets with -All
#    Returns the number of child items written.
# -------------------------------------------------------------------
$script:totalItemsWritten = 0
$script:totalItemsSize = 0

function Write-DriveItemsRecursive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DriveId,
        [Parameter(Mandatory)][string]$ItemId,
        [string]$CurrentPath = '',
        [Parameter(Mandatory)][string]$CsvPath,
        [Parameter(Mandatory)][hashtable]$GroupMeta
    )

    # SDK cmdlet with -All handles pagination automatically.
    # -Property limits the $select fields to avoid SDK null-ref deserialization bugs
    # on items with null nested objects (thumbnails, sharepointIds, etc.).
    try {
        $children = Get-MgDriveItemChild -DriveId $DriveId -DriveItemId $ItemId -All `
            -Property Id, Name, Size, Folder, CreatedDateTime, LastModifiedDateTime, WebUrl
    }
    catch {
        Write-Warning "    Error at '$CurrentPath': $($_.Exception.Message)"
        return
    }

    if ($children.Count -eq 0) { return }

    $rows = [System.Collections.Generic.List[PSCustomObject]]::new()
    $foldersToRecurse = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($child in $children) {
        $itemPath = if ($CurrentPath) { "$CurrentPath/$($child.Name)" } else { $child.Name }
        $isFolder = $null -ne $child.Folder.ChildCount

        $size = if ($child.size) { $child.size } else { 0 }

        $rows.Add((New-CsvRow -Values @{
            AppName      = $GroupMeta.AppName
            GroupId      = $GroupMeta.GroupId
            GroupName    = $GroupMeta.GroupName
            GroupCreated = $GroupMeta.GroupCreated
            GroupAdminUrl = $GroupMeta.GroupAdminUrl
            IsTeam       = $GroupMeta.IsTeam
            TeamArchived = $GroupMeta.TeamArchived
            OwnerCount   = $GroupMeta.OwnerCount
            MemberCount  = $GroupMeta.MemberCount
            IssuerName   = $GroupMeta.IssuerName
            ContextId    = $GroupMeta.ContextId
            CourseName   = $GroupMeta.CourseName
            SiteId       = $GroupMeta.SiteId
            SiteWebUrl   = $GroupMeta.SiteWebUrl
            SiteStorageQuota = $GroupMeta.SiteStorageQuota
            SiteStorageUsage = $GroupMeta.SiteStorageUsage
            SiteArchiveStatus = $GroupMeta.SiteArchiveStatus
            DriveCount   = $GroupMeta.DriveCount
            DriveId      = $GroupMeta.DriveId
            DriveName    = $GroupMeta.DriveName
            ItemName     = $child.Name
            ItemPath     = $itemPath
            ItemType     = if ($isFolder) { 'Folder' } else { 'File' }
            ItemSize     = $size
            ItemCreated  = $child.CreatedDateTime
            ItemModified = $child.LastModifiedDateTime
            ItemWebUrl   = $child.WebUrl
        }))

        if ($isFolder -and $child.Folder.ChildCount -gt 0) {
            $foldersToRecurse.Add([PSCustomObject]@{ Id = $child.Id; Path = $itemPath })
        }
        else {
            $script:totalItemsSize += $size
        }
    }


    # Stream to CSV
    $rows | Export-Csv -Path $CsvPath -Append -NoTypeInformation -Encoding UTF8
    $script:totalItemsWritten += $rows.Count
    #$script:totalItemsSize += ($rows | Measure-Object -Property ItemSize -Sum).Sum

    if ($Rows.Count -gt 1000) {
        $rows | Format-Table ItemPath, ItemType, ItemSize, ItemCreated, ItemModified -AutoSize
    }

    # Recurse into subfolders
    foreach ($folder in $foldersToRecurse) {
        Write-DriveItemsRecursive -DriveId $DriveId -ItemId $folder.Id `
            -CurrentPath $folder.Path -CsvPath $CsvPath -GroupMeta $GroupMeta
    }
}


# ----------------------------------------------------------------------
# 5. For each group, get the SharePoint site, all drives, and list items
#    Write a CSV row at every level even where no children exist.
# -----------------------------------------------------------------------

if ($CsvPath) {
    if (-not (Test-Path -Path $CsvPath -PathType Leaf)) {
        # Validate the parent folder
        $parentFolder = Split-Path -Path $CsvPath -Parent
        if (-not (Test-Path -LiteralPath $parentFolder -PathType Container)) {
            Write-Host "❌ Folder does not exist: $parentFolder" -ForegroundColor Red
            Write-Host "Please specify a valid folder in the CsvPath parameter." -ForegroundColor Yellow
            exit 1
        }
        if (-not (Split-Path $CsvPath -Leaf)) {
            Write-Host "❌ Invalid file path: $CsvPath" -ForegroundColor Red
            Write-Host "Please specify a valid full file path in the CsvPath parameter." -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Warning "Replacing $CsvPath"
        if ($Confirm) {
            Remove-Item $CsvPath -Force -Confirm
        }
         else {
            Remove-Item $CsvPath -Force
         }
    }
}
else {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    if ($FilterGroupId -or $FilterLTIContextId) {
        $CsvPath   = Join-Path $scriptDir "Microsoft_LTI_Objects_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    } else {
         $CsvPath   = Join-Path $scriptDir "Microsoft_${LMS}_${LTIApp}LTI_Objects_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    } 
}

# Write CSV header by exporting an empty object then keeping only the header row
if ($GroupsOnly) {
    New-GroupOnlyCsvRow -Values @{} | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
} else {
    New-CsvRow -Values @{} | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
}
(Get-Content $CsvPath -First 1) | Set-Content $CsvPath -Encoding UTF8

Write-Host "CSV file: $CsvPath" -ForegroundColor Green

$accessDenied = @()
$otherErrors  = @()
$successCount = 0
$groupCount   = 0
$totalGroups  = $groups.Count
$totalDrives  = 0
$totalItems   = 0

if ($GroupsOnly) {
    # Write group-only row and skip enumeration of other objects
    Write-Host "Groups-only mode: no drive, or item info will be included." -ForegroundColor Yellow
}


foreach ($group in $groups) {
    $groupCount++

    Write-Host "-------------------------------------------------------" -ForegroundColor Gray
    Write-Host "Group : $($group.DisplayName) ($groupCount of $totalGroups)" -ForegroundColor Cyan
    Write-Host "ID    : $($group.Id)" -ForegroundColor Gray
    Write-Host "Desc  : $($group.Description)" -ForegroundColor Gray
    Write-Host "Created: $($group.CreatedDateTime)" -ForegroundColor Gray
    
    try {
        # Common group-level metadata
        $parsed = Parse-GroupDescription -Description $group.Description

        $owners = Get-MgGroupOwner -GroupId $group.Id -ConsistencyLevel eventual -All -Property Id
        #$owners | Format-Table -AutoSize
        $ownerCount = $owners.Count

        # Exclude owners from members count since owners are usually returned in the members endpoint and we want to avoid double-counting them, for this purpose
        $members = Get-MgGroupMember -GroupId $group.Id -ConsistencyLevel eventual -All -Property Id | Where-Object {$_.Id -notin $owners.Id}
        #$members | Format-Table -AutoSize
        $memberCount = $members.Count

        # Check if the group is a Team-connected group
         try {
            $team = Get-MgTeam -TeamId $group.Id -Property IsArchived -ErrorAction Stop
        }
        catch {
            $team = $null
        }

        $IsTeam = $($null -ne $Team)

        # Check if the group is a Team-connected group (has 'Team' in ResourceProvisioningOptions)
        #$isTeam = $group.ResourceProvisioningOptions -contains 'Team'

        # Check archived status — only Team-connected groups can be archived (via Teams API)
        # Non-Team M365 groups have no formal archive state.
        if ($isTeam) {
            $archived = [bool]$team.IsArchived
        } else {
            $archived = 'N/A'
        }

        Write-Host "Owners : $($ownerCount) | Members: $($memberCount) | IsTeam: $($isTeam) | Archived: $($archived)" -ForegroundColor Gray

        $baseMeta = @{
            AppName      = $group.App
            GroupId      = $group.Id
            GroupName    = $group.DisplayName
            GroupCreated = $group.CreatedDateTime
            GroupAdminUrl = $adminUrl = "https://admin.cloud.microsoft/?#/groups/:/TeamDetails/$($group.Id)"
            IsTeam       = $isTeam
            TeamArchived = $archived
            OwnerCount   = $ownerCount
            MemberCount  = $memberCount
            IssuerName   = $parsed.IssuerName
            ContextId    = $parsed.ContextId
            CourseName   = $parsed.CourseName
            SiteId       = ''
            SiteWebUrl   = ''
            SiteStorageQuota = ''
            SiteStorageUsage = ''
            SiteArchiveStatus = ''
            DriveCount   = ''
            DriveId      = ''
            DriveName    = ''
            DriveSize    = ''
        }


        Write-Host "Admin Url : $($adminUrl)" -ForegroundColor Gray

        # Get the group's root SharePoint site
        $site = $null
        try {
            $site = Get-MgGroupSite -GroupId $group.Id -SiteId "root" -Property "id,webUrl" -ErrorAction Stop
        }
        catch {
            $msg = $_.Exception.Message
            if ($msg -match 'Access Denied|Forbidden|403|Authorization_RequestDenied|Insufficient privileges') {
                throw $_   # re-throw to outer catch for access-denied handling
            }
            #throw $msg
            # Site not found or other error — treat as group with no site
            $site = $null
        }

        # This should not happen because to delete a group connected site you must delete the group - however, there is technically a possibility of a group existing without a site 
        # if the site provisioning failed or was deleted outside of normal processes, so we will log it just in case
        if (-not $site) {
            # Group has no site — write a group-only row
            Write-Host "  (no SharePoint site found)" -ForegroundColor DarkYellow
            if ($GroupsOnly) {
                $baseMeta.DriveCount = 0
                New-GroupOnlyCsvRow -Values $baseMeta | Export-Csv -Path $CsvPath -Append -NoTypeInformation -Encoding UTF8
            } else {
                New-CsvRow -Values $baseMeta | Export-Csv -Path $CsvPath -Append -NoTypeInformation -Encoding UTF8
            }
            $script:totalItemsWritten++
            $successCount++
            continue
        }

        $siteId  = $site.Id
        $siteUrl = $site.WebUrl

        # Get the archive status of the site
        # note: could use $siteArchived = (Get-SPOSite $siteUrl).ArchiveStatus if we wanted to open a connection to SPO OMS
        try {
            $archivedSite = Get-MgBetaSite -SiteId $siteId `
                -Property "siteCollection"

            $siteArchiveStatus = $archivedSite.SiteCollection.ArchivalDetails.ArchiveStatus
            if ($null -eq $siteArchiveStatus) {
                $siteArchiveStatus = 'None'
            }
        }
        catch {
            $msg = $_.Exception.Message
            if ($msg -match 'Access Denied|Forbidden|403|Authorization_RequestDenied|Insufficient privileges') {
                throw $_   # re-throw to outer catch for access-denied handling
            }
            throw $msg
            Write-Warning "  Could not retrieve archive status for site '$($siteUrl)': $msg"
            $siteArchiveStatus = 'Unknown'
        }

        $baseMeta.SiteId       = $siteId
        $baseMeta.SiteWebUrl   = $siteUrl
        $baseMeta.SiteArchiveStatus = $siteArchiveStatus

        Write-Host "Site Id : $($siteId) | ArchiveStatus : $($siteArchiveStatus)" -ForegroundColor Gray
        Write-Host "Site Url : $($siteUrl)" -ForegroundColor Gray

        if ($GroupsOnly) {
            # Get the drive count and site storage quota
            $drives = @(Get-MgSiteDrive -SiteId $siteId -All -Property Id, Quota)
            $driveCount = $drives.Count
            $baseMeta.SiteStorageQuota = if ($drives.Count -gt 0 -and $drives[0].Quota) { $drives[0].Quota.Total } else { '' }
            $baseMeta.SiteStorageUsage = if ($drives.Count -gt 0 -and $drives[0].Quota) { $drives[0].Quota.Used } else { '' }
            $baseMeta.DriveCount = $driveCount
            New-GroupOnlyCsvRow -Values $baseMeta | Export-Csv -Path $CsvPath -Append -NoTypeInformation -Encoding UTF8
            $script:totalItemsWritten++
            $successCount++
            continue
        }

        # Get ALL document libraries (drives) on the site using SDK cmdlet with -All
        $allDrives = @(Get-MgSiteDrive -SiteId $siteId -All -Property Id, Name, WebUrl, Quota)
        $baseMeta.SiteStorageQuota = if ($allDrives.Count -gt 0 -and $allDrives[0].Quota) { $allDrives[0].Quota.Total } else { '' }
        $baseMeta.SiteStorageUsage = if ($allDrives.Count -gt 0 -and $allDrives[0].Quota) { $allDrives[0].Quota.Used } else { '' }
        $baseMeta.DriveCount = $allDrives.Count

        # This should never happen since every site should have at least a Documents library, but handle just in case
        if ($allDrives.Count -eq 0) {
            # Site has no drives — write a site-only row
            Write-Warning "  No document libraries found for '$($group.DisplayName)'."
            New-CsvRow -Values $baseMeta | Export-Csv -Path $CsvPath -Append -NoTypeInformation -Encoding UTF8
            $script:totalItemsWritten++
            $successCount++
            continue
        }

        $totalDrives += $allDrives.Count

        Write-Host "  Found $($allDrives.Count) drive(s): $(($allDrives | ForEach-Object { $_.Name }) -join ', ')" -ForegroundColor Gray

        $groupItemCountTotal = 0

        foreach ($drive in $allDrives) {
            $groupMeta = $baseMeta.Clone()
            $groupMeta.DriveId   = $drive.Id
            $groupMeta.DriveName = $drive.Name

            $beforeCount = $script:totalItemsWritten
            $beforeSize = $script:totalItemsSize
            Write-DriveItemsRecursive -DriveId $drive.Id -ItemId 'root' -CsvPath $CsvPath -GroupMeta $groupMeta
            $driveItemCount = $script:totalItemsWritten - $beforeCount
            $driveSizeTotal = $script:totalItemsSize - $beforeSize
            $groupItemCountTotal += $driveItemCount
            $totalItems += $driveItemCount

            # Write a drive summary row with the total item count and size for this drive
            $groupMeta.ItemCount = $driveItemCount
            $groupMeta.DriveSize = $driveSizeTotal
            New-CsvRow -Values $groupMeta | Export-Csv -Path $CsvPath -Append -NoTypeInformation -Encoding UTF8
            $script:totalItemsWritten++


            Write-Host "  $driveItemCount items found in drive '$($drive.Name)'" -ForegroundColor Green
        }

        if ($groupItemCountTotal -eq 0) {
            Write-Host "  (no files or folders across all drives)" -ForegroundColor DarkYellow
        }
        else {
            Write-Host "  Total: $groupItemCountTotal items" -ForegroundColor Green
        }
        $successCount++
    }
    catch {
        $msg = $_.Exception.Message
        if ($msg -match 'Access Denied|Forbidden|403|Authorization_RequestDenied|Insufficient privileges') {
            Write-Warning "  ACCESS DENIED for '$($group.DisplayName)'"
            $accessDenied += $group
        }
        else {
            Write-Warning "  Error processing '$($group.DisplayName)': $msg"
            $otherErrors += [PSCustomObject]@{ Group = $group.DisplayName; Error = $msg }
        }
    }
}


# -------------------------------------------------------------------
# 6. Summary
# -------------------------------------------------------------------
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "  Total groups found : $($groups.Count)"
Write-Host "  Successful         : $successCount" -ForegroundColor Green
Write-Host "  Access Denied      : $($accessDenied.Count)" -ForegroundColor $(if ($accessDenied.Count -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Other Errors       : $($otherErrors.Count)" -ForegroundColor $(if ($otherErrors.Count -gt 0) { 'Yellow' } else { 'Green' })

if (-not $GroupsOnly) {
    Write-Host "  Total Drives       : $totalDrives" -ForegroundColor Cyan
    Write-Host "  Total Items        : $totalItems" -ForegroundColor Cyan
}

if ($accessDenied.Count -gt 0) {
    Write-Host "`nAccess Denied groups:" -ForegroundColor Red
    $accessDenied | Format-Table DisplayName, Id -AutoSize
    Write-Host "FIX: Ensure the app has Group.Read.All, Sites.Read.All, Files.Read.All APPLICATION permissions (admin-consented)." -ForegroundColor Yellow
}

if ($script:totalItemsWritten -gt 0) {
    Write-Host "`n=== $($script:totalItemsWritten) rows written to: $CsvPath ===`n" -ForegroundColor Green
}
else {
    Write-Host "`nNo files or folders found across all groups.`n" -ForegroundColor Yellow
}

# Disconnect cleanly
Disconnect-MgGraph | Out-Null
Write-Host "Disconnected from Microsoft Graph`n." -ForegroundColor Gray
