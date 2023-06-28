<#
.SYNOPSIS
This script is designed to query O365 groups and discover groups that were created by the OneDrive LTI to support LMS integration and write informaion about the groups found to a CSV file. 

.EXAMPLE
.\Get-OneDriveLTI-Groups.ps1 

.PARAMETER LMS
 possible LMS issuerName values are:
  Canvas
  Schoology
  Blackboard
  Generic

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
    [ValidateNotNullOrEmpty()]
    [string]$LMS
)

if ($PSVersionTable.PSVersion -lt 7)
{
    Write-Error "PowerShell version 7.xx is required to run this script"
    Return
}

#set this to a file path if you want a CSV output, otherwise, set to '' or $null for no logging, the script will prompt to replace if exists
$csvLogFilePath = "C:\ODLTIGroupLog.csv"
$csvLogDelimiter = ','

if (Get-Module -ListAvailable -Name Microsoft.Graph) {
    Write-Host "Microsoft.Graph Module Installed."
} 
else {
    Write-Host "Installing Microsoft.Graph Module..."
    Install-Module Microsoft.Graph -Scope CurrentUser
}

if (Get-Module -ListAvailable -Name Microsoft.Graph.Groups) {
    Write-Host "Microsoft.Graph.Groups Module Imported."
}
else {
    Write-Host "Importing Microsoft.Graph.Groups Module...."
    Import-Module Microsoft.Graph.Groups
}

$details = $null
$groups = $null
$issuer = $null

#Set up logging ...
if ($csvLogFilePath) {
    $answer = 'y'
    if (Test-Path -Path $csvLogFilePath) {
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
       if (-not (Test-Path -Path $csvLogFilePath -IsValid)) {
         Write-Error "The log file path specified is invalid."
         Return
       }
    }
    if ($answer -eq 'y') {
        Set-Content $csvLogFilePath -Value ('GroupId' + $csvLogDelimiter + 'GroupName' + $csvLogDelimiter + 'GroupDescription') -Force -Encoding utf8 -ErrorAction Stop
    } 
    else {
        $csvLogFilePath = $null
    }
}

Write-Host "Connecting ..."
Connect-MgGraph -Scopes "Group.Read.All"

$issuer = "Description:issuerName: " + $LMS

Write-Host "Listing Groups connected to " $LMS "LMS Courses..."
$groups = Get-MgGroup -Filter "startsWith(DisplayName,'Course:')" -Search $issuer -ConsistencyLevel eventual | Select-Object Id,Description,DisplayName 

$cnt = 0
foreach($group in $groups)
{ 
     $cnt = $cnt + 1
     Write-Host $cnt " || " $group.Id " || " $group.DisplayName " || " $group.Description

    if ($csvLogFilePath) {
        $details = [ordered] @{            
            GroupId = $group.Id 
            GroupName = $group.displayName       
            GroupDescription = $group.Description                 
        }
            
        New-Object PSObject -Property $details | Export-Csv -Path $csvLogFilePath -Delimiter $csvLogDelimiter -NoTypeInformation -Append -Force -Encoding utf8 -UseQuotes AsNeeded
    }
}
if ($cnt -eq 0)
{
    Write-Host "No groups were found."
}

Write-Host "Disconnecting ..."
Disconnect-MgGraph