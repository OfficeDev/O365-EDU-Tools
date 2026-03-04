<#
.SYNOPSIS
    Lists Microsoft 365 groups connected to LMS courses via the classsic Microsoft OneDrive LTI,
    then enumerates folders and files in each group's default SharePoint document library.

.DESCRIPTION
    Uses Microsoft Graph PowerShell SDK to:
      1. Retrieve groups created by the classic Microsoft OneDrive LTI whose DisplayName starts with "Course:" and description contains the LMS platform name (Any, Canvas, Blackboard, Schoology, Other).
      2. For each group, retrieve the default SharePoint site's drive (document library).
      3. Recursively list all folders and files within that drive.

.NOTES
    Prerequisites:
      - Microsoft.Graph PowerShell module (Install-Module Microsoft.Graph)
      - An Entra ID app registration with Group.Read.All, Sites.Read.All,
        Files.Read.All APPLICATION permissions (admin-consented), plus a
        client secret.

.PARAMETER TenantId
    Tenant ID for the Entra ID directory.

.PARAMETER AppId
    App registration (client) ID.

.PARAMETER ClientSecret
    Client secret for the app registration.

.EXAMPLE
    .\Get-OneDriveLTICourseFiles.ps1 -TenantId "contoso.onmicrosoft.com" -AppId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -ClientSecret "your-secret" -LMS "Canvas"
#>

#Requires -Modules Microsoft.Graph.Groups, Microsoft.Graph.Sites, Microsoft.Graph.Files

param(
    [Parameter(Mandatory=$True)]
    [string]$TenantId,
    [Alias("AppId")]
    [Parameter(Mandatory=$True)]
    [string]$AppClientId,
    [Alias("Secret")]
    [Parameter(Mandatory=$True)]
    [string]$ClientSecretValue,
    
    [Parameter(Mandatory=$False)]
    [ValidateSet('Any','Canvas','Schoology','Blackboard','Other')]
    [String]$LMS = "Any"
)

# -------------------------------------------------------------------
# 1. Connect to Microsoft Graph with app-only (client secret) auth
# -------------------------------------------------------------------
Write-Host "Connecting to Microsoft Graph (app-only, client secret)..." -ForegroundColor Yellow

$body = @{
    grant_type = "client_credentials"
    client_id = $AppClientId
    client_secret = $ClientSecretValue
    scope = "https://graph.microsoft.com/.default"
}
$response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $body

Connect-MgGraph -AccessToken $response.access_token
Write-Host "Connected as app $AppClientId in tenant $TenantId" -ForegroundColor Green

# -----------------------------------------------------------------------
# 2. Retrieve LMS course groups created by the OneDrive LTI integration
# -----------------------------------------------------------------------
Write-Host "`n=== Retrieving LMS Course Groups ===" -ForegroundColor Cyan

$filter = "startsWith(DisplayName,'Course:')"

if ($LMS -eq "Any") {
    $groups = Get-MgGroup -Filter $filter -Search "Description:contextId:" -ConsistencyLevel eventual -All | Select-Object Id, Description, DisplayName, CreatedDateTime
}
else {
    $issuer = $LMS
    if ($LMS -eq "Other") {
        $issuer = "Generic"
    }
    $groups = Get-MgGroup -Filter $filter -Search "Description:issuerName: " -ConsistencyLevel eventual -All | Select-Object Id, Description, DisplayName, CreatedDateTime
}

if (-not $groups -or $groups.Count -eq 0) {
    Write-Warning "No groups found with 'Course:*' in the display name, and $($lms) as the LMS issuerName"
    return
}

Write-Host "Found $($groups.Count) group(s):`n" -ForegroundColor Green

$groups | Format-Table -AutoSize

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
# 4. Helper: paginated, streaming enumeration of drive items
#    Writes each page of results to the CSV immediately.
# -------------------------------------------------------------------
$script:PageSize = 200          # items per Graph API page
$script:totalItemsWritten = 0   # running count across all groups

function Write-DriveItemsRecursive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DriveId,
        [Parameter(Mandatory)][string]$ItemId,
        [string]$CurrentPath  = "",
        [Parameter(Mandatory)][string]$CsvPath,
        [Parameter(Mandatory)][hashtable]$GroupMeta
    )

    # --- Page through children using the Graph beta/stable paging model ---
    $uri = "https://graph.microsoft.com/v1.0/drives/$DriveId/items/$ItemId/children?`$top=$($script:PageSize)"

    while ($uri) {
        try {
            $page = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
        }
        catch {
            Write-Warning "    Paging error at '$CurrentPath': $($_.Exception.Message)"
            return
        }

        $children = $page.value
        if (-not $children -or $children.Count -eq 0) { break }

        # Build CSV rows for this page
        $rows = [System.Collections.Generic.List[PSCustomObject]]::new()
        $foldersToRecurse = [System.Collections.Generic.List[PSCustomObject]]::new()


        foreach ($child in $children) {
            $itemPath = if ($CurrentPath) { "$CurrentPath/$($child.name)" } else { $child.name }
            $isFolder = $null -ne $child.folder.ChildCount

            $rows.Add([PSCustomObject]@{
                GroupId      = $GroupMeta.GroupId
                GroupName    = $GroupMeta.GroupName
                GroupCreated = $GroupMeta.GroupCreated 
                GroupAdminUrl= $GroupMeta.GroupAdminUrl
                LMSIssuerName   = $GroupMeta.IssuerName
                LTIContextId    = $GroupMeta.ContextId
                CourseName   = $GroupMeta.CourseName
                SiteId       = $GroupMeta.SiteId
                SiteWebUrl   = $GroupMeta.SiteWebUrl
                DriveId      = $GroupMeta.DriveId
                DriveName    = $GroupMeta.DriveName
                ItemName     = $child.name
                ItemPath     = $itemPath
                ItemType     = if ($isFolder) { 'Folder' } else { 'File' }
                ItemSize     = if ($child.size) { $child.size } else { 0 }
                ItemCreated  = $child.createdDateTime
                ItemModified = $child.lastModifiedDateTime
                ItemWebUrl   = $child.webUrl
            })

            if ($isFolder) {
                $foldersToRecurse.Add([PSCustomObject]@{ Id = $child.id; Path = $itemPath })
            }
        }

        $rows | Format-Table -Property ItemType, ItemPath, ItemSize, ItemModified -AutoSize

        # Append this page to CSV
        $rows | Export-Csv -Path $CsvPath -Append -NoTypeInformation -Encoding UTF8
        $script:totalItemsWritten += $rows.Count

        Write-Host "  Wrote $($rows.Count) drive items (total: $($script:totalItemsWritten))" -ForegroundColor DarkGray

        # Follow @odata.nextLink for the next page
        $uri = $page.'@odata.nextLink'

        # Recurse into folders found in this page
        foreach ($folder in $foldersToRecurse) {
            Write-DriveItemsRecursive -DriveId $DriveId -ItemId $folder.Id `
                -CurrentPath $folder.Path -CsvPath $CsvPath -GroupMeta $GroupMeta
        }
    }
}

# -------------------------------------------------------------------
# 5. For each group, get the SharePoint site drive and list contents
# -------------------------------------------------------------------
$csvPath = Join-Path $PSScriptRoot "$($LMS)_OneDriveLTI_Group_Files_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

# Write CSV header by exporting an empty object with the right columns
[PSCustomObject]@{
    GroupId=''; GroupName=''; GroupCreated=''; GroupAdminUrl=''; LMSIssuerName=''; LTIContextId=''; CourseName='';
    SiteId=''; SiteWebUrl=''; DriveId=''; DriveName='';
    ItemName=''; ItemPath=''; ItemType=''; ItemSize=''; ItemCreated=''; ItemModified=''; ItemWebUrl=''
} | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
# Remove the dummy data row, keep only the header
$header = Get-Content $csvPath -First 1
$header | Set-Content $csvPath -Encoding UTF8

Write-Host "CSV file: $csvPath" -ForegroundColor Green

$allResults   = @()
$accessDenied = @()
$otherErrors  = @()
$successCount = 0

foreach ($group in $groups) {
    Write-Host "-----------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "Group : $($group.DisplayName)" -ForegroundColor Cyan
    Write-Host "ID    : $($group.Id)" -ForegroundColor Gray
    Write-Host "Desc  : $($group.Description)" -ForegroundColor Gray
    Write-Host "Created  : $($group.CreatedDateTime)" -ForegroundColor Gray

    try {
        # Parse description fields
        $parsed = Parse-GroupDescription -Description $group.Description

        # Get the group's default SharePoint site
        $site = Get-MgGroupSite -GroupId $group.Id -SiteId "root" -ErrorAction Stop

        Write-Host "Site  : $($site.WebUrl)" -ForegroundColor Gray

        # Get the default document library drive
        $drive = Get-MgSiteDrive -SiteId $site.Id -ErrorAction Stop | Select-Object -First 1

        if (-not $drive) {
            Write-Warning "  No document library found for this group's site."
            continue
        }

        Write-Host "Drive : $($drive.Name)  (ID: $($drive.Id))" -ForegroundColor Gray
        Write-Host ""

        # Build metadata hashtable for CSV rows
        $groupMeta = @{
            GroupId    = $group.Id
            GroupName  = $group.DisplayName
            GroupCreated = $group.CreatedDateTime
            GroupAdminUrl = "https://admin.cloud.microsoft/?#/groups/:/TeamDetails/$($group.Id)"
            IssuerName = $parsed.IssuerName
            ContextId  = $parsed.ContextId
            CourseName = $parsed.CourseName
            SiteId     = $site.Id
            SiteWebUrl = $site.WebUrl
            DriveId    = $drive.Id
            DriveName  = $drive.Name
        }

        # Enumerate and stream items to CSV page-by-page
        $beforeCount = $script:totalItemsWritten
        Write-DriveItemsRecursive -DriveId $drive.Id -ItemId "root" -CsvPath $csvPath -GroupMeta $groupMeta
        $groupItemCount = $script:totalItemsWritten - $beforeCount

        if ($groupItemCount -eq 0) {
            Write-Host "  (empty drive: no files or folders)" -ForegroundColor DarkYellow
            Write-Host ""
        }
        else {
            Write-Host "  $groupItemCount item(s) written to CSV" -ForegroundColor Green
            Write-Host ""
        }
        $successCount++
    }
    catch {
        $msg = $_.Exception.Message
        if ($msg -match 'Access Denied|Forbidden|403|Authorization_RequestDenied|Insufficient privileges') {
            Write-Warning "  ACCESS DENIED for '$($group.DisplayName)' you are not a member/owner or lack app permissions."
            $accessDenied += $group
        }
        else {
            Write-Warning "  Error processing group '$($group.DisplayName)': $msg"
            $otherErrors += [PSCustomObject]@{ Group = $group.DisplayName; Error = $msg }
        }
    }
}

# -------------------------------------------------------------------
# Summary
# -------------------------------------------------------------------
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "  Total groups found : $($groups.Count)"
Write-Host "  Successful         : $successCount" -ForegroundColor Green
Write-Host "  Access Denied      : $($accessDenied.Count)" -ForegroundColor $(if ($accessDenied.Count -gt 0) {'Red'} else {'Green'})
Write-Host "  Other Errors       : $($otherErrors.Count)" -ForegroundColor $(if ($otherErrors.Count -gt 0) {'Yellow'} else {'Green'})

if ($accessDenied.Count -gt 0) {
    Write-Host "`nAccess Denied groups:" -ForegroundColor Red
    $accessDenied | Format-Table -Property DisplayName, Id -AutoSize
    Write-Host "FIX: Ensure the app registration has the required APPLICATION permissions:" -ForegroundColor Yellow
    Write-Host "  - Group.Read.All, Sites.Read.All, Files.Read.All" -ForegroundColor Gray
    Write-Host "  - Admin consent must be granted for all permissions in Entra ID." -ForegroundColor Gray
}

# -------------------------------------------------------------------
# 6. Final summary
# -------------------------------------------------------------------
if ($script:totalItemsWritten -gt 0) {
    Write-Host "`n=== Exported $($script:totalItemsWritten) item(s) to: $csvPath ===" -ForegroundColor Green
}
else {
    Write-Host "`nNo files or folders found across all groups." -ForegroundColor Yellow
}
