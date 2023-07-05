

<#
.SYNOPSIS
This script is designed to query O365 groups and discover groups that were created by the OneDrive LTI to support LMS integration. 

.EXAMPLE
.\Get-OneDriveLTI-Groups.ps1 

.PARAMETER LMS
 possible LMS issuerName string values are:
  Canvas
  Schoology
  Blackboard
  Generic

.PARAMETER CsvLogFilePath
A string that is a full valid path to the log file that the script will create and write each group discovered into.

.PARAMETER CsvLogDelimiter
The character to use as a delimeter in the log file that the script creates. Must be a single character surrounded by single quotes. Default is a comma character (',')

.EXAMPLE
PS> .\Get-OneDriveLTI-Groups.ps1 -LMS 'Canvas' -CsvLogFilePath 'C:\logs\OTLTIGroupList.csv' -CsvLogFileDelimiter ','

.NOTES
========================
 Required Prerequisites
========================
1.  PowerShell version 7 is required to run this script.  To learn how to install PowerShell 7 on your OS, please visit:  https://learn.microsoft.com/shows/it-ops-talk/how-to-install-powershell-7
2.  Set exection policy to Unrestricted for scope of the CurrentUser. example:

     Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

3. Install Microsoft.Graph module with CurrentUser scope. example:

    Install-Module Microsoft.Graph -Scope CurrentUser

4. Import the Micrsoft.Graph.Groups module. example:

    Import-Module Microsoft.Graph.Groups 

5. Check that you can connect to your Microsfot Graph environment from the PowerShell module to make sure everything is set up correctly.
    a. Open a separate PowerShell session
    
    b. Execute: "Connect-MgGraph -Scopes "Group.Read.All"" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up

6. After you have completed the above without errors, you are ready to run this script.
========================
#>

[cmdletbinding()]
param(
    [Parameter(Mandatory=$True)]
    [ValidateSet('Canvas','Schoology','Blackboard','Generic')]
    [String]$LMS,

    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]$CsvLogFilePath,

    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]$CsvLogDelimiter = ','
)

#PowerShell major version required for this script
$majorVersionRequired = 7

function ImportOrInstallModule {
    param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )
    if (-not (Get-Module -ListAvailable -Name $Name)) {
        Import-Module $Name -ErrorAction SilentlyContinue 
        if ($error){
            if (Find-Module -Name $Name | Where-Object {$_.Name -eq $Name}) {
                Install-Module -Name $Name -Force -Scope CurrentUser
            }
            else {
                Write-Error "Module $Name not installed. You must locate and install this module before continuing"
                Exit
            }
        }
    }
}

#main process
$version = $PSVersionTable.PSVersion
Write-Host "PowerShell Version " $version
if ($version.Major -lt $majorVersionRequired)
{
    Write-Error "PowerShell version $majorVersionRequired or higher is required to run this script"
    Exit
}

#Import MS Graph PowerShell SDK module
ImportOrInstallModule -Name "Microsoft.Graph"

$details = $null
$groups = $null
$issuer = $null

#Set up logging ...
if ($CsvLogFilePath) {
    $answer = 'y'
    if (Test-Path -Path $CsvLogFilePath) {
        $answer = 'n'
        $Cursor = [System.Console]::CursorTop
        Do {
        [System.Console]::CursorTop = $Cursor
        $answer = Read-Host -Prompt 'Found existing log file. Overwrite existing file? (y/n)'
        $answer = $answer.ToLowerInvariant()
        }
        Until ($answer -eq 'y' -or $answer -eq 'n')
    }
    else {
       if (-not (Test-Path -Path $CsvLogFilePath -IsValid)) {
         Write-Error "The log file path specified is invalid."
         Exit
       }
    }
    if ($answer -eq 'y') {
        $columns= @(         
            "GroupId",
            "GroupName",       
            "GroupDescription"                 
        )
        Set-Content $CsvLogFilePath -Value ($columns -Join $CsvLogDelimiter)-Force -Encoding utf8 -ErrorAction Stop
    } 
    else {
        $CsvLogFilePath = $null
    }
}

Write-Host "Connecting ..."
Connect-MgGraph -Scopes "Group.Read.All" -ForceRefresh

$issuer = "Description:issuerName: " + $LMS

Write-Host "Listing Groups connected to " $LMS "LMS Courses..."
$groups = Get-MgGroup -Filter "startsWith(DisplayName,'Course:')" -Search $issuer -ConsistencyLevel eventual | Select-Object Id,Description,DisplayName 

$cnt = 0
foreach($group in $groups)
{ 
     $cnt = $cnt + 1
     Write-Host $cnt " | " $group.Id " | " $group.DisplayName " | " $group.Description

    if ($CsvLogFilePath) {
        $details = [ordered] @{            
            GroupId = $group.Id 
            GroupName = $group.displayName       
            GroupDescription = $group.Description                 
        }
            
        New-Object PSObject -Property $details | Export-Csv -Path $CsvLogFilePath -Delimiter $CsvLogDelimiter -NoTypeInformation -Append -Force -Encoding utf8 -UseQuotes AsNeeded
    }
}
if ($cnt -eq 0)
{
    Write-Host "No groups were found."
}

Write-Host "Disconnecting ..."
Disconnect-MgGraph