<#
-----------------------------------------------------------------------
 <copyright file="MigrateClassGroupsToTeams.ps1" company="Microsoft">
 © Microsoft. All rights reserved.
 </copyright>
-----------------------------------------------------------------------
.Synopsis
    Helps create Microsoft Teams teams from previously created Class Team unified groups
#>

param
(
    [Parameter(Mandatory=$true)]
    [string]$UPN,

    [Parameter(Mandatory=$true)]
    [string]$TenantName
)

# from https://blogs.technet.microsoft.com/cloudlojik/2018/06/29/connecting-to-microsoft-graph-with-a-native-app-using-powershell/
Function Get-AccessToken ($TenantName, $ClientID, $redirectUri, $resourceAppIdURI, $CredPrompt){
    Write-Host "Checking for AzureAD module..."
    if (!$CredPrompt){$CredPrompt = 'Auto'}
    $AadModule = Get-Module -Name "AzureAD" -ListAvailable
    if ($AadModule -eq $null) {$AadModule = Get-Module -Name "AzureADPreview" -ListAvailable}
    if ($AadModule -eq $null) {write-host "AzureAD Powershell module is not installed. The module can be installed by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt. Stopping." -f Yellow;exit}
    if ($AadModule.count -gt 1) {
        $Latest_Version = ($AadModule | select version | Sort-Object)[-1]
        $aadModule      = $AadModule | ? { $_.version -eq $Latest_Version.version }
        $adal           = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms      = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
        }
    else {
        $adal           = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms      = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
        }
    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
    $authority          = "https://login.microsoftonline.com/$TenantName"
    Write-Verbose -Message $authority
    $authContext        = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters"    -ArgumentList $CredPrompt
    $authResult         = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters).Result
    return $authResult
}

$ErrorActionPreference = 'Stop'

# --Get the auth token
$authResult = Get-AccessToken -TenantName $TenantName -ClientID "12128f48-ec9e-42f0-b203-ea49fb6af367" -redirectUri "https://teamscmdlet.microsoft.com" -resourceAppIdURI "https://graph.microsoft.com/" -CredPrompt "Always"

Write-Verbose -Message $authResult

$headers = @{
    'Authorization' = ('bearer ' + $authResult.AccessToken)
}

# --Fetch all groups for the user
$groupPaginationLimit = 999

$groupsRequestUrl = "https://graph.microsoft.com/edu/users/$UPN/ownedObjects/microsoft.graph.group?`$top=$groupPaginationLimit"

$groups = New-Object System.Collections.ArrayList
try {
    do {    
        $groupsResponse = Invoke-WebRequest -Uri $groupsRequestUrl -Method Get -Headers $headers

        $groupsContent = ConvertFrom-Json -InputObject $groupsResponse.Content

        $groupsCount = $groupsContent.value.Count

        [void]$groups.AddRange($groupsContent.value)

        Write-Verbose -Message "Retrieved $groupsCount groups."
        if ($groupsContent.'@odata.nextLink'){
            Write-Verbose -Message "More groups to retrieve..."
        }

        $groupsRequestUrl = $groupsContent.'@odata.nextLink'
    } while ($groupsRequestUrl)
} catch {
    $message = $_.Exception.Message

    Write-Host "Error while getting groups for $UPN : $message"
    return
}

$groupsCount = $groups.Count

Write-Verbose -Message "Done fetching groups. Retrieved $groupsCount total groups."

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
        $createTeamResponse = Invoke-WebRequest -Uri $createTeamUrl -Headers $headers -Method Post -Body $createTeamBody -ContentType application/json
        $statusCode = $createTeamResponse.StatusCode
        Write-Verbose -Message "Create team request succeded with status code: $statusCode"
        
        if ($statusCode -gt 199 -and $statusCode -lt 300) {
            [void]$results.Add(@($group.displayName, "team created", $success))
        } else {
            [void]$results.Add(@($group.displayName, "unknown", $failed))
        }
        # Throttling here is necessary to prevent failures caused by too many requests per user
        Start-Sleep -Seconds 1
    } catch {
        $requestError = $_
        $responseStream = $requestError.Exception.Response.GetResponseStream()
        $streamReader = New-Object System.IO.StreamReader -ArgumentList $responseStream
        $readBuffer = [char[]]::new(256)
        $readCount = $streamReader.Read($readBuffer, 0, 256);
        $strBuilder = New-Object System.Text.StringBuilder
        while ($readCount -gt 0) {
            $str = New-Object System.String -ArgumentList @($readBuffer, 0, $readCount)
            [void]$strBuilder.Append($str)
            $readCount = $streamReader.Read($readBuffer, 0, 256)
        }

        $resultStr = $strBuilder.ToString()

        if ($resultStr.Contains("Failed to execute request for MiddleTier CreateTeamS2SAsync. Status code: Conflict")) {
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
    Write-Host $result[0].Substring(0, (($result[0].length - 1), 10 | Measure-Object -Min).Minimum) "...`t`t" $result[1] -ForegroundColor $foregroundColor -BackgroundColor $backgroundColor
}
