<# 
Script Name:
Get-All_Users_With_And_Without_Classroom.ps1

Written By: 
Bill Sluss and adapted by Bheemanapally Ramchandram

Change Log:
Version 1.0, 12/05/2016 - First Draft
Version 2.0, 03/22/2022 - Updated script to use Graph API instead of ADAL 
#>

<#
.SYNOPSIS
    Get-All_Users_With_and_Without_Classroom.ps1 script is designed to export all users within Graph API, and break them into 2 lists. Users with Classroom and User without Classroom. The result of this script will be 2 CSV files. The first file is called Users_with_classroom.csv, and a second file called Users_without_classroom.csv.
.EXAMPLE
    .\Get-All_Users_With_and_Without_Classroom.ps1
#>

Param (
    [switch] $PPE,
    [Parameter(Mandatory = $false)]
    [string] $OutFolder = ".",
    # Parameter to specify whether to download the script with common functions or not
    [switch] $skipDownloadCommonFunctions
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

$logFilePath = "$OutFolder\SDSAllusers.log"
$eduObjectType= "Users"

if ($skipDownloadCommonFunctions -eq $false) {
    # Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose
        "Grabbed 'common.ps1' to the directory alongside the executing script"
        Write-Output "[$(get-date -Format G)] Grabbed 'common.ps1' to the directory alongside the executing script. common.ps1 script contains common functions, which can be used by other SDS scripts" | out-file $logFilePath -Append
    } 
    catch {
        throw "Unable to download common.ps1"
    }
}

#import file with common functions
. .\common.ps1

function Get-PrerequisiteHelp {
    Write-Output @"
========================
 Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'. 
PowerShell 7 and later is the recommended PowerShell version for use with the Microsoft Graph PowerShell SDK on all platforms (https://docs.microsoft.com/en-us/graph/powershell/installation#supported-powershell-versions).

2. Make sure to download common.ps1 to the same folder of the script which has common functions needed.  https://github.com/OfficeDev/O365-EDU-Tools/blob/master/SDS%20Scripts/common.ps1
Command to download the function: Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes GroupMember.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell sesion without error, you are correctly set up

4. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working

(END)
========================
"@
}

function Get-Users($graphEndPoint, $eduObjectType, $refreshToken, $graphScopes, $logFilePath) {

    $endpointUrl = "$graphEndPoint/beta/$eduObjectType"

    $fileName = $eduObjectType + ".csv"
    $filePath = Join-Path $OutFolder $fileName

    $objectProperties = @()
    $objectProperties += @{N='id';E={$_.Id}}, @{N='displayName';E={$_.DisplayName}}, @{N='Mail';E={$_.Mail}}, @{N='jobTitle';E={$_.JobTitle}}

    PageAll-GraphRequest-WriteToFile $endpointUrl $refreshToken 'GET' $graphScopes $logFilePath $filePath $objectProperties $eduObjectType | out-null

    return $filePath
}

function Get-UserClass($allUsers, $graphEndPoint, $refreshToken, $graphScopes, $logFilePath) {
    #Create the arrays
    $HasClassroom = @()
    $NoClassroom = @()

    foreach($user in $allUsers) {
        $userMembersUri = $graphEndPoint + '/beta/users/' + $user.Id +'/memberOf/microsoft.graph.group'
        $userMembership = PageAll-GraphRequest $userMembersUri $refreshToken 'GET' $graphScopes $logFilePath
        $userMembershipCount = $userMembership.Count
        Write-Output "Retrieved $($userMembershipCount) user groups."
    
        if ($userMembershipCount -gt 0) {
            $HasClassroom += New-Object PsObject -Property @{"Username"="$($user.DisplayName)";"ID"="$($user.id)";"Mail"="$($user.Mail)";"JobTitle"="$($user.jobTitle)"; }
        }
        else {
            $NoClassroom += New-Object PsObject -Property @{"Username"="$($user.DisplayName)";"ID"="$($user.id)";"Mail"="$($user.Mail)";"JobTitle"="$($user.jobTitle)"; }
        }        
    }
	
    #Export the results
    $HasClassroom | Export-CSV "$OutFolder\Users_with_classroom.csv" -NoTypeInformation
    $NoClassroom | Export-CSV "$OutFolder\Users_without_classroom.csv" -NoTypeInformation
}

# Main function
$graphEndPoint = $GraphEndpointProd

if ($PPE) {
    $graphEndPoint = $GraphEndpointPPE
}

#Scopes used to request access to data
$graphScopes = "GroupMember.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All"

try {
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch {
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-PrerequisiteHelp | Out-String | Write-Error
    throw
}

# Create output folder if it does not exist
if ((Test-Path $OutFolder) -gt 1) {
    mkdir $OutFolder;
}

$refreshToken = Initialize $graphScopes

$OutputFileName = Get-Users $graphEndPoint $eduObjectType $refreshToken $graphScopes $logFilePath
$allUsers = import-csv $OutputFileName

Get-UserClass $allUsers $graphEndPoint $refreshToken $graphScopes $logFilePath

Write-Output "`nDone.`n"

Write-Output "Please run 'disconnect-graph' if you are finished making changes.`n"