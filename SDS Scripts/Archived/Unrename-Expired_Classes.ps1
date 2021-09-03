<#
-----------------------------------------------------------------------
 <copyright file="Unrename-Expired_Classes.ps1" company="Microsoft">
 © Microsoft. All rights reserved.
 </copyright>
-----------------------------------------------------------------------
.Synopsis
    Provides ability to un-cleanup expired sections

.Example
    .\Unrename-Expired_Classes.ps1 -SectionsToUnretireFilePath "C:\SectionUsageReport.csv" -SDSExpiredPrefix "Exp0818_"
#>

Param (
    [Parameter(Mandatory=$true)]
    [string] $SectionsToUnretireFilePath,

    [Parameter(Mandatory=$false)]
    [string] $OutFolder = ".",

    [Parameter(Mandatory=$true)]
    [string] $SDSExpiredPrefix,

    [ValidateSet('AzureCloud', 'AzurePPE')]
    [string] $AzureEnvironment = "AzureCloud"
)

# Azure enviroment variables
$GraphEndpointProd = "https://graph.microsoft.com"
$AuthEndpointProd = "https://login.windows.net"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"
$AuthEndpointPPE = "https://login.windows-ppe.net"
$GraphVersion = "edu"
$GraphVersionForBatch = "beta"
$BatchSize = 5
$DefaultForegroundColor = "White"
$StatusPrefix = "Active"

$CurrentTime=$(((get-date).ToUniversalTime()).ToString("yyyy-MM-dd_HH-mm-ssZ"))
$msgLogInstanceFilename = ("ArchivalLog_"+$CurrentTime+".log")
$msgErrorLogInstanceFilename = ("ArchivalErrorLog_"+$CurrentTime+".log")
$sectionListFilename = ("UpdatedSections_"+$CurrentTime+".csv")

# Authorization token constants
$clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
$redirectUri = [Uri] "urn:ietf:wg:oauth:2.0:oob"

<#
.Synopsis
    Write messages to log file and console
#>
function Write-Message($message, $foregroundColor)
{
    switch($foregroundColor)
    {
        Red {$type ="ERROR"}
        Green {$type = "SUCCESS"}
        Cyan {$type = "ACTION"}
        default{$type = "INFO"}
    }

    try 
    {
            $messageToLog = "[ $type ]: $message"
            if($type -eq "ERROR")
            {
                Write-ErrorLog $messageToLog
            }
            else
            {
                Write-Log $messageToLog
            }

            if ($foregroundColor -eq $null)
            {
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
function Write-Log($message)
{
    $logFile = Join-Path $OutFolder $msgLogInstanceFilename
    $message | Out-File -FilePath $logFile -Append
}

<#
.Synopsis
    Writes messages to error log file
#>
function Write-ErrorLog($message)
{
    $logFile = Join-Path $OutFolder $msgErrorLogInstanceFilename
    $errorMessage = ((get-date).ToUniversalTime()).ToString("yyyy-MM-dd_HH-mm-ssZ") + $message
    $errorMessage | Out-File -FilePath $logFile -Append
    Write-Log $errorMessage
}

<#
.Synopsis
    Acquires the authentication result and sets it at the global scope. This is to acquire an OAuth2token for graph API calls.
#>
function Acquire-AuthenticationResult($resourceAppIdURI)
{
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $global:authority,$false
    $promptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Always
    $global:authToken = $authContext.AcquireToken([string] $resourceAppIdURI, [string] $clientId, [Uri] $redirectUri, $promptBehavior)
}

<#
.Synopsis
    Acquires the authentication result from the refresh token and sets it at the global scope. This is to acquire an OAuth2token for graph API calls.
#>
function Acquire-AuthenticationResultFromRefreshToken
{
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $global:authority,$false
    $global:authToken = $authContext.AcquireTokenByRefreshToken([string] $($global:authToken.RefreshToken), [string] $clientId)
}

<#
.Synopsis
    Invoke web request. Based on http request method, it constructs request headers using global $authToken.
    Response is in json format. If token expired, it will ask user to refresh token. Max retry time is 5.
.Parameter method
    Http request method
.Parameter uri
    Http request uri
.Parameter payload
    Http request payload. Not used if method is Get.
#>
function Send-WebRequest($method, $uri, $payload)
{
    $response = ""

    $expiresOn = $global:authToken.ExpiresOn.UtcDateTime.AddMinutes(-1)
    $now = (Get-Date).ToUniversalTime()
    if ($expiresOn -lt $now) {
        Get-AuthenticationResultFromRefreshToken
    }

    if ($method -ieq "get") {
        $headers = @{ "Authorization" = "Bearer " + $($global:authToken.AccessToken) }
        $response = Invoke-WebRequest -Method $method -Uri $uri -Headers $headers
    }
    else {
        $headers = @{ 
            "Authorization" = "Bearer " + $($global:authToken.AccessToken)
            "Content-Type" = "application/json"
        }

        $response = Invoke-WebRequest -Method $method -Uri $uri -Headers $headers -Body $payload
    }

    return $response
}

<#
.Synopsis
    Loads modules and DLLs required to run this script.
    ADAL package is downloaded from nuget server if not available.
#>
function Load-ActiveDirectoryAuthenticationLibrary 
{
    $NugetSource = "https://www.nuget.org/api/v2/"
    $AdalPackageName = "Microsoft.IdentityModel.Clients.ActiveDirectory"
    $AdalNugetVersion = "2.28.1"
    $NugetClientLatest = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

    $modulePath = $env:Temp + "\AADGraph"
    $nugetPackagePath = $modulePath+"\Nugets"
    if(-not (Test-Path ($nugetPackagePath))) 
    {
        Write-Message "[Load-ADAL] Creating directory $nugetPackagePath"
        New-Item -Path ($nugetPackagePath) -ItemType "Directory" | out-null
    }
    $adalPackageDirectories = (Get-ChildItem -Path ($nugetPackagePath) -Filter $($AdalPackageName+"*") -Directory)

    if($adalPackageDirectories -eq $null -or $adalPackageDirectories.Length -eq 0){
        Write-Message "[Load-ADAL] ADAL package directory not found in $nugetPackagePath"

            # Get latest nuget client
        Write-Message "[Load-ADAL] Downloading latest nuget client from $NugetClientLatest"
            $nugetClientPath = $modulePath + "\Nugets\nuget.exe"
            Remove-Item -Path $nugetClientPath -Force -ErrorAction Ignore
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($NugetClientLatest, $nugetClientPath);
        
            # Install ADAL nuget package
        $nugetDownloadExpression = $nugetClientPath + " install " + $AdalPackageName + " -source " + $NugetSource + " -Version " + $AdalNugetVersion + " -OutputDirectory " + $nugetPackagePath
        Write-Message "[Load-ADAL] Active Directory Authentication Library Nuget doesn't exist. Downloading now: `n$nugetDownloadExpression"
        Invoke-Expression $nugetDownloadExpression
    }

    $adalPackageDirectories = (Get-ChildItem -Path ($nugetPackagePath) -Filter $($AdalPackageName+"*") -Directory)
    if ($adalPackageDirectories -eq $null -or $adalPackageDirectories.length -le 0)
    {
        Write-Message "Unable to download ADAL nuget package" Red
        return $false
    }

    $adal4_5Directory = Join-Path $adalPackageDirectories[$adalPackageDirectories.length-1].FullName -ChildPath "lib\net45"
    $ADAL_Assembly = Join-Path $adal4_5Directory -ChildPath "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $ADAL_WindowsForms_Assembly = Join-Path $adal4_5Directory -ChildPath "Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"

    if($ADAL_Assembly.Length -gt 0 -and $ADAL_WindowsForms_Assembly.Length -gt 0)
    {
        Write-Message "[Load-ADAL] Loading ADAL Assemblies: `n`t$ADAL_Assembly `n`t$ADAL_WindowsForms_Assembly"
        Write-Debug "file path length for $ADAL_Assembly is $($ADAL_Assembly.Length)"
        [System.Reflection.Assembly]::LoadFrom($ADAL_Assembly) | out-null
        [System.Reflection.Assembly]::LoadFrom($ADAL_WindowsForms_Assembly) | out-null
        return $true
    }
    else
    {
        Write-Message "[Load-ADAL] Fixing Active Directory Authentication Library package directories ..."
        $adalPackageDirectories | Remove-Item -Recurse -Force | Out-Null
        $message = "Not able to load ADAL assembly. Delete the Nugets folder under " + $modulePath + " , restart PowerShell session and try again ..."
        Write-Message $message Red
    }

    return $false
}

<#
.Synopsis
    Updates to AAD through MS Graph allows batching of requests. This method will generate
    the payload for the batched request
#>
function Generate-UpdateBatchRequest($sections)
{
    $requests = @()
    $headers = New-Object System.Object
    $headers | Add-Member -type NoteProperty -name "Content-Type" -value "application/json"
    
    for ($index = 0; $index -lt $sections.Count; $index++) 
    {
        $section = $sections[$index]
        $url = "/groups/$($section.objectId)"        
        $request = New-Object System.Object
        $request | Add-Member -type NoteProperty -name "id" -value ($index + 1)
        $request | Add-Member -type NoteProperty -name "method" -value "PATCH"
        $request | Add-Member -type NoteProperty -name "url" -value $url

        Write-Log ([string]::Format("PATCH {0} :{1}",$index + 1, $url))

        $request | Add-Member -type NoteProperty -name "headers" -value $headers
        $anchorId = $section.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId -replace $SDSExpiredPrefix
        $sectionId = $section.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId -replace $SDSExpiredPrefix
        $displayName = $section.displayName -replace $SDSExpiredPrefix
        $mailNickName = $section.mailNickName -replace $SDSExpiredPrefix

        $body = New-Object System.Object
        $body | Add-Member -type NoteProperty -name "displayName" -value $displayName
        $body | Add-Member -type NoteProperty -name "extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId" -value $anchorId
        $body | Add-Member -type NoteProperty -name "extension_fe2174665583431c953114ff7268b7b3_Education_Status" -value $StatusPrefix
        $body | Add-Member -type NoteProperty -name "mailNickName" -value $mailNickName
        $body | Add-Member -type NoteProperty -name "extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId" -value $sectionId
        $request | Add-Member -type NoteProperty -name "body" -value $body

        $requests = $requests + $request
    }

    return $requests
}

<#
.Synopsis
    Parses the response from MS Graph and writes the status along with the error message
    to a log file
    THis'll also write the updates information to a CSV file
#>
function Parse-UpdateResponse ($requests, $response) {
    $isSuccess = $true
    return $isSuccess
}

<#
.Synopsis
    Retrieves the section objects based on the input section file
    This function will load the object ids from the file and make graph queries 
    to retrieve the objects
#>
function Get-SectionsFromFile()
{
    $importResult = Import-CSV $SectionsToUnretireFilePath

    # Create empty array for the 1 entry scenario. Import-CSV won't create an array instead will return just the object
    $sectionsFromFile = @()
    $sectionsFromFile = $sectionsFromFile + $importResult
    $sections = @()
    # use beta version for get batch processing
    $uri = [string]::Format("{0}/{1}/directoryObjects/getbyIds", $global:graphEndPoint, $GraphVersionForBatch)

    Write-Progress -Activity "Retrieving Sections" -Status "Retrieved 0/$($sectionsFromFile.Count) sections" -Id 2

    # getByIds supports upto 1000 ids. However keep the number at 500 to get the response without requiring pagination
    $getByIdsSize = 500
    for ($index = 0; $index -lt $sectionsFromFile.Count; $index = $index + $getByIdsSize) 
    {
        $firstPage = $true
        do
        {
            if ($firstPage)
            {
                $graphIds = @()
                $graphIds = $graphIds + ($sectionsFromFile | select -ExpandProperty GraphId -skip $index -First $getByIdsSize)
                $graphIdsJson = $graphIds | Where-Object {$_} | ConvertTo-Json
                if ($graphIds.Count -eq 1 )
                {
                    $graphIdsJson = [string]::Format("[{0}]", $graphIdsJson)
                }

                $payload = [string]::Format("{{`"ids`":{0},`"types`":[`"group`"]}}", $graphIdsJson)

                $response = Send-WebRequest -uri $uri -method "POST" -payload $payload
            }
            else
            {
                $response = Send-WebRequest -uri $responseObject.odatanextLink -method "GET"
            }

            $responseString = $response.Content.Replace("@odata.", "odata")
            $responseObject = $responseString | ConvertFrom-Json
            $responses = $responseObject.value `
            | Select-Object @{Name="objectId";Expression={$_.id}}, displayName, mailNickName, extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId, extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId
            $sections = $sections + $responses
        }
        while ($responseObject.odatanextLink -ne $null)

        $complete = [int]($index/$sectionsFromFile.Count * 100)
        Write-Progress -Activity "Retrieving Sections" -Status "Retrieved $($sections.Count)/$($sectionsFromFile.Count) sections" -PercentComplete $complete -Id 2
    }

    return $sections
}

<#
.Synopsis
    Updates properties on the section objects in AAD
#>
function Update-Sections($sections)
{
    $isSuccess = $true
    try
    {
        $sectionCount = $sections.Count

        # use beta version for batch processing
        $uri = [string]::Format("{0}/{1}/`$batch", $global:graphEndPoint, $GraphVersionForBatch)

        # Setup update results csv
        "Old Section Name,New Section Name,SIS Id,Update Status" | Out-File $updateResultsFilePath -Encoding utf8

        Write-Progress -Activity "Updating Sections" -Status "Updated [0/$sectionCount] sections" -PercentComplete 0

        for ($index = 0; $index -lt $sections.Count; $index = $index + $BatchSize) 
        {
            $complete = [int]($index/$sectionCount * 100)
            
            $requestSections = @()
            $requestSections = $requestSections + ($sections | select -skip $index -First $BatchSize)

            $requests = Generate-UpdateBatchRequest $requestSections
            $requestsJson = $requests | ConvertTo-Json

            if ($requestSections.Count -gt 1 )
            {
                $requestsJson = [string]::Format("{{`"requests`":{0}}}", $requestsJson)
            }
            else 
            {
                $requestsJson = [string]::Format("{{`"requests`":[{0}]}}", $requestsJson)
            }

            $response = Send-WebRequest -uri $uri -method "POST" -payload $requestsJson

            $isSuccess = Parse-UpdateResponse $requests $response

            $countUpdated = $index + $BatchSize
            Write-Progress -Activity "Updating Sections" -Status "Updated [$countUpdated/$sectionCount] sections" -PercentComplete $complete
        }
    }
    catch
    {
        Write-Message $_.Exception.Message 
        $isSuccess = $false
    }
    return $isSuccess
}

<#
.Synopsis
    Unretire sections main function. 
#>
function Unretire-Sections (
    [Parameter(Mandatory=$true)]
    [string] $SectionsToUnretireFilePath,

    [Parameter(Mandatory=$false)]
    [string] $OutFolder = ".",

    [ValidateSet('AzureCloud', 'AzurePPE')]
    [string] $AzureEnvironment = "AzureCloud"
)
{
    try
    {
        if ($AzureEnvironment -eq "AzurePPE")
        {
            $global:graphEndPoint = $GraphEndpointPPE
            $global:authEndPoint = $AuthEndpointPPE
        }
        else
        {
            $global:graphEndPoint = $GraphEndpointProd
            $global:authEndPoint = $AuthEndpointProd
        }
        $global:authority = $authEndPoint + "/common"

        if (!(Test-Path $OutFolder))
        {
            mkdir $OutFolder;
        }

        # Connect to the tenant
        $adalLoaded = Load-ActiveDirectoryAuthenticationLibrary
        if ($adalLoaded)
        {
            Acquire-AuthenticationResult $global:graphEndPoint
        }
        else
        {
            Write-Error "Could not load dependent libraries required by the script."
            exit
        }

        $updateResultsFilePath = Join-Path $OutFolder $sectionListFilename

        $filteredSections = @()

        if (($SectionsToUnretireFilePath -ne $null) -and ($SectionsToUnretireFilePath.Length -gt 0))
        {
            $fileExists = Test-Path $SectionsToUnretireFilePath
            if ($fileExists -eq $false)
            {
                Write-Error "Could not find file. Path: $SectionsToUnretireFilePath"
                exit
            }

            Write-Message "Retrieving sections from file $SectionsToUnretireFilePath"

            # Don't filter for when reading from a file
            $sectionsFromFile = Get-SectionsFromFile
            $filteredSections = $filteredSections + $SectionsFromFile
        }

        Write-Message ([string]::Format("{0} sections will be updated", $filteredSections.Count))
        
        Write-Message "Updating section properties"
        $success = Update-Sections $filteredSections
        if ($success)
        {
            Write-Message "Section properties updated" Green
        }
        else 
        {
            Write-Message "Failed to update section properties. Please refer to error log file at $OutFolder" Red    
        }
    }
    catch 
    {
        Write-Log $_.Exception.Message
        Write-Message "`n`nException occured while script execution. Please rerun the script.`n`n" Red
        write-Message $_.InvocationInfo
    }
}

# main
Unretire-Sections $SectionsToUnretireFilePath $OutFolder $AzureEnvironment
