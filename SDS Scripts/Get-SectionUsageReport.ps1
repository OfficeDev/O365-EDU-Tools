<#
.SYNOPSIS
This script is designed to generate section usage report

.DESCRIPTION
The script will query all SDS created sections and write their properties to a file

.PARAMETER PPE
Used to refer pre production environment

.PARAMETER skipToken
Used to start where the script left off fetching the users in case of interruption.  The value used is nextLink in the log file, otherwise use default value of "" to start from the beginning.

.PARAMETER outFolder
The script will create a CSV file at this location ".\"

.PARAMETER graphVersion
The version of the Graph API.

.PARAMETER graphScopes
Scopes used to request access to data

.PARAMETER skipDownloadCommonFunctions
Parameter to specify whether to download the script with common functions or not

.EXAMPLE
.\Get-SectionUsageReport.ps1

.NOTES
***This script may take a while.***

========================
 Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'.

2. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session

    b. Execute: "connect-graph -scopes Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All" to bring up a sign in UI. 

    c. Sign in with any tenant administrator credentials

    d. If you are returned to the PowerShell session without error, you are correctly set up

3. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working

4.  Please visit the following link if a message is received that the license cannot be assigned.
    https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-groups-resolve-problems
#>

Param (
    [switch] $PPE = $false,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory = $false)]
    [string] $outFolder = ".\Section_Usage_Report",
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    [switch] $skipDownloadCommonFunctions
)

# Azure environment variables
$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"
$DefaultForegroundColor = "White"
$CurrentTime = $(((get-date).ToUniversalTime()).ToString("yyyy-MM-dd_HH-mm-ssZ"))
$msgLogInstanceFilename = ("SectionReportLog_" + $CurrentTime + ".log")
$msgErrorLogInstanceFilename = ("SectionReportErrorLog_" + $CurrentTime + ".log")
$outputFilename = "SectionUsageReport.csv"

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0) {
    Write-Host "Creating output folder path"
    mkdir $outFolder | Out-Null;
}

if ($skipDownloadCommonFunctions -eq $false) {
    # Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose
        "Grabbed 'common.ps1' to the directory alongside the executing script"
        Write-Output "[$(get-date -Format G)] Grabbed 'common.ps1' to the directory alongside the executing script. common.ps1 script contains common functions, which can be used by other SDS scripts" | out-file $msgErrorLogInstanceFilename -Append
    } 
    catch {
        throw "Unable to download common.ps1"
    }
}

#import file with common functions
. .\common.ps1

<#
.Synopsis
    Write messages to log file and console
#>
function Write-Message($message, $foregroundColor) {
    switch ($foregroundColor) {
        Red { $type = "ERROR" }
        Green { $type = "SUCCESS" }
        Cyan { $type = "ACTION" }
        default { $type = "INFO" }
    }

    try {
        $messageToLog = "[ $type ]: $message"
        if ($type -eq "ERROR") {
            Write-ErrorLog $messageToLog
        }
        else {
            Write-Log $messageToLog
        }

        if ($null -eq $foregroundColor) {
            $foregroundColor = $defaultForegroundColor
        }

        Write-Host $message -ForegroundColor $foregroundColor
    }
    catch { }
}
<#
.Synopsis
    Writes messages to log file
#>
function Write-Log($message) {
    $logFile = Join-Path $outFolder $msgLogInstanceFilename
    $message | Out-File -FilePath $logFile -Append
}
<#
.Synopsis
    Writes messages to error log file
#>
function Write-ErrorLog($message) {
    $logFile = Join-Path $outFolder $msgErrorLogInstanceFilename
    $errorMessage = ((get-date).ToUniversalTime()).ToString("yyyy-MM-dd_HH-mm-ssZ") + $message
    $errorMessage | Out-File -FilePath $logFile -Append
    Write-Log $errorMessage
}

function Get-SectionGroups($graphEndPoint, $eduObjectType, $refreshToken, $graphScopes, $msgErrorLogInstanceFilename) {
    $uri = "$graphEndPoint/$graphVersion/groups?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'";
    $fileName = $eduObjectType +"-Usage-Report.csv"
    $filePath = Join-Path $outFolder $fileName 
    $objectProperties = @()
    $objectProperties += @{label = "Id"; expression = { $_.id } }, @{label = 'SectionId'; expression = {$_.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId}}, @{label = 'Name'; expression = {$_.displayName}}
    PageAll-GraphRequest-WriteToFile $uri $refreshToken 'GET' $graphScopes $msgErrorLogInstanceFilename $filePath $objectProperties $eduObjectType | out-null

    return $filePath
}

# Main function
$graphEndPoint = $GraphEndpointProd

if ($PPE) {
    $graphEndPoint = $GraphEndpointPPE
}

$graphScopes = "Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All"
$refreshToken = Initialize $graphScopes

try {
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
    Write-Message "Authenticated to Microsoft"
}
catch {
    Write-ErrorLog "Failed to load Microsoft Graph PowerShell Module."
    Get-Help -Name .\Get-SectionUsageReport.ps1 -Full | Out-String | Write-Error
    throw
}

# Get all Sections of Edu Object Type Section
Write-Message "Fetching Section Usage Report"
$OutputFileName = Get-SectionGroups $graphEndPoint 'Section' $refreshToken $graphScopes $msgErrorLogInstanceFilename
Write-Message "`nSection usage report successfully generated at $outputFilename `n" -ForegroundColor Green
Write-Output "`nDone.  Log files can be reviewed at $outFolder`n"
Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"