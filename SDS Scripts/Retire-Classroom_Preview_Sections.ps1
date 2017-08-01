<#
-----------------------------------------------------------------------
 <copyright file="RetireSections.ps1" company="Microsoft">
 © Microsoft. All rights reserved.
 </copyright>
-----------------------------------------------------------------------
.Synopsis
    Provides ability to retire sections

.Description
    The script will help in renaming groups setup for Classroom Preview. The renaming will help reuse 
    groups with new settings. The archival functionality will filter out sections which are already 
    retired and those that were setup for Classroom preview. The script execution is idempotent
    The Displayname and mailNickname will be updated, along with 2 extension properties - AnchorId &
    Status.

    The script retrieves all sections from AAD, and applies the filter unless the a list of sections to
    retire is provided.

.Parameter SectionsToRetireFilePath
    Path to file containing the list of sections to retire. This is an optional parameter. When
    this file is provided the script skips filtering the groups
    
    Note: This file should follow the schema of the "Section Usage report"

.Parameter RetirePrefix
    The string used as a prefix when archiving sections. This is an optional parameter. If this
    field is not provided the script will use "SDSRetired" as the prefix string. 

    e.g. If group display name was "Physics 101", the new name will be "SDSRetired Physics 101"

.Parameter OutFolder
    The script will create logs and a report of the archival process. These files will be stored in this
    folder. The default value is the current folder

.Parameter AzureEnvironment
    The AAD environment. By default the script uses Azure cloud. For testing purposes this can use PPE
    environment

.Example
    RetireSections -SectionsToRetireFilePath "D:\Archval\SectionsToRetire.csv" -RetirePrefix "Retired"
    -OutFolder "D:\Archival"

#>

Param (
    [Parameter(Mandatory=$false)]
    [string] $SectionsToRetireFilePath = $null,

    [Parameter(Mandatory=$false)]
    [string] $RetirePrefix = "",

    [string] $OutFolder = ".",

    [ValidateSet('AzureCloud', 'AzurePPE')]
    [string] $AzureEnvironment = "AzureCloud"
)

<#
-----------------------------------------------------------------------
 <copyright file="RetireSections.Functions.ps1" company="Microsoft">
 © Microsoft. All rights reserved.
 </copyright>
-----------------------------------------------------------------------
.Synopsis
    Helps in renaming groups setup for Classroom Preview. The renaming will help reuse groups with new settings
#>

# Azure enviroment variables
$GraphEndpointProd = "https://graph.microsoft.com"
$AuthEndpointProd = "https://login.windows.net"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"
$AuthEndpointPPE = "https://login.windows-ppe.net"
$GraphVersion = "edu"
$GraphVersionForBatch = "beta"
$BatchSize = 5
$DefaultForegroundColor = "White"
$SDSRetiredPrefix = "SDSRetired"
$StatusPrefix = "Retired"

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

        $anchorId = [string]::Format("{0}_{1}", $SDSRetiredPrefix, $($section.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId))
        $displayName = [string]::Format("{0} {1}", $SDSRetiredPrefix, $($section.displayName))
        $mailNickName = [string]::Format("{0}_{1}", $SDSRetiredPrefix, $($section.mailNickName))

        $body = New-Object System.Object
        $body | Add-Member -type NoteProperty -name "displayName" -value $displayName
        $body | Add-Member -type NoteProperty -name "extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId" -value $anchorId
        $body | Add-Member -type NoteProperty -name "extension_fe2174665583431c953114ff7268b7b3_Education_Status" -value $StatusPrefix
        $body | Add-Member -type NoteProperty -name "mailNickName" -value $mailNickName
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
    if ($response -eq $null)
    {
        $isSuccess = $false
        return $isSuccess
    }

    $responsesObject = $response.Content | ConvertFrom-Json
    foreach ($response in $responsesObject.responses) 
    {
        Write-Log ([string]::Format("{0} : StatusCode: {1}",$($response.id), $($response.status)))

        $request = $requests | Where-Object {$_.id -ieq $response.id} | Select-Object -First 1

        $displayName = $request.body.displayName
        $anchorId = $request.body.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId

        if ($displayName.IndexOf("$SDSRetiredPrefix ") -gt -1)
        {
            $oldDisplayName = $displayName.Substring($displayName.IndexOf("$SDSRetiredPrefix ") + "$SDSRetiredPrefix ".Length)
        }
        $newDisplayName = $displayName
        $sisId = $anchorId.Substring($anchorId.IndexOf("_") + "_".Length)
            
        if ($response.status -ne 204)
        {
            Write-Message "Failed to update section $sisId" Red
            $errorMsg = [string]::Format("{0} : StatusCode: {1} Code: {2}`nMessage: {3}`nRequestId: {4}`n",$($response.id), $($response.status), $($response.body.error.code), $($response.body.error.message), $($response.body.error.innerError.'request-id'))
            Write-ErrorLog $errorMsg
            $isSuccess = $false
            $statusMessage = "Failed"
        }
        else # success 
        {
            $statusMessage = "Success"
        }
        $message = [string]::Format("{0},{1},{2},{3}", $oldDisplayName, $newDisplayName, $sisId, $statusMessage)
        $message | Out-File $updateResultsFilePath -Encoding utf8 -Append
    }
    return $isSuccess
}

<#
.Synopsis
    Retrieves sections from AAD. 
    The query uses a filter for object type and selects properties of interest
#>
function Get-Sections()
{
    $firstPage = $true
    $sections = @()

    Write-Progress -Activity "Retrieving Sections" -Status "Retrieved $($sections.Count) sections" -Id 2
    do
    {
        if ($firstPage)
        {
            $queryParams = "`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'Section'&`$select=objectId,creationOptions,mailNickName,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId,extension_fe2174665583431c953114ff7268b7b3_Education_Status"

            $uri = [string]::Format("{0}/{1}/groups?{2}", $global:graphEndPoint, $GraphVersion, $queryParams);

            $firstPage = $false
        }
        else
        {
            $uri = $responseObject.odatanextLink
        }

        $response = Send-WebRequest "Get" $uri
        $responseString = $response.Content.Replace("@odata.", "odata")
        $responseObject = $responseString | ConvertFrom-Json

        $sections = $sections + $responseObject.Value;
        Write-Progress -Activity "Retrieving Sections" -Status "Retrieved $($sections.Count) sections" -Id 2
    }
    while ($responseObject.odatanextLink -ne $null)

    return $sections;
}

<#
.Synopsis
    Retrieves the section objects based on the input section file
    This function will load the object ids from the file and make graph queries 
    to retrieve the objects
#>
function Get-SectionsFromFile()
{
    $importResult = Import-CSV $SectionsToRetireFilePath

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

                $graphIdsJson = $graphIds | ConvertTo-Json
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
            $responses = $responseObject.value | select @{Name="objectId";Expression={$_.id}}, displayName, mailNickName, extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId, extension_fe2174665583431c953114ff7268b7b3_Education_Status
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
    Filters the sections and removes sections meet the following criteria
    1. Status is not Retired
    2. creationOptions is NOT one of [SharePointReadOnlyMembers, ExchangeProvisioningOption1]
#>
function Filter-Sections ($sections) 
{
    $filteredSections = @()
    foreach ($section in $sections) 
    {
        $isNotRetired = ($section.extension_fe2174665583431c953114ff7268b7b3_Education_Status -ne $null) -and $($section.extension_fe2174665583431c953114ff7268b7b3_Education_Status) -notmatch $StatusPrefix
        $isPreviewCreationOptions = ($section.creationOptions -ne $null) -and ($($section.creationOptions) -contains "SharePointReadOnlyMembers") -and ($($section.creationOptions) -contains "ExchangeProvisioningOption1")
        if ($isNotRetired -and $isPreviewCreationOptions)
        {
            $filteredSections = $filteredSections + $section
        }    
    }
    return $filteredSections
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
    Retire sections main function. 
#>
function Retire-Sections (
    [Parameter(Mandatory=$false)]
    [string] $SectionsToRetireFilePath = $null,

    [Parameter(Mandatory=$false)]
    [string] $RetirePrefix = "",

    [string] $OutFolder = ".",

    [ValidateSet('AzureCloud', 'AzurePPE')]
    [string] $AzureEnvironment = "AzurePPE"
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

        if (($RetirePrefix -ne $null) -and ($RetirePrefix.Length -gt 0))
        {
            Write-Message "Replacing default prefix with $RetirePrefix"
            $SDSRetiredPrefix = $RetirePrefix
        }

        $updateResultsFilePath = Join-Path $OutFolder $sectionListFilename

        $filteredSections = @()

        if (($SectionsToRetireFilePath -ne $null) -and ($SectionsToRetireFilePath.Length -gt 0))
        {
            $fileExists = Test-Path $SectionsToRetireFilePath
            if ($fileExists -eq $false)
            {
                Write-Error "Could not find file. Path: $SectionsToRetireFilePath"
                exit
            }

            Write-Message "Retrieving sections from file $SectionsToRetireFilePath"

            # Don't filter for when reading from a file
            $sectionsFromFile = Get-SectionsFromFile
            $filteredSections = $filteredSections + $SectionsFromFile
        }
        else 
        {
            Write-Message "Retrieving sections from AAD ..."
            $sections = Get-Sections
            
            $filteredSections = Filter-Sections $sections
        }

        Write-Message ([string]::Format("{0} sections will be updated", $filteredSections.Count))
        
        Write-Message "Updating section properties"
        $success = Update-Sections $filteredSections
        if ($success)
        {
            Write-Message "Section properties updated" Green
            Start-Process -FilePath "https://aka.ms/sdsprofilemigration"
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
    }
}

# main
Retire-Sections $SectionsToRetireFilePath $RetirePrefix $OutFolder $AzureEnvironment
