[CmdletBinding()]
param(
    # Emit only service plans that are enabled for the user. Default is every plan in every
    # assigned SKU, so disabled plans stay visible as context.
    [switch] $EnabledServicesOnly
)
# No verbose-console switch, by design. Commentary (endpoints, row counts, per-step messages) goes to
# Logs.log under Stage 'Detail' and never to the screen. Removed rather than defaulted off so a stray
# argument in a shortcut or scheduled task cannot turn the console into a wall of text.

#region 0. ADMINISTRATOR ELEVATION
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if (-not $PSCommandPath) {
        # Literal three-space indent instead of $script:PhaseIndent: region 0 runs before region 2
        # defines it, so reading it here would throw under StrictMode.
        Write-Host '   [ERROR] Administrator privileges are required. This session' -ForegroundColor Red
        Write-Host '           cannot request elevation because it was not launched' -ForegroundColor Red
        Write-Host '           from a script file.' -ForegroundColor Red
        exit 1
    }
    try {
        Write-Host '   [INFO] Not running as administrator. Requesting elevation...'
        # No -NoExit. Wait-ForOperator holds the elevated window open from the script's own finally, so
        # it covers the failure path too and the window closes on a keypress rather than leaving a live
        # prompt that nothing ever closes.
        $relaunchArgs = [System.Collections.Generic.List[string]]::new()
        foreach ($fixed in '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"") {
            $relaunchArgs.Add($fixed)
        }

        # Forward the caller's arguments; -File alone dropped them, so -EnabledServicesOnly produced a
        # full report with nothing on screen to say the switch had been ignored. $PSBoundParameters holds
        # only what was actually supplied, so a switch left off stays off instead of arriving as :$false.
        foreach ($name in $PSBoundParameters.Keys) {
            $value = $PSBoundParameters[$name]
            if ($value -is [System.Management.Automation.SwitchParameter]) {
                # -Switch:$false is a deliberate instruction and has to survive the hop; a bare
                # -Switch covers the ordinary true case.
                if ($value.IsPresent) { $relaunchArgs.Add("-$name") }
                else                  { $relaunchArgs.Add("-${name}:`$false") }
            }
            elseif ($value -is [bool]) {
                $relaunchArgs.Add("-${name}:`$$value")
            }
            else {
                # Braces around the name stop PowerShell reading "$name:" as a scope qualifier, and
                # the value is quoted so one containing a space does not arrive as two arguments.
                $relaunchArgs.Add("-$name")
                $relaunchArgs.Add("`"$value`"")
            }
        }
        Start-Process -FilePath 'powershell.exe' -ArgumentList $relaunchArgs.ToArray() -Verb RunAs -ErrorAction Stop
    }
    catch {
        # Message on its own line: Windows' elevation errors are long enough to wrap mid-sentence when
        # run onto the end of the label.
        Write-Host '   [ERROR] Administrator elevation was canceled or failed:' -ForegroundColor Red
        Write-Host "           $($_.Exception.Message)" -ForegroundColor Red
        # Must be non-zero. The launcher only pauses on a non-zero code, so a bare exit closed the
        # window with the message above unread when the UAC prompt was declined.
        exit 1
    }
    exit
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Silences third-party progress bars for the whole run. Windows PowerShell pins Write-Progress as a
# band across the top of the console, and the Graph SDK raises one record per request without ever
# completing it, so the band grows and covers the banner and phase lines. Set once here rather than per
# call site, so a Graph cmdlet added later cannot reintroduce it. Get-AllUserLicenseAssignment and
# New-ServiceUsageRows opt back in explicitly; both complete their bars, so the band clears.
$ProgressPreference = 'SilentlyContinue'
# The script checks execution policy but never changes enterprise PowerShell policy.

#region 1. CONFIGURATION
$ScriptRoot = if ($PSScriptRoot) {
        $PSScriptRoot
    } else {
        (Get-Location).Path
    }
$ResourcesPath = Join-Path $ScriptRoot 'Resources'
# Read-only companion inputs that ship with the script. Kept separate from Resources, which the
# script creates and overwrites on every run.
$ReferencePath = Join-Path $ScriptRoot 'Reference'

# Taken once for the whole run so a run crossing a minute boundary still writes one workbook.
# ':' and '/' are illegal in filenames, so the colon is dropped and the date's slashes become dashes:
# AdoptionReport_0930PM_09-16-2026.xlsx. 'hh' is 12-hour and pairs with 'tt'; changing it to 'HH'
# would make the AM/PM suffix contradict the hour. Two runs inside the same minute reuse one
# filename, which -ClearSheet handles by rewriting each sheet in place.
$RunStamp = Get-Date -Format 'hhmmtt_MM-dd-yyyy'

$Config = [ordered]@{
    MaxAttempts               = 3
    RetryBaseSeconds          = 5
    RetryMaxSeconds           = 60
    GraphUri                  = 'https://graph.microsoft.com/v1.0'
    OutputPath                = $ResourcesPath
    LogsPath                  = Join-Path $ResourcesPath 'Logs.log'
    ErrorsPath                = Join-Path $ResourcesPath 'Errors.log'
    # Timestamped, so each run leaves a new workbook and the history accumulates in the script folder.
    # Unlike the CSVs below, which are rewritten every run as working data behind one report.
    ReportXlsxPath            = Join-Path $ScriptRoot "AdoptionReport_$RunStamp.xlsx"
    SkuCsvPath                = Join-Path $ResourcesPath 'SubscribedSkus.csv'
    ServicePlanCatalogCsvPath = Join-Path $ResourcesPath 'ServicePlanCatalog.csv'
    # Optional, ships in Reference\. Maps raw Graph plan names to friendly names for display only and
    # never gates data; if the file is missing, every plan falls back to its raw tenant name.
    FriendlyNameCsvPath       = Join-Path $ReferencePath 'ServicePlanFriendlyNames.csv'
    UserLicenseCsvPath        = Join-Path $ResourcesPath 'UserLicenseAssignments.csv'
    ServiceUsageCsvPath       = Join-Path $ResourcesPath 'AllServiceUsage.csv'
    ServiceSummaryCsvPath     = Join-Path $ResourcesPath 'ServiceUsageSummary.csv'
    ActiveUserReportCsvPath   = Join-Path $ResourcesPath 'Office365ActiveUserDetail.csv'
    # The five per-workload usage reports merged into the 'Other Service Usage status' sheet. Each is downloaded
    # to its own CSV so the raw Microsoft output stays auditable next to the merged sheet -- if a
    # merged value looks wrong, the source row is right there to check it against.
    M365AppUserCsvPath        = Join-Path $ResourcesPath 'M365AppUserDetail.csv'
    TeamsUserActivityCsvPath  = Join-Path $ResourcesPath 'TeamsUserActivityUserDetail.csv'
    MailboxUsageCsvPath       = Join-Path $ResourcesPath 'MailboxUsageDetail.csv'
    OneDriveUsageCsvPath      = Join-Path $ResourcesPath 'OneDriveUsageAccountDetail.csv'
    CopilotUsageCsvPath       = Join-Path $ResourcesPath 'M365CopilotUsageUserDetail.csv'
    # The Copilot usage report has not reached v1.0 in every tenant -- where it has not, v1.0
    # answers 404 and only the beta surface serves it. Get-UsageReportCsv tries v1.0 first and falls
    # back to this, so the report is not lost on tenants that only have the beta surface, and no
    # other call in the script is moved off v1.0.
    GraphBetaUri              = 'https://graph.microsoft.com/beta'
    RequiredModules           = @('Microsoft.Graph.Authentication', 'ImportExcel')
    # User.Read.All is needed for per-user assignedLicenses/assignedPlans; Organization.Read.All
    # for /subscribedSkus. Directory.Read.All would cover both but is broader than necessary.
    RequiredScopes            = @('User.Read.All', 'Organization.Read.All')
    # Requested at sign-in so a willing admin can consent, but never hard-validated by
    # Test-RequiredScopes -- the M365 Activity and Other Service Usage status sheets are independent, historically
    # unreliable (report concealment, sparse instrumentation), and must never fail the whole
    # assessment just because this one optional scope was declined or a report call hiccups.
    # Group.Read.All is here, not in RequiredScopes, for the same reason: it is only ever used to turn
    # a group object ID into a display name for AssignedByGroupNames. Reading every group in the
    # directory is a wider permission than the rest of this script needs, an admin is entitled to
    # decline it, and a refusal must not fail a run that is otherwise complete -- the column falls
    # back to raw object IDs. AssignmentType needs no extra scope at all; it comes from
    # licenseAssignmentStates, which User.Read.All already covers.
    OptionalScopes            = @('Reports.Read.All', 'Group.Read.All')
    ReportPeriod              = 'D90'
    MaxErrorTextLength        = 4000
    UserPageSize              = 999
    # Excel hard limit is 1,048,576 rows including the header. Large tenants can exceed that once
    # every user is multiplied by every service plan, so the sheet is skipped rather than corrupted.
    MaxExcelRows              = 1000000
}

$script:RunId = [guid]::NewGuid().Guid
$script:Attempt = 0
$script:Started = Get-Date
# Captured here, before anything writes a sheet, because the workbook path is timestamped: normally
# no file exists yet, and the only way one does is a second run starting inside the same minute. The
# stale-worksheet cleanup is gated on this so it does not open the finished workbook on every run
# hunting for legacy sheet names that a file this run just created cannot possibly contain.
$script:WorkbookPreExisted = Test-Path -LiteralPath $Config.ReportXlsxPath
$script:LoggingAvailable = $false
$script:PreflightNetworkOK = $false
$script:PreflightWriteOK = $false
$script:GraphContext = $null
$script:ServicePlanCatalog = @()
$script:CatalogBySkuId = @{}
$script:SkuNameById = @{}
$script:UsersWithoutLicense = 0
$script:UnknownSkuRefs = 0
# Distinct skuIds already logged as unknown, used as a set, so the log line does not repeat for every
# user holding the same retired SKU. UnknownSkuRefs above still counts every reference.
$script:UnknownSkuIdsSeen = @{}
$script:FriendlyNameByPlan = @{}
# Group object ID -> display name, for AssignedByGroupNames. Cached because the resolver is called from
# inside the correlation loop, which must stay free of per-user API calls. Unresolvable groups are
# cached under their raw ID so those are not retried per user either.
$script:LicensingGroupNames = @{}
# Set on the first 401/403 from /groups. A declined consent will not change mid-run, so there is no
# point asking again for every remaining group.
$script:GroupLookupBlocked = $false
# Columns Get-ReportFieldValue could not find in the source report, counted by "report/field".
# Microsoft renames these CSV headers between report versions, and an empty column reads exactly like
# "nobody used this", so misses are surfaced as a warning rather than swallowed.
$script:ReportFieldMisses = @{}
# Reset at the start of every New-UsageDetailRows call; declared here so Set-StrictMode never sees
# an unset variable if the merge is reached before anything has incremented them.
$script:UsageMaskedSeen = 0
$script:UsageSyntheticSeq = 0
# Stamped onto every row of the workbook (ScriptVersion, CollectionTimestampUtc) -- bump this
# alongside the filename when the script's behaviour changes meaningfully.
$script:ScriptVersion = '3.0'

# Not reset per attempt, unlike the counters above: that is what lets a retry resume /users paging
# instead of starting over. Pages are appended as they succeed, so a later attempt only ever adds
# pages it does not already have and cannot double-count anyone.
$script:UserCollectionCheckpoint = [pscustomobject]@{
    Users     = (New-Object System.Collections.Generic.List[object])
    NextLink  = $null
    PageCount = 0
    Complete  = $false
}

# --- console surface state ---------------------------------------------------------------------
# The screen shows one short progress line per phase plus a closing summary. Everything else is detail
# and goes to Logs.log only. No flag controls this; see the note at the param block.
$script:PhaseCount = 5
$script:PhaseIndex = 0
$script:PhaseLabel = ''
# A phase line is written with -NoNewline so its result can be appended on the same line. These two
# track whether that line is still open, and whether something else printed over it in the meantime.
$script:PhaseOpen = $false
$script:PhaseBroken = $false
$script:PhaseLabelWidth = 42
# Indent for the '[n/5]' checkpoint lines, matching the indent the banner and summary use for paths.
# Must be spaces, not a tab: PadRight counts a tab as one character while the console renders it as up
# to eight columns, which would pad the dot leader short and scatter the results column.
$script:PhaseIndent = '   '
# Findings that change how the workbook should be read (concealed identities, unknown SKUs, an empty
# report). Write-only since the 'Worth knowing' block was removed from Write-RunSummary; the notes are
# read from Logs.log now. Kept because 12 call sites still record through it.
$script:UserNotes = New-Object System.Collections.Generic.List[string]
# Filled in by Export-UsageDetailReport so the usage phase can state its own result.
$script:UsageReportsWithRows = 0
$script:UsageReportCount = 0
# The last error text put on screen, so Write-ErrorLog can suppress the top-level catch re-reporting
# a failure the attempt loop has already shown. Reset per attempt -- see Invoke-Assessment.
$script:LastConsoleError = ''

#region 2. LOGGING / TERMINAL HELPERS
# Every call here prints; there is no switch to make a line log-only. Running commentary calls Write-Log
# directly under Stage 'Detail' instead, so the destination is obvious from the verb: Write-Terminal is
# the screen, Write-Log is the file. Two call sites remain, in Write-ErrorLog and the worksheet-order
# confirmation.
function Write-Terminal {
    param(
        [Parameter(Mandatory)] [string] $Message,
        [ValidateSet('Info','Success','Warning','Error')] [string] $Level = 'Info'
    )

    $prefix = switch ($Level) {
        'Success' { '[OK]' }
        'Warning' { '[WARN]' }
        'Error'   { '[ERROR]' }
        default   { '[INFO]' }
    }

    # A phase line is open and was written with -NoNewline, so end it before printing over it.
    # Complete-Phase then restates which phase the result belongs to.
    if ($script:PhaseOpen -and (-not $script:PhaseBroken)) {
        Write-Host ''
        $script:PhaseBroken = $true
    }

    # Colour is metadata only and adds nothing to a redirected capture, so tests matching this text are
    # unaffected. 'Info' stays at the host default; an explicit White would vanish on a light console.
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
    }
    # Indented with the checkpoints so every status line starts in the same column and the progress
    # region reads as one list. Applied here, where the prefix is added, so no call site has to remember.
    if ($color) { Write-Host "$($script:PhaseIndent)$prefix $Message" -ForegroundColor $color }
    else        { Write-Host "$($script:PhaseIndent)$prefix $Message" }
}

function Write-Banner {
    # Same wording and 60-character rule as the launcher's banner, so the two windows in the elevated
    # shape read as one run. ASCII only: box-drawing characters depend on the console codepage.
    $title = 'Service Usage Assessment'
    # Wrapped because $ErrorActionPreference is 'Stop' here, and a host without RawUI (the ISE, some
    # embedded terminals) would let a purely decorative assignment terminate a good run.
    try { $Host.UI.RawUI.WindowTitle = $title } catch { }
    Write-Host ''
    Write-Host '============================================================'
    Write-Host "                  $title"
    Write-Host '============================================================'
    # Label and path on separate lines: the folder is long enough to wrap after a label, and a path
    # broken at an arbitrary column cannot be copied reliably.
    Write-Host 'Output folder:'
    Write-Host "   $($Config.OutputPath)"
    Write-Host ''
}

function Start-Phase {
    param([Parameter(Mandatory)] [string] $Label)

    $script:PhaseIndex++
    $script:PhaseLabel = $Label
    $script:PhaseOpen = $true
    $script:PhaseBroken = $false

    # Indent goes inside the padded width, so the dot leader gives back the three columns it takes and
    # the results column does not move.
    $text = '{0}[{1}/{2}] {3} ' -f $script:PhaseIndent, $script:PhaseIndex, $script:PhaseCount, $Label
    if ($text.Length -lt $script:PhaseLabelWidth) { $text = $text.PadRight($script:PhaseLabelWidth, '.') }
    Write-Host $text -NoNewline
    Write-Log -Message "Phase $($script:PhaseIndex)/$($script:PhaseCount): $Label" -Level 'INFO' -Stage 'Progress'
}

function Complete-Phase {
    param([string] $Result = 'done')

    # Guarded so a phase that threw and was completed by Write-RunSummary cannot print twice.
    if (-not $script:PhaseOpen) { return }

    # Eight spaces, not $script:PhaseLabelWidth: this sits just past the '   [n/5] ' prefix so it reads as
    # a continuation, where padding to the 42-column leader would run off an 80-column window. Composed
    # from $script:PhaseIndent so changing the checkpoint indent moves this with it.
    if ($script:PhaseBroken) { Write-Host ('{0}        -> {1}: {2}' -f $script:PhaseIndent, $script:PhaseLabel, $Result) }
    else { Write-Host " $Result" }

    $script:PhaseOpen = $false
    $script:PhaseBroken = $false
    Write-Log -Message "Phase $($script:PhaseIndex) result: $Result" -Level 'INFO' -Stage 'Progress'
}

function Add-UserNote {
    param([Parameter(Mandatory)] [string] $Note)

    # Never printed to the console. Logs.log is the only place these are read; see $script:UserNotes.
    $script:UserNotes.Add($Note)
    Write-Log -Message "Note for the operator: $Note" -Level 'WARN' -Stage 'Summary'
}

function Write-RunSummary {
    param([switch] $Failed)

    if ($script:PhaseOpen) { Complete-Phase -Result 'did not complete' }

    $elapsed = (Get-Date) - $script:Started
    $took = '{0}m {1}s' -f [int]$elapsed.TotalMinutes, $elapsed.Seconds

    # Framed in the same 60-character rule as the banner, rather than running on from the last phase
    # result. This is the block the closing keypress exists to make readable.
    Write-Host ''
    Write-Host '============================================================'
    if ($Failed) { Write-Host " Stopped after $took without completing." }
    else         { Write-Host " Completed in $took." }
    Write-Host '============================================================'
    Write-Host ''

    # Read from disk rather than from a flag: a run that skips every sheet for the row limit still
    # reports success and writes no workbook. Show-Report decides the same way, so the promise made
    # here and the window that opens cannot disagree.
    $reportReady = (-not $Failed) -and (Test-Path -LiteralPath $Config.ReportXlsxPath)

    # Two endings, one action each. Neither restates a path: on the good path Show-Report opens the
    # workbook, and on the other the operator is attaching files rather than opening them.
    if ($reportReady) {
        Write-Host 'The assessment is complete. Your report will open in Excel automatically.'
        Write-Host ''
        Write-Host 'Thank you. Have a great day.'
    }
    else {
        # Hand-wrapped, like the region 0 blocks: one sentence runs past 80 columns and the console
        # would break it wherever the window happens to end.
        Write-Host 'Please send Logs.log and Errors.log to your support contact. Both files'
        Write-Host 'are in the Resources folder.'
        Write-Host ''
        Write-Host 'Thank you.'
    }
    Write-Host ''
}

function Wait-ForOperator {
    # Holds the window open until the operator acknowledges, replacing the -NoExit region 0 used to pass
    # to the elevated relaunch. Called from the outer finally so it covers success and failure alike, and
    # after Resume-SystemSleep so the machine can sleep while it waits.
    #
    # Both guards are needed. UserInteractive is false for a service or a scheduled task. Redirected
    # input leaves UserInteractive true, so the first test alone lets the run through, and ReadKey then
    # blocks indefinitely rather than throwing into the fallback below, hanging a run that has already
    # printed its summary.
    if (-not [Environment]::UserInteractive -or [Console]::IsInputRedirected) {
        Write-Log 'No interactive console detected. The closing keypress was skipped so the run cannot hang.' 'INFO' 'General'
        return
    }

    try {
        Write-Host ''
        Write-Host 'Press any key to continue . . . ' -NoNewline
        # Flush first, or a key tapped during the run is read as the acknowledgement and closes the
        # window before anyone has looked at it.
        $Host.UI.RawUI.FlushInputBuffer()
        # ReadKey rather than Read-Host so it really is any key and nothing is echoed into the summary.
        #
        # Modifier and lock keys are ignored because a keep-awake utility on this estate toggles Scroll
        # Lock (VK 145) every 15 seconds or so, and a bare ReadKey took that as the operator's answer and
        # dismissed the prompt within seconds of the summary appearing. Characters, Enter, Escape and the
        # function keys all still count.
        $ignoredKeys = @(16, 17, 18, 20, 91, 92, 93, 144, 145, 160, 161, 162, 163, 164, 165)
        do {
            $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
        while ($ignoredKeys -contains $key.VirtualKeyCode)
        Write-Host ''
        Write-Log 'Operator acknowledged the closing prompt.' 'INFO' 'General'
    }
    catch {
        # The ISE and some embedded terminals do not implement RawUI.ReadKey and throw; Read-Host works
        # there at the cost of needing Enter. This does not catch redirected input, which blocks rather
        # than throwing, hence the guard above. Wrapped again so a closing prompt can never fail a
        # completed run.
        try {
            Write-Host ''
            Read-Host 'Press Enter to continue' | Out-Null
        }
        catch {
            Write-Log "Could not hold the window open for a keypress: $($_.Exception.Message)" 'WARN' 'General'
        }
    }
}

function Initialize-Logs {
    try {
        # Logs are created before the deeper preflight checks.
        if (-not (Test-Path -LiteralPath $Config.LogsPath)) {
            New-Item -ItemType File -Path $Config.LogsPath -Force | Out-Null
        }
        if (-not (Test-Path -LiteralPath $Config.ErrorsPath)) {
            New-Item -ItemType File -Path $Config.ErrorsPath -Force | Out-Null
        }
        $script:LoggingAvailable = $true
    }
    catch {
        $script:LoggingAvailable = $false
        # Write-Terminal, not Write-Log: the line above just set $script:LoggingAvailable to $false,
        # which is the flag Write-Log tests, so the message would be dropped. Without a console path, a
        # non-writable output folder produced a run that printed all five phases and then pointed the
        # operator at a Logs.log that was never created. Warning, not Error: the run can still produce a
        # workbook, but every diagnostic for it is lost.
        Write-Terminal "Could not create Logs.log and Errors.log in '$($Config.OutputPath)'. Details: $($_.Exception.Message)" 'Warning'
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory)] [string] $Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS','DEBUG')] [string] $Level = 'INFO',
        [string] $Stage = 'General'
    )

    $line = '{0} | RunId={1} | Attempt={2} | {3} | {4} | {5}' -f `
        (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $script:RunId, $script:Attempt, $Level, $Stage, $Message

    if ($script:LoggingAvailable) {
        try { Add-Content -LiteralPath $Config.LogsPath -Value $line -Encoding UTF8 } catch { }
    }
}

function Write-ErrorLog {
    param(
        [Parameter(Mandatory)] [string] $Message,
        [string] $Stage = 'General',
        [string] $Category = 'Unknown',
        [System.Exception] $Exception
    )

    $detail = $Message
    if ($Exception) {
        $detail = "{0} | ExceptionType={1} | ExceptionMessage={2}" -f $Message, $Exception.GetType().FullName, $Exception.Message
        if ($Exception.InnerException) {
            $detail += " | InnerException=$($Exception.InnerException.Message)"
        }
    }
    if ($detail.Length -gt $Config.MaxErrorTextLength) {
        $detail = $detail.Substring(0, $Config.MaxErrorTextLength) + '...'
    }

    $line = '{0} | RunId={1} | Attempt={2} | Category={3} | Stage={4} | {5}' -f `
        (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $script:RunId, $script:Attempt, $Category, $Stage, $detail

    if ($script:LoggingAvailable) {
        try { Add-Content -LiteralPath $Config.ErrorsPath -Value $line -Encoding UTF8 } catch { }
    }

    # Errors.log above keeps the full detail; what follows only decides what reaches the screen. The
    # '(line N)' the top-level catch appends is stripped from the screen copy, since a script line
    # number is nothing the operator can act on.
    $onScreen = [regex]::Replace($Message, '\s*\(line \d+\)\s*$', '')

    # A failure inside the attempt loop is reported there and again by the top-level catch, which showed
    # the operator the same error twice. Only the immediate repeat is suppressed; the counter resets each
    # attempt, so a second attempt failing the same way still says so.
    if ($onScreen -eq $script:LastConsoleError) { return }
    $script:LastConsoleError = $onScreen

    Write-Terminal "$Stage failed: $onScreen" 'Error'
}

function New-AssessmentException {
    param(
        [Parameter(Mandatory)] [string] $Message,
        [Parameter(Mandatory)] [string] $Category,
        [string] $Stage = 'General',
        [int] $HttpStatus = 0,
        [bool] $Retryable = $false,
        [bool] $HardStop = $false
    )

    $ex = [System.Exception]::new($Message)
    $ex.Data['AssessmentCategory'] = $Category
    $ex.Data['AssessmentStage'] = $Stage
    $ex.Data['HttpStatus'] = $HttpStatus
    $ex.Data['Retryable'] = $Retryable
    $ex.Data['HardStop'] = $HardStop
    return $ex
}

function Get-ExceptionMetadata {
    param([Parameter(Mandatory)] [System.Exception] $Exception)

    if ($Exception.Data.Contains('AssessmentCategory')) {
        return [pscustomobject]@{
            Category   = $Exception.Data['AssessmentCategory']
            Stage      = $Exception.Data['AssessmentStage']
            HttpStatus = [int]$Exception.Data['HttpStatus']
            Retryable  = [bool]$Exception.Data['Retryable']
            HardStop   = [bool]$Exception.Data['HardStop']
        }
    }

    # Unrecognized exceptions (e.g. raw Graph SDK errors) get classified from the exception itself.
    $status = Get-GraphExceptionStatus -Exception $Exception
    # Must stay identical to the same test in Invoke-GraphWithRetry, which carries the reasoning. This
    # one decides whether the attempt loop retries, that one whether the request does; a timeout judged
    # transient in one and permanent in the other gives the worst of both.
    $retryable = $status -in @(408, 429, 500, 502, 503, 504) -or $Exception.Message -match '(timeout|timed out|temporar|network|connection|unable to connect|name could not be resolved|no such host|task was cancel)'

    return [pscustomobject]@{
        Category   = 'Unknown'
        Stage      = 'General'
        HttpStatus = $status
        Retryable  = $retryable
        HardStop   = $false
    }
}

function Test-FileLockError {
    param([Parameter(Mandatory)] [System.Exception] $Exception)
    # Most common failure mode: last run's CSV/XLSX left open in Excel. ImportExcel's Export-Excel
    # swallows the real IOException and throws its own wrapper with no inner exception, so that wrapper
    # text is matched too; for XLSX writes the "being used by another process" message never gets here.
    return $Exception.Message -match '(being used by another process|cannot access the file|sharing violation|Could not open Excel Package)'
}

function Suspend-SystemSleep {
    # A large tenant collection can run for several minutes and should not stop because the device went
    # idle. ES_SYSTEM_REQUIRED under ES_CONTINUOUS is scoped to this process and never touches the saved
    # power plan, so Windows clears it when the process ends however it ends, and there is nothing to
    # restore. ES_DISPLAY_REQUIRED is omitted: only system sleep matters here. A manually closed laptop
    # lid can still sleep the machine regardless of this flag.
    try {
        if (-not ('Win32.PowerState' -as [type])) {
            Add-Type -Namespace Win32 -Name PowerState -MemberDefinition @'
                [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
                public static extern uint SetThreadExecutionState(uint esFlags);
'@ -ErrorAction Stop
        }

        # PowerShell reads a bare 0x80000000 literal as a signed Int32 (-2147483648), which then fails
        # to cast to [uint32]. Casting from the hex string avoids it.
        $esContinuous     = [uint32]'0x80000000'
        $esSystemRequired = [uint32]0x00000001
        $previousState = [Win32.PowerState]::SetThreadExecutionState($esContinuous -bor $esSystemRequired)
        if ($previousState -eq 0) {
            Write-Log 'SetThreadExecutionState returned 0 (failed). Sleep prevention is not active for this run.' 'WARN' 'General'
            return
        }
        Write-Log 'System sleep prevention enabled for the duration of this run.' 'INFO' 'Detail'
        Write-Log 'System sleep prevention enabled for the duration of this run.' 'INFO' 'General'
    }
    catch {
        # Non-fatal: worst case the device sleeps mid-run. Not worth failing the assessment over.
        Write-Log "Could not enable system sleep prevention: $($_.Exception.Message)" 'WARN' 'General'
    }
}

function Resume-SystemSleep {
    # Releases the request immediately rather than waiting for process exit. Safe to call even if
    # Suspend-SystemSleep never ran.
    try {
        if ('Win32.PowerState' -as [type]) {
            $esContinuous = [uint32]'0x80000000'
            [Win32.PowerState]::SetThreadExecutionState($esContinuous) | Out-Null
            Write-Log 'System sleep prevention released.' 'INFO' 'General'
        }
    }
    catch { }
}

#region 3. PREFLIGHT
function Test-PowerShellEnvironment {
    Write-Log 'Checking PowerShell environment...' 'INFO' 'Detail'
    Write-Log "PowerShellVersion=$($PSVersionTable.PSVersion); Edition=$($PSVersionTable.PSEdition); OS=$([Environment]::OSVersion.VersionString)" 'INFO' 'Preflight'

    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw (New-AssessmentException -Message 'PowerShell 5.1 or later is required.' -Category 'Environment' -Stage 'PowerShell' -HardStop $false)
    }

    Write-Log "Output folder: $($Config.OutputPath)" 'INFO' 'Detail'
    Write-Log "OutputPath=$($Config.OutputPath)" 'INFO' 'Preflight'
}

function Test-WriteAccess {
    Write-Log 'Checking write access to the output folder...' 'INFO' 'Detail'
    $testFile = Join-Path $Config.OutputPath ('.m365-assessment-write-test-{0}.tmp' -f ([guid]::NewGuid().Guid))
    try {
        New-Item -ItemType File -Path $testFile -Force | Out-Null
        Set-Content -LiteralPath $testFile -Value 'write-test' -Encoding ASCII -Force
        Remove-Item -LiteralPath $testFile -Force -ErrorAction SilentlyContinue
        $script:PreflightWriteOK = $true
        Write-Log 'Write access check passed.' 'SUCCESS' 'Detail'
        Write-Log 'Output folder write-access check passed.' 'SUCCESS' 'Preflight'
    }
    catch {
        $script:PreflightWriteOK = $false
        Write-Log "Write access check failed. The script will continue, but the output and log files may not be created later. Details: $($_.Exception.Message)" 'WARN' 'Detail'
        Write-Log "Output folder write-access check failed: $($_.Exception.Message)" 'WARN' 'Preflight'
    }
}

function Test-NetworkConnectivity {
    Write-Log 'Checking Microsoft Graph network connectivity...' 'INFO' 'Detail'
    try {
        if (Get-Command -Name Resolve-DnsName -ErrorAction SilentlyContinue) {
            $dns = Resolve-DnsName -Name 'graph.microsoft.com' -ErrorAction Stop | Select-Object -First 1
        }
        else {
            $dns = [System.Net.Dns]::GetHostEntry('graph.microsoft.com')
        }

        $client = [System.Net.Sockets.TcpClient]::new()
        try {
            $connection = $client.BeginConnect('graph.microsoft.com', 443, $null, $null)
            $tcp = $connection.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds(10))
            if ($tcp) { $client.EndConnect($connection) }
        }
        finally {
            $client.Dispose()
        }

        if (-not $tcp) {
            throw (New-AssessmentException -Message 'Cannot reach graph.microsoft.com on TCP port 443. Check the network connection or proxy settings and run the script again.' -Category 'Network' -Stage 'Preflight Network' -HardStop $true)
        }
        $script:PreflightNetworkOK = $true
        Write-Log 'Network and Graph reachability check passed.' 'SUCCESS' 'Detail'
        Write-Log "Network connectivity passed. DNS=$($dns.Name)" 'SUCCESS' 'Preflight'
    }
    catch {
        $meta = Get-ExceptionMetadata -Exception $_.Exception
        Write-ErrorLog -Message $_.Exception.Message -Stage 'Preflight Network' -Category 'Network' -Exception $_.Exception
        throw (New-AssessmentException -Message 'Microsoft Graph network connectivity is unavailable. Restore network access and run the script again.'-Category 'Network' -Stage 'Preflight Network' -HttpStatus $meta.HttpStatus -HardStop $true)
    }
}

function Ensure-Module {
    param([Parameter(Mandatory)] [string] $ModuleName)

    Write-Log "Checking module: $ModuleName" 'INFO' 'Detail'

    try {
        $available = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1
        if (-not $available) {
            Write-Log "Module '$ModuleName' is missing. Attempting to install it for the current user..." 'WARN' 'Detail'
            Write-Log "Installing missing module $ModuleName (CurrentUser)." 'INFO' 'Module'
            # Progress opted back in for the download only. This is the one unattended wait in the run,
            # and Ensure-Module reports only through Write-Log, so with progress silenced a first run on
            # a new machine sits on '[1/5] Checking prerequisites .....' looking like a hang.
            # Install-Module completes its progress records, so the band clears rather than stacking the
            # way the Graph SDK's does. Restored by hand on the next line because an assignment anywhere
            # in a function is function-wide, and Import-Module below runs on every run.
            $ProgressPreference = 'Continue'
            Install-Module -Name $ModuleName -Repository PSGallery -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            $ProgressPreference = 'SilentlyContinue'
        }

        Import-Module -Name $ModuleName -Force -ErrorAction Stop
        $loaded = Get-Module -Name $ModuleName
        Write-Log "Module '$ModuleName' is ready (version $($loaded.Version))." 'SUCCESS' 'Detail'
        Write-Log "Module ready: $ModuleName version $($loaded.Version)" 'SUCCESS' 'Module'
        return $true
    }
    catch {
        Write-Log "Module '$ModuleName' could not be prepared. Details: $($_.Exception.Message)" 'WARN' 'Detail'
        Write-Log "Module preparation failed for $ModuleName : $($_.Exception.Message)" 'WARN' 'Module'
        return $false
    }
}

function Test-Configuration {
    Write-Log 'Validating configuration...' 'INFO' 'Detail'
    if ($Config.MaxAttempts -lt 1 -or $Config.MaxAttempts -gt 3) {
        throw (New-AssessmentException -Message 'The MaxAttempts setting must be between 1 and 3.' -Category 'Configuration' -Stage 'Preflight Configuration' -HardStop $false)
    }
    Write-Log 'Configuration validation passed.' 'SUCCESS' 'Preflight'
}

function Import-ServicePlanFriendlyNames {
    # Optional and non-fatal: a missing or corrupt reference file only means raw tenant names are
    # displayed. It never affects which plans are collected.
    if (-not (Test-Path -LiteralPath $Config.FriendlyNameCsvPath)) {
        Write-Log "Friendly name reference file not found at '$($Config.FriendlyNameCsvPath)'. ServicePlanName will show raw tenant values." 'INFO' 'Preflight'
        return
    }

    try {
        $rows = @(Import-Csv -LiteralPath $Config.FriendlyNameCsvPath -Encoding UTF8 -ErrorAction Stop)
        $map = New-Object 'System.Collections.Hashtable' ([StringComparer]::OrdinalIgnoreCase)
        foreach ($row in $rows) {
            $key = [string]$row.ServicePlanName
            $value = [string]$row.FriendlyName
            if (-not [string]::IsNullOrWhiteSpace($key) -and -not [string]::IsNullOrWhiteSpace($value) -and -not $map.ContainsKey($key)) {
                $map[$key] = $value
            }
        }
        $script:FriendlyNameByPlan = $map
        Write-Log "Loaded $($map.Count) service plan friendly name(s) from '$($Config.FriendlyNameCsvPath)'." 'SUCCESS' 'Detail'
        Write-Log "Friendly name reference loaded. Entries=$($map.Count)" 'SUCCESS' 'Preflight'
    }
    catch {
        Write-Log "Could not read the service plan friendly name reference file. ServicePlanName will show raw tenant values. Details: $($_.Exception.Message)" 'WARN' 'Detail'
        Write-Log "Friendly name reference load failed: $($_.Exception.Message)" 'WARN' 'Preflight'
    }
}

function Get-FriendlyServicePlanName {
    param([AllowNull()] [string] $ServicePlanName)

    if ([string]::IsNullOrWhiteSpace($ServicePlanName)) { return $ServicePlanName }
    if ($script:FriendlyNameByPlan.ContainsKey($ServicePlanName)) { return $script:FriendlyNameByPlan[$ServicePlanName] }
    return $ServicePlanName
}

function Test-Preflight {
    Write-Log '=============================================' 'INFO' 'Detail'
    Write-Log '1. CONFIGURE + PREFLIGHT' 'INFO' 'Detail'
    Write-Log '=============================================' 'INFO' 'Detail'
    Write-Log "Configure + Preflight started. EnabledServicesOnly=$([bool]$EnabledServicesOnly)" 'INFO' 'Preflight'

    Test-Configuration
    Test-PowerShellEnvironment
    Initialize-Logs
    Test-WriteAccess
    Test-NetworkConnectivity
    Import-ServicePlanFriendlyNames

    foreach ($module in $Config.RequiredModules) {
        if (-not (Ensure-Module -ModuleName $module)) {
            throw (New-AssessmentException -Message "The required module '$module' is not available." -Category 'Dependency' -Stage 'Module Preparation' -HardStop $true)
        }
    }

    Write-Log 'Preflight checks completed.' 'SUCCESS' 'Detail'
    Write-Log 'One-time preflight completed. Proceeding to bounded execution attempts.' 'SUCCESS' 'Preflight'
}

function Test-ValidCsvFile {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string[]] $RequiredHeaders
    )

    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $item = Get-Item -LiteralPath $Path
    if ($item.Length -le 0) { return $false }

    try {
        $rows = @(Import-Csv -LiteralPath $Path -ErrorAction Stop)
        if ($rows.Count -gt 0) {
            $headers = @($rows[0].PSObject.Properties.Name)
        }
        else {
            # A report with no matching users is a valid result.  Import-Csv does
            # not expose headers for a header-only file, so read that line directly.
            $headerLine = Get-Content -LiteralPath $Path -TotalCount 1 -ErrorAction Stop
            $headers = @($headerLine.TrimStart([char]0xFEFF).Split(',') | ForEach-Object { $_.Trim().Trim('"') })
        }
        foreach ($header in $RequiredHeaders) {
            if ($headers -notcontains $header) {
                return $false
            }
        }
        return $true
    }
    catch { return $false }
}

#region 4. AUTHENTICATION / AUTHORIZATION / PRIVACY
function Connect-AssessmentGraph {
    Write-Log 'Signing in to Microsoft Graph...' 'INFO' 'Detail'
    Write-Log 'A Microsoft sign-in window should open. Sign in with the administrator account used for the assessment.' 'INFO' 'Detail'

    try {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    } catch { }

    try {
        # Browser/WAM only; no device-code fallback, which is not a realistic ask for these operators.
        # OptionalScopes is requested so a willing admin can consent, but Test-RequiredScopes validates
        # only RequiredScopes, so declining the optional one does not block the run.
        Connect-MgGraph -Scopes (@($Config.RequiredScopes) + @($Config.OptionalScopes)) -ContextScope Process -NoWelcome -ErrorAction Stop
        Write-Log 'Interactive browser authentication succeeded.' 'SUCCESS' 'Detail'
        Write-Log 'Connect-MgGraph browser authentication succeeded.' 'SUCCESS' 'Authentication'
    }
    catch {
        # Logged verbatim: a closed window, a blocked pop-up and a broker failure all arrive here, and
        # this line is the only record of which one it was. The throw below is Retryable, so a sign-in
        # the operator closed by mistake reopens on the next attempt.
        Write-Log "Browser authentication failed: $($_.Exception.Message)" 'WARN' 'Authentication'
        throw (New-AssessmentException -Message 'The Microsoft sign-in window did not complete. Make sure the sign-in pop-up window is not blocked, then try again.'-Category 'Authentication' -Stage 'Authentication' -Retryable $true)
    }

    $context = Get-MgContext
    if (-not $context -or [string]::IsNullOrWhiteSpace($context.Account) -or [string]::IsNullOrWhiteSpace($context.TenantId)) {
        throw (New-AssessmentException -Message 'The Graph session does not have a valid account and tenant context.'-Category 'Authentication' -Stage 'Authentication' -Retryable $true)
    }

    $script:GraphContext = $context
    Write-Log "Signed in as $($context.Account)" 'INFO' 'Detail'
    Write-Log "Tenant ID: $($context.TenantId)" 'INFO' 'Detail'
    Write-Log "Authenticated Graph session established; TenantId=$($context.TenantId); ScopeCount=$(@($context.Scopes).Count)" 'SUCCESS' 'Authentication'
}

function Test-RequiredScopes {
    Write-Log 'Validating requested Graph permissions...' 'INFO' 'Detail'

    $context = Get-MgContext
    $grantedScopes = @($context.Scopes)

    $missing = @($Config.RequiredScopes | Where-Object { $_ -notin $grantedScopes })
    if ($missing.Count -gt 0) {
        # Directory.Read.All is a superset of User.Read.All and Organization.Read.All, so a tenant
        # that consented to it instead should not be failed here.
        if ($grantedScopes -contains 'Directory.Read.All') {
            $missing = @($missing | Where-Object { $_ -notin @('User.Read.All', 'Organization.Read.All') })
        }
    }
    if ($missing.Count -gt 0) {
        $message = "The Graph session is missing one or more required delegated permissions: $($missing -join ', '). Admin consent or permission approval may be required."
        throw (New-AssessmentException -Message $message -Category 'Authorization' -Stage 'Graph Scope Validation' -HardStop $true)
    }

    Write-Log 'Required delegated Graph scopes are present.' 'SUCCESS' 'Detail'
    Write-Log "Required scopes present: $($Config.RequiredScopes -join ', ')" 'SUCCESS' 'Authorization'
}

function Test-AuthorizationReadiness {
    Write-Log 'Validating tenant license and directory authorization (non-mutating)...' 'INFO' 'Detail'

    try {
        $skuUri = "$($Config.GraphUri)/subscribedSkus?`$select=skuId,skuPartNumber,consumedUnits,prepaidUnits,capabilityStatus"
        $null = Invoke-MgGraphRequest -Uri $skuUri -Method GET -OutputType PSObject -ErrorAction Stop
        Write-Log 'Tenant license authorization test passed.' 'SUCCESS' 'Detail'
        Write-Log 'Tenant license authorization test passed.' 'SUCCESS' 'Authorization'
    }
    catch {
        $meta = Get-ExceptionMetadata -Exception $_.Exception
        if ([int]$meta.HttpStatus -in @(401,403)) {
            throw (New-AssessmentException -Message 'The signed-in administrator cannot access the tenant license inventory. Verify Organization.Read.All consent and a supported Entra role such as Global Reader or Directory Readers.'-Category 'Authorization' -Stage 'Tenant SKU Authorization' -HttpStatus ([int]$meta.HttpStatus) -HardStop $true)
        }
        throw (New-AssessmentException -Message $_.Exception.Message -Category 'Graph/API' -Stage 'Tenant SKU Authorization' -HttpStatus ([int]$meta.HttpStatus) -Retryable $true)
    }

    # Proven up front rather than failing part-way through paging thousands of users.
    try {
        $userUri = "$($Config.GraphUri)/users?`$select=id,assignedLicenses&`$top=1"
        $null = Invoke-MgGraphRequest -Uri $userUri -Method GET -OutputType PSObject -ErrorAction Stop
        Write-Log 'Per-user license read authorization test passed.' 'SUCCESS' 'Detail'
        Write-Log 'Per-user license read authorization test passed.' 'SUCCESS' 'Authorization'
    }
    catch {
        $meta = Get-ExceptionMetadata -Exception $_.Exception
        if ([int]$meta.HttpStatus -in @(401,403)) {
            throw (New-AssessmentException -Message 'The signed-in administrator cannot read user license assignments. Verify User.Read.All (or Directory.Read.All) consent and a supported Entra role such as Global Reader.' -Category 'Authorization' -Stage 'User Read Authorization' -HttpStatus ([int]$meta.HttpStatus) -HardStop $true)
        }
        throw (New-AssessmentException -Message $_.Exception.Message -Category 'Graph/API' -Stage 'User Read Authorization' -HttpStatus ([int]$meta.HttpStatus) -Retryable $true)
    }
}

#region 5. GRAPH DATA COLLECTION
function Get-GraphExceptionStatus {
    param([Parameter(Mandatory)] [System.Exception] $Exception)
    $status = 0
    try { if ($Exception.ResponseStatusCode) { $status = [int]$Exception.ResponseStatusCode } } catch { }
    try { if ($status -eq 0 -and $Exception.Response.StatusCode) { $status = [int]$Exception.Response.StatusCode } } catch { }
    if ($status -eq 0) {
        # Last resort, when both structured sources return nothing. Anchored on the shapes an HTTP
        # status actually arrives in, not a bare three-digit number: the old '\b(401|403|...)\b' matched
        # prose, and Graph's report endpoints emit prose with numbers in it, so '500 users were skipped'
        # was read as HTTP 500 and retried as transient until the attempts ran out.
        #
        # Kept to the same nine codes. Widening to any \d{3} would start returning codes like 404 that
        # callers have never had to handle.
        $m = $Exception.Message
        $patterns = @(
            'status code\D{0,30}(\d{3})',        # Response status code does not indicate success: 429 (...)
            'returned an error:\s*\((\d{3})\)',  # The remote server returned an error: (401) Unauthorized.
            '\bHTTP\b\S*\s+(\d{3})\b'            # HTTP 503 -- also HTTP/1.1 429 Too Many Requests
        )
        foreach ($p in $patterns) {
            if ($m -match $p -and [int]$Matches[1] -in @(401, 403, 408, 409, 429, 500, 502, 503, 504)) {
                $status = [int]$Matches[1]
                break
            }
        }
    }
    return $status
}

function Get-RetryAfterSeconds {
    param([Parameter(Mandatory)] [System.Exception] $Exception)
    $retryAfter = 0
    try {
        if ($Exception.Response.Headers['Retry-After']) {
            [int]::TryParse([string]$Exception.Response.Headers['Retry-After'], [ref]$retryAfter) | Out-Null
        }
    } catch { }
    return $retryAfter
}

function Invoke-GraphWithRetry {
    param(
        [Parameter(Mandatory)] [string] $Uri,
        [Parameter(Mandatory)] [ValidateSet('GET','POST','PATCH','DELETE')] [string] $Method,
        [string] $OutputFilePath,
        [int] $MaxTransientRetries = 3,
        [string] $Stage = 'Graph API',
        [switch] $ReturnPsObject
    )

    # Silenced again locally, not just globally. $ProgressPreference is dynamically scoped, and the two
    # functions that own a progress bar set it to 'Continue' and then call this, so without this line
    # Invoke-MgGraphRequest inherits 'Continue' during the two phases that make the most Graph calls.
    # Assigning it here is function-local, so PowerShell restores the caller's value on return.
    $ProgressPreference = 'SilentlyContinue'

    # MaxTransientRetries means retries after the initial request, not total attempts.
    for ($localAttempt = 0; $localAttempt -le $MaxTransientRetries; $localAttempt++) {
        try {
            $params = @{ Uri = $Uri; Method = $Method; ErrorAction = 'Stop' }
            if ($OutputFilePath) { $params['OutputFilePath'] = $OutputFilePath }
            if ($ReturnPsObject) { $params['OutputType'] = 'PSObject' }

            return Invoke-MgGraphRequest @params
        }
        catch {
            $status = Get-GraphExceptionStatus -Exception $_.Exception
            $retryAfter = Get-RetryAfterSeconds -Exception $_.Exception
            # A timeout or DNS failure has no HTTP response, so $status is 0 and this text match is the
            # only signal that the call is worth retrying. .NET says 'timed out', 'Unable to connect' and
            # 'name could not be resolved', never 'timeout', 'connection' or 'name resolution', so the
            # original list abandoned five of the ten commonest transient texts after one request.
            #
            # Each addition is narrower than the failure it covers, since too broad a match retries a
            # permanent error four times:
            #   'name could not be resolved', not 'could not be resolved': Graph answers 404 with
            #      'Resource could not be resolved', which must stay non-retryable.
            #   'task was cancel', not 'was cancel': keeps Ctrl+C and 'The operation was canceled' out.
            #   'unable to connect': 'connection' never matched 'connect to'.
            $transient = $status -in @(408, 429, 500, 502, 503, 504) -or $_.Exception.Message -match '(timeout|timed out|temporar|network|connection|unable to connect|name could not be resolved|no such host|task was cancel)'

            if (-not $transient -or $localAttempt -ge $MaxTransientRetries) {
                throw
            }

            $delay = if ($retryAfter -gt 0) {
                [math]::Min($retryAfter, $Config.RetryMaxSeconds)
            } else {
                [math]::Min([math]::Pow(2, $localAttempt) * $Config.RetryBaseSeconds, $Config.RetryMaxSeconds)
            }

            # Small jitter avoids synchronized retries.
            $jitter = Get-Random -Minimum 0 -Maximum 3
            $sleepSeconds = $delay + $jitter
            Write-Log "$Stage returned a transient error (HTTP $status). Retrying in $sleepSeconds second(s)..." 'WARN' 'Detail'
            Write-Log "Transient Graph error HTTP=$status; Retry-After=$retryAfter; local retry=$($localAttempt + 1)/$MaxTransientRetries; sleep=$sleepSeconds" 'WARN' $Stage
            Start-Sleep -Seconds $sleepSeconds
        }
    }
}

function Get-SubscribedSkusData {
    param([Parameter(Mandatory)] [string] $Path)

    Write-Log 'Collecting tenant license inventory (/subscribedSkus)...' 'INFO' 'Detail'
    try {
        $uri = "$($Config.GraphUri)/subscribedSkus?`$select=skuId,skuPartNumber,consumedUnits,prepaidUnits,capabilityStatus,servicePlans"
        $response = Invoke-GraphWithRetry -Uri $uri -Method GET -ReturnPsObject -Stage 'Tenant SKU Collection'
        if (-not $response.value) {
            throw (New-AssessmentException -Message 'The /subscribedSkus response returned no SKU records.' -Category 'Data Validation' -Stage 'Tenant SKU Collection' -Retryable $true)
        }

        $rows = foreach ($sku in @($response.value)) {
            $enabled = $null
            $suspended = $null
            $warning = $null
            try { $enabled = [int]$sku.prepaidUnits.enabled } catch { }
            try { $suspended = [int]$sku.prepaidUnits.suspended } catch { }
            try { $warning = [int]$sku.prepaidUnits.warning } catch { }
            $consumed = $null
            try { $consumed = [int]$sku.consumedUnits } catch { }
            $available = $null
            if ($null -ne $enabled -and $null -ne $consumed) { $available = $enabled - $consumed }

            [pscustomobject]@{
                SkuId             = $sku.skuId
                SkuPartNumber     = $sku.skuPartNumber
                CapabilityStatus  = $sku.capabilityStatus
                PurchasedEnabled  = $enabled
                SuspendedUnits    = $suspended
                WarningUnits      = $warning
                ConsumedUnits     = $consumed
                AvailableUnits    = $available
                ServicePlanCount  = @($sku.servicePlans).Count
            }
        }

        $rows | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding UTF8
        $required = @('SkuId','SkuPartNumber','ConsumedUnits')
        if (-not (Test-ValidCsvFile -Path $Path -RequiredHeaders $required)) {
            throw (New-AssessmentException -Message 'The generated SubscribedSkus.csv failed validation.' -Category 'Data Validation' -Stage 'Tenant SKU Validation' -Retryable $true)
        }
        Write-Log "Tenant license inventory collected: $(@($rows).Count) SKU(s)." 'SUCCESS' 'Detail'
        Write-Log "Tenant SKU collection completed. Rows=$(@($rows).Count)" 'SUCCESS' 'Collection'

        # Full service-plan catalog plus the skuId-keyed lookups the per-user expansion needs.
        $catalogRows = New-Object System.Collections.Generic.List[object]
        $bySkuId = @{}
        $nameById = @{}
        foreach ($sku in @($response.value)) {
            $skuId = [string]$sku.skuId
            $nameById[$skuId] = [string]$sku.skuPartNumber
            $planList = New-Object System.Collections.Generic.List[object]
            foreach ($plan in @($sku.servicePlans)) {
                $entry = [pscustomobject]@{
                    SkuId              = $skuId
                    SkuPartNumber      = $sku.skuPartNumber
                    ServicePlanId      = [string]$plan.servicePlanId
                    # Formatted for display via the optional reference file; falls back to the raw
                    # tenant value on no match.
                    ServicePlanName    = Get-FriendlyServicePlanName -ServicePlanName $plan.servicePlanName
                    ProvisioningStatus = $plan.provisioningStatus
                    AppliesTo          = $plan.appliesTo
                }
                $catalogRows.Add($entry)
                $planList.Add($entry)
            }
            $bySkuId[$skuId] = $planList.ToArray()
        }

        $script:ServicePlanCatalog = $catalogRows.ToArray()
        $script:CatalogBySkuId = $bySkuId
        $script:SkuNameById = $nameById

        if ($script:ServicePlanCatalog.Count -gt 0) {
            $script:ServicePlanCatalog | Export-Csv -LiteralPath $Config.ServicePlanCatalogCsvPath -NoTypeInformation -Encoding UTF8
            $catalogRequired = @('SkuPartNumber','ServicePlanId','ServicePlanName')
            if (-not (Test-ValidCsvFile -Path $Config.ServicePlanCatalogCsvPath -RequiredHeaders $catalogRequired)) {
                throw (New-AssessmentException -Message 'The generated ServicePlanCatalog.csv failed validation.' -Category 'Data Validation' -Stage 'Service Plan Catalog Validation' -Retryable $true)
            }
            $distinctPlans = @($script:ServicePlanCatalog | ForEach-Object { $_.ServicePlanName } | Sort-Object -Unique).Count
            Write-Log "Service plan catalog collected: $($script:ServicePlanCatalog.Count) service plan row(s); $distinctPlans distinct plan name(s)." 'SUCCESS' 'Detail'
            Write-Log "Service plan catalog export completed. Rows=$($script:ServicePlanCatalog.Count); DistinctPlanNames=$distinctPlans" 'SUCCESS' 'Collection'
        }

        return $rows
    }
    catch {
        if (Test-FileLockError -Exception $_.Exception) {
            throw (New-AssessmentException -Message "Cannot write '$Path'. The file appears to be open in another program (for example Excel). Close the file and run the script again." -Category 'File System' -Stage 'Tenant SKU Collection' -Retryable $false)
        }
        $meta = Get-ExceptionMetadata -Exception $_.Exception
        if ([int]$meta.HttpStatus -eq 401 -or [int]$meta.HttpStatus -eq 403) {
            throw (New-AssessmentException -Message 'The tenant license inventory request was rejected. Verify Organization.Read.All consent and the administrator role.'-Category 'Authorization' -Stage 'Tenant SKU Collection' -HttpStatus ([int]$meta.HttpStatus) -HardStop $true)
        }
        if ($_.Exception.Data.Contains('AssessmentCategory')) { throw }
        throw (New-AssessmentException -Message $_.Exception.Message -Category 'Graph/API' -Stage 'Tenant SKU Collection' -HttpStatus ([int]$meta.HttpStatus) -Retryable $true)
    }
}

function Get-AllUserLicenseAssignment {
    # Owns the 'Reading licenses' bar, so it opts back in to the progress stream silenced globally. Safe
    # here because this bar is completed explicitly below, which clears the band.
    $ProgressPreference = 'Continue'

    $checkpoint = $script:UserCollectionCheckpoint

    # A prior attempt in this run already collected every page, so reuse it rather than re-paging a
    # large tenant because a later stage failed.
    if ($checkpoint.Complete) {
        Write-Log "Reusing $($checkpoint.Users.Count) user(s) already collected earlier in this run." 'INFO' 'Detail'
        Write-Log "User collection reused from checkpoint. Users=$($checkpoint.Users.Count)" 'INFO' 'Collection'
        return $checkpoint.Users.ToArray()
    }

    Write-Log 'Collecting per-user license assignments (/users, paged)...' 'INFO' 'Detail'

    # Appends into the checkpoint's own list, never a fresh local one. That list already holds every page
    # a failed attempt collected, and this only adds pages on top, so a retry cannot double-count.
    $users = $checkpoint.Users
    # licenseAssignmentStates carries how each licence reached the user: assignedByGroup is null for a
    # direct assignment and holds a group object ID for group-based licensing. assignedLicenses says
    # only that the user holds the SKU. Covered by User.Read.All, so no extra consent is needed.
    $select = 'id,userPrincipalName,displayName,accountEnabled,assignedLicenses,assignedPlans,' +
        'mail,userType,createdDateTime,onPremisesSyncEnabled,usageLocation,department,jobTitle,' +
        'licenseAssignmentStates'
    $uri = if ($checkpoint.NextLink) {
            Write-Log "Resuming user collection: $($users.Count) user(s) already collected before the previous failure." 'WARN' 'Detail'
            Write-Log "Resuming user collection from checkpoint. AlreadyCollected=$($users.Count); PageCount=$($checkpoint.PageCount)" 'WARN' 'Collection'
            $checkpoint.NextLink
        } else {
            "$($Config.GraphUri)/users?`$select=$select&`$top=$($Config.UserPageSize)"
        }

    try {
        while ($uri) {
            $response = Invoke-GraphWithRetry -Uri $uri -Method GET -ReturnPsObject -Stage 'User License Collection'
            foreach ($u in @($response.value)) { $users.Add($u) }
            $checkpoint.PageCount++

            # A bar rather than repeated lines: a large tenant is dozens of pages and minutes of runtime,
            # and printed lines would push the phase list off the screen. Pages are logged below anyway.
            Write-Progress -Id 1 -Activity 'Reading licenses' -Status "$($users.Count) users so far" -CurrentOperation "page $($checkpoint.PageCount)"
            if ($checkpoint.PageCount % 10 -eq 0) {
                Write-Log "  ...retrieved $($users.Count) user(s) across $($checkpoint.PageCount) page(s)." 'INFO' 'Detail'
            }
            Write-Log "User page $($checkpoint.PageCount) retrieved; cumulative users=$($users.Count)" 'INFO' 'Collection'

            $uri = $null
            $nextLink = $response.PSObject.Properties['@odata.nextLink']
            if ($nextLink -and -not [string]::IsNullOrWhiteSpace([string]$nextLink.Value)) {
                $uri = [string]$nextLink.Value
            }

            # Advanced only after this page's users are appended, and only to the next unfetched page, so
            # a throw on the next iteration leaves the checkpoint pointing where a retry should resume.
            $checkpoint.NextLink = $uri
        }
    }
    catch {
        $meta = Get-ExceptionMetadata -Exception $_.Exception
        if ([int]$meta.HttpStatus -in @(401,403)) {
            throw (New-AssessmentException -Message 'The request to read user license assignments was rejected. Verify User.Read.All (or Directory.Read.All) consent.'-Category 'Authorization' -Stage 'User License Collection' -HttpStatus ([int]$meta.HttpStatus) -HardStop $true)
        }
        if ($_.Exception.Data.Contains('AssessmentCategory')) { throw }
        throw (New-AssessmentException -Message $_.Exception.Message -Category 'Graph/API' -Stage 'User License Collection' -HttpStatus ([int]$meta.HttpStatus) -Retryable $true)
    }

    if ($users.Count -eq 0) {
        throw (New-AssessmentException -Message 'The /users response returned no users.' -Category 'Data Validation' -Stage 'User License Collection' -Retryable $true)
    }

    $checkpoint.Complete = $true
    # Without this the bar stays on screen over the following output for the rest of the run.
    Write-Progress -Id 1 -Activity 'Reading licenses' -Completed
    Write-Log "Per-user license assignments collected: $($users.Count) user(s) across $($checkpoint.PageCount) page(s)." 'SUCCESS' 'Detail'
    Write-Log "User license collection completed. Users=$($users.Count); Pages=$($checkpoint.PageCount)" 'SUCCESS' 'Collection'
    return $users.ToArray()
}

#region 6. DATA NORMALIZATION / CORRELATION

function Get-LicensingGroupName {
    param([Parameter(Mandatory)] [string] $GroupId)

    # Turns a group object ID from licenseAssignmentStates into the group's display name.
    #
    # Every answer is cached, failures included, because this is reached from the correlation loop:
    # uncached, a tenant licensing everyone through groups costs one Graph call per user per licence.
    # Falls back to the raw object ID rather than a blank or an exception -- a GUID still pastes into
    # the portal. Nothing here can fail the run.
    if ($script:LicensingGroupNames.ContainsKey($GroupId)) { return $script:LicensingGroupNames[$GroupId] }

    if ($script:GroupLookupBlocked) {
        $script:LicensingGroupNames[$GroupId] = $GroupId
        return $GroupId
    }

    # -f rather than interpolation so the literal $select needs no escaping.
    $uri = '{0}/groups/{1}?$select=displayName' -f $Config.GraphUri, $GroupId
    $name = $GroupId

    try {
        $group = Invoke-GraphWithRetry -Uri $uri -Method GET -ReturnPsObject -Stage 'Group Name Lookup'
        $nameProp = if ($group) { $group.PSObject.Properties['displayName'] } else { $null }
        if ($nameProp -and -not [string]::IsNullOrWhiteSpace([string]$nameProp.Value)) {
            $name = [string]$nameProp.Value
        }
    }
    catch {
        $status = Get-GraphExceptionStatus -Exception $_.Exception
        if ($status -in @(401, 403)) {
            # Noted once, not per group: a consent decision has the same answer for every group.
            $script:GroupLookupBlocked = $true
            Add-UserNote 'Group display names could not be read, so AssignedByGroupNames shows group object IDs instead of names. Grant consent for Group.Read.All (or Directory.Read.All) to see the names. AssignmentType is unaffected and remains correct.'
        }
        else {
            # A deleted group still licensing users, or a failure the retry could not clear. Logged
            # rather than noted: it concerns one group, not the report.
            Write-Log "Group name lookup failed for $GroupId (HTTP $status): $($_.Exception.Message). Reporting the object ID instead." 'WARN' 'Correlation'
        }
    }

    $script:LicensingGroupNames[$GroupId] = $name
    return $name
}

function ConvertTo-PackedServiceUsageRow {
    param(
        [Parameter(Mandatory)] [object[]] $Rows,
        [Parameter(Mandatory)] [object] $User,
        # Every row this user has, across all their licences; $Rows is one licence's slice. Used only
        # for the user-level context columns, which must read the same on all of that user's rows.
        [AllowEmptyCollection()] [object[]] $AllUserRows = @()
    )

    # Packs one licence's plan rows for one user into a single workbook row, so a user holding E3 and E5
    # gets two rows sharing a UserPrincipalName. E3 and E5 overlap on around ten service plans, so
    # folding both into one row double-counted the shared plans and could put "TEAMS1;FALSE" (disabled
    # in E3) and "TEAMS1;TRUE" (granted by E5) in the same cell with no way to tell them apart.
    #
    # Each pair becomes "Plan;TRUE" or "Plan;FALSE" in the Services cell, with a ";CapabilityStatus"
    # segment appended only when that status is set and is not "Enabled", so a plan that is nominally
    # enabled but actually Suspended or Deleted still shows up.
    $items = @($Rows | Sort-Object -Property ServicePlanName)
    $userItems = if (@($AllUserRows).Count -gt 0) { @($AllUserRows) } else { $items }

    $packed = ($items | ForEach-Object {
            $enabledText = if ($_.ServiceEnabled) { 'TRUE' } else { 'FALSE' }
            $pair = "$($_.ServicePlanName);$enabledText"
            if ($_.CapabilityStatus -and $_.CapabilityStatus -ne 'Enabled') {
                $pair += ";$($_.CapabilityStatus)"
            }
            $pair
        }) -join ','

    $disabledNames = (($items | Where-Object { -not $_.ServiceEnabled } | ForEach-Object { $_.ServicePlanName } | Sort-Object -Unique) -join ';')

    # The user's main licence: whichever of their SKUs carries the most service plans in the catalog. A
    # base licence always dwarfs an add-on like POWER_BI_PRO on plan count, so this avoids a hardcoded
    # SKU list that would rot on every Microsoft rename. Counts come from the catalog, not $items, so
    # -EnabledServicesOnly does not change the answer. Ties break on SkuPartNumber for repeatability.
    $primarySkuId = $null
    $skuRanking = @($userItems | Group-Object -Property SkuId | ForEach-Object {
            $groupSkuId = [string]$_.Name
            [pscustomobject]@{
                SkuId         = $groupSkuId
                SkuPartNumber = [string]$_.Group[0].SkuPartNumber
                PlanCount     = if ($script:CatalogBySkuId.ContainsKey($groupSkuId)) {
                        @($script:CatalogBySkuId[$groupSkuId]).Count
                    } else { @($_.Group).Count }
            }
        } | Sort-Object -Property @{ Expression = 'PlanCount'; Descending = $true }, @{ Expression = 'SkuPartNumber'; Descending = $false })
    if ($skuRanking.Count -gt 0) { $primarySkuId = $skuRanking[0].SkuId }

    # Same signal as UnknownSkuRefs, per user rather than tenant-wide. Checked against
    # $User.assignedLicenses, not $items: a skuId absent from /subscribedSkus has no catalog entry to
    # expand, so it produces zero rows in $items and checking there would never find it.
    $hasLicenseError = $false
    $assignedLicProp = $User.PSObject.Properties['assignedLicenses']
    if ($assignedLicProp -and $assignedLicProp.Value) {
        foreach ($lic in @($assignedLicProp.Value)) {
            if (-not $script:SkuNameById.ContainsKey([string]$lic.skuId)) { $hasLicenseError = $true; break }
        }
    }

    # How this row's licence reached the user, scoped to this row's SkuId, so a user holding E5 by group
    # and Power BI Pro directly reports each on its own row.
    #
    # This drives whether a reclaim recommendation works: removing a group-assigned licence directly
    # does nothing, because group-based licensing reapplies it at the next reconciliation. The action
    # there is a membership change, or a rule change for a dynamic group.
    #
    # 'Direct + Group' is real, not a hedge: Graph returns two entries for the same skuId when a licence
    # is assigned both ways, and the user keeps it if only one side is removed.
    #
    # 'Unknown' means licenseAssignmentStates held no entry for this SkuId, which should not happen
    # against live Graph. Not reported as 'Direct', since inferring a path from missing data is the
    # guess this column exists to remove.
    $thisSkuId      = [string]$items[0].SkuId
    $statesProp     = $User.PSObject.Properties['licenseAssignmentStates']
    $assignmentType = 'Unknown'
    $groupNames     = ''
    if ($statesProp -and $statesProp.Value) {
        $states = @(@($statesProp.Value) | Where-Object { [string]$_.skuId -eq $thisSkuId })
        if ($states.Count -gt 0) {
            $groupIds = @($states | ForEach-Object {
                    $abg = $_.PSObject.Properties['assignedByGroup']
                    if ($abg -and $abg.Value) { [string]$abg.Value }
                } | Where-Object { $_ } | Sort-Object -Unique)
            $hasDirect = @($states | Where-Object {
                    $abg = $_.PSObject.Properties['assignedByGroup']
                    -not ($abg -and $abg.Value)
                }).Count -gt 0
            $assignmentType = if ($hasDirect -and $groupIds.Count -gt 0) { 'Direct + Group' }
                elseif ($groupIds.Count -gt 0) { 'Group' }
                else { 'Direct' }
            # Semicolon-joined and sorted to match AssignedSkuPartNumbers and DisabledServicePlanNames,
            # so every multi-value cell on this sheet splits the same way downstream.
            if ($groupIds.Count -gt 0) {
                $groupNames = ((@($groupIds | ForEach-Object { Get-LicensingGroupName -GroupId $_ }) | Sort-Object -Unique) -join ';')
            }
        }
    }

    # Read via PSObject.Properties rather than dot-access so a field genuinely absent from the Graph
    # response, rather than merely null, does not trip StrictMode.
    $idProp       = $User.PSObject.Properties['id']
    $mailProp     = $User.PSObject.Properties['mail']
    $userTypeProp = $User.PSObject.Properties['userType']
    $createdProp  = $User.PSObject.Properties['createdDateTime']
    $onPremProp   = $User.PSObject.Properties['onPremisesSyncEnabled']
    $usageLocProp = $User.PSObject.Properties['usageLocation']
    $deptProp     = $User.PSObject.Properties['department']
    $jobTitleProp = $User.PSObject.Properties['jobTitle']

    return [pscustomobject]@{
        UserId                   = if ($idProp) { [string]$idProp.Value } else { $null }
        UserPrincipalName        = $items[0].UserPrincipalName
        DisplayName              = $items[0].DisplayName
        Mail                     = if ($mailProp) { [string]$mailProp.Value } else { $null }
        UserType                 = if ($userTypeProp) { [string]$userTypeProp.Value } else { $null }
        AccountEnabled           = $items[0].AccountEnabled
        CreatedDateTime          = if ($createdProp) { $createdProp.Value } else { $null }
        OnPremisesSyncEnabled    = if ($onPremProp) { $onPremProp.Value } else { $null }
        UsageLocation            = if ($usageLocProp) { [string]$usageLocProp.Value } else { $null }
        Department               = if ($deptProp) { [string]$deptProp.Value } else { $null }
        JobTitle                 = if ($jobTitleProp) { [string]$jobTitleProp.Value } else { $null }
        # User-level context: identical on every row belonging to this user, so a reader can see at a
        # glance that this row is one of several licences the person holds.
        AssignedSkuCount         = @($userItems.SkuPartNumber | Sort-Object -Unique).Count
        AssignedSkuPartNumbers   = (($userItems.SkuPartNumber | Sort-Object -Unique) -join ';')
        PrimarySkuId             = $primarySkuId
        # The one licence THIS row describes. Compare SkuId against PrimarySkuId to pick out just the
        # main-licence row per user. Every count and flag below is scoped to this licence alone.
        SkuPartNumber            = $items[0].SkuPartNumber
        SkuId                    = $items[0].SkuId
        TotalServicePlans    = $items.Count
        EnabledServicePlans  = @($items | Where-Object { $_.ServiceEnabled }).Count
        DisabledServicePlans = @($items | Where-Object { -not $_.ServiceEnabled }).Count
        DisabledServicePlanNames = $disabledNames
        HasLicenseError          = $hasLicenseError
        TenantId                 = $script:GraphContext.TenantId
        CollectionTimestampUtc   = $script:Started.ToUniversalTime()
        ScriptVersion            = $script:ScriptVersion
        HasIssue             = [bool](@($items | Where-Object { $_.CapabilityStatus -and $_.CapabilityStatus -ne 'Enabled' }).Count -gt 0)
        Services             = $packed
        # Appended at the end, not beside SkuPartNumber where they belong logically: inserting mid-object
        # shifts every later column one letter right, and anything addressing this sheet by position
        # would then read the wrong field. New columns go on the end; existing ones never move.
        #
        # Direct | Group | Direct + Group | Unknown. AssignedByGroupNames is blank when the type is
        # Direct, and that empty cell is the answer rather than missing data.
        AssignmentType       = $assignmentType
        AssignedByGroupNames = $groupNames
        # This sheet is one row per user per licence, so any user count on it inflates by how many
        # licences people hold. Filtering to IsPrimarySku=TRUE reduces each user to one row, which is
        # what makes a user-level total correct. Comparing PrimarySkuId against SkuId does the same
        # thing, but that is a GUID comparison a reader has to know to make.
        IsPrimarySku         = [bool]($primarySkuId -and ([string]$items[0].SkuId -eq [string]$primarySkuId))
    }
}

function New-ServiceUsageRows {
    param(
        [Parameter(Mandatory)] [object[]] $Users
    )

    # Owns the 'Matching users to services' bar, completed at the end of the function.
    $ProgressPreference = 'Continue'

    # Streams AllServiceUsage.csv to disk in chunks rather than accumulating every user-service-plan row
    # first. At prod scale (~9.8M rows, ~3KB per PSCustomObject) holding them all would need around 30GB
    # before a byte reached disk. The per-plan summary and packed workbook rows accumulate in the same
    # pass and stay small, being bounded by distinct plan count and user count.
    Write-Log 'Correlating per-user licenses and enabled services...' 'INFO' 'Detail'

    if (Test-Path -LiteralPath $Config.ServiceUsageCsvPath) {
        Remove-Item -LiteralPath $Config.ServiceUsageCsvPath -Force -ErrorAction SilentlyContinue
    }

    $chunkSize = 5000
    $csvBuffer = New-Object System.Collections.Generic.List[object]
    $totalRows = 0
    $totalEnabledRows = 0
    $totalDisabledRows = 0
    $processed = 0

    # Keyed by "SkuPartNumber|ServicePlanName" -> running counts. Bounded by distinct plan count
    # (tens to low hundreds), never by row count.
    $summaryAcc = @{}
    $packedRows = New-Object System.Collections.Generic.List[object]

    foreach ($user in $Users) {
        $processed++
        # A percentage is meaningful here, unlike the paging loop, because the total is known up front.
        # Throttled to every 250 users: per-user updates cost more than the correlation itself.
        if ($processed % 250 -eq 0) {
            $pct = if ($Users.Count -gt 0) { [int](($processed / $Users.Count) * 100) } else { 0 }
            Write-Progress -Id 1 -Activity 'Matching users to services' -Status "$processed of $($Users.Count) users" -PercentComplete $pct
        }
        if ($processed % 5000 -eq 0) {
            Write-Log "  ...correlated $processed user(s); $totalRows service row(s) so far." 'INFO' 'Detail'
        }

        $upn = [string]$user.userPrincipalName

        $assignedLicenses = @()
        $licProp = $user.PSObject.Properties['assignedLicenses']
        if ($licProp -and $licProp.Value) { $assignedLicenses = @($licProp.Value) }

        if ($assignedLicenses.Count -eq 0) {
            $script:UsersWithoutLicense++
            continue
        }

        # assignedPlans carries the tenant-side capabilityStatus per plan; used as a cross-check
        # against the disabledPlans list on the licence itself.
        $planStatus = @{}
        $apProp = $user.PSObject.Properties['assignedPlans']
        if ($apProp -and $apProp.Value) {
            foreach ($ap in @($apProp.Value)) {
                $spId = [string]$ap.servicePlanId
                if ($spId) { $planStatus[$spId] = [string]$ap.capabilityStatus }
            }
        }

        # One user's rows only, bounded by how many plans a single user can hold, so this is cheap.
        # Discarded before the next user.
        $userRows = New-Object System.Collections.Generic.List[object]

        foreach ($lic in $assignedLicenses) {
            $skuId = [string]$lic.skuId
            $skuName = if ($script:SkuNameById.ContainsKey($skuId)) {
                    $script:SkuNameById[$skuId]
                } else {
                    $script:UnknownSkuRefs++
                    # Logged once per distinct skuId, not per user holding it. This sits inside both the
                    # per-user and per-licence loops, so on a tenant with one retired SKU assigned
                    # tenant-wide the unconditional call wrote a line per user: ~20,000 Add-Content
                    # cycles in the hottest loop, each carrying a UPN into a file that gets shared.
                    # Nothing is lost, since the skuId is the only part that varies, UnknownSkuRefs
                    # still counts every reference, and affected rows are marked UnknownSku(<skuId>).
                    if (-not $script:UnknownSkuIdsSeen.ContainsKey($skuId)) {
                        $script:UnknownSkuIdsSeen[$skuId] = $true
                        Write-Log "Assigned skuId '$skuId' is not present in /subscribedSkus (may be a deleted or unpurchased SKU). Users holding it are marked UnknownSku($skuId) in the license rows." 'WARN' 'Correlation'
                    }
                    "UnknownSku($skuId)"
                }

            $disabledPlans = @()
            $dpProp = $lic.PSObject.Properties['disabledPlans']
            if ($dpProp -and $dpProp.Value) {
                $disabledPlans = @(@($dpProp.Value) | ForEach-Object { [string]$_ })
            }

            $plans = @()
            if ($script:CatalogBySkuId.ContainsKey($skuId)) { $plans = @($script:CatalogBySkuId[$skuId]) }
            if ($plans.Count -eq 0) { continue }

            foreach ($plan in $plans) {
                $planId = [string]$plan.ServicePlanId
                # A plan is enabled for the user unless it is explicitly in disabledPlans.
                $serviceEnabled = ($planId -notin $disabledPlans)

                if ($EnabledServicesOnly -and -not $serviceEnabled) { continue }

                $row = [pscustomobject]@{
                    UserPrincipalName = $upn
                    DisplayName       = [string]$user.displayName
                    AccountEnabled    = $user.accountEnabled
                    SkuPartNumber     = $skuName
                    SkuId             = $skuId
                    ServicePlanName   = $plan.ServicePlanName
                    ServicePlanId     = $planId
                    ServiceEnabled    = $serviceEnabled
                    CapabilityStatus  = if ($planStatus.ContainsKey($planId)) { $planStatus[$planId] } else { $null }
                }
                $userRows.Add($row)

                $summaryKey = "$skuName|$($plan.ServicePlanName)"
                if (-not $summaryAcc.ContainsKey($summaryKey)) {
                    $summaryAcc[$summaryKey] = [pscustomobject]@{
                        SkuPartNumber    = $skuName
                        ServicePlanName  = $plan.ServicePlanName
                        TotalAssigned    = 0
                        EnabledForUsers  = 0
                        DisabledForUsers = 0
                        EnabledPercent   = $null
                    }
                }
                $summaryEntry = $summaryAcc[$summaryKey]
                $summaryEntry.TotalAssigned++
                if ($serviceEnabled) { $summaryEntry.EnabledForUsers++; $totalEnabledRows++ }
                else { $summaryEntry.DisabledForUsers++; $totalDisabledRows++ }

                $csvBuffer.Add($row)
                $totalRows++
                if ($csvBuffer.Count -ge $chunkSize) {
                    try {
                        $csvBuffer | Export-Csv -LiteralPath $Config.ServiceUsageCsvPath -NoTypeInformation -Encoding UTF8 -Append -ErrorAction Stop
                    }
                    catch {
                        if (Test-FileLockError -Exception $_.Exception) {
                            throw (New-AssessmentException -Message "Cannot write '$($Config.ServiceUsageCsvPath)'. The file appears to be open in another program (for example Excel). Close the file and run the script again." -Category 'File System' -Stage 'CSV Export' -Retryable $false)
                        }
                        throw (New-AssessmentException -Message "The AllServiceUsage CSV export failed: $($_.Exception.Message)" -Category 'Reporting' -Stage 'CSV Export' -Retryable $false)
                    }
                    $csvBuffer.Clear()
                }
            }
        }

        if ($userRows.Count -gt 0) {
            # Grouped on SkuId rather than SkuPartNumber because the ID is the real licence identity.
            # The full row set is passed through so the user-level context columns read identically on
            # every row. See ConvertTo-PackedServiceUsageRow for why this is per licence, not per user.
            $allUserRows = $userRows.ToArray()
            foreach ($skuGroup in @($allUserRows | Group-Object -Property SkuId)) {
                $packedRows.Add((ConvertTo-PackedServiceUsageRow -Rows @($skuGroup.Group) -User $user -AllUserRows $allUserRows))
            }
        }
    }

    if ($csvBuffer.Count -gt 0) {
        try {
            $csvBuffer | Export-Csv -LiteralPath $Config.ServiceUsageCsvPath -NoTypeInformation -Encoding UTF8 -Append -ErrorAction Stop
        }
        catch {
            if (Test-FileLockError -Exception $_.Exception) {
                throw (New-AssessmentException -Message "Cannot write '$($Config.ServiceUsageCsvPath)'. The file appears to be open in another program (for example Excel). Close the file and run the script again." -Category 'File System' -Stage 'CSV Export' -Retryable $false)
            }
            throw (New-AssessmentException -Message "The AllServiceUsage CSV export failed: $($_.Exception.Message)" -Category 'Reporting' -Stage 'CSV Export' -Retryable $false)
        }
        $csvBuffer.Clear()
    }

    # Matches the Write-Progress in the correlation loop above; without it the bar persists on screen.
    Write-Progress -Id 1 -Activity 'Matching users to services' -Completed

    if ($totalRows -gt 0) {
        Write-Log "CSV output written: $($Config.ServiceUsageCsvPath)" 'SUCCESS' 'Detail'
    }

    $summary = @($summaryAcc.Values | ForEach-Object {
            $_.EnabledPercent = if ($_.TotalAssigned -gt 0) {
                    [math]::Round(($_.EnabledForUsers / $_.TotalAssigned) * 100, 1)
                } else { $null }
            $_
        } | Sort-Object -Property SkuPartNumber, ServicePlanName)

    Write-Log "Correlation completed: $totalRows user-service row(s) from $processed user(s)." 'SUCCESS' 'Detail'
    Write-Log "Correlation completed. Rows=$totalRows; Users=$processed; UsersWithoutLicense=$($script:UsersWithoutLicense)" 'SUCCESS' 'Correlation'

    return [pscustomobject]@{
        RowCount         = $totalRows
        EnabledRowCount  = $totalEnabledRows
        DisabledRowCount = $totalDisabledRows
        Summary          = $summary
        # SkuPartNumber as a secondary key so a multi-licence user's rows land together in a repeatable
        # order rather than wherever the licence enumeration put them.
        PackedRows       = @($packedRows.ToArray() | Sort-Object -Property UserPrincipalName, SkuPartNumber)
    }
}

function Export-ServiceUsageReport {
    param(
        [Parameter(Mandatory)] [object] $Correlation
    )

    if ($Correlation.RowCount -eq 0) {
        Write-Log 'No user-service rows were produced. Check that users have licenses assigned and that /subscribedSkus returned the matching SKUs.' 'WARN' 'Detail'
        Write-Log 'Service usage export produced zero rows.' 'WARN' 'Reporting'
        return
    }

    # AllServiceUsage.csv was already streamed to disk by New-ServiceUsageRows. Writing it here from a
    # materialized array is the 30GB problem noted there, so this function writes only the summary and
    # the pivoted workbook sheet.
    try {
        $Correlation.Summary | Export-Csv -LiteralPath $Config.ServiceSummaryCsvPath -NoTypeInformation -Encoding UTF8 -Force -ErrorAction Stop
    }
    catch {
        if (Test-FileLockError -Exception $_.Exception) {
            throw (New-AssessmentException -Message "AllServiceUsage.csv was written, but '$($Config.ServiceSummaryCsvPath)' could not be written. The file appears to be open in another program (for example Excel). Close the file and run the script again."-Category 'File System' -Stage 'CSV Export' -Retryable $false)
        }
        throw (New-AssessmentException -Message "AllServiceUsage.csv was written, but the ServiceUsageSummary CSV export failed: $($_.Exception.Message)" -Category 'Reporting' -Stage 'CSV Export' -Retryable $false)
    }

    # Pivoted to one row per user per licence, so the row count is the licence-assignment count rather
    # than the much larger user-service-plan count, which is what keeps it under Excel's row limit. Note
    # that a tenant where everyone holds two SKUs produces twice the rows, so MaxExcelRows bites sooner
    # than the user count suggests. Named differently from AllServiceUsage.csv, which is one row per
    # plan, because a shared name would hide that difference.
    $packedRows = @($Correlation.PackedRows)
    $workbookWritten = $false

    if ($packedRows.Count -ge $Config.MaxExcelRows) {
        # Says "this sheet", not "no workbook": the summary tab is written before this function and the
        # usage sheets after it, so a workbook does exist and only this sheet is missing from it.
        Write-Log "Users and Assigned Services sheet skipped: the user-license row count ($($packedRows.Count)) exceeds the Excel limit of $($Config.MaxExcelRows). The other sheets are unaffected. The full per-plan detail is in AllServiceUsage.csv." 'WARN' 'Detail'
        Write-Log "Skipped Users and Assigned Services worksheet; rows=$($packedRows.Count) exceeds MaxExcelRows=$($Config.MaxExcelRows). Other sheets unaffected." 'WARN' 'Reporting'
        Add-UserNote "The Users and Assigned Services sheet was left out. At $('{0:N0}' -f $packedRows.Count) license assignments, it is larger than a single Excel sheet can hold. Everything it would have shown is in Resources\AllServiceUsage.csv."
    }
    else {
        try {
            $packedRows | Export-Excel -Path $Config.ReportXlsxPath -WorksheetName 'Users and Assigned Services' -AutoSize -FreezeTopRow -BoldTopRow -ClearSheet -ErrorAction Stop
            $workbookWritten = $true
        }
        catch {
            if (Test-FileLockError -Exception $_.Exception) {
                throw (New-AssessmentException -Message "The CSV files were created, but '$($Config.ReportXlsxPath)' could not be written. The file appears to be open in another program (for example Excel). Close the file and run the script again."-Category 'File System' -Stage 'XLSX Export' -Retryable $false)
            }
            throw (New-AssessmentException -Message "The CSV files were created, but the Users and Assigned Services worksheet failed: $($_.Exception.Message)" -Category 'Reporting' -Stage 'XLSX Export' -Retryable $false)
        }

        # -ClearSheet only clears the sheet being written, so a pre-existing workbook would show stale
        # sheets from an earlier version of this script next to fresh data. Non-fatal: a leftover sheet
        # is cosmetic and must never fail a run that already wrote its detail. Skipped when this run
        # created the file, since it cannot then hold a sheet from an older build; it still matters for
        # a second run inside the same minute, or a build pinned back to a fixed name.
        if ($script:WorkbookPreExisted) {
            try {
                $existingSheets = @(Get-ExcelSheetInfo -Path $Config.ReportXlsxPath -ErrorAction Stop | ForEach-Object { $_.Name })
                # All superseded tab names: 'Usage Detail' became 'Other Service Usage status',
                # 'ServiceUsageSummary' became 'Service Usage Summary', and 'Service Assignments' became
                # 'Users and Assigned Services'. Each has to be listed or a pre-existing workbook ends up
                # holding the same rows twice under two tab names.
                #
                # Do not tidy the spacing of these names to match the current ones. 'ServiceUsageSummary'
                # and 'Service Usage Summary' differ only by spaces, and aligning them would make this
                # cleanup delete the sheet the run just wrote.
                foreach ($staleSheet in @('AllServiceUsage', 'ServiceUsageSummary', 'ServiceUsageByUser', 'Usage Detail', 'Service Assignments')) {
                    if ($existingSheets -contains $staleSheet) {
                        Remove-Worksheet -FullName $Config.ReportXlsxPath -WorksheetName $staleSheet -ErrorAction Stop
                        Write-Log "Removed a stale $staleSheet worksheet left in the workbook by an earlier version of this script." 'INFO' 'Detail'
                        Write-Log "Removed stale $staleSheet worksheet from the existing workbook." 'INFO' 'Reporting'
                    }
                }
            }
            catch {
                Write-Log "Could not check for or remove a stale worksheet: $($_.Exception.Message)" 'WARN' 'Reporting'
            }
        }
        else {
            Write-Log 'Skipped the stale-worksheet check: this run created the workbook, so it cannot contain sheets from an earlier build.' 'INFO' 'Reporting'
        }
    }

    if ($workbookWritten) {
        Write-Log "Reports created: $($Config.ReportXlsxPath) (sheet: Users and Assigned Services, $($packedRows.Count) user-license row(s))" 'SUCCESS' 'Detail'
    }
    else {
        Write-Log "CSV reports created in $($Config.OutputPath). The Users and Assigned Services sheet was not written for this run." 'SUCCESS' 'Detail'
    }
    Write-Log "  Service plan assignments: $($Correlation.RowCount) | Enabled: $($Correlation.EnabledRowCount) | Disabled: $($Correlation.DisabledRowCount)" 'INFO' 'Detail'
    Write-Log "Service plan export completed. Rows=$($Correlation.RowCount); Enabled=$($Correlation.EnabledRowCount); Disabled=$($Correlation.DisabledRowCount)" 'SUCCESS' 'Reporting'

    if ($script:UsersWithoutLicense -gt 0) {
        Add-UserNote "$($script:UsersWithoutLicense) user(s) hold no license at all, so they do not appear on the license sheet."
    }
    if ($script:UnknownSkuRefs -gt 0) {
        # Says where these show up. A SKU missing from /subscribedSkus has no catalog entry, so the
        # correlation loop skips it and the user never reaches the sheet, only the per-user CSV. Saying
        # just "shown as UnknownSku" sent the reader to a sheet that does not contain them.
        Add-UserNote "$($script:UnknownSkuRefs) license(s) point to a product that is no longer in your tenant. Those licenses list no services, so they appear only in Resources\UserLicenseAssignments.csv marked UnknownSku, and not on the report sheets. This is normal after a subscription ends."
    }
}

#region 6b. M365 ACTIVITY REPORT (independent of the /users pipeline above -- see notes below)

function ConvertTo-ReportDate {
    param([AllowNull()] [string] $Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $parsed = [datetime]::MinValue
    if ([datetime]::TryParse($Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)) {
        return $parsed
    }
    return $null
}

function ConvertTo-ReportBoolean {
    param([AllowNull()] [string] $Value)
    # The activity CSV writes literal "TRUE"/"FALSE" text, and a bare [bool] cast on any non-empty
    # string is $true in PowerShell, including [bool]'FALSE', so this compares the text itself.
    # "Yes" and "1" are accepted too, because the per-workload reports do not share one vocabulary for a
    # boolean and an unrecognised affirmative falls through to $false, reading as "never used the app" --
    # a wrong answer that looks entirely plausible. Only the affirmative set is broadened, so nothing
    # that already resolved to $true can flip.
    return @('TRUE', 'YES', '1') -contains ([string]$Value).Trim().ToUpperInvariant()
}

function Get-ActiveUserDetailReport {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Period
    )

    Write-Log "Collecting Microsoft 365 activity report (period=$Period)..." 'INFO' 'Detail'
    try {
        $uri = "$($Config.GraphUri)/reports/getOffice365ActiveUserDetail(period='$Period')?`$format=text/csv"
        Invoke-GraphWithRetry -Uri $uri -Method GET -OutputFilePath $Path -Stage 'Activity Report Collection' | Out-Null

        $rows = @(Import-Csv -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop)
        Write-Log "Activity report collected: $($rows.Count) row(s)." 'SUCCESS' 'Detail'
        Write-Log "Activity report collected. Rows=$($rows.Count); Period=$Period" 'SUCCESS' 'Collection'
        # Unary comma so a header-only report reaches the caller as an empty array rather than being
        # unrolled to $null, which made Export-ActivityReport's "no rows" message unreachable and left a
        # raw parameter-binding error in the log instead.
        return ,$rows
    }
    catch {
        if (Test-FileLockError -Exception $_.Exception) {
            throw (New-AssessmentException -Message "Cannot write '$Path'. The file appears to be open in another program (for example Excel). Close the file and run the script again." -Category 'File System' -Stage 'Activity Report Collection' -Retryable $false)
        }
        $meta = Get-ExceptionMetadata -Exception $_.Exception
        throw (New-AssessmentException -Message $_.Exception.Message -Category 'Graph/API' -Stage 'Activity Report Collection' -HttpStatus ([int]$meta.HttpStatus) -Retryable $true)
    }
}

function ConvertTo-ActivityReportRow {
    param(
        [Parameter(Mandatory)] $Row,
        [Parameter(Mandatory)] [string] $Period
    )

    # Independent of the /users + licence pipeline above: no join, no UPN cross-reference. Under tenant
    # report concealment the UPN here can be blank or not an email, which must not be read as a failed
    # join, because there is no join. Every column below comes from this row alone.
    $refreshDate = ConvertTo-ReportDate -Value $Row.'Report Refresh Date'
    $exch  = ConvertTo-ReportDate -Value $Row.'Exchange Last Activity Date'
    $odb   = ConvertTo-ReportDate -Value $Row.'OneDrive Last Activity Date'
    $spo   = ConvertTo-ReportDate -Value $Row.'SharePoint Last Activity Date'
    $skype = ConvertTo-ReportDate -Value $Row.'Skype For Business Last Activity Date'
    $yam   = ConvertTo-ReportDate -Value $Row.'Yammer Last Activity Date'
    $teams = ConvertTo-ReportDate -Value $Row.'Teams Last Activity Date'

    $dates = @(@($exch, $odb, $spo, $skype, $yam, $teams) | Where-Object { $_ })
    $lastAny = if ($dates.Count -gt 0) { @($dates | Sort-Object -Descending)[0] } else { $null }

    # Measured against the report's own snapshot date rather than today, which would mislead whenever the
    # report is not perfectly fresh. Both sides come from the same row, so the cross-report skew
    # New-UsageDetailRows guards against cannot arise. Floored at 0 anyway, so the identically-named
    # column on the other sheet cannot disagree and no negative day count reaches the sheet.
    $daysSince = if ($lastAny -and $refreshDate) { [math]::Max(0, [math]::Round(($refreshDate - $lastAny).TotalDays, 0)) } else { $null }
    $periodDays = switch ($Period) { 'D7' { 7 } 'D30' { 30 } 'D90' { 90 } 'D180' { 180 } default { 30 } }

    # A missing refresh date must be caught in the first branch: $daysSince is $null when either side is
    # missing and $null -le 30 is TRUE in PowerShell, so a row with real activity dates but no refresh
    # date would read 'Active', understating dormancy on exactly the rows whose recency cannot be
    # measured. 'No usage data' rather than 'Inactive' because there is no evidence of dormancy either.
    $bucket = if (-not $lastAny -or -not $refreshDate) { 'No usage data' }
        elseif ($daysSince -le $periodDays) { 'Active' }
        else { 'Inactive' }

    $upn = [string]$Row.'User Principal Name'
    # An observation, not a claim about cause: could be tenant concealment, could be something else.
    $looksMasked = [string]::IsNullOrWhiteSpace($upn) -or ($upn -notlike '*@*')

    # ---- Adoption measures. Both halves of the ratio come from this same row ----
    # The Has*License flags are the entitlement and the matching *LastActivityDate columns are the use,
    # so nothing here needs a join, the licence catalogue, or a second report. That is why these live on
    # this sheet and not the merged five-report sheet, which has activity but no entitlement to divide
    # by. Hoisted into variables only so they can be counted; the six columns below are unchanged.
    $hasExch  = ConvertTo-ReportBoolean -Value $Row.'Has Exchange License'
    $hasOdb   = ConvertTo-ReportBoolean -Value $Row.'Has OneDrive License'
    $hasSpo   = ConvertTo-ReportBoolean -Value $Row.'Has SharePoint License'
    $hasSkype = ConvertTo-ReportBoolean -Value $Row.'Has Skype For Business License'
    $hasYam   = ConvertTo-ReportBoolean -Value $Row.'Has Yammer License'
    $hasTeams = ConvertTo-ReportBoolean -Value $Row.'Has Teams License'

    $entitledCount = @(@($hasExch, $hasOdb, $hasSpo, $hasSkype, $hasYam, $hasTeams) | Where-Object { $_ }).Count

    # Each licence flag is paired with its own date and both must hold, so activity in a workload the
    # user is not licensed for cannot count towards adoption. Without the pairing the ratio can exceed
    # 100%, which happens when a licence was removed after the activity was recorded. Measured from the
    # refresh date, the same basis as $daysSince, so a row cannot read Active while every workload is not.
    $activeCount = 0
    if ($refreshDate) {
        foreach ($pair in @(@($hasExch, $exch), @($hasOdb, $odb), @($hasSpo, $spo),
                            @($hasSkype, $skype), @($hasYam, $yam), @($hasTeams, $teams))) {
            if ($pair[0] -and $pair[1] -and ((($refreshDate - $pair[1]).TotalDays) -le $periodDays)) { $activeCount++ }
        }
    }

    # Thresholds match the tool this idea came from, so the labels mean the same thing elsewhere.
    # 'InsufficientData' rather than 0% when there is nothing to divide by: a user the report lists no
    # licences for has not failed to adopt anything, and 0% would drag every tenant average down.
    $adoptionDepth = if ($entitledCount -le 0) { 'InsufficientData' }
        elseif ($activeCount -le 0) { 'Inactive' }
        elseif ((($activeCount / [double]$entitledCount) * 100) -ge 75) { 'Power' }
        elseif ((($activeCount / [double]$entitledCount) * 100) -ge 50) { 'Regular' }
        else { 'Light' }

    # Built from $entitledCount and $bucket rather than re-deriving either, so this can never disagree
    # with the ActivityBucket column sitting beside it on the same sheet.
    $usageStatus = if ($entitledCount -le 0) { 'Unlicensed' }
        elseif ($bucket -eq 'No usage data') { 'Licensed + No Usage Data' }
        elseif ($bucket -eq 'Active') { 'Licensed + Active' }
        else { 'Licensed + Inactive' }

    # Marks rows whose derived columns rest on incomplete input, so they can be excluded rather than
    # averaged in. Two causes: a concealed identity, and a row carrying no licence flags. 'Partial' means
    # only "do not draw conclusions from this row"; the raw activity dates on it stay valid.
    $completeness = if ($looksMasked -or $entitledCount -le 0) { 'Partial' } else { 'Complete' }

    return [pscustomobject]@{
        ReportRefreshDate                 = $refreshDate
        UserPrincipalName                 = $upn
        DisplayName                       = [string]$Row.'Display Name'
        IsDeleted                         = ConvertTo-ReportBoolean -Value $Row.'Is Deleted'
        DeletedDate                       = ConvertTo-ReportDate -Value $Row.'Deleted Date'
        HasExchangeLicense                = $hasExch
        HasOneDriveLicense                = $hasOdb
        HasSharePointLicense              = $hasSpo
        HasSkypeForBusinessLicense        = $hasSkype
        HasYammerLicense                  = $hasYam
        HasTeamsLicense                   = $hasTeams
        ExchangeLastActivityDate          = $exch
        OneDriveLastActivityDate          = $odb
        SharePointLastActivityDate        = $spo
        SkypeForBusinessLastActivityDate  = $skype
        YammerLastActivityDate            = $yam
        TeamsLastActivityDate             = $teams
        ExchangeLicenseAssignDate         = ConvertTo-ReportDate -Value $Row.'Exchange License Assign Date'
        OneDriveLicenseAssignDate         = ConvertTo-ReportDate -Value $Row.'OneDrive License Assign Date'
        SharePointLicenseAssignDate       = ConvertTo-ReportDate -Value $Row.'SharePoint License Assign Date'
        SkypeForBusinessLicenseAssignDate = ConvertTo-ReportDate -Value $Row.'Skype For Business License Assign Date'
        YammerLicenseAssignDate           = ConvertTo-ReportDate -Value $Row.'Yammer License Assign Date'
        TeamsLicenseAssignDate            = ConvertTo-ReportDate -Value $Row.'Teams License Assign Date'
        AssignedProducts                  = [string]$Row.'Assigned Products'
        LastActivityAnyWorkload           = $lastAny
        DaysSinceLastActivity             = $daysSince
        ActivityBucket                    = $bucket
        IdentityLooksMasked               = $looksMasked
        # Appended at the end, not placed beside the columns they derive from: inserting mid-object shifts
        # every later column one letter right, and anything downstream addressing this sheet by position
        # would then read the wrong field.
        #
        # Sum the two counts, never average the percentage. SUM(active)/SUM(entitled) is the adoption rate
        # for any group, whereas the mean of a per-user percentage weights a one-workload user the same as
        # a six-workload one. That is why the counts are published and the percentage is not.
        EntitledWorkloadCount             = $entitledCount
        ActiveWorkloadCount               = $activeCount
        AdoptionDepth                     = $adoptionDepth
        LicenseUsageStatus                = $usageStatus
        DataCompleteness                  = $completeness
        # The window every column above was measured against. Five of them mean something different at
        # D30 than at D90, and without this the sheet carried no record of which produced them, so two
        # workbooks built on different periods were indistinguishable and combining a folder of them
        # compared incompatible windows. Named and valued exactly as the column on the Other Service
        # Usage status sheet so the two can be joined on it. Appended last for the reason above.
        ReportPeriodDays                  = $periodDays
    }
}

function Export-ActivityReport {
    param(
        # AllowEmptyCollection because Mandatory rejects an empty array before the body runs, which
        # would make the zero-row branch below dead code.
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]] $Rows,
        [Parameter(Mandatory)] [string] $Period
    )

    $activityRows = @($Rows | ForEach-Object { ConvertTo-ActivityReportRow -Row $_ -Period $Period })
    if ($activityRows.Count -eq 0) {
        Write-Log 'No activity report rows were produced. The M365 Activity sheet was not written.' 'WARN' 'Detail'
        Write-Log 'Activity report produced zero rows.' 'WARN' 'Reporting'
        return
    }

    if ($activityRows.Count -ge $Config.MaxExcelRows) {
        Write-Log "M365 Activity sheet skipped: the row count ($($activityRows.Count)) exceeds the Excel limit of $($Config.MaxExcelRows)." 'WARN' 'Detail'
        Write-Log "Skipped M365 Activity worksheet; rows=$($activityRows.Count) exceeds MaxExcelRows=$($Config.MaxExcelRows)." 'WARN' 'Reporting'
        return
    }

    try {
        $activityRows | Export-Excel -Path $Config.ReportXlsxPath -WorksheetName 'M365 Activity' -AutoSize -FreezeTopRow -BoldTopRow -ClearSheet -ErrorAction Stop
    }
    catch {
        if (Test-FileLockError -Exception $_.Exception) {
            throw (New-AssessmentException -Message "'$($Config.ReportXlsxPath)' could not be written. The file appears to be open in another program (for example Excel). Close the file and run the script again." -Category 'File System' -Stage 'XLSX Export' -Retryable $false)
        }
        throw (New-AssessmentException -Message "The M365 Activity worksheet failed: $($_.Exception.Message)" -Category 'Reporting' -Stage 'XLSX Export' -Retryable $false)
    }

    Write-Log "M365 Activity sheet written: $($activityRows.Count) row(s)." 'SUCCESS' 'Detail'
    Write-Log "M365 Activity worksheet written. Rows=$($activityRows.Count)" 'SUCCESS' 'Reporting'

    $masked = @($activityRows | Where-Object { $_.IdentityLooksMasked }).Count
    if ($masked -gt 0) {
        Add-UserNote "$masked of $($activityRows.Count) rows on the activity sheet have no name or email address, because your tenant hides user details in reports. Those rows are included, not dropped."
        Write-Log "Activity rows with a masked-looking UPN: $masked / $($activityRows.Count)" 'WARN' 'Reporting'
    }
}

#region 6c. USAGE DETAIL SHEET (five per-workload usage reports, merged on UPN)

# Why this is a separate sheet and not extra columns on 'Users and Assigned Services':
#   * Users and Assigned Services is one row per user per LICENCE. A usage number joined onto it would
#     repeat on every licence row a person holds, so anyone summing MailboxItems over an E3+E5
#     user would get double the real figure. Usage is per user, so it needs a per-user sheet.
#   * All five reports are report-endpoint data keyed on UPN, and all five are equally affected by the
#     tenant's "conceal user-level information" setting, so merging them with each other is
#     like-for-like. Merging them into the licence pipeline would not be: that pipeline reads /users
#     directly and is never concealed, so the join would drop exactly the users the reports masked.
# Reports.Read.All is an optional scope, so every fetch here is individually best-effort. Four reports
# succeeding and one failing still produces a sheet, with SourceReports naming which contributed to each
# row. That matters most for Copilot, which many tenants cannot serve at all.

function ConvertTo-ReportFieldMap {
    param([Parameter(Mandatory)] $Row)

    # Report CSV headers are display names ('Storage Used (Byte)') whose spacing, casing and punctuation
    # have all shifted between report versions. Canonicalising to lowercase alphanumerics means
    # 'User Principal Name' and 'userPrincipalName' resolve alike, so only a genuine rename can miss.
    $map = @{}
    foreach ($prop in $Row.PSObject.Properties) {
        $key = ($prop.Name -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
        if (-not $map.ContainsKey($key)) { $map[$key] = $prop.Value }
    }
    return $map
}

function Get-ReportFieldValue {
    param(
        [Parameter(Mandatory)] [hashtable] $Map,
        # Candidates in preference order. More than one because some columns have been renamed between
        # report versions (Teams' UPN column has shipped as both 'User Principal Name' and 'User Id').
        [Parameter(Mandatory)] [string[]] $Names,
        [Parameter(Mandatory)] [string] $Report
    )

    foreach ($name in $Names) {
        $key = ($name -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
        if ($Map.ContainsKey($key)) { return $Map[$key] }
    }

    # Nothing matched: record it rather than quietly returning $null forever. Keyed on the first
    # candidate, the name this script expects to see.
    $missKey = '{0}/{1}' -f $Report, $Names[0]
    if (-not $script:ReportFieldMisses.ContainsKey($missKey)) { $script:ReportFieldMisses[$missKey] = 0 }
    $script:ReportFieldMisses[$missKey]++
    return $null
}

function ConvertTo-ReportNumber {
    param([AllowNull()] $Value)

    # Blank stays $null, never 0. In a usage report 0 is "measured, nothing there" and blank is "not
    # reported for this user", so collapsing them invents data Microsoft never returned.
    if ($null -eq $Value) { return $null }
    $text = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    $parsed = [double]0
    if ([double]::TryParse($text, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
        return $parsed
    }
    return $null
}

function ConvertTo-ReportMegabytes {
    param([AllowNull()] $Value)

    $bytes = ConvertTo-ReportNumber -Value $Value
    if ($null -eq $bytes) { return $null }
    return [math]::Round(($bytes / 1MB), 2)
}

function Get-UsageReportCsv {
    param(
        # The report function name only, e.g. getMailboxUsageDetail. The URI is built here so the period
        # is always applied and cannot be omitted by a caller.
        [Parameter(Mandatory)] [string] $Report,
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Period,
        # API surfaces to try, in order. Only needed for the Copilot report, which 404s on v1.0 in tenants
        # where only beta serves it. A 404 is not in Invoke-GraphWithRetry's transient list, so a miss
        # costs one request rather than a full retry cycle. Empty means v1.0 only.
        [string[]] $BaseUris = @()
    )

    # The @() wraps the whole if, not each branch: a branch returning a one-element array is unrolled to
    # a bare string on assignment, and then $bases.Count throws under StrictMode while $bases[0] yields
    # the string's first character. Wrapping outside keeps the single-surface case an array.
    $bases = @(if (@($BaseUris).Count -gt 0) { $BaseUris } else { $Config.GraphUri })
    Write-Log "Collecting $Report (period=$Period)..." 'INFO' 'Detail'

    $lastMessage = $null
    for ($i = 0; $i -lt $bases.Count; $i++) {
        $base = $bases[$i]
        try {
            $uri = "$base/reports/$Report(period='$Period')?`$format=text/csv"
            Invoke-GraphWithRetry -Uri $uri -Method GET -OutputFilePath $Path -Stage 'Usage Report Collection' | Out-Null

            $rows = @(Import-Csv -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop)
            Write-Log "  $Report : $($rows.Count) row(s)." 'SUCCESS' 'Detail'
            if ($i -gt 0) {
                Write-Log "    (served by $base; not available on $($bases[0]) in this tenant)" 'INFO' 'Detail'
            }
            Write-Log "$Report collected from $base. Rows=$($rows.Count); Period=$Period" 'SUCCESS' 'Collection'
            # Unary comma so a header-only report reaches the caller as an empty array rather than
            # being unrolled to $null -- same reason as Get-ActiveUserDetailReport.
            return ,$rows
        }
        catch {
            # A locked output file is not fixed by asking a different API surface for the same data, so it
            # stops here rather than consuming the fallback on a purely local problem.
            if (Test-FileLockError -Exception $_.Exception) {
                throw (New-AssessmentException -Message "Cannot write '$Path'. The file appears to be open in another program (for example Excel). Close the file and run the script again." -Category 'File System' -Stage 'Usage Report Collection' -Retryable $false)
            }
            $lastMessage = $_.Exception.Message
            $lastMeta = Get-ExceptionMetadata -Exception $_.Exception
            if ($i -lt ($bases.Count - 1)) {
                Write-Log "$Report is unavailable at $base (HTTP $([int]$lastMeta.HttpStatus)). Trying $($bases[$i + 1])." 'WARN' 'Collection'
                continue
            }
            throw (New-AssessmentException -Message "$Report failed: $lastMessage" -Category 'Graph/API' -Stage 'Usage Report Collection' -HttpStatus ([int]$lastMeta.HttpStatus) -Retryable $true)
        }
    }
}

function Get-UsageReportSet {
    param([Parameter(Mandatory)] [string] $Period)

    # Each report is fetched independently and a failure is recorded, not thrown: one report being
    # unavailable (not licensed, throttled, service issue) must not cost the reader the other four. The
    # caller decides what to do with an all-empty set.
    $set = [ordered]@{}
    $definitions = @(
        @{ Key = 'Apps';     Report = 'getM365AppUserDetail';           Path = $Config.M365AppUserCsvPath;       BaseUris = @() }
        @{ Key = 'Teams';    Report = 'getTeamsUserActivityUserDetail'; Path = $Config.TeamsUserActivityCsvPath; BaseUris = @() }
        @{ Key = 'Mailbox';  Report = 'getMailboxUsageDetail';          Path = $Config.MailboxUsageCsvPath;      BaseUris = @() }
        @{ Key = 'OneDrive'; Report = 'getOneDriveUsageAccountDetail';  Path = $Config.OneDriveUsageCsvPath;     BaseUris = @() }
        # Copilot is the only one given a fallback surface: v1.0 first so the tenant's supported
        # surface is always preferred, then beta for tenants where v1.0 does not serve it yet.
        @{ Key = 'Copilot';  Report = 'getMicrosoft365CopilotUsageUserDetail'; Path = $Config.CopilotUsageCsvPath; BaseUris = @($Config.GraphUri, $Config.GraphBetaUri) }
    )

    foreach ($def in $definitions) {
        try {
            # Not wrapped in @(). Get-UsageReportCsv returns its rows with a unary comma, emitting the
            # whole array as one object, which is what keeps a header-only report alive as an empty array.
            # @() would collect that object into a new array and nest it, leaving every report a single
            # property-less Object[]; the merge below would find no UPN on it, read that as a concealed
            # identity and emit one blank-UPN row per report instead of the merged sheet.
            $set[$def.Key] = Get-UsageReportCsv -Report $def.Report -Path $def.Path -Period $Period -BaseUris $def.BaseUris
        }
        catch {
            $set[$def.Key] = @()
            Write-Log "  $($def.Report) unavailable: $($_.Exception.Message)" 'WARN' 'Detail'
            Write-Log "$($def.Report) unavailable: $($_.Exception.Message)" 'WARN' 'Collection'
        }
    }
    return $set
}

function New-UsageDetailRows {
    param(
        [Parameter(Mandatory)] [System.Collections.Specialized.OrderedDictionary] $ReportSet,
        [Parameter(Mandatory)] [string] $Period
    )

    $periodDays = switch ($Period) { 'D7' { 7 } 'D30' { 30 } 'D90' { 90 } 'D180' { 180 } default { 30 } }

    # Ordered so the sheet comes out in first-seen order before the final sort, which keeps the
    # output stable between runs on the same data.
    $merged = [ordered]@{}
    # Script-scoped because the nested helper below writes to them; initialised here so the counts are
    # per-call and a retried attempt does not inherit the previous attempt's totals.
    $script:UsageMaskedSeen = 0
    $script:UsageSyntheticSeq = 0

    # A local so the masked-key rule is applied identically for all five reports. A blank or non-email
    # UPN cannot be a join key: every masked row would collapse into one and merge unrelated people.
    # Those rows get a unique synthetic key instead, staying visible as separate flagged rows.
    function Resolve-Slot {
        param($Upn, $Source)
        $text = ([string]$Upn).Trim()
        $looksMasked = [string]::IsNullOrWhiteSpace($text) -or ($text -notlike '*@*')
        if ($looksMasked) {
            $script:UsageMaskedSeen++
            $key = "!masked!$Source!$($script:UsageSyntheticSeq)"
            $script:UsageSyntheticSeq++
        }
        else {
            $key = $text.ToLowerInvariant()
        }
        if (-not $merged.Contains($key)) {
            $merged[$key] = [pscustomobject]@{
                UserPrincipalName    = $text
                DisplayName          = $null
                IsDeleted            = $null
                DeletedDate          = $null
                ReportRefreshDate    = $null
                IdentityLooksMasked  = $looksMasked
                Sources              = (New-Object System.Collections.Generic.List[string])
                AppsLastActivity     = $null
                AppsLastActivation   = $null
                OutlookUsed          = $null
                WordUsed             = $null
                ExcelUsed            = $null
                PowerPointUsed       = $null
                OneNoteUsed          = $null
                TeamsAppUsed         = $null
                UsedOnWindows        = $null
                UsedOnMac            = $null
                UsedOnMobile         = $null
                UsedOnWeb            = $null
                TeamsLastActivity    = $null
                TeamsMessages        = $null
                TeamsChannelMessages = $null
                TeamsChatMessages    = $null
                TeamsCalls           = $null
                TeamsMeetings        = $null
                MailboxLastActivity  = $null
                MailboxItems         = $null
                MailboxStorageMB     = $null
                MailboxDeletedItems  = $null
                MailboxHasArchive    = $null
                OneDriveLastActivity = $null
                OneDriveFiles        = $null
                OneDriveActiveFiles  = $null
                OneDriveStorageMB    = $null
                OneDriveSiteCount    = $null
                CopilotLastActivity  = $null
                CopilotChat          = $null
                CopilotTeams         = $null
                CopilotWord          = $null
                CopilotExcel         = $null
                CopilotPowerPoint    = $null
                CopilotOutlook       = $null
                CopilotOneNote       = $null
                CopilotLoop          = $null
            }
        }
        $slot = $merged[$key]
        if (-not $slot.Sources.Contains($Source)) { $slot.Sources.Add($Source) }
        return $slot
    }

    # Keeps the newest refresh date across the reports that contributed to this row, not whichever was
    # processed first. Microsoft refreshes the five reports on independent schedules, so their
    # 'Report Refresh Date' values differ by a day or two. First-wins gave every user in the Apps report
    # the Apps date, while LastActivityAnyWorkload below takes the maximum across all five, so
    # subtracting the two produced negative DaysSinceLastActivity for the most recently active people.
    #
    # Newest makes the column mean "as of the freshest report behind this row", the same basis the
    # activity date is picked on. That makes it a floor on staleness rather than an exact figure: where
    # the reports are out of step, a workload with an older report could have activity not yet visible.
    # Worth a day or two against a 30/90/180-day period, so it changes no dormancy call.
    function Update-SlotRefreshDate {
        param($Slot, $Value)
        $d = ConvertTo-ReportDate -Value $Value
        if ($d -and (-not $Slot.ReportRefreshDate -or $d -gt $Slot.ReportRefreshDate)) { $Slot.ReportRefreshDate = $d }
    }

    # --- getM365AppUserDetail: which apps and which platforms, per user -------------------------
    foreach ($row in @($ReportSet['Apps'])) {
        $map = ConvertTo-ReportFieldMap -Row $row
        $slot = Resolve-Slot -Upn (Get-ReportFieldValue -Map $map -Names 'User Principal Name' -Report 'Apps') -Source 'Apps'
        Update-SlotRefreshDate -Slot $slot -Value (Get-ReportFieldValue -Map $map -Names 'Report Refresh Date' -Report 'Apps')
        $slot.AppsLastActivity   = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Last Activity Date' -Report 'Apps')
        $slot.AppsLastActivation = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Last Activation Date' -Report 'Apps')
        # The report's own per-app rollups across all platforms. Blank is treated as FALSE, matching
        # ConvertTo-ReportBoolean and the M365 Activity sheet, so "no signal" and "unused" look alike.
        $slot.OutlookUsed    = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'Outlook' -Report 'Apps')
        $slot.WordUsed       = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'Word' -Report 'Apps')
        $slot.ExcelUsed      = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'Excel' -Report 'Apps')
        $slot.PowerPointUsed = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'PowerPoint' -Report 'Apps')
        $slot.OneNoteUsed    = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'OneNote' -Report 'Apps')
        $slot.TeamsAppUsed   = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'Teams' -Report 'Apps')
        $slot.UsedOnWindows  = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'Windows' -Report 'Apps')
        $slot.UsedOnMac      = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'Mac' -Report 'Apps')
        $slot.UsedOnMobile   = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'Mobile' -Report 'Apps')
        $slot.UsedOnWeb      = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'Web' -Report 'Apps')
    }

    # --- getTeamsUserActivityUserDetail: message, call and meeting volumes ----------------------
    foreach ($row in @($ReportSet['Teams'])) {
        $map = ConvertTo-ReportFieldMap -Row $row
        $slot = Resolve-Slot -Upn (Get-ReportFieldValue -Map $map -Names 'User Principal Name', 'User Id' -Report 'Teams') -Source 'Teams'
        Update-SlotRefreshDate -Slot $slot -Value (Get-ReportFieldValue -Map $map -Names 'Report Refresh Date' -Report 'Teams')
        $slot.TeamsLastActivity = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Last Activity Date' -Report 'Teams')
        $slot.TeamsCalls        = ConvertTo-ReportNumber -Value (Get-ReportFieldValue -Map $map -Names 'Call Count' -Report 'Teams')
        $slot.TeamsMeetings     = ConvertTo-ReportNumber -Value (Get-ReportFieldValue -Map $map -Names 'Meeting Count' -Report 'Teams')
        $channel = ConvertTo-ReportNumber -Value (Get-ReportFieldValue -Map $map -Names 'Team Chat Message Count' -Report 'Teams')
        $chat    = ConvertTo-ReportNumber -Value (Get-ReportFieldValue -Map $map -Names 'Private Chat Message Count' -Report 'Teams')
        $slot.TeamsChannelMessages = $channel
        $slot.TeamsChatMessages    = $chat
        # Both components are kept alongside the total so it can be audited, and so channel posts can be
        # told from 1:1 chat. Stays $null when neither was reported rather than becoming a misleading 0;
        # [double]$null is 0, so one component missing still totals the other correctly.
        $slot.TeamsMessages = if (($null -eq $channel) -and ($null -eq $chat)) { $null }
            else { ([double]$channel) + ([double]$chat) }
        if (-not $slot.IsDeleted) { $slot.IsDeleted = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'Is Deleted' -Report 'Teams') }
    }

    # --- getMailboxUsageDetail: item count and storage ------------------------------------------
    foreach ($row in @($ReportSet['Mailbox'])) {
        $map = ConvertTo-ReportFieldMap -Row $row
        $slot = Resolve-Slot -Upn (Get-ReportFieldValue -Map $map -Names 'User Principal Name' -Report 'Mailbox') -Source 'Mailbox'
        Update-SlotRefreshDate -Slot $slot -Value (Get-ReportFieldValue -Map $map -Names 'Report Refresh Date' -Report 'Mailbox')
        if (-not $slot.DisplayName) { $slot.DisplayName = [string](Get-ReportFieldValue -Map $map -Names 'Display Name' -Report 'Mailbox') }
        $slot.MailboxLastActivity = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Last Activity Date' -Report 'Mailbox')
        $slot.MailboxItems        = ConvertTo-ReportNumber -Value (Get-ReportFieldValue -Map $map -Names 'Item Count' -Report 'Mailbox')
        $slot.MailboxStorageMB    = ConvertTo-ReportMegabytes -Value (Get-ReportFieldValue -Map $map -Names 'Storage Used (Byte)' -Report 'Mailbox')
        $slot.MailboxDeletedItems = ConvertTo-ReportNumber -Value (Get-ReportFieldValue -Map $map -Names 'Deleted Item Count' -Report 'Mailbox')
        $slot.MailboxHasArchive   = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'Has Archive' -Report 'Mailbox')
        $slot.IsDeleted   = ConvertTo-ReportBoolean -Value (Get-ReportFieldValue -Map $map -Names 'Is Deleted' -Report 'Mailbox')
        $slot.DeletedDate = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Deleted Date' -Report 'Mailbox')
    }

    # --- getOneDriveUsageAccountDetail: file count and storage ----------------------------------
    # Unlike the other three, this report is one row per SITE, not per user, and its owner column is
    # 'Owner Principal Name'. A user with more than one OneDrive site contributes several rows, so files
    # and storage are summed and the site count carried through; the first row alone would under-report.
    foreach ($row in @($ReportSet['OneDrive'])) {
        $map = ConvertTo-ReportFieldMap -Row $row
        $slot = Resolve-Slot -Upn (Get-ReportFieldValue -Map $map -Names 'Owner Principal Name', 'User Principal Name' -Report 'OneDrive') -Source 'OneDrive'
        Update-SlotRefreshDate -Slot $slot -Value (Get-ReportFieldValue -Map $map -Names 'Report Refresh Date' -Report 'OneDrive')
        if (-not $slot.DisplayName) { $slot.DisplayName = [string](Get-ReportFieldValue -Map $map -Names 'Owner Display Name' -Report 'OneDrive') }

        $activity = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Last Activity Date' -Report 'OneDrive')
        if ($activity -and ((-not $slot.OneDriveLastActivity) -or ($activity -gt $slot.OneDriveLastActivity))) { $slot.OneDriveLastActivity = $activity }

        $files       = ConvertTo-ReportNumber -Value (Get-ReportFieldValue -Map $map -Names 'File Count' -Report 'OneDrive')
        $activeFiles = ConvertTo-ReportNumber -Value (Get-ReportFieldValue -Map $map -Names 'Active File Count' -Report 'OneDrive')
        $storage     = ConvertTo-ReportMegabytes -Value (Get-ReportFieldValue -Map $map -Names 'Storage Used (Byte)' -Report 'OneDrive')
        if ($null -ne $files)       { $slot.OneDriveFiles       = ([double]$slot.OneDriveFiles) + $files }
        if ($null -ne $activeFiles) { $slot.OneDriveActiveFiles = ([double]$slot.OneDriveActiveFiles) + $activeFiles }
        if ($null -ne $storage)     { $slot.OneDriveStorageMB   = [math]::Round((([double]$slot.OneDriveStorageMB) + $storage), 2) }
        $slot.OneDriveSiteCount = ([int]$slot.OneDriveSiteCount) + 1
    }

    # --- getMicrosoft365CopilotUsageUserDetail: per-app Copilot last-activity dates --------------
    # This report gives dates, not counts: per surface, when the user last used Copilot there, or blank.
    # The per-app columns below are therefore dates rather than TRUE/FALSE, since "last used Word Copilot
    # on 3 September" answers a licence-review question a bare TRUE cannot. CopilotUsed and
    # CopilotActiveAppCount are derived from them. Two candidate header spellings per column because
    # these headers have moved between revisions and between the v1.0 and beta surfaces.
    foreach ($row in @($ReportSet['Copilot'])) {
        $map = ConvertTo-ReportFieldMap -Row $row
        $slot = Resolve-Slot -Upn (Get-ReportFieldValue -Map $map -Names 'User Principal Name' -Report 'Copilot') -Source 'Copilot'
        Update-SlotRefreshDate -Slot $slot -Value (Get-ReportFieldValue -Map $map -Names 'Report Refresh Date' -Report 'Copilot')
        if (-not $slot.DisplayName) { $slot.DisplayName = [string](Get-ReportFieldValue -Map $map -Names 'Display Name' -Report 'Copilot') }
        $slot.CopilotLastActivity = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Last Activity Date' -Report 'Copilot')
        $slot.CopilotChat       = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Copilot Chat Last Activity Date', 'Microsoft 365 Copilot Chat Last Activity Date' -Report 'Copilot')
        $slot.CopilotTeams      = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Microsoft Teams Copilot Last Activity Date', 'Teams Copilot Last Activity Date' -Report 'Copilot')
        $slot.CopilotWord       = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Word Copilot Last Activity Date' -Report 'Copilot')
        $slot.CopilotExcel      = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Excel Copilot Last Activity Date' -Report 'Copilot')
        $slot.CopilotPowerPoint = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'PowerPoint Copilot Last Activity Date' -Report 'Copilot')
        $slot.CopilotOutlook    = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Outlook Copilot Last Activity Date' -Report 'Copilot')
        $slot.CopilotOneNote    = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'OneNote Copilot Last Activity Date' -Report 'Copilot')
        $slot.CopilotLoop       = ConvertTo-ReportDate -Value (Get-ReportFieldValue -Map $map -Names 'Loop Copilot Last Activity Date' -Report 'Copilot')
    }

    # Flattened into the final shape here because the merge above needs mutable slots while the sheet
    # needs a fixed column order.
    $rows = foreach ($slot in $merged.Values) {
        # Copilot counts towards "any workload": someone whose only recent activity is Copilot is not
        # dormant, and omitting it would have this column contradict the Copilot columns beside it.
        $dates = @(@($slot.AppsLastActivity, $slot.TeamsLastActivity, $slot.MailboxLastActivity, $slot.OneDriveLastActivity, $slot.CopilotLastActivity) | Where-Object { $_ })
        $lastAny = if ($dates.Count -gt 0) { @($dates | Sort-Object -Descending)[0] } else { $null }

        # Breadth of Copilot adoption: how many surfaces this person has ever used. Counted from the
        # per-app dates, so a surface Microsoft does not report on cannot be counted, which is why the
        # dates stay visible beside it.
        $copilotApps = @(@($slot.CopilotChat, $slot.CopilotTeams, $slot.CopilotWord, $slot.CopilotExcel,
                           $slot.CopilotPowerPoint, $slot.CopilotOutlook, $slot.CopilotOneNote, $slot.CopilotLoop) | Where-Object { $_ })
        # $null rather than FALSE when the Copilot report returned nothing for this user: "no Copilot
        # row" means unlicensed or unreported, which is not the same claim as "licensed and unused".
        $copilotUsed = if (-not $slot.Sources.Contains('Copilot')) { $null }
            else { ($null -ne $slot.CopilotLastActivity) -or ($copilotApps.Count -gt 0) }
        # Measured against the report's own refresh date, not today, for the same reason as
        # ConvertTo-ActivityReportRow. Floored at 0: with the refresh date taken as the newest of the
        # contributing reports the cross-report skew is gone, leaving only a single report dating activity
        # after its own refresh date, which is not worth publishing under this header. Stays $null, never
        # 0, when there is no activity date at all, so "never recorded" cannot read as "active today".
        $daysSince = if ($lastAny -and $slot.ReportRefreshDate) { [math]::Max(0, [math]::Round(($slot.ReportRefreshDate - $lastAny).TotalDays, 0)) } else { $null }

        # The same three values, computed the same way, as ActivityBucket on the M365 Activity sheet, so
        # the two sheets can be filtered together and cannot disagree about who is dormant. This sheet
        # carried DaysSinceLastActivity but never a classification of it, so dormancy could not be sliced
        # on the richer of the two sheets.
        #
        # 'No usage data' is distinct from 'Inactive' for the same reason DaysSinceLastActivity stays
        # $null rather than 0: no report returning a date is a gap in the source, not evidence of
        # nothing. SourceReports beside it names which reports did contribute. The missing refresh date
        # is guarded in the first branch because $null -le 30 is TRUE, so 'Active' would claim recency it
        # cannot measure.
        $slotBucket = if (-not $lastAny -or -not $slot.ReportRefreshDate) { 'No usage data' }
            elseif ($daysSince -le $periodDays) { 'Active' }
            else { 'Inactive' }

        [pscustomobject]@{
            UserPrincipalName       = $slot.UserPrincipalName
            DisplayName             = $slot.DisplayName
            IsDeleted               = $slot.IsDeleted
            DeletedDate             = $slot.DeletedDate
            ReportRefreshDate       = $slot.ReportRefreshDate
            ReportPeriodDays        = $periodDays
            # Which of the five reports returned a row for this person. 'Mailbox;OneDrive' means the Apps,
            # Teams and Copilot reports had nothing for them, which is a gap in the source rather than
            # zero usage, and this column is how a reader tells the two apart.
            SourceReports           = (($slot.Sources | Sort-Object) -join ';')
            SourceReportCount       = $slot.Sources.Count
            IdentityLooksMasked     = $slot.IdentityLooksMasked
            AppsLastActivity        = $slot.AppsLastActivity
            AppsLastActivationDate  = $slot.AppsLastActivation
            OutlookUsed             = $slot.OutlookUsed
            WordUsed                = $slot.WordUsed
            ExcelUsed               = $slot.ExcelUsed
            PowerPointUsed          = $slot.PowerPointUsed
            OneNoteUsed             = $slot.OneNoteUsed
            TeamsAppUsed            = $slot.TeamsAppUsed
            UsedOnWindows           = $slot.UsedOnWindows
            UsedOnMac               = $slot.UsedOnMac
            UsedOnMobile            = $slot.UsedOnMobile
            UsedOnWeb               = $slot.UsedOnWeb
            TeamsLastActivity       = $slot.TeamsLastActivity
            TeamsMessages           = $slot.TeamsMessages
            TeamsChannelMessages    = $slot.TeamsChannelMessages
            TeamsChatMessages       = $slot.TeamsChatMessages
            TeamsCalls              = $slot.TeamsCalls
            TeamsMeetings           = $slot.TeamsMeetings
            MailboxLastActivity     = $slot.MailboxLastActivity
            MailboxItems            = $slot.MailboxItems
            MailboxStorageMB        = $slot.MailboxStorageMB
            MailboxDeletedItems     = $slot.MailboxDeletedItems
            MailboxHasArchive       = $slot.MailboxHasArchive
            OneDriveLastActivity    = $slot.OneDriveLastActivity
            OneDriveFiles           = $slot.OneDriveFiles
            OneDriveActiveFiles     = $slot.OneDriveActiveFiles
            OneDriveStorageMB       = $slot.OneDriveStorageMB
            OneDriveSiteCount       = $slot.OneDriveSiteCount
            CopilotUsed             = $copilotUsed
            CopilotLastActivity     = $slot.CopilotLastActivity
            CopilotActiveAppCount   = if ($slot.Sources.Contains('Copilot')) { $copilotApps.Count } else { $null }
            CopilotChatLastActivity       = $slot.CopilotChat
            CopilotTeamsLastActivity      = $slot.CopilotTeams
            CopilotWordLastActivity       = $slot.CopilotWord
            CopilotExcelLastActivity      = $slot.CopilotExcel
            CopilotPowerPointLastActivity = $slot.CopilotPowerPoint
            CopilotOutlookLastActivity    = $slot.CopilotOutlook
            CopilotOneNoteLastActivity    = $slot.CopilotOneNote
            CopilotLoopLastActivity       = $slot.CopilotLoop
            LastActivityAnyWorkload = $lastAny
            DaysSinceLastActivity   = $daysSince
            TenantId                = $script:GraphContext.TenantId
            CollectionTimestampUtc  = $script:Started.ToUniversalTime()
            ScriptVersion           = $script:ScriptVersion
            # Appended rather than placed next to DaysSinceLastActivity where it belongs logically:
            # inserting it there would move that column off AX and shift the three stamp columns above.
            ActivityBucket          = $slotBucket
        }
    }

    return [pscustomobject]@{
        Rows       = @(@($rows) | Sort-Object -Property UserPrincipalName)
        MaskedRows = $script:UsageMaskedSeen
    }
}

function Export-UsageDetailReport {
    param([Parameter(Mandatory)] [string] $Period)

    $reportSet = Get-UsageReportSet -Period $Period
    $sourceCounts = @($reportSet.Keys | ForEach-Object { '{0}={1}' -f $_, @($reportSet[$_]).Count })
    Write-Log "Usage report row counts: $($sourceCounts -join '; ')" 'INFO' 'Reporting'

    # Counted from the set rather than hardcoded, so adding a sixth report never leaves a message or the
    # partial-coverage test below claiming the old number.
    $reportCount = @($reportSet.Keys).Count
    $reportsWithRows = @($reportSet.Keys | Where-Object { @($reportSet[$_]).Count -gt 0 }).Count
    # Published for the 'Reading service usage' phase line. Set here because this is the only place that
    # knows how many reports came back with data, and the caller must state it even if the sheet throws.
    $script:UsageReportCount = $reportCount
    $script:UsageReportsWithRows = $reportsWithRows

    $totalSourceRows = 0
    foreach ($key in $reportSet.Keys) { $totalSourceRows += @($reportSet[$key]).Count }
    if ($totalSourceRows -eq 0) {
        Write-Log "None of the $reportCount usage reports returned any rows. The Other Service Usage status sheet was not written." 'WARN' 'Detail'
        Write-Log "All $reportCount usage reports returned zero rows." 'WARN' 'Reporting'
        return
    }

    $result = New-UsageDetailRows -ReportSet $reportSet -Period $Period
    $usageRows = @($result.Rows)
    if ($usageRows.Count -eq 0) {
        Write-Log 'No usage detail rows were produced. The Other Service Usage status sheet was not written.' 'WARN' 'Detail'
        Write-Log 'Usage detail merge produced zero rows.' 'WARN' 'Reporting'
        return
    }

    if ($usageRows.Count -ge $Config.MaxExcelRows) {
        Write-Log "Other Service Usage status sheet skipped: the row count ($($usageRows.Count)) exceeds the Excel limit of $($Config.MaxExcelRows). The $reportCount source CSVs in $($Config.OutputPath) still hold the full detail." 'WARN' 'Detail'
        Write-Log "Skipped Other Service Usage status worksheet; rows=$($usageRows.Count) exceeds MaxExcelRows=$($Config.MaxExcelRows)." 'WARN' 'Reporting'
        return
    }

    try {
        $usageRows | Export-Excel -Path $Config.ReportXlsxPath -WorksheetName 'Other Service Usage status' -AutoSize -FreezeTopRow -BoldTopRow -ClearSheet -ErrorAction Stop
    }
    catch {
        if (Test-FileLockError -Exception $_.Exception) {
            throw (New-AssessmentException -Message "'$($Config.ReportXlsxPath)' could not be written. The file appears to be open in another program (for example Excel). Close the file and run the script again." -Category 'File System' -Stage 'XLSX Export' -Retryable $false)
        }
        throw (New-AssessmentException -Message "The Other Service Usage status worksheet failed: $($_.Exception.Message)" -Category 'Reporting' -Stage 'XLSX Export' -Retryable $false)
    }

    Write-Log "Other Service Usage status sheet written: $($usageRows.Count) row(s) merged from $reportsWithRows of $reportCount usage reports." 'SUCCESS' 'Detail'
    Write-Log "Other Service Usage status worksheet written. Rows=$($usageRows.Count); Sources=$($sourceCounts -join '; ')" 'SUCCESS' 'Reporting'

    if (@($reportSet['Copilot']).Count -eq 0) {
        Add-UserNote 'The Copilot columns are blank because the Copilot usage report returned no data. This is not evidence of unused Copilot licenses. Many tenants cannot serve this report at all.'
        Write-Log 'The Copilot usage report returned zero rows. The Copilot columns are blank for every user.' 'WARN' 'Reporting'
    }

    # Match quality, stated plainly. A row present in only one report is not a user who used only one
    # workload but a user the other reports did not return, and the difference matters to anyone about to
    # reclaim a licence based on these blanks.
    $partial = @($usageRows | Where-Object { $_.SourceReportCount -lt $reportCount }).Count
    if ($partial -gt 0) {
        Add-UserNote "$partial of $($usageRows.Count) rows on the usage sheet came from some but not all of the reports. A blank cell there means not reported, not unused. The SourceReports column names the reports that covered each person."
        Write-Log "Other Service Usage status rows with partial source coverage: $partial / $($usageRows.Count)" 'INFO' 'Reporting'
    }

    if ($result.MaskedRows -gt 0) {
        Add-UserNote "$($result.MaskedRows) usage rows have no name or email address, because your tenant hides user details in reports. Each row is kept separate rather than merged, so nobody is mistaken for someone else."
        Write-Log "Other Service Usage status rows with a masked-looking UPN: $($result.MaskedRows)" 'WARN' 'Reporting'
    }

    if ($script:ReportFieldMisses.Count -gt 0) {
        $missText = @($script:ReportFieldMisses.Keys | Sort-Object | ForEach-Object { '{0} ({1} row(s))' -f $_, $script:ReportFieldMisses[$_] }) -join '; '
        Add-UserNote "Some columns are blank because Microsoft appears to have renamed them in the source report: $missText"
        Write-Log "Other Service Usage status unresolved report fields: $missText" 'WARN' 'Reporting'
    }
}

function Export-ServiceUsageSummarySheet {
    param([Parameter(Mandatory)] [object] $Correlation)

    # The per-service-plan rollup that until now only reached ServiceUsageSummary.csv. Same object:
    # $Correlation.Summary is built during correlation, so this adds no Graph calls and no second pass.
    #
    # Called first in the pipeline on purpose. ImportExcel appends worksheets in write order, so a tab's
    # position is decided by when it is written and nothing else; move this call and the tab moves. On a
    # pre-existing workbook -ClearSheet drops and re-adds each sheet, pushing it to the end, so writing
    # all four in the wanted order is what makes the finished tab order converge on it.
    $summaryRows = @($Correlation.Summary)
    if ($summaryRows.Count -eq 0) {
        Write-Log 'No service plan rollup rows were produced. The Service Usage Summary sheet was not written.' 'WARN' 'Detail'
        Write-Log 'Service usage summary produced zero rows.' 'WARN' 'Reporting'
        return
    }

    # No MaxExcelRows guard here, unlike the three per-user sheets: one row per SKU/service-plan pair is
    # bounded by the tenant's plan catalog, so it cannot approach Excel's limit at any user count.
    try {
        $summaryRows | Export-Excel -Path $Config.ReportXlsxPath -WorksheetName 'Service Usage Summary' -AutoSize -FreezeTopRow -BoldTopRow -ClearSheet -ErrorAction Stop
    }
    catch {
        if (Test-FileLockError -Exception $_.Exception) {
            throw (New-AssessmentException -Message "'$($Config.ReportXlsxPath)' could not be written. The file appears to be open in another program (for example Excel). Close the file and run the script again." -Category 'File System' -Stage 'XLSX Export' -Retryable $false)
        }
        throw (New-AssessmentException -Message "The Service Usage Summary worksheet failed: $($_.Exception.Message)" -Category 'Reporting' -Stage 'XLSX Export' -Retryable $false)
    }

    Write-Log "Service Usage Summary sheet written: $($summaryRows.Count) service plan row(s)." 'SUCCESS' 'Detail'
    Write-Log "Service Usage Summary worksheet written. Rows=$($summaryRows.Count)" 'SUCCESS' 'Reporting'

    # Stated on screen because the column is easy to read as the opposite of what it is. EnabledPercent
    # is EnabledForUsers/TotalAssigned, provisioning coverage, and says nothing about whether anyone
    # opened the app. The sheet this replaces carried UsagePercentOfEnabled, which did mean usage, so
    # anyone comparing an old workbook to a new one could read a provisioned plan as a reclaim candidate.
    Add-UserNote 'On the Service Usage Summary sheet, EnabledPercent means how many people have the service switched on, not how many people use it. A service can show 100% and still be unused. Actual usage is on the Other Service Usage status sheet.'
}

function Export-UserLicenseSummary {
    param([Parameter(Mandatory)] [object[]] $Users)

    # One row per user: what they hold and how many of their services are enabled. Cheap, since the data
    # is already in memory.
    $rows = foreach ($user in $Users) {
        $assigned = @()
        $licProp = $user.PSObject.Properties['assignedLicenses']
        if ($licProp -and $licProp.Value) { $assigned = @($licProp.Value) }

        $skuNames = @()
        $disabledCount = 0
        $planCount = 0
        foreach ($lic in $assigned) {
            $skuId = [string]$lic.skuId
            $skuNames += if ($script:SkuNameById.ContainsKey($skuId)) { $script:SkuNameById[$skuId] } else { "UnknownSku($skuId)" }
            $dpProp = $lic.PSObject.Properties['disabledPlans']
            if ($dpProp -and $dpProp.Value) { $disabledCount += @($dpProp.Value).Count }
            if ($script:CatalogBySkuId.ContainsKey($skuId)) { $planCount += @($script:CatalogBySkuId[$skuId]).Count }
        }

        [pscustomobject]@{
            UserPrincipalName   = [string]$user.userPrincipalName
            DisplayName         = [string]$user.displayName
            AccountEnabled      = $user.accountEnabled
            LicenseCount        = $assigned.Count
            AssignedSkus        = ($skuNames -join ';')
            TotalServicePlans   = $planCount
            DisabledServicePlans = $disabledCount
            EnabledServicePlans = ($planCount - $disabledCount)
        }
    }

    $rows = @($rows)
    try {
        $rows | Export-Csv -LiteralPath $Config.UserLicenseCsvPath -NoTypeInformation -Encoding UTF8 -Force -ErrorAction Stop
    }
    catch {
        if (Test-FileLockError -Exception $_.Exception) {
            throw (New-AssessmentException -Message "Cannot write '$($Config.UserLicenseCsvPath)'. The file appears to be open in another program (for example Excel). Close the file and run the script again." -Category 'File System' -Stage 'User License Export' -Retryable $false)
        }
        throw (New-AssessmentException -Message "The user license CSV export failed: $($_.Exception.Message)" -Category 'Reporting' -Stage 'User License Export' -Retryable $false)
    }

    Write-Log "Per-user license summary written: $($Config.UserLicenseCsvPath) ($($rows.Count) user(s))." 'SUCCESS' 'Detail'
    Write-Log "User license summary export completed. Rows=$($rows.Count)" 'SUCCESS' 'Reporting'
}

function Show-Report {
    # Opens the finished workbook for the operator. Decided by looking at the disk rather than a flag, for
    # the same reason Write-RunSummary does: a run that skipped every sheet for the row limit writes no
    # workbook, and saying otherwise sends the reader hunting for a file that was never created.
    if (-not (Test-Path -LiteralPath $Config.ReportXlsxPath)) {
        Write-Log 'No workbook was written, so there is nothing to open.' 'INFO' 'Reporting'
        return
    }

    # Handed to explorer.exe rather than started as EXCEL.EXE by path, because of elevation. This script
    # runs elevated (region 0) and a child process inherits that, so launching Excel directly would open
    # it as administrator: no mapped drives, no drag-and-drop with a normal window, and OneDrive AutoSave
    # unhappy on a synced folder, which is where this workbook lands. explorer.exe already runs at the
    # operator's own integrity level, so the workbook opens as it would on a double-click.
    #
    # The cost is that it opens in whatever owns .xlsx. If Excel were removed or another product claimed
    # the extension, the file would open elsewhere and nothing here would say so. Accepted: the
    # alternative was locating EXCEL.EXE in the registry, at the price of an elevated Excel every run.
    #
    # Non-fatal by design, like the sleep-prevention calls: the workbook is written, and the catch below
    # is what puts its path on screen now that the summary no longer lists it, so a failure here costs
    # the operator one double-click.
    try {
        Start-Process -FilePath 'explorer.exe' -ArgumentList "`"$($Config.ReportXlsxPath)`"" -ErrorAction Stop
        Write-Log "Opened the report for the operator: $($Config.ReportXlsxPath)" 'SUCCESS' 'Reporting'
    }
    catch {
        # Reported as a real error, to Errors.log and the screen, rather than a quiet log line: the
        # operator has been told the run finished and is waiting for a window that is not coming, and the
        # path is what lets them finish by hand.
        #
        # This catch is narrow. explorer.exe reports success the moment it accepts the file, so this fires
        # only when the shell itself could not be started; an Excel that opens and then refuses the
        # workbook looks like success from here. That is the limit of opening by association.
        #
        # The run still reports success, and has to. The workbook is written and correct, so throwing here
        # would send the top-level catch into Write-RunSummary -Failed, telling the reader the files are
        # partial and not to report from them, which would be false.
        Write-ErrorLog -Message "The report was written but could not be opened automatically. Open it manually: $($Config.ReportXlsxPath)" -Stage 'Opening the report' -Category 'Reporting' -Exception $_.Exception
    }
}

function Invoke-Assessment {
    for ($attempt = 1; $attempt -le $Config.MaxAttempts; $attempt++) {
        $script:Attempt = $attempt

        # Counters are per-attempt so a retry does not double-count.
        $script:UsersWithoutLicense = 0
        $script:UnknownSkuRefs = 0
        # Same reasoning as the group-name cache below: this set suppresses a repeat log line, so carrying
        # it across a retry would leave the attempt that produced the workbook with no record of which
        # SKUs were unknown.
        $script:UnknownSkuIdsSeen = @{}
        # The "group names are showing as object IDs" note is added once, when a lookup is first refused.
        # Keeping the cache across a retry would short-circuit every lookup, so the note would never be
        # re-added and the workbook would ship GUIDs with nothing explaining why. Re-resolving a handful
        # of groups costs one call each.
        $script:LicensingGroupNames = @{}
        $script:GroupLookupBlocked = $false

        # Phase 1 (prerequisites) ran once before this loop, so phases restart from there. Notes are
        # cleared too: they describe the data a completed attempt produced, and a retry replaces that data
        # wholesale, so carrying them over reports the abandoned attempt's caveats against the new workbook.
        $script:PhaseIndex = 1
        $script:UserNotes.Clear()
        # Cleared so this attempt's failure is shown even if it is worded identically to the previous
        # attempt's. The dedupe in Write-ErrorLog is only there to stop the top-level catch echoing
        # the same error a second time within one attempt.
        $script:LastConsoleError = ''
        if ($attempt -gt 1) {
            # Printed even though retry notices are otherwise log-only: without it the phase list
            # visibly restarts at [2/5] with nothing on screen explaining why.
            Write-Host ''
            Write-Host "$($script:PhaseIndent)Retrying: attempt $attempt of $($Config.MaxAttempts)."
        }

        try {
            Start-Phase 'Signing in'
            Connect-AssessmentGraph
            Test-RequiredScopes
            Test-AuthorizationReadiness
            $signedInAs = if (($null -ne $script:GraphContext) -and $script:GraphContext.Account) { $script:GraphContext.Account } else { 'application credentials' }
            Complete-Phase "signed in as $signedInAs"

            # Grouped under one phase because to the reader it is one step, read the tenant's licences and
            # work out who has what, even though it is four calls.
            Start-Phase 'Reading licenses'
            Get-SubscribedSkusData -Path $Config.SkuCsvPath | Out-Null
            $users = @(Get-AllUserLicenseAssignment)

            $correlation = New-ServiceUsageRows -Users $users

            Export-UserLicenseSummary -Users $users

            # Written first, which is the only reason it is the workbook's first tab: ImportExcel appends
            # worksheets in write order. The requested order is Service Usage Summary, Users and Assigned
            # Services, M365 Activity, Other Service Usage status, which is the order these four
            # Export-Excel calls run in, so moving any of them reorders the workbook.
            #
            # Its data is $correlation, already in memory, so it can run this early with no second pass and
            # no extra Graph call. Still best-effort in its own try/catch: a rollup of data the later
            # sheets deliver in full must not fail a completed run, and running first means an unhandled
            # failure here would cost the whole workbook rather than one tab.
            try {
                Export-ServiceUsageSummarySheet -Correlation $correlation
            }
            catch {
                Write-Log "Service Usage Summary sheet skipped: $($_.Exception.Message)" 'WARN' 'Detail'
                Write-Log "Service Usage Summary sheet skipped: $($_.Exception.Message)" 'WARN' 'Reporting'
            }

            Export-ServiceUsageReport -Correlation $correlation
            Complete-Phase ('{0:N0} users, {1} license type(s)' -f $users.Count, $script:SkuNameById.Count)

            Start-Phase 'Reading service usage'

            # Independent and best-effort: a failure here (missing Reports.Read.All consent, an empty or
            # throttled report, concealment) must not fail the core assessment above and must not trigger
            # this function's MaxAttempts retry. Either would let an optional, historically unreliable data
            # source decide whether the reliable licence data is delivered at all.
            try {
                $activityRows = Get-ActiveUserDetailReport -Path $Config.ActiveUserReportCsvPath -Period $Config.ReportPeriod
                Export-ActivityReport -Rows $activityRows -Period $Config.ReportPeriod
            }
            catch {
                Write-Log "M365 Activity sheet skipped: $($_.Exception.Message)" 'WARN' 'Detail'
                Write-Log "M365 Activity sheet skipped: $($_.Exception.Message)" 'WARN' 'Reporting'
            }

            # Same best-effort contract as the M365 Activity sheet above, in its own try/catch rather than
            # sharing that one so a failure in either sheet does not stop the other being written.
            try {
                Export-UsageDetailReport -Period $Config.ReportPeriod
            }
            catch {
                Write-Log "Other Service Usage status sheet skipped: $($_.Exception.Message)" 'WARN' 'Detail'
                Write-Log "Other Service Usage status sheet skipped: $($_.Exception.Message)" 'WARN' 'Reporting'
            }
            # Counted from what the reports actually returned, so a tenant that cannot serve Copilot
            # reads '4 of 5' rather than silently implying full coverage.
            Complete-Phase ('{0} of {1} usage reports available' -f $script:UsageReportsWithRows, $script:UsageReportCount)

            Start-Phase 'Checking the report'

            # Every sheet has been written by this point. This phase inspects the result, so it reads the
            # finished workbook rather than counting the calls above: a sheet skipped for the row limit, or
            # one whose export failed, must not be claimed as written.
            $sheetsWritten = 0
            $sheetOrder = @()
            if (Test-Path -LiteralPath $Config.ReportXlsxPath) {
                try {
                    # Sorted by Index because tab order is what is being checked; the order the objects
                    # come back in is not something to rely on.
                    $sheetOrder = @(Get-ExcelSheetInfo -Path $Config.ReportXlsxPath -ErrorAction Stop |
                        Sort-Object Index | ForEach-Object { $_.Name })
                    $sheetsWritten = $sheetOrder.Count
                }
                catch { $sheetsWritten = 0 }
            }

            # Closed before the tab-order check below so the count lands on the [5/5] line itself. A
            # Write-Terminal while the phase line is still open ends that line, which sends the result to
            # the '-> Checking the report: ...' continuation underneath the [OK] instead.
            if ($sheetsWritten -gt 0) { Complete-Phase "$sheetsWritten sheet(s) written" }
            else { Complete-Phase 'no workbook written; see the notes below' }

            # Tab order is a side effect of write order, so it is easy to break by moving an Export-Excel
            # call. Checked here so the run says so rather than leaving it to be noticed in the workbook.
            if ($sheetsWritten -gt 0) {
                $wanted = @('Service Usage Summary', 'Users and Assigned Services', 'M365 Activity', 'Other Service Usage status')
                # Only the sheets this workbook has, in the order they should appear, so a run that
                # legitimately skipped one is not reported as mis-ordered.
                $expected = @($wanted | Where-Object { $sheetOrder -contains $_ })
                $actual = @($sheetOrder | Where-Object { $wanted -contains $_ })
                if (($expected -join '|') -ne ($actual -join '|')) {
                    Add-UserNote "The report tabs are not in the usual order (found: $($actual -join ', ')). The data is correct. Only the tab order is affected."
                    Write-Log "The worksheet order is unexpected. Expected='$($expected -join ', ')'; Actual='$($actual -join ', ')'" 'WARN' 'Reporting'
                }
                else {
                    # One of only two lines in the script that go to the screen: the four tabs came out in
                    # the order the downstream pivots expect. Paired with an explicit Write-Log because
                    # Write-Terminal writes to the screen and nothing else.
                    Write-Terminal "Worksheet order verified: $($actual -join ' | ')" 'Success'
                    Write-Log "Worksheet order verified. Actual='$($actual -join ', ')'" 'SUCCESS' 'Reporting'
                }
            }

            Write-Log "Assessment completed successfully on attempt $attempt." 'SUCCESS' 'Detail'
            return
        }
        catch {
            $meta = Get-ExceptionMetadata -Exception $_.Exception
            Write-ErrorLog -Message $_.Exception.Message -Stage $meta.Stage -Category $meta.Category -Exception $_.Exception

            # An Authorization failure means the signed-in account is missing a permission this run
            # needs. Another attempt with the same account cannot change that, and every Authorization
            # throw site marks HardStop, so it stops on the line below with the missing permission named.
            if ($meta.HardStop -or -not $meta.Retryable -or $attempt -ge $Config.MaxAttempts) { throw }
            $delay = [math]::Min([math]::Pow(2, $attempt - 1) * $Config.RetryBaseSeconds, $Config.RetryMaxSeconds)
            Write-Log "Attempt $attempt failed with a retryable error. Retrying in $delay second(s)..." 'WARN' 'Detail'
            Start-Sleep -Seconds $delay
        }
        finally {
            try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch { }
        }
    }
}

#region 7. MAIN EXECUTION
Suspend-SystemSleep
try {
    Initialize-Logs
    Write-Banner

    Start-Phase 'Checking prerequisites'
    Test-Preflight
    Complete-Phase 'done'

    Invoke-Assessment
    Write-RunSummary
    # Last thing in the successful path, after the summary has printed rather than at the end of the
    # reporting phase: the closing lines name the file, the notes and the log locations, and Excel taking
    # focus first would push all three past the reader. Not reached on the failure path below, which says
    # the files may be partial, so opening one there would invite what that message exists to prevent.
    Show-Report
}
catch {
    $meta = Get-ExceptionMetadata -Exception $_.Exception
    Write-ErrorLog -Message "$($_.Exception.Message) (line $($_.InvocationInfo.ScriptLineNumber))" -Stage $meta.Stage -Category $meta.Category -Exception $_.Exception
    # Summarised even on failure: the operator still needs to know how far it got, where the logs are,
    # and which notes were already raised. Exiting straight to a bare stack trace hides all three.
    Write-RunSummary -Failed
    exit 1
}
finally {
    Resume-SystemSleep
    # Last thing that happens, on every path. In the finally rather than at the end of the try so the
    # failure path above, which ends in exit 1, holds the window open too: exit runs finally first, so the
    # error and the partial-file warning are read before the window goes. Ordered after Resume-SystemSleep
    # so the sleep request is released while this waits on a human.
    Wait-ForOperator
}
