<#
-----------------------------------------------------------------------
 <copyright file="MigrateClassGroupsToTeams.ps1" company="Microsoft">
 © Microsoft. All rights reserved.
 </copyright>
-----------------------------------------------------------------------
.Synopsis
    Helps create Microsoft Teams teams from previously created Class Team unified groups

Syntax Examples and Options:
.\MigrateClassGroupsToTeams.ps1 -UPN "user@contoso.com"
#>

param
(
    [switch] $PPE = $false,
    
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",

    [Parameter(Mandatory=$true)]
    [string]$UPN,
    
    [Parameter(Mandatory=$false)]
    [string] $OutFolder = ".\MigratedGroupsToTeams",

    [Parameter(Mandatory=$false)]
    [string] $downloadFcns = "y"
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

$logFilePath = "$OutFolder\MigratedGroupsToTeams.log"

#checking parameter to download common.ps1 file for required common functions
if ($downloadFcns -ieq "y" -or $downloadFcns -ieq "yes"){
    # Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose
        "Grabbed 'common.ps1' to current directory"
    } 
    catch {
        throw "Unable to download common.ps1"
    }
}
    
#import file with common functions
. .\common.ps1

function Get-PrerequisiteHelp
{
    Write-Output @"
========================
 Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'

2.  Make sure to download common.ps1 to the same folder of the script which has common functions needed.  https://github.com/OfficeDev/O365-EDU-Tools/blob/master/SDS%20Scripts/common.ps1

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes "Team.Create, GroupMember.ReadWrite.All, Group.ReadWrite.All, User.Read, User.Read.All, User.ReadWrite.All, Directory.Read.All, Directory.ReadWrite.All, Directory.AccessAsUser.All" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up

4. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working

(END)
========================
"@
}

function Get-GroupsForUser($UPN)
{
    # --Fetch all groups for the user
    $groupPaginationLimit = 999

    $initialGroupsRequestUrl = "https://graph.microsoft.com/edu/users/$UPN/ownedObjects/microsoft.graph.group?`$top=$groupPaginationLimit"
    $groupsRequestUrl = TokenSkipCheck $initialGroupsRequestUrl $logFilePath
    $groups = New-Object System.Collections.ArrayList

    try {
        do {    
            $groupsResponse = invoke-graphrequest -Uri $groupsRequestUrl -Method 'GET' -ContentType "application/json"

            $groupsContent = $groupsResponse

            $groupsRespCount = $groupsContent.value.Count

            $groupsPageCount = 1

            [void]$groups.AddRange($groupsContent.value)
            
            Write-Output -Message "[$(get-date -Format G)] Retrieved $groupsRespCount groups" | Out-File -FilePath $logFilePath -Append 
            
            if ($groupsContent.'@odata.nextLink'){
                Write-Output -Message "[$(get-date -Format G)] Retrieved $groupsPageCount pages.  More groups to retrieve..." | Out-File -FilePath $logFilePath -Append 
            }

            $groupsRequestUrl = $groupsContent.'@odata.nextLink'
            Out-File -FilePath $logFilePath -Append -InputObject "[$(get-date -Format G)] $groupsPageCount page of groups retrieved. nextLink: $groupsRequestUrl"
            
            New-TeamsFromGroups $groups

            $groupsPageCount += 1

        } while ($groupsRequestUrl)
    } catch {
        $message = $_.Exception.Message

        Write-Host "Error while getting groups for $UPN : $message"
        return
    }

    $groupsCount = $groups.Count

    Write-Host -Message "Done fetching groups. Retrieved $groupsCount total groups." -ForegroundColor Green
}

function New-TeamsFromGroups ($groups)
{
    # --Create teams for the groups
    $createTeamUrl = "https://graph.microsoft.com/beta/teams"

    $results = New-Object System.Collections.ArrayList

    $skipped = 0
    $success = 1
    $failed = 2
    $progressCount = 0

    foreach ($group in $groups) {
        $progressCount += 1
        $i = ($progressCount / $groups.Count) * 100
        Write-Progress -Activity "Converting groups to teams" -Status "$i% complete" -PercentComplete $i
        $name = $group.displayName
        $objectId = $group.objectId

        # NOTE: conditions required for groups to become class teams may change without notice
        if ($group.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType -ne "Section") {
            Write-Verbose -Message "Skipping team $name - ObjectType must be 'Section'"
            [void]$results.Add(@($group.displayName, "skipped: ObjectType must be 'Section'", $skipped))
            continue
        }

        if (!$group.creationOptions.Contains("classAssignments")) {
            Write-Verbose -Message "Skipping team $name - creationOptions must contain 'classAssignments'"
            [void]$results.Add(@($group.displayName, "skipped: creationOptions must contain 'classAssignments", $skipped))
            continue
        }

        $createTeamBody = '{
            "template@odata.bind": "https://graph.microsoft.com/beta/teamsTemplates(''educationClass'')",
            "group@odata.bind": "https://graph.microsoft.com/v1.0/groups(''' + $objectId + ''')"
        }'

        try {
            $createTeamResponse = invoke-graphrequest -Uri $createTeamUrl -Method 'POST' -Body $createTeamBody -ContentType "application/json"
            
            $statusCode = $createTeamResponse.StatusCode
            Write-Verbose -Message "Create team request succeded with status code: $statusCode"        
            [void]$results.Add(@($group.displayName, "team created", $success))

            Start-Sleep -Milliseconds 400
        } catch {
            $requestError = $_
            $resultStr = $requestError.Exception.Response.ToString() 
            $errorStatusCode = $requestError.Exception.Response.StatusCode.value__

            if ($errorStatusCode -eq 409){
                Write-Verbose -Message "Group is already a team"
                [void]$results.Add(@($group.displayName, "skipped: group is already a team", $skipped))
                continue
            }

            $message = $requestError.Exception.Message
            Write-Verbose -Message "Error: $message \n $resultStr"
            [void]$results.Add(@($group.displayName, "error: " + $request.Exception.Message, $failed))
        }
    }

    Write-Host "Finished!"
    foreach ($result in $results) {
        $foregroundColor = "Black"
        $backgroundColor = "Green"
        if ($result[2] -eq $failed) {
            $backgroundColor = "Red"
        } elseif ($result[2] -eq $skipped) {
            $backgroundColor = "Magenta"
        }
        $teamLog = [String]::Join("`t`t",$result,0,2)
        Out-File -InputObject "[$(get-date -Format G)] $teamLog" -FilePath $logFilePath -Append 
        Write-Host $result[0].Substring(0, (($result[0].length - 1), 10 | Measure-Object -Min).Minimum) "...`t`t" $result[1] -ForegroundColor $foregroundColor -BackgroundColor $backgroundColor
    }
}

Function Format-ResultsAndExport($graphscopes, $logFilePath) {
    
    $refreshToken = Initialize $graphscopes

    Write-Progress -Activity $activityName -Status "Connected. Discovering tenant information"
    
    Get-GroupsForUser $UPN

}

# Main
$graphEndPoint = $GraphEndpointProd

if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
}

$activityName = "Reading SDS objects in the directory"

$graphscopes = "Team.Create, GroupMember.ReadWrite.All, Group.ReadWrite.All, User.Read, User.Read.All, User.ReadWrite.All, Directory.Read.All, Directory.ReadWrite.All, Directory.AccessAsUser.All"

try
{
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-PrerequisiteHelp | Out-String | Write-Error
    throw
}

# Connect to the tenant
Write-Progress -Activity $activityName -Status "Connecting to tenant"
 
# Create output folder if it does not exist
if ((Test-Path $OutFolder) -eq 0)
{
	mkdir $OutFolder;
}

Format-ResultsAndExport $graphscopes $logFilePath

Write-Output "`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"
