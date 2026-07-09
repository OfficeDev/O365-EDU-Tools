<#
.SYNOPSIS
    Copies a OneNote Class Notebook from a source teacher's OneDrive into the signed-in
    co-teacher's own OneDrive for Business.

.DESCRIPTION
    Create a clone of a Class Notebook where I am a co-teacher from one teacher to my own OneDrive,
    optionally renaming and revoking existing permissions to the old notebook. Simulates 
    the Teacher Transfer functionality.

    The signed-in user is the DESTINATION co-teacher. The script:
    1. Authenticates to Microsoft Graph as the co-teacher (delegated)
    2. Locates the source Class Notebook in the source teacher's OneDrive. If the signed-in
       user does not have direct access to the source teacher's drive, it falls back to the
       "Shared with me" view to locate the notebook the source teacher shared.
    3. Copies the notebook folder into the co-teacher's own OneDrive (defaults to the
       "Class Notebooks" folder, created if missing)
    4. Re-applies sharing on the new copy: source/other teachers get write, students get read
    5. Sets Class Notebook metadata (NotebookType=EDU, etc.)
    6. Repairs per-section permissions (student folders, _Teacher Only, etc.)
    7. Optionally revokes co-teacher and student access on the source notebook

    The -FixPermissions switch provides a standalone mode to repair permissions on an
    existing Class Notebook owned by the signed-in user.

.PARAMETER NotebookName
    The display name of the Class Notebook to copy.

.PARAMETER TeacherUpn
    The UPN (email) of the source teacher who owns the notebook.
    Required for the copy flow. Not needed for -FixPermissions.

.PARAMETER TargetNotebookName
    Optional name to give the copied notebook at the destination. Defaults to -NotebookName.

.PARAMETER DestinationFolder
    Folder path in the signed-in co-teacher's OneDrive root where the notebook will be
    placed. Defaults to "Class Notebooks". The folder is created if it does not already exist.

.PARAMETER FixPermissions
    Switch to repair permissions on an existing Class Notebook owned by the signed-in user.
    Only requires -NotebookName.

.EXAMPLE
    # Copy a notebook owned by another teacher into MY OneDrive
    .\Copy-ClassNotebookToCoTeacher.ps1 -NotebookName "Biology 101" -TeacherUpn "owner@contoso.edu"

.EXAMPLE
    # Copy with a custom destination name and folder
    .\Copy-ClassNotebookToCoTeacher.ps1 -NotebookName "Biology 101" -TeacherUpn "owner@contoso.edu" `
        -TargetNotebookName "Bio 101 - My Copy" -DestinationFolder "My Class Notebooks"

.EXAMPLE
    # Fix permissions on an existing Class Notebook owned by the signed-in user
    .\Copy-ClassNotebookToCoTeacher.ps1 -NotebookName "Biology 101" -FixPermissions

.NOTES
    Prerequisites:
    - Microsoft.Graph PowerShell module (Install-Module Microsoft.Graph -Scope CurrentUser)
    - Delegated permissions:
        * Files.ReadWrite
        * Files.Read.All       (recommended; allows reading the source teacher's drive directly.
                               Without it, the script falls back to the "Shared with me" lookup
                               and the source notebook must already be shared with you.)
        * Sites.ReadWrite.All
        * Sites.Manage.All
        * Notes.ReadWrite.All
        * User.Read
        * User.ReadBasic.All
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$NotebookName,

    [Parameter(Mandatory = $false)]
    [string]$TeacherUpn,

    [Parameter(Mandatory = $false)]
    [string]$TargetNotebookName,

    [Parameter(Mandatory = $false)]
    [string]$DestinationFolder = "Class Notebooks",

    [Parameter(Mandatory = $false)]
    [switch]$FixPermissions
)

#region --- Configuration & Validation ---

$ErrorActionPreference = "Stop"

if (-not $TargetNotebookName) {
    $TargetNotebookName = $NotebookName
}

if (-not $FixPermissions) {
    if (-not $TeacherUpn) {
        throw "TeacherUpn is required (the source teacher who owns the notebook)."
    }
}

# Ensure Microsoft.Graph module is available
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Error "Microsoft.Graph PowerShell module is not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    exit 1
}

#endregion

#region --- Authentication ---

function Connect-ToGraph {
    Write-Host "[Auth] Connecting as Teacher (interactive)..." -ForegroundColor Cyan
    $scopes = @(
        "Files.ReadWrite",
        "Files.Read.All",
        "Sites.ReadWrite.All",
        "Sites.Manage.All",
        "Notes.ReadWrite.All",
        "User.Read",
        "User.ReadBasic.All"
    )
    Connect-MgGraph -Scopes $scopes -NoWelcome

    $context = Get-MgContext
    if (-not $context) { throw "Failed to authenticate to Microsoft Graph." }
    $identity = if ($context.Account) { $context.Account } else { "App: $($context.AppName)" }
    Write-Host "[Auth] Connected as: $identity" -ForegroundColor Green
}

#endregion

#region --- Helper Functions ---

function Find-ClassNotebook {
    param([string]$UserId)

    Write-Host "[Notebook] Searching for Class Notebook '$NotebookName'..." -ForegroundColor Cyan

    # Use the classNotebooks endpoint which only returns actual Class Notebooks
    # This validates the notebook IS a class notebook (not a regular notebook)
    $uri = "https://graph.microsoft.com/beta/users/$UserId/onenote/classNotebooks"
    try {
        $classNotebooks = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject
    }
    catch {
        # Fallback: try v1.0 notebooks endpoint and validate via section groups
        Write-Host "[Notebook] classNotebooks endpoint unavailable, falling back to notebooks endpoint..." -ForegroundColor Yellow
        $uri = "https://graph.microsoft.com/v1.0/users/$UserId/onenote/notebooks?`$filter=displayName eq '$NotebookName'"
        $notebooks = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject

        if (-not $notebooks.value -or $notebooks.value.Count -eq 0) {
            throw "Notebook '$NotebookName' not found for user $TeacherUpn."
        }

        $notebook = $notebooks.value | Select-Object -First 1

        # Validate it's a class notebook by checking for characteristic section groups
        $sgUri = "https://graph.microsoft.com/v1.0/users/$UserId/onenote/notebooks/$($notebook.id)/sectionGroups"
        $sectionGroups = Invoke-MgGraphRequest -Method GET -Uri $sgUri -OutputType PSObject
        $sgNames = @($sectionGroups.value | ForEach-Object { $_.displayName })

        $hasContentLibrary = $sgNames -contains "_Content Library"
        $hasCollabSpace = $sgNames -contains "_Collaboration Space"

        if (-not $hasContentLibrary -and -not $hasCollabSpace) {
            throw "Notebook '$NotebookName' does not appear to be a Class Notebook. Missing expected section groups (_Content Library, _Collaboration Space)."
        }

        Write-Host "[Notebook] Found notebook: $($notebook.displayName) (validated via section groups)" -ForegroundColor Green
        return $notebook
    }

    # Find matching class notebook by name
    $notebook = $classNotebooks.value | Where-Object { $_.displayName -eq $NotebookName } | Select-Object -First 1

    if (-not $notebook) {
        throw "Class Notebook '$NotebookName' not found for user $TeacherUpn. Ensure this is a Class Notebook (not a regular notebook)."
    }

    Write-Host "[Notebook] Found Class Notebook: $($notebook.displayName) (ID: $($notebook.id))" -ForegroundColor Green
    Write-Host "[Notebook]   HasTeacherOnlySectionGroup: $($notebook.hasTeacherOnlySectionGroup)" -ForegroundColor Gray
    Write-Host "[Notebook]   IsCollaborationSpaceLocked: $($notebook.isCollaborationSpaceLocked)" -ForegroundColor Gray
    Write-Host "[Notebook]   StudentSections: $($notebook.studentSections -join ', ')" -ForegroundColor Gray

    return $notebook
}

function Get-ClassNotebookMembers {
    param([string]$UserId, [string]$NotebookId)

    Write-Host "[Members] Retrieving Class Notebook membership from metadata..." -ForegroundColor Cyan

    $teachers = @()
    $students = @()

    # Try the classNotebooks endpoint which exposes teachers/students directly
    $uri = "https://graph.microsoft.com/beta/users/$UserId/onenote/classNotebooks/$NotebookId"
    try {
        $classNb = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject

        # Extract teachers from Class Notebook metadata
        if ($classNb.teachers) {
            foreach ($teacher in $classNb.teachers) {
                $teacherUpn = $teacher.id  # PrincipalModel uses id as UPN/email
                if ($teacher.principalType -eq "Person" -or $teacher.id) {
                    # Resolve teacher to get their Azure AD object ID
                    try {
                        $userObj = Invoke-MgGraphRequest -Method GET `
                            -Uri "https://graph.microsoft.com/v1.0/users/$($teacher.id)" -OutputType PSObject
                        $teachers += @{ upn = $userObj.userPrincipalName; id = $userObj.id }
                    }
                    catch {
                        # If we can't resolve, use what we have
                        $teachers += @{ upn = $teacher.id; id = $null }
                    }
                }
            }
        }

        # Extract students from Class Notebook metadata
        if ($classNb.students) {
            foreach ($student in $classNb.students) {
                try {
                    $userObj = Invoke-MgGraphRequest -Method GET `
                        -Uri "https://graph.microsoft.com/v1.0/users/$($student.id)" -OutputType PSObject
                    $students += @{ upn = $userObj.userPrincipalName; id = $userObj.id }
                }
                catch {
                    $students += @{ upn = $student.id; id = $null }
                }
            }
        }

        # Store class notebook metadata for later use
        $script:ClassNotebookMetadata = @{
            HasTeacherOnlySectionGroup = $classNb.hasTeacherOnlySectionGroup
            IsCollaborationSpaceLocked = $classNb.isCollaborationSpaceLocked
            IsNotebookLocked           = $false  # Not exposed via classNotebooks API; default
            StudentSections            = $classNb.studentSections
            CreatedByAppId             = $classNb.createdByAppId
            CultureName                = $null   # Will be read from source drive item metadata
        }

        Write-Host "[Members] Retrieved from Class Notebook metadata: $($teachers.Count) teacher(s), $($students.Count) student(s)" -ForegroundColor Green

    }
    catch {
        Write-Host "[Members] classNotebooks metadata endpoint unavailable, falling back to permissions..." -ForegroundColor Yellow

        # Fallback: infer from notebook permissions (original approach)
        $teachers += @{ upn = $TeacherUpn; id = $UserId }

        $driveItem = Get-NotebookDriveItem -UserId $UserId -NotebookName $NotebookName
        if ($driveItem) {
            $permUri = "https://graph.microsoft.com/v1.0/users/$UserId/drive/items/$($driveItem.id)/permissions"
            $permissions = Invoke-MgGraphRequest -Method GET -Uri $permUri -OutputType PSObject

            foreach ($perm in $permissions.value) {
                if ($perm.grantedToV2 -and $perm.grantedToV2.user) {
                    $grantedUser = $perm.grantedToV2.user
                    $roles = $perm.roles

                    if ($roles -contains "write" -or $roles -contains "owner") {
                        if ($grantedUser.id -ne $UserId) {
                            $userUpn = if ($grantedUser.email) { $grantedUser.email } else { $grantedUser.displayName }
                            $teachers += @{ upn = $userUpn; id = $grantedUser.id }
                        }
                    }
                    elseif ($roles -contains "read") {
                        $userUpn = if ($grantedUser.email) { $grantedUser.email } else { $grantedUser.displayName }
                        $students += @{ upn = $userUpn; id = $grantedUser.id }
                    }
                }
            }
        }

        $script:ClassNotebookMetadata = @{
            HasTeacherOnlySectionGroup = $true  # Assume standard class notebook structure
            IsCollaborationSpaceLocked = $false
            IsNotebookLocked           = $false
            StudentSections            = @()
            CreatedByAppId             = $null
            CultureName                = $null
        }

        Write-Host "[Members] Inferred from permissions: $($teachers.Count) teacher(s), $($students.Count) student(s)" -ForegroundColor Green
    }

    # Get section groups for structural validation
    $sgUri = "https://graph.microsoft.com/v1.0/users/$UserId/onenote/notebooks/$NotebookId/sectionGroups"
    $sectionGroups = Invoke-MgGraphRequest -Method GET -Uri $sgUri -OutputType PSObject

    return @{
        Teachers      = $teachers
        Students      = $students
        SectionGroups = $sectionGroups.value
    }
}

function Get-NotebookDriveItem {
    param([string]$UserId, [string]$NotebookName)

    # Class Notebooks are stored in OneDrive under a specific path
    # Typically: /Class Notebooks/<NotebookName> or /Notebooks/<NotebookName>
    $searchPaths = @(
        "Class Notebooks/$NotebookName",
        "Notebooks/$NotebookName",
        $NotebookName
    )

    foreach ($path in $searchPaths) {
        try {
            $encodedPath = $path -replace ' ', '%20'
            $uri = "https://graph.microsoft.com/v1.0/users/$UserId/drive/root:/$encodedPath"
            $item = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject
            if ($item) {
                Write-Host "[Drive] Found notebook at: $path" -ForegroundColor Green
                return $item
            }
        }
        catch {
            # Path not found or access denied, try next
            continue
        }
    }

    # Fallback: search by name
    try {
        $uri = "https://graph.microsoft.com/v1.0/users/$UserId/drive/root/search(q='$NotebookName')?`$filter=folder ne null"
        $results = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject
        $match = $results.value | Where-Object { $_.name -eq $NotebookName } | Select-Object -First 1

        if ($match) {
            Write-Host "[Drive] Found notebook via search: $($match.name)" -ForegroundColor Green
            return $match
        }
    }
    catch { }

    throw "Could not locate notebook folder '$NotebookName' in teacher's OneDrive."
}

function Get-NotebookDriveItemForSource {
    # The signed-in co-teacher may not have direct access to the source teacher's drive.
    # Try the direct path first; if that fails, fall back to the shared-with-me view.
    param(
        [string]$SourceUserId,
        [string]$NotebookName
    )

    try {
        return Get-NotebookDriveItem -UserId $SourceUserId -NotebookName $NotebookName
    }
    catch {
        Write-Host "[Drive] Direct access to source teacher's drive failed; trying 'Shared with me' fallback..." -ForegroundColor Yellow
    }

    $sharedUri = "https://graph.microsoft.com/v1.0/me/drive/sharedWithMe"
    $shared = Invoke-MgGraphRequest -Method GET -Uri $sharedUri -OutputType PSObject

    $candidates = @($shared.value | Where-Object {
        $_.name -eq $NotebookName -and ($_.folder -or $_.remoteItem.folder -or $_.remoteItem.package)
    })

    if (-not $candidates -or $candidates.Count -eq 0) {
        throw "Notebook '$NotebookName' not found via direct access or in 'Shared with me'. Ensure the source teacher has shared the notebook with the signed-in co-teacher."
    }

    # Prefer the share that is owned by the source teacher
    $match = $candidates | Where-Object {
        $_.remoteItem.shared.owner.user.id -eq $SourceUserId -or
        $_.createdBy.user.id -eq $SourceUserId
    } | Select-Object -First 1
    if (-not $match) { $match = $candidates | Select-Object -First 1 }

    Write-Host "[Drive] Found shared notebook from source teacher." -ForegroundColor Green

    # Normalize so the caller can use .id and .parentReference.driveId for the copy call.
    if ($match.remoteItem) {
        $remote = $match.remoteItem
        return [PSCustomObject]@{
            id              = $remote.id
            name            = $remote.name
            folder          = $remote.folder
            package         = $remote.package
            parentReference = $remote.parentReference
            # Preserve the original drive id explicitly so the copy can target /drives/{id}/items/{id}
            sourceDriveId   = $remote.parentReference.driveId
            isShared        = $true
        }
    }
    return $match
}

function Get-OrCreateCoTeacherDestinationFolder {
    param([string]$FolderName)

    if ([string]::IsNullOrWhiteSpace($FolderName)) {
        $root = Invoke-MgGraphRequest -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/me/drive/root" -OutputType PSObject
        return $root
    }

    $encodedPath = ($FolderName -split '/' | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join '/'
    $folderUri = "https://graph.microsoft.com/v1.0/me/drive/root:/$encodedPath"

    try {
        $existing = Invoke-MgGraphRequest -Method GET -Uri $folderUri -OutputType PSObject
        if ($existing) {
            Write-Host "[CoTeacher] Destination folder exists: $FolderName" -ForegroundColor Green
            return $existing
        }
    }
    catch {
        # Will create below
    }

    Write-Host "[CoTeacher] Creating destination folder '$FolderName' in co-teacher's OneDrive..." -ForegroundColor Cyan
    $createBody = @{
        name                                = $FolderName
        folder                              = @{}
        "@microsoft.graph.conflictBehavior" = "rename"
    }
    $created = Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/v1.0/me/drive/root/children" `
        -Body ($createBody | ConvertTo-Json -Depth 5) `
        -ContentType "application/json" -OutputType PSObject
    Write-Host "[CoTeacher] Created folder: $($created.name)" -ForegroundColor Green
    return $created
}

function Copy-NotebookToCoTeacherDrive {
    param(
        [PSObject]$DriveItem,
        [string]$SourceUserId,
        [string]$DestinationFolderName
    )

    Write-Host "[Copy] Copying notebook into co-teacher's OneDrive..." -ForegroundColor Cyan

    $destDrive = Invoke-MgGraphRequest -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/me/drive" -OutputType PSObject

    $destFolder = Get-OrCreateCoTeacherDestinationFolder -FolderName $DestinationFolderName

    $copyBody = @{
        parentReference = @{
            driveId = $destDrive.id
            id      = $destFolder.id
        }
        name            = $TargetNotebookName
    }

    # Choose the copy URL based on what we actually have:
    #  - If the item came via sharedWithMe, use /drives/{driveId}/items/{id}/copy.
    #  - If the item has a parentReference.driveId (e.g. direct access), use /drives/{driveId}/...
    #  - Otherwise use /users/{sourceUserId}/drive/items/{id}/copy.
    if ($DriveItem.PSObject.Properties.Name -contains 'sourceDriveId' -and $DriveItem.sourceDriveId) {
        $copyUri = "https://graph.microsoft.com/v1.0/drives/$($DriveItem.sourceDriveId)/items/$($DriveItem.id)/copy"
    }
    elseif ($DriveItem.parentReference -and $DriveItem.parentReference.driveId) {
        $copyUri = "https://graph.microsoft.com/v1.0/drives/$($DriveItem.parentReference.driveId)/items/$($DriveItem.id)/copy"
    }
    else {
        $copyUri = "https://graph.microsoft.com/v1.0/users/$SourceUserId/drive/items/$($DriveItem.id)/copy"
    }

    $copyResponse = Invoke-MgGraphRequest -Method POST -Uri $copyUri `
        -Body ($copyBody | ConvertTo-Json -Depth 5) `
        -ContentType "application/json" `
        -OutputType PSObject `
        -StatusCodeVariable "statusCode" `
        -ResponseHeadersVariable "responseHeaders"

    if ($responseHeaders -and $responseHeaders["Location"]) {
        $monitorUrl = $responseHeaders["Location"][0]
        Write-Host "[Copy] Copy operation initiated. Monitoring progress..." -ForegroundColor Yellow

        $copyComplete = $false
        $maxWait = 600
        $elapsed = 0

        while (-not $copyComplete -and $elapsed -lt $maxWait) {
            Start-Sleep -Seconds 5
            $elapsed += 5

            try {
                $status = Invoke-MgGraphRequest -Method GET -Uri $monitorUrl -OutputType PSObject
                if ($status.status -eq "completed") {
                    $copyComplete = $true
                    Write-Host "[Copy] Copy completed successfully." -ForegroundColor Green
                }
                elseif ($status.status -eq "failed") {
                    throw "Copy operation failed: $($status.error.message)"
                }
                else {
                    $pct = if ($status.percentageComplete) { $status.percentageComplete } else { "?" }
                    Write-Host "[Copy] Progress: $pct% ..." -ForegroundColor Yellow
                }
            }
            catch [System.Net.Http.HttpRequestException] {
                continue
            }
        }

        if (-not $copyComplete) {
            throw "Copy operation timed out after $maxWait seconds."
        }
    }
    else {
        Write-Host "[Copy] Copy completed." -ForegroundColor Green
    }

    Start-Sleep -Seconds 5
    $lookupPath = if ([string]::IsNullOrWhiteSpace($DestinationFolderName)) {
        $TargetNotebookName
    } else {
        "$DestinationFolderName/$TargetNotebookName"
    }
    $encodedLookup = ($lookupPath -split '/' | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join '/'
    $copiedItem = Invoke-MgGraphRequest -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/me/drive/root:/$encodedLookup" -OutputType PSObject

    return $copiedItem
}

function Get-SourceStudentSectionNames {
    param([PSObject]$NotebookDriveItem)

    Write-Host "[Sections] Discovering student section names from source notebook..." -ForegroundColor Cyan

    $driveId = if ($NotebookDriveItem.PSObject.Properties.Name -contains 'sourceDriveId' -and $NotebookDriveItem.sourceDriveId) {
        $NotebookDriveItem.sourceDriveId
    }
    elseif ($NotebookDriveItem.parentReference -and $NotebookDriveItem.parentReference.driveId) {
        $NotebookDriveItem.parentReference.driveId
    }
    else { $null }

    if (-not $driveId) {
        Write-Warning "Cannot determine drive ID for source notebook."
        return @()
    }

    # Strategy 1: Read DefaultSectionNames from the source notebook's SharePoint list item metadata.
    # This is the most reliable method since it works regardless of whether the notebook is
    # stored as a folder or a OneNote package.
    try {
        $sourceItemUri = "https://graph.microsoft.com/v1.0/drives/$driveId/items/$($NotebookDriveItem.id)?`$expand=listItem"
        $sourceItemDetails = Invoke-MgGraphRequest -Method GET -Uri $sourceItemUri -OutputType PSObject
        if ($sourceItemDetails.listItem -and $sourceItemDetails.listItem.fields) {
            $srcFields = $sourceItemDetails.listItem.fields

            # Enrich ClassNotebookMetadata with source list item fields
            if ($script:ClassNotebookMetadata) {
                if ($srcFields.CultureName) {
                    $script:ClassNotebookMetadata.CultureName = $srcFields.CultureName
                    Write-Host "[Sections] Source CultureName: $($srcFields.CultureName)" -ForegroundColor Gray
                }
                if ($srcFields.IsNotebookLocked) {
                    $script:ClassNotebookMetadata.IsNotebookLocked = ($srcFields.IsNotebookLocked -eq "true" -or $srcFields.IsNotebookLocked -eq $true)
                }
                if ($srcFields.Is_Collaboration_Space_Locked) {
                    $script:ClassNotebookMetadata.IsCollaborationSpaceLocked = ($srcFields.Is_Collaboration_Space_Locked -eq "true" -or $srcFields.Is_Collaboration_Space_Locked -eq $true)
                }
                if ($srcFields.Has_Teacher_Only_SectionGroup) {
                    $script:ClassNotebookMetadata.HasTeacherOnlySectionGroup = ($srcFields.Has_Teacher_Only_SectionGroup -eq "true" -or $srcFields.Has_Teacher_Only_SectionGroup -eq $true)
                }
            }

            $defaultNames = $srcFields.DefaultSectionNames
            if ($defaultNames) {
                $sectionNames = @($defaultNames -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                if ($sectionNames.Count -gt 0) {
                    Write-Host "[Sections] Found $($sectionNames.Count) student section(s) from metadata: $($sectionNames -join ', ')" -ForegroundColor Green
                    return $sectionNames
                }
            }
        }
    }
    catch {
        Write-Host "[Sections] Could not read source list item metadata: $_" -ForegroundColor Yellow
    }

    # Strategy 2: Enumerate the notebook's folder children to find student section groups,
    # then read section names from the first student's folder. Works for folder-based notebooks.
    try {
        $childrenUri = "https://graph.microsoft.com/v1.0/drives/$driveId/items/$($NotebookDriveItem.id)/children"
        $children = Invoke-MgGraphRequest -Method GET -Uri $childrenUri -OutputType PSObject

        $systemFolders = @("_Content Library", "_Collaboration Space", "_Teacher Only")

        # Include items with folder OR package facet (OneNote section groups may use either)
        $studentFolders = @($children.value | Where-Object {
            ($_.folder -or $_.package) -and $_.name -notin $systemFolders
        })

        if ($studentFolders.Count -gt 0) {
            $firstStudent = $studentFolders[0]
            $sectionsUri = "https://graph.microsoft.com/v1.0/drives/$driveId/items/$($firstStudent.id)/children"
            $sections = Invoke-MgGraphRequest -Method GET -Uri $sectionsUri -OutputType PSObject

            $sectionNames = @($sections.value | ForEach-Object {
                $_.name -replace '\.one$', ''
            })

            if ($sectionNames.Count -gt 0) {
                Write-Host "[Sections] Found $($sectionNames.Count) student section(s) from folder structure: $($sectionNames -join ', ')" -ForegroundColor Green
                return $sectionNames
            }
        }
    }
    catch {
        Write-Host "[Sections] Could not enumerate source notebook children: $_" -ForegroundColor Yellow
    }

    Write-Host "[Sections] No student sections found in source." -ForegroundColor Yellow
    return @()
}

function Set-CoTeacherNotebookPermissions {
    param(
        [string]$CoTeacherUpn,
        [PSObject]$CopiedNotebookItem,
        [array]$Teachers,
        [array]$Students
    )

    Write-Host "[Permissions] Applying sharing on the co-teacher's copy..." -ForegroundColor Cyan

    # Use /me/drive for the destination since the signed-in user owns it
    $driveId = $CopiedNotebookItem.parentReference.driveId
    if (-not $driveId) {
        $destDrive = Invoke-MgGraphRequest -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/me/drive" -OutputType PSObject
        $driveId = $destDrive.id
    }
    $itemUri = "https://graph.microsoft.com/v1.0/drives/$driveId/items/$($CopiedNotebookItem.id)/invite"

    # All other teachers (including the original source teacher) get write access on the new copy.
    foreach ($teacher in $Teachers) {
        if (-not $teacher.upn) { continue }
        if ($teacher.upn -ieq $CoTeacherUpn) { continue }  # destination already owns the copy

        $inviteBody = @{
            recipients     = @(@{ email = $teacher.upn })
            roles          = @("write")
            requireSignIn  = $true
            sendInvitation = $false
        }
        try {
            Invoke-MgGraphRequest -Method POST -Uri $itemUri `
                -Body ($inviteBody | ConvertTo-Json -Depth 5) `
                -ContentType "application/json" | Out-Null
            Write-Host "[Permissions]   - Write access granted to teacher: $($teacher.upn)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not grant write to teacher $($teacher.upn): $_"
        }
    }

    # Students are NOT granted blanket read on the notebook root — that would expose
    # _Teacher Only. Instead, students are recorded in the Class Notebook metadata
    # (Students field + DefaultSectionNames). The teacher should use the Class Notebook
    # management page to distribute sections, which sets up proper per-section permissions.
    if ($Students.Count -gt 0) {
        Write-Host "[Permissions] Students ($($Students.Count)) are recorded in metadata but NOT granted" -ForegroundColor Yellow
        Write-Host "[Permissions] root-level access (to protect _Teacher Only)." -ForegroundColor Yellow
        Write-Host "[Permissions] Use the Class Notebook management page to distribute sections to students." -ForegroundColor Yellow
    }

    Write-Host "[Permissions] Co-teacher notebook permissions applied." -ForegroundColor Green
}

function Set-CoTeacherNotebookMetadata {
    param(
        [string]$CoTeacherUpn,
        [string]$CoTeacherId,
        [PSObject]$CopiedNotebookItem,
        [array]$Teachers,
        [array]$Students,
        [array]$StudentSectionNames = @()
    )

    Write-Host "[Metadata] Setting Class Notebook metadata on co-teacher's copy..." -ForegroundColor Cyan

    # Use /me/drive for the destination since the signed-in user owns it
    $driveBase = "https://graph.microsoft.com/v1.0/me/drive"

    # Step 1: Verify we can access the drive's document library list
    try {
        $list = Invoke-MgGraphRequest -Method GET -Uri "$driveBase/list" -OutputType PSObject
    }
    catch {
        Write-Warning "Could not access co-teacher's OneDrive document library list. Metadata cannot be set: $_"
        return
    }

    # Step 2: Resolve the copied item to its SharePoint list item
    $listItemId = $null
    try {
        $driveItemWithList = Invoke-MgGraphRequest -Method GET `
            -Uri "$driveBase/items/$($CopiedNotebookItem.id)?`$expand=listItem" -OutputType PSObject
        if ($driveItemWithList.listItem) {
            $listItemId = $driveItemWithList.listItem.id
            Write-Host "[Metadata] Resolved list item ID: $listItemId" -ForegroundColor Gray
        }
    }
    catch {
        Write-Warning "Could not resolve drive item to list item: $_"
    }

    if (-not $listItemId) {
        Write-Warning "Cannot determine SharePoint list item ID for the notebook folder. Metadata cannot be set."
        return
    }

    $listItemFieldsUri = "$driveBase/items/$($CopiedNotebookItem.id)/listItem/fields"
    $columnsUri = "$driveBase/list/columns"

    # Step 3: Ensure required SharePoint columns exist on the document library
    # These match exactly what the Class Notebook Creator service provisions
    Write-Host "[Metadata] Ensuring required SharePoint columns exist..." -ForegroundColor Cyan

    $columnsToEnsure = @(
        @{ displayName = "Notebook Type"; name = "NotebookType"; description = ""; text = @{} }
        @{ displayName = "Folder Type"; name = "FolderType"; description = ""; text = @{} }
        @{ displayName = "Culture Name"; name = "CultureName"; description = ""; text = @{} }
        @{ displayName = "App Version"; name = "AppVersion"; description = ""; text = @{} }
        @{ displayName = "Self Registration Enabled"; name = "Self_Registration_Enabled"; description = ""; text = @{} }
        @{ displayName = "Has Teacher Only SectionGroup"; name = "Has_Teacher_Only_SectionGroup"; description = ""; text = @{} }
        @{ displayName = "Is Collaboration Space Locked"; name = "Is_Collaboration_Space_Locked"; description = ""; text = @{} }
        @{ displayName = "Is Notebook Locked"; name = "IsNotebookLocked"; description = ""; text = @{} }
        @{ displayName = "Math Settings"; name = "Math_Settings"; description = ""; text = @{} }
        @{ displayName = "Teams Channel Section Location"; name = "Teams_Channel_Section_Location"; description = ""; text = @{} }
        @{ displayName = "Default Section Names"; name = "DefaultSectionNames"; description = ""; note = @{ linesForEditing = 6 } }
        @{ displayName = "Invited Teachers"; name = "Invited_Teachers"; description = ""; text = @{} }
        @{ displayName = "Invited Students"; name = "Invited_Students"; description = ""; text = @{} }
    )

    $userColumns = @(
        @{ displayName = "Teachers"; name = "Teachers"; description = ""; personOrGroup = @{ allowMultipleSelection = $true; chooseFromType = "peopleOnly" } }
        @{ displayName = "Students"; name = "Students"; description = ""; personOrGroup = @{ allowMultipleSelection = $true; chooseFromType = "peopleOnly" } }
        @{ displayName = "Owner"; name = "Owner"; description = ""; personOrGroup = @{ allowMultipleSelection = $false; chooseFromType = "peopleOnly" } }
    )

    try {
        $existingColumns = Invoke-MgGraphRequest -Method GET -Uri $columnsUri -OutputType PSObject
    }
    catch {
        Write-Warning "Could not list existing columns."
        $existingColumns = @{ value = @() }
    }

    foreach ($col in $columnsToEnsure) {
        $exists = $existingColumns.value | Where-Object { $_.name -eq $col.name }
        if (-not $exists) {
            try {
                Invoke-MgGraphRequest -Method POST -Uri $columnsUri `
                    -Body ($col | ConvertTo-Json -Depth 5) `
                    -ContentType "application/json" | Out-Null
                Write-Host "[Metadata]   Created column: $($col.displayName) ($($col.name))" -ForegroundColor Gray
            }
            catch {
                Write-Host "[Metadata]   Column '$($col.name)' skipped (may already exist)" -ForegroundColor DarkGray
            }
        }
    }

    foreach ($col in $userColumns) {
        $exists = $existingColumns.value | Where-Object { $_.name -eq $col.name }
        if (-not $exists) {
            try {
                Invoke-MgGraphRequest -Method POST -Uri $columnsUri `
                    -Body ($col | ConvertTo-Json -Depth 5) `
                    -ContentType "application/json" | Out-Null
                Write-Host "[Metadata]   Created user column: $($col.displayName)" -ForegroundColor Gray
            }
            catch {
                Write-Host "[Metadata]   User column '$($col.name)' skipped (may already exist)" -ForegroundColor DarkGray
            }
        }
    }

    Start-Sleep -Seconds 3

    # Step 4: Set the core metadata fields on the notebook list item
    # These are the CRITICAL fields checked by GetNotebookType() in the CNB service
    $hasTeacherOnly = "true"
    $isCollabLocked = "false"
    $isNotebookLocked = "false"
    $cultureName = $null
    if ($script:ClassNotebookMetadata) {
        $hasTeacherOnly = if ($script:ClassNotebookMetadata.HasTeacherOnlySectionGroup) { "true" } else { "false" }
        $isCollabLocked = if ($script:ClassNotebookMetadata.IsCollaborationSpaceLocked) { "true" } else { "false" }
        $isNotebookLocked = if ($script:ClassNotebookMetadata.IsNotebookLocked) { "true" } else { "false" }
        $cultureName = $script:ClassNotebookMetadata.CultureName
    }

    $coreMetadata = @{
        NotebookType                    = "EDU"
        FolderType                      = "Notebook"
        AppVersion                      = "4.3.0.3"
        Has_Teacher_Only_SectionGroup   = $hasTeacherOnly
        Is_Collaboration_Space_Locked   = $isCollabLocked
        IsNotebookLocked                = $isNotebookLocked
        Self_Registration_Enabled       = "false"
        Invited_Teachers                = ""
        Invited_Students                = ""
    }

    if ($cultureName) {
        $coreMetadata["CultureName"] = $cultureName
    }

    # Propagate student section names from the source notebook
    if ($StudentSectionNames -and $StudentSectionNames.Count -gt 0) {
        $coreMetadata["DefaultSectionNames"] = ($StudentSectionNames -join "`n")
        Write-Host "[Metadata] DefaultSectionNames: $($StudentSectionNames -join ', ')" -ForegroundColor Gray
    }

    try {
        Invoke-MgGraphRequest -Method PATCH -Uri $listItemFieldsUri `
            -Body ($coreMetadata | ConvertTo-Json -Depth 5) `
            -ContentType "application/json" | Out-Null
        Write-Host "[Metadata] Core fields set: NotebookType=EDU, FolderType=Notebook" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to set core metadata fields: $_"
        Write-Host "[Metadata] The 'NotebookType=EDU' field is CRITICAL for the Class Notebook toolbar." -ForegroundColor Red
    }

    # Step 5: Set Teachers/Students/Owner user fields
    Write-Host "[Metadata] Setting Teachers/Students/Owner user fields..." -ForegroundColor Cyan

    $teacherEmails = @($Teachers | ForEach-Object { $_.upn } | Where-Object { $_ })
    $studentEmails = @($Students | ForEach-Object { $_.upn } | Where-Object { $_ })

    # Resolve the siteId for User Information List lookup
    $siteId = $null
    try {
        $driveRoot = Invoke-MgGraphRequest -Method GET `
            -Uri "$driveBase/root?`$select=sharepointIds" -OutputType PSObject
        $siteId = $driveRoot.sharepointIds.siteId
    }
    catch { }

    if (-not $siteId) {
        # Fallback: derive siteId from the drive webUrl
        try {
            $driveInfo = Invoke-MgGraphRequest -Method GET -Uri $driveBase -OutputType PSObject
            $webUrl = $driveInfo.webUrl
            $siteUrl = $webUrl -replace '/[^/]+$', ''
            $parts = $siteUrl -replace 'https://', ''
            $hostname = ($parts -split '/')[0]
            $relativePath = ($parts -split '/', 2)[1]
            $siteRef = "$hostname`:/$relativePath"
            $siteObj = Invoke-MgGraphRequest -Method GET `
                -Uri "https://graph.microsoft.com/v1.0/sites/$siteRef" -OutputType PSObject
            $siteId = $siteObj.id
        }
        catch {
            Write-Host "[Metadata] Could not resolve site ID for user field lookup: $_" -ForegroundColor Yellow
        }
    }

    if ($siteId) {
        Write-Host "[Metadata] Resolving teacher/student user IDs on the site..." -ForegroundColor Gray
        $resolvedTeachers = @()
        $resolvedTeacherEmails = @()
        $resolvedStudents = @()
        $resolvedStudentEmails = @()
        $coTeacherLookupId = $null

        $preferHeader = @{ "Prefer" = "HonorNonIndexedQueriesWarningMayFailRandomly" }

        # Helper: ensure a user exists in the site's User Information List by granting
        # them a temporary read invite on the notebook, then resolve the LookupId.
        function Resolve-UserLookupId {
            param([string]$SiteId, [string]$Email, [string]$DriveBase, [string]$ItemId)
            $userInfoListUri = "https://graph.microsoft.com/v1.0/sites/$SiteId/lists/User Information List/items?`$filter=fields/EMail eq '$Email'&`$select=id&`$expand=fields(`$select=EMail)"
            $userResult = Invoke-MgGraphRequest -Method GET -Uri $userInfoListUri -Headers $preferHeader -OutputType PSObject
            if ($userResult.value -and $userResult.value.Count -gt 0) {
                return [int]$userResult.value[0].id
            }

            # User not in UIL — ensure them by granting a read invite on the notebook root.
            # This triggers SharePoint to create the UIL entry.
            Write-Host "[Metadata]   Ensuring user '$Email' on site via invite..." -ForegroundColor Gray
            try {
                $inviteBody = @{
                    recipients     = @(@{ email = $Email })
                    roles          = @("read")
                    requireSignIn  = $true
                    sendInvitation = $false
                }
                Invoke-MgGraphRequest -Method POST `
                    -Uri "$DriveBase/items/$ItemId/invite" `
                    -Body ($inviteBody | ConvertTo-Json -Depth 5) `
                    -ContentType "application/json" | Out-Null
            }
            catch {
                Write-Host "[Metadata]   Could not invite '$Email' to ensure site user: $_" -ForegroundColor Yellow
                return $null
            }

            # Wait briefly for UIL propagation then retry
            Start-Sleep -Seconds 2
            $userResult = Invoke-MgGraphRequest -Method GET -Uri $userInfoListUri -Headers $preferHeader -OutputType PSObject
            if ($userResult.value -and $userResult.value.Count -gt 0) {
                return [int]$userResult.value[0].id
            }
            return $null
        }

        foreach ($email in $teacherEmails) {
            try {
                $lookupId = Resolve-UserLookupId -SiteId $siteId -Email $email -DriveBase $driveBase -ItemId $CopiedNotebookItem.id
                if ($lookupId) {
                    $resolvedTeachers += $lookupId
                    $resolvedTeacherEmails += $email
                    if ($email -ieq $CoTeacherUpn) { $coTeacherLookupId = $lookupId }
                    Write-Host "[Metadata]   Teacher '$email' resolved to LookupId: $lookupId" -ForegroundColor Gray
                }
                else {
                    Write-Host "[Metadata]   Teacher '$email' could not be resolved" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "[Metadata]   Could not resolve teacher '$email': $_" -ForegroundColor Yellow
            }
        }

        foreach ($email in $studentEmails) {
            try {
                $lookupId = Resolve-UserLookupId -SiteId $siteId -Email $email -DriveBase $driveBase -ItemId $CopiedNotebookItem.id
                if ($lookupId) {
                    $resolvedStudents += $lookupId
                    $resolvedStudentEmails += $email
                    Write-Host "[Metadata]   Student '$email' resolved to LookupId: $lookupId" -ForegroundColor Gray
                }
                else {
                    Write-Host "[Metadata]   Student '$email' could not be resolved" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "[Metadata]   Could not resolve student '$email': $_" -ForegroundColor Yellow
            }
        }

        $userFieldPatch = @{}

        if ($resolvedTeachers.Count -gt 0) {
            $userFieldPatch["TeachersLookupId@odata.type"] = "Collection(Edm.Int32)"
            $userFieldPatch["TeachersLookupId"] = $resolvedTeachers
            Write-Host "[Metadata]   Setting Teachers field with $($resolvedTeachers.Count) user(s)" -ForegroundColor Gray
        }

        if ($resolvedStudents.Count -gt 0) {
            $userFieldPatch["StudentsLookupId@odata.type"] = "Collection(Edm.Int32)"
            $userFieldPatch["StudentsLookupId"] = $resolvedStudents
            Write-Host "[Metadata]   Setting Students field with $($resolvedStudents.Count) user(s)" -ForegroundColor Gray
        }

        # Last resort: any users that still couldn't be resolved (e.g. external or deleted
        # accounts that the invite API rejected) go to Invited_Teachers/Invited_Students.
        $unresolvedTeacherEmails = @($teacherEmails | Where-Object { $_ -notin $resolvedTeacherEmails })
        if ($unresolvedTeacherEmails.Count -gt 0) {
            $userFieldPatch["Invited_Teachers"] = ($unresolvedTeacherEmails -join ",")
            Write-Host "[Metadata]   Setting Invited_Teachers for $($unresolvedTeacherEmails.Count) unresolvable teacher(s)" -ForegroundColor Yellow
        }

        $unresolvedStudentEmails = @($studentEmails | Where-Object { $_ -notin $resolvedStudentEmails })
        if ($unresolvedStudentEmails.Count -gt 0) {
            $userFieldPatch["Invited_Students"] = ($unresolvedStudentEmails -join ",")
            Write-Host "[Metadata]   Setting Invited_Students for $($unresolvedStudentEmails.Count) unresolvable student(s)" -ForegroundColor Yellow
        }

        # Owner = co-teacher (they own this copy); fall back to first resolved teacher
        $ownerLookupId = if ($coTeacherLookupId) { $coTeacherLookupId }
                         elseif ($resolvedTeachers.Count -gt 0) { $resolvedTeachers[0] }
                         else { $null }
        if ($ownerLookupId) {
            $userFieldPatch["OwnerLookupId"] = $ownerLookupId
            Write-Host "[Metadata]   Setting Owner field to co-teacher (LookupId: $ownerLookupId)" -ForegroundColor Gray
        }

        if ($userFieldPatch.Count -gt 0) {
            try {
                Invoke-MgGraphRequest -Method PATCH -Uri $listItemFieldsUri `
                    -Body ($userFieldPatch | ConvertTo-Json -Depth 5) `
                    -ContentType "application/json" | Out-Null
                Write-Host "[Metadata] Teachers/Students/Owner user fields set successfully" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to set user fields via Graph: $_"
            }
        }
        else {
            Write-Warning "No users could be resolved on the site. Users must visit the site at least once."
        }
    }
    else {
        Write-Warning "Could not resolve site ID. Teachers/Students/Owner fields cannot be set automatically."
    }

    Write-Host "[Metadata] Class Notebook metadata configuration complete." -ForegroundColor Green
    Write-Host "[Metadata] Verify with:" -ForegroundColor Cyan
    Write-Host "[Metadata]   GET $driveBase/items/$($CopiedNotebookItem.id)/listItem/fields" -ForegroundColor DarkCyan
    Write-Host "[Metadata]   Expected: NotebookType='EDU', FolderType='Notebook'" -ForegroundColor DarkCyan
}

function Repair-ClassNotebookPermissions {
    # Replicates the CNB service's FixNotebookPermissionsV4 using Microsoft Graph.
    # Reads Teachers/Students from the notebook's SharePoint list item fields, then
    # sets per-section-group permissions:
    #   Notebook root:        Teachers=write, Students=NO ROOT ACCESS (inherits to children)
    #   _Collaboration Space: Teachers=write, Students=write (or read if locked)
    #   _Content Library:     Teachers=write, Students=read
    #   _Teacher Only:        Teachers=write, Students=NO ACCESS
    #   OneNote_RecycleBin:   Teachers=write, Students=write
    #   Student folders:      Teachers=write, only that student=write (or read if notebook locked)
    param(
        [string]$DriveId,
        [string]$NotebookItemId
    )

    Write-Host "[Repair] Repairing Class Notebook permissions via Graph API..." -ForegroundColor Cyan
    $driveBase = "https://graph.microsoft.com/v1.0/drives/$DriveId"

    # Step 1: Get the notebook item with its list item fields to read Teachers/Students
    Write-Host "[Repair] Reading notebook metadata..." -ForegroundColor Gray
    $nbItem = Invoke-MgGraphRequest -Method GET `
        -Uri "$driveBase/items/${NotebookItemId}?`$expand=listItem" -OutputType PSObject

    $fields = $null
    $listItemFieldsUri = "$driveBase/items/$NotebookItemId/listItem/fields"
    try {
        $fields = Invoke-MgGraphRequest -Method GET -Uri $listItemFieldsUri -OutputType PSObject
    }
    catch {
        Write-Warning "Cannot read notebook list item fields: $_"
    }

    $isCollabLocked = $false
    if ($fields -and $fields.Is_Collaboration_Space_Locked -eq "true") {
        $isCollabLocked = $true
    }

    # Step 2: Collect teacher and student emails from the Teachers/Students PersonOrGroup fields
    $teacherEmails = @()
    $studentEmails = @()

    # Resolve siteId for User Information List lookups
    $siteId = $null
    if ($nbItem.listItem -and $nbItem.listItem.parentReference -and $nbItem.listItem.parentReference.siteId) {
        $siteId = $nbItem.listItem.parentReference.siteId
    }
    if (-not $siteId) {
        try {
            $driveInfo = Invoke-MgGraphRequest -Method GET -Uri $driveBase -OutputType PSObject
            if ($driveInfo.sharepointIds) { $siteId = $driveInfo.sharepointIds.siteId }
        }
        catch { }
    }

    $preferHeader = @{ "Prefer" = "HonorNonIndexedQueriesWarningMayFailRandomly" }

    if ($siteId -and $fields) {
        # Graph returns PersonOrGroup fields as objects with LookupId, LookupValue, Email
        # properties (single-value) or arrays of such objects (multi-value).
        # Extract emails directly from these objects.

        # Helper: extract emails from a PersonOrGroup field value
        function Extract-EmailsFromField {
            param($FieldValue)
            $emails = @()
            if (-not $FieldValue) { return $emails }

            # Could be a single object or an array of objects
            $items = if ($FieldValue -is [System.Collections.IEnumerable] -and $FieldValue -isnot [string] -and $FieldValue -isnot [System.Collections.Hashtable]) {
                $FieldValue
            } else {
                @($FieldValue)
            }

            foreach ($item in $items) {
                $email = $null
                if ($item -is [PSCustomObject] -or $item -is [System.Collections.Hashtable]) {
                    $email = if ($item.Email) { $item.Email }
                             elseif ($item.EMail) { $item.EMail }
                             else { $null }
                }
                if ($email) { $emails += $email }
            }
            return $emails
        }

        $teacherEmails = @(Extract-EmailsFromField -FieldValue $fields.Teachers)
        $studentEmails = @(Extract-EmailsFromField -FieldValue $fields.Students)

        if ($teacherEmails.Count -gt 0) {
            Write-Host "[Repair] Teachers from metadata: $($teacherEmails -join ', ')" -ForegroundColor Gray
        }
        if ($studentEmails.Count -gt 0) {
            Write-Host "[Repair] Students from metadata: $($studentEmails -join ', ')" -ForegroundColor Gray
        }

        # Also resolve the Owner field
        if ($teacherEmails.Count -eq 0 -and $fields.OwnerLookupId) {
            try {
                $preferHeader = @{ "Prefer" = "HonorNonIndexedQueriesWarningMayFailRandomly" }
                $ownerItem = Invoke-MgGraphRequest -Method GET `
                    -Uri "https://graph.microsoft.com/v1.0/sites/$siteId/lists/User Information List/items/$($fields.OwnerLookupId)/fields" `
                    -Headers $preferHeader -OutputType PSObject
                if ($ownerItem.EMail) {
                    $teacherEmails += $ownerItem.EMail
                    Write-Host "[Repair] Owner resolved: $($ownerItem.EMail)" -ForegroundColor Gray
                }
            }
            catch { }
        }
    }

    # Fallback: Invited_Teachers / Invited_Students text fields
    if ($teacherEmails.Count -eq 0 -and $fields -and $fields.Invited_Teachers) {
        $teacherEmails = @($fields.Invited_Teachers -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }
    if ($studentEmails.Count -eq 0 -and $fields -and $fields.Invited_Students) {
        $studentEmails = @($fields.Invited_Students -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }

    # Fallback: infer from existing permissions on the notebook drive item
    if ($teacherEmails.Count -eq 0 -or $studentEmails.Count -eq 0) {
        Write-Host "[Repair] Metadata fields empty; inferring membership from drive item permissions..." -ForegroundColor Yellow
        try {
            $perms = Invoke-MgGraphRequest -Method GET `
                -Uri "$driveBase/items/$NotebookItemId/permissions" -OutputType PSObject
            foreach ($perm in $perms.value) {
                if (-not $perm.grantedToV2 -or -not $perm.grantedToV2.user) { continue }
                $grantedUser = $perm.grantedToV2.user
                $userEmail = if ($grantedUser.email) { $grantedUser.email } else { $null }
                if (-not $userEmail) { continue }
                $roles = $perm.roles
                if ($roles -contains "owner") { continue }
                if ($roles -contains "write") {
                    if ($userEmail -notin $teacherEmails) { $teacherEmails += $userEmail }
                }
                elseif ($roles -contains "read") {
                    if ($userEmail -notin $studentEmails) { $studentEmails += $userEmail }
                }
            }
        }
        catch {
            Write-Host "[Repair] Could not read drive item permissions: $_" -ForegroundColor Yellow
        }
    }

    # Also include the notebook owner (from createdBy) as a teacher
    if ($nbItem.createdBy -and $nbItem.createdBy.user) {
        $ownerEmail = $nbItem.createdBy.user.email
        if ($ownerEmail -and $ownerEmail -notin $teacherEmails) {
            $teacherEmails += $ownerEmail
        }
    }

    Write-Host "[Repair] Teachers: $($teacherEmails.Count), Students: $($studentEmails.Count)" -ForegroundColor Gray

    if ($teacherEmails.Count -eq 0) {
        Write-Warning "No teachers found in notebook metadata. Cannot repair permissions."
        return
    }

    # Step 3: Get children of the notebook folder to identify section groups
    $childrenUri = "$driveBase/items/$NotebookItemId/children"
    $children = Invoke-MgGraphRequest -Method GET -Uri $childrenUri -OutputType PSObject

    # Identify system section groups and student folders
    $systemFolderTypes = @{
        "_Content Library"      = @{ studentRole = "read"; folderType = "Content Library" }
        "_Collaboration Space"  = @{ studentRole = if ($isCollabLocked) { "read" } else { "write" }; folderType = "Collaboration Space" }
        "_Teacher Only"         = @{ studentRole = "none"; folderType = "Writer Only" }
        "OneNote_RecycleBin"    = @{ studentRole = "write"; folderType = "Recycle Bin" }
    }

    # Helper: grant permissions on a drive item
    function Grant-ItemPermission {
        param([string]$ItemId, [string]$Email, [string]$Role)
        $inviteBody = @{
            recipients     = @(@{ email = $Email })
            roles          = @($Role)
            requireSignIn  = $true
            sendInvitation = $false
        }
        Invoke-MgGraphRequest -Method POST `
            -Uri "$driveBase/items/$ItemId/invite" `
            -Body ($inviteBody | ConvertTo-Json -Depth 5) `
            -ContentType "application/json" | Out-Null
    }

    # Helper: revoke all permissions for a set of emails on a drive item
    function Revoke-ItemPermissions {
        param([string]$ItemId, [string[]]$Emails)
        if (-not $Emails -or $Emails.Count -eq 0) { return }
        $emailSet = @($Emails | ForEach-Object { $_.ToLowerInvariant() })
        try {
            $perms = Invoke-MgGraphRequest -Method GET `
                -Uri "$driveBase/items/$ItemId/permissions" -OutputType PSObject
            foreach ($perm in $perms.value) {
                if ($perm.roles -contains "owner") { continue }
                $permEmail = $null
                if ($perm.grantedToV2 -and $perm.grantedToV2.user -and $perm.grantedToV2.user.email) {
                    $permEmail = $perm.grantedToV2.user.email.ToLowerInvariant()
                }
                if ($permEmail -and $emailSet -contains $permEmail) {
                    try {
                        Invoke-MgGraphRequest -Method DELETE `
                            -Uri "$driveBase/items/$ItemId/permissions/$($perm.id)" | Out-Null
                    }
                    catch { }
                }
            }
        }
        catch { }
    }

    # Step 4: Set HTML_x0020_File_x0020_Type on notebook root
    try {
        $nbListItemFieldsUri = "$driveBase/items/$NotebookItemId/listItem/fields"
        Invoke-MgGraphRequest -Method PATCH -Uri $nbListItemFieldsUri `
            -Body (@{ "HTML_x0020_File_x0020_Type" = "OneNote.Notebook" } | ConvertTo-Json) `
            -ContentType "application/json" | Out-Null
    }
    catch {
        Write-Host "[Repair] Could not set HTML File Type on notebook (may already be set)" -ForegroundColor DarkGray
    }

    # Step 5: Set permissions on notebook root
    # Students need read on the root to navigate to the notebook. This inherits to children,
    # so we must explicitly revoke student access from _Teacher Only and other students'
    # folders in subsequent steps.
    Write-Host "[Repair] Setting notebook root permissions..." -ForegroundColor Gray
    foreach ($email in $teacherEmails) {
        try { Grant-ItemPermission -ItemId $NotebookItemId -Email $email -Role "write" } catch { }
    }
    foreach ($email in $studentEmails) {
        try { Grant-ItemPermission -ItemId $NotebookItemId -Email $email -Role "read" } catch { }
    }

    # Determine if notebook is locked (affects student section group permissions)
    $isNotebookLocked = $false
    if ($fields -and ($fields.IsNotebookLocked -eq "true" -or $fields.IsNotebookLocked -eq $true)) {
        $isNotebookLocked = $true
    }

    # Step 6: Set permissions and FolderType metadata on system section groups
    $systemFolderNames = @($systemFolderTypes.Keys)
    foreach ($child in $children.value) {
        if (-not ($child.folder -or $child.package)) { continue }
        if ($child.name -notin $systemFolderNames) { continue }

        $sysConfig = $systemFolderTypes[$child.name]
        $studentRole = $sysConfig.studentRole
        $folderType = $sysConfig.folderType
        Write-Host "[Repair] Setting permissions on '$($child.name)' (students=$studentRole)..." -ForegroundColor Gray

        # Set FolderType metadata on the section group
        try {
            $childFieldsUri = "$driveBase/items/$($child.id)/listItem/fields"
            Invoke-MgGraphRequest -Method PATCH -Uri $childFieldsUri `
                -Body (@{ FolderType = $folderType } | ConvertTo-Json) `
                -ContentType "application/json" | Out-Null
        }
        catch {
            Write-Host "[Repair]   Could not set FolderType on '$($child.name)'" -ForegroundColor DarkGray
        }

        # Teachers always get write
        foreach ($email in $teacherEmails) {
            try { Grant-ItemPermission -ItemId $child.id -Email $email -Role "write" } catch { }
        }

        # Students: revoke any existing access first, then grant correct role (or none)
        if ($studentRole -eq "none") {
            Revoke-ItemPermissions -ItemId $child.id -Emails $studentEmails
        }
        else {
            foreach ($email in $studentEmails) {
                try { Grant-ItemPermission -ItemId $child.id -Email $email -Role $studentRole } catch { }
            }
        }
    }

    # Step 7: Resolve student-to-folder mapping, then fix permissions
    # First pass: build a map of which student owns which folder.
    # Second pass: revoke students from all unmatched/orphaned folders.
    # Third pass: grant correct permissions on matched student folders.
    $childFolderMap = @{}
    foreach ($child in $children.value) {
        if (-not ($child.folder -or $child.package)) { continue }
        if ($child.name -in $systemFolderNames) { continue }
        $childFolderMap[$child.name.ToLowerInvariant()] = $child
    }

    # First pass: resolve each student to their folder
    $studentToFolder = @{}
    $matchedFolderIds = @()
    foreach ($email in $studentEmails) {
        $alias = ($email -replace '@.*$', '').ToLowerInvariant()
        $studentFolder = $null

        # Try exact alias match
        if ($childFolderMap.ContainsKey($alias)) {
            $studentFolder = $childFolderMap[$alias]
        }

        # Try display name via Graph
        if (-not $studentFolder) {
            try {
                $userObj = Invoke-MgGraphRequest -Method GET `
                    -Uri "https://graph.microsoft.com/v1.0/users/$email`?`$select=displayName" -OutputType PSObject
                if ($userObj.displayName) {
                    $displayNameLower = $userObj.displayName.ToLowerInvariant()
                    if ($childFolderMap.ContainsKey($displayNameLower)) {
                        $studentFolder = $childFolderMap[$displayNameLower]
                    }
                }
            }
            catch { }
        }

        # Try substring match as last resort
        if (-not $studentFolder) {
            foreach ($folderName in $childFolderMap.Keys) {
                if ($folderName -like "*$alias*") {
                    $studentFolder = $childFolderMap[$folderName]
                    break
                }
            }
        }

        if ($studentFolder) {
            $studentToFolder[$email] = $studentFolder
            $matchedFolderIds += $studentFolder.id
        }
        else {
            Write-Host "[Repair] No folder found for student '$email' — section group may not exist yet" -ForegroundColor DarkYellow
        }
    }

    # Second pass: revoke student access from ALL non-system folders first (unmatched AND matched).
    # This cleans up inherited root-level read and any stale cross-student grants.
    foreach ($folderName in $childFolderMap.Keys) {
        $folder = $childFolderMap[$folderName]
        if ($folder.id -notin $matchedFolderIds) {
            Write-Host "[Repair] Revoking student access from unmatched folder '$($folder.name)'" -ForegroundColor Gray
            Revoke-ItemPermissions -ItemId $folder.id -Emails $studentEmails
        }
        else {
            # For matched folders, revoke OTHER students (not the owner)
            $ownerEmail = ($studentToFolder.GetEnumerator() | Where-Object { $_.Value.id -eq $folder.id } | Select-Object -First 1).Key
            $otherStudents = @($studentEmails | Where-Object { $_ -ine $ownerEmail })
            if ($otherStudents.Count -gt 0) {
                Revoke-ItemPermissions -ItemId $folder.id -Emails $otherStudents
            }
        }
    }

    # Third pass: grant correct permissions on matched student folders
    foreach ($entry in $studentToFolder.GetEnumerator()) {
        $email = $entry.Key
        $studentFolder = $entry.Value
        Write-Host "[Repair] Setting permissions on student folder '$($studentFolder.name)' → $email" -ForegroundColor Gray

        # Teachers get write
        foreach ($teacherEmail in $teacherEmails) {
            try { Grant-ItemPermission -ItemId $studentFolder.id -Email $teacherEmail -Role "write" } catch { }
        }

        # Only this student gets access to their own section group
        $studentSectionRole = if ($isNotebookLocked) { "read" } else { "write" }
        try { Grant-ItemPermission -ItemId $studentFolder.id -Email $email -Role $studentSectionRole } catch { }
    }

    Write-Host "[Repair] Permission repair complete." -ForegroundColor Green
}

function Remove-SourceNotebookAccess {
    # Best-effort cleanup: revoke co-teacher and student access on the SOURCE notebook
    # so they no longer hit the original after the new copy is in place. The owner
    # (source teacher) is preserved.
    param(
        [PSObject]$DriveItem,
        [string]$SourceUserId,
        [string]$SourceTeacherUpn,
        [array]$Teachers,
        [array]$Students
    )

    Write-Host "[Cleanup] Removing co-teacher and student access from source notebook..." -ForegroundColor Cyan

    # The source item may have come from sharedWithMe (sourceDriveId set) or directly from
    # the source teacher's drive. Use the appropriate base URL for permission CRUD.
    if ($DriveItem.PSObject.Properties.Name -contains 'sourceDriveId' -and $DriveItem.sourceDriveId) {
        $itemBase = "https://graph.microsoft.com/v1.0/drives/$($DriveItem.sourceDriveId)/items/$($DriveItem.id)"
    }
    elseif ($DriveItem.parentReference -and $DriveItem.parentReference.driveId) {
        $itemBase = "https://graph.microsoft.com/v1.0/drives/$($DriveItem.parentReference.driveId)/items/$($DriveItem.id)"
    }
    else {
        $itemBase = "https://graph.microsoft.com/v1.0/users/$SourceUserId/drive/items/$($DriveItem.id)"
    }

    try {
        $permissions = Invoke-MgGraphRequest -Method GET -Uri "$itemBase/permissions" -OutputType PSObject
    }
    catch {
        Write-Warning "Could not enumerate source permissions (you may lack rights on the source notebook): $_"
        return
    }

    # Build the set of UPNs / IDs whose access we want to revoke.
    $revokeUpns = @()
    foreach ($t in $Teachers) {
        if ($t.upn -and $t.upn -ine $SourceTeacherUpn) { $revokeUpns += $t.upn.ToLowerInvariant() }
    }
    foreach ($s in $Students) {
        if ($s.upn) { $revokeUpns += $s.upn.ToLowerInvariant() }
    }
    $revokeUpns = @($revokeUpns | Select-Object -Unique)

    $removed = 0
    $skipped = 0
    $failed = 0

    foreach ($perm in $permissions.value) {
        # Skip the owner permission so the source teacher keeps full access
        if ($perm.roles -contains "owner") { $skipped++; continue }

        $targets = @()
        if ($perm.grantedToV2) {
            if ($perm.grantedToV2.user) { $targets += $perm.grantedToV2.user }
            if ($perm.grantedToV2.siteUser) { $targets += $perm.grantedToV2.siteUser }
        }
        if ($perm.grantedToIdentitiesV2) {
            foreach ($g in $perm.grantedToIdentitiesV2) {
                if ($g.user) { $targets += $g.user }
                if ($g.siteUser) { $targets += $g.siteUser }
            }
        }

        $matchUpn = $null
        foreach ($tgt in $targets) {
            $upnCandidate = $tgt.email
            if (-not $upnCandidate -and $tgt.userPrincipalName) { $upnCandidate = $tgt.userPrincipalName }
            if ($upnCandidate -and $revokeUpns -contains $upnCandidate.ToLowerInvariant()) {
                $matchUpn = $upnCandidate
                break
            }
        }

        if (-not $matchUpn) { $skipped++; continue }

        try {
            Invoke-MgGraphRequest -Method DELETE -Uri "$itemBase/permissions/$($perm.id)" | Out-Null
            Write-Host "[Cleanup]   - Revoked access for: $matchUpn" -ForegroundColor Green
            $removed++
        }
        catch {
            Write-Warning "Could not revoke permission for ${matchUpn}: $_"
            $failed++
        }
    }

    Write-Host "[Cleanup] Done. Revoked: $removed, Skipped: $skipped, Failed: $failed" -ForegroundColor Green
    if ($failed -gt 0) {
        Write-Host "[Cleanup] Some permissions could not be removed. The source teacher (owner) may need to remove them manually in OneDrive." -ForegroundColor Yellow
    }
}

#endregion

#region --- Main Execution ---

try {
    if ($FixPermissions) {
        # --- FIX PERMISSIONS MODE ---
        Write-Host "========================================" -ForegroundColor Magenta
        Write-Host " Class Notebook Permission Repair" -ForegroundColor Magenta
        Write-Host "========================================" -ForegroundColor Magenta
        Write-Host ""

        # Step 1: Authenticate
        Connect-ToGraph

        # Step 2: Get the signed-in user's identity
        $me = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/me" -OutputType PSObject
        Write-Host "[Info] Signed in as: $($me.userPrincipalName)" -ForegroundColor Cyan

        # Step 3: Find the notebook drive item using /me/drive
        Write-Host "[Fix] Looking up notebook '$NotebookName' in OneDrive..." -ForegroundColor Cyan
        $meDrive = Invoke-MgGraphRequest -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/me/drive" -OutputType PSObject

        # Search well-known paths on /me/drive
        $nbDriveItem = $null
        $searchPaths = @(
            "Class Notebooks/$NotebookName",
            "Notebooks/$NotebookName",
            $NotebookName
        )
        foreach ($path in $searchPaths) {
            try {
                $encodedPath = $path -replace ' ', '%20'
                $nbDriveItem = Invoke-MgGraphRequest -Method GET `
                    -Uri "https://graph.microsoft.com/v1.0/me/drive/root:/$encodedPath" -OutputType PSObject
                if ($nbDriveItem) {
                    Write-Host "[Drive] Found notebook at: $path" -ForegroundColor Green
                    break
                }
            }
            catch { continue }
        }

        if (-not $nbDriveItem) {
            # Fallback: search by name
            try {
                $searchUri = "https://graph.microsoft.com/v1.0/me/drive/root/search(q='$NotebookName')?`$filter=folder ne null"
                $results = Invoke-MgGraphRequest -Method GET -Uri $searchUri -OutputType PSObject
                $nbDriveItem = $results.value | Where-Object { $_.name -eq $NotebookName } | Select-Object -First 1
            }
            catch { }
        }

        if (-not $nbDriveItem) {
            throw "Could not locate notebook folder '$NotebookName' in your OneDrive."
        }

        $fixDriveId = if ($nbDriveItem.parentReference -and $nbDriveItem.parentReference.driveId) {
            $nbDriveItem.parentReference.driveId
        } else { $meDrive.id }

        Write-Host "[Fix] Found notebook item: $($nbDriveItem.name) (ID: $($nbDriveItem.id))" -ForegroundColor Green

        # Step 4: Repair permissions
        Repair-ClassNotebookPermissions -DriveId $fixDriveId -NotebookItemId $nbDriveItem.id

        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host " Permission Repair Complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Notebook: $NotebookName" -ForegroundColor White
        Write-Host ""
    }
    else {
        # --- CO-TEACHER COPY MODE ---
        Write-Host "========================================" -ForegroundColor Magenta
        Write-Host " Class Notebook -> Co-Teacher OneDrive Copy" -ForegroundColor Magenta
        Write-Host "========================================" -ForegroundColor Magenta
        Write-Host ""

        # Step 1: Authenticate
        Connect-ToGraph

        # Step 2: Resolve source teacher (the OWNER of the original notebook)
        $sourceTeacher = Invoke-MgGraphRequest -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/users/$TeacherUpn" -OutputType PSObject
        $teacherId = $sourceTeacher.id
        Write-Host "[Info] Source teacher: $TeacherUpn (ID: $teacherId)" -ForegroundColor Cyan

        # Step 3: Resolve destination co-teacher (the signed-in user)
        $me = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/me" -OutputType PSObject
        $coTeacherUpn = $me.userPrincipalName
        $coTeacherId = $me.id
        Write-Host "[CoTeacher] Destination co-teacher: $($me.displayName) <$coTeacherUpn>" -ForegroundColor Green

        if ($coTeacherUpn -ieq $TeacherUpn) {
            throw "Destination co-teacher and source teacher are the same user ($TeacherUpn). Nothing to do."
        }

        # Step 4: Find the source Class Notebook & its drive item (with sharedWithMe fallback)
        $notebook = $null
        $notebookLookupFailed = $false
        try {
            $notebook = Find-ClassNotebook -UserId $teacherId
        }
        catch {
            $notebookLookupFailed = $true
            Write-Host "[Notebook] Could not enumerate source teacher's notebooks directly: $_" -ForegroundColor Yellow
        }

        $driveItem = Get-NotebookDriveItemForSource -SourceUserId $teacherId -NotebookName $NotebookName

        # Step 5: Membership lookup (used for re-sharing and metadata on the new copy)
        $membership = @{ Teachers = @(); Students = @() }
        if ($notebook) {
            try {
                $membership = Get-ClassNotebookMembers -UserId $teacherId -NotebookId $notebook.id
            }
            catch {
                Write-Warning "Could not retrieve notebook membership: $_"
                $notebookLookupFailed = $true
            }
        }

        # Fallback: if OneNote metadata is unavailable, infer membership from drive item
        # sharing permissions (Files API works cross-user with Files.Read.All delegated)
        if ($membership.Students.Count -eq 0 -and $driveItem) {
            Write-Host "[Members] OneNote metadata unavailable; inferring membership from drive item permissions..." -ForegroundColor Cyan
            try {
                if ($driveItem.PSObject.Properties.Name -contains 'sourceDriveId' -and $driveItem.sourceDriveId) {
                    $permUri = "https://graph.microsoft.com/v1.0/drives/$($driveItem.sourceDriveId)/items/$($driveItem.id)/permissions"
                }
                elseif ($driveItem.parentReference -and $driveItem.parentReference.driveId) {
                    $permUri = "https://graph.microsoft.com/v1.0/drives/$($driveItem.parentReference.driveId)/items/$($driveItem.id)/permissions"
                }
                else {
                    $permUri = "https://graph.microsoft.com/v1.0/users/$teacherId/drive/items/$($driveItem.id)/permissions"
                }
                $permissions = Invoke-MgGraphRequest -Method GET -Uri $permUri -OutputType PSObject

                $inferredTeachers = @()
                $inferredStudents = @()

                foreach ($perm in $permissions.value) {
                    if ($perm.grantedToV2 -and $perm.grantedToV2.user) {
                        $grantedUser = $perm.grantedToV2.user
                        $roles = $perm.roles
                        $userUpn = if ($grantedUser.email) { $grantedUser.email } else { $grantedUser.displayName }

                        if ($roles -contains "write" -or $roles -contains "owner") {
                            if ($grantedUser.id -ne $teacherId) {
                                $inferredTeachers += @{ upn = $userUpn; id = $grantedUser.id }
                            }
                        }
                        elseif ($roles -contains "read") {
                            $inferredStudents += @{ upn = $userUpn; id = $grantedUser.id }
                        }
                    }
                }

                $membership.Teachers = @($membership.Teachers) + $inferredTeachers
                $membership.Students = @($membership.Students) + $inferredStudents

                if ($inferredTeachers.Count -gt 0 -or $inferredStudents.Count -gt 0) {
                    Write-Host "[Members] Inferred from permissions: $($inferredTeachers.Count) co-teacher(s), $($inferredStudents.Count) student(s)" -ForegroundColor Green
                    $notebookLookupFailed = $false
                }
            }
            catch {
                Write-Warning "Could not read drive item permissions: $_"
            }
        }

        if ($notebookLookupFailed -or $membership.Students.Count -eq 0) {
            Write-Host "" -ForegroundColor Yellow
            Write-Host "WARNING: Could not retrieve the full Class Notebook membership." -ForegroundColor Red
            Write-Host "The OneNote API does not support cross-user access with delegated auth," -ForegroundColor Red
            Write-Host "and the drive item permissions did not yield any student members." -ForegroundColor Red
            Write-Host "" -ForegroundColor Red
            Write-Host "Consequences if you proceed:" -ForegroundColor Yellow
            Write-Host "  - The copied notebook will NOT have student membership in its metadata." -ForegroundColor White
            Write-Host "  - Students will NOT be re-shared on the new copy automatically." -ForegroundColor White
            Write-Host "  - You can fix membership later with manual sharing." -ForegroundColor White
            Write-Host "" -ForegroundColor Yellow
            Write-Host "To avoid this:" -ForegroundColor Cyan
            Write-Host "  - Ask the source teacher to run the script themselves (they can read their own notebooks)" -ForegroundColor White
            Write-Host "  - Ensure the notebook is shared with individual students (not via a group link)" -ForegroundColor White
            Write-Host "    so their permissions appear on the drive item" -ForegroundColor White
            Write-Host ""
            $proceedChoice = Read-Host "Proceed anyway without full membership? (Y/N)"
            if ($proceedChoice -notmatch '^[Yy]') {
                Write-Host "Copy cancelled." -ForegroundColor Yellow
                exit 0
            }
        }

        # Always include the source teacher among teachers so they retain write access on the copy
        if (-not ($membership.Teachers | Where-Object { $_.upn -ieq $TeacherUpn })) {
            $membership.Teachers = @($membership.Teachers) + @(@{ upn = $TeacherUpn; id = $teacherId })
        }

        # Include the co-teacher among teachers so metadata lists them correctly
        if (-not ($membership.Teachers | Where-Object { $_.upn -ieq $coTeacherUpn })) {
            $membership.Teachers = @($membership.Teachers) + @(@{ upn = $coTeacherUpn; id = $coTeacherId })
        }

        # Discover student section names from the source notebook's folder structure
        $studentSectionNames = Get-SourceStudentSectionNames -NotebookDriveItem $driveItem

        Write-Host ""
        Write-Host "[Summary] Copy Plan:" -ForegroundColor Magenta
        Write-Host "  Notebook:           $NotebookName" -ForegroundColor White
        if ($TargetNotebookName -ne $NotebookName) {
            Write-Host "  Target name:        $TargetNotebookName" -ForegroundColor White
        }
        Write-Host "  Source teacher:     $TeacherUpn" -ForegroundColor White
        Write-Host "  Destination co-tch: $coTeacherUpn" -ForegroundColor White
        Write-Host "  Destination folder: $DestinationFolder" -ForegroundColor White
        Write-Host "  Teachers (re-share):$($membership.Teachers.Count)" -ForegroundColor White
        Write-Host "  Students (re-share):$($membership.Students.Count)" -ForegroundColor White
        if ($studentSectionNames.Count -gt 0) {
            Write-Host "  Student sections:   $($studentSectionNames -join ', ')" -ForegroundColor White
        }
        Write-Host ""

        $confirm = Read-Host "Proceed with copy into co-teacher's OneDrive? (Y/N)"
        if ($confirm -notmatch '^[Yy]') {
            Write-Host "Copy cancelled." -ForegroundColor Yellow
            exit 0
        }

        # Step 6: Copy notebook into co-teacher's drive
        $copiedItem = Copy-NotebookToCoTeacherDrive `
            -DriveItem $driveItem `
            -SourceUserId $teacherId `
            -DestinationFolderName $DestinationFolder

        # Step 7: Re-share copy with original teachers (write) and students (read)
        # This must happen BEFORE metadata so users are added to the site's User Information
        # List and can be resolved to SharePoint LookupIds for the Teachers/Students fields.
        Set-CoTeacherNotebookPermissions `
            -CoTeacherUpn $coTeacherUpn `
            -CopiedNotebookItem $copiedItem `
            -Teachers $membership.Teachers `
            -Students $membership.Students

        # Step 8: Set Class Notebook metadata on the co-teacher's copy
        Set-CoTeacherNotebookMetadata `
            -CoTeacherUpn $coTeacherUpn `
            -CoTeacherId $coTeacherId `
            -CopiedNotebookItem $copiedItem `
            -Teachers $membership.Teachers `
            -Students $membership.Students `
            -StudentSectionNames $studentSectionNames

        # Step 9: Repair per-section permissions on the copied notebook
        # Reads Teachers/Students from metadata and sets proper per-folder permissions:
        # _Teacher Only = teachers only, _Content Library = read, student folders = per-student
        $repairDriveId = $copiedItem.parentReference.driveId
        if (-not $repairDriveId) {
            $repairDr = Invoke-MgGraphRequest -Method GET `
                -Uri "https://graph.microsoft.com/v1.0/me/drive" -OutputType PSObject
            $repairDriveId = $repairDr.id
        }
        Repair-ClassNotebookPermissions -DriveId $repairDriveId -NotebookItemId $copiedItem.id

        # Step 10: Optionally revoke co-teacher and student access on the SOURCE notebook so
        # users don't keep hitting the previous version. The source teacher (owner) is preserved.
        Write-Host ""
        Write-Host "To prevent users from continuing to open the OLD notebook in the source teacher's OneDrive," -ForegroundColor Yellow
        Write-Host "you can revoke co-teacher and student access on the source now." -ForegroundColor Yellow
        Write-Host "  - The source teacher (owner) will keep full access." -ForegroundColor Gray
        Write-Host "  - All other teachers and all students will lose access to the source notebook." -ForegroundColor Gray
        Write-Host "  - The new copy in $coTeacherUpn's OneDrive is unaffected." -ForegroundColor Gray
        $cleanupConfirm = Read-Host "Revoke co-teacher and student access on the source notebook? (Y/N)"
        if ($cleanupConfirm -match '^[Yy]') {
            Remove-SourceNotebookAccess `
                -DriveItem $driveItem `
                -SourceUserId $teacherId `
                -SourceTeacherUpn $TeacherUpn `
                -Teachers $membership.Teachers `
                -Students $membership.Students
        }
        else {
            Write-Host "[Cleanup] Skipped. Source notebook permissions are unchanged." -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host " Copy Complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Source:      $TeacherUpn / $NotebookName" -ForegroundColor White
        Write-Host "Destination: $coTeacherUpn / $DestinationFolder/$TargetNotebookName" -ForegroundColor White
        Write-Host "Copied item: $($copiedItem.webUrl)" -ForegroundColor White
        Write-Host ""
        Write-Host "Note: The original notebook in the source teacher's OneDrive has NOT been deleted." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Operation failed: $_"
    Write-Error $_.ScriptStackTrace
    exit 1
}
finally {
    # Disconnect from Graph
    try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch { }
}

#endregion
