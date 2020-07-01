<#
-----------------------------------------------------------------------
 <copyright file="Get-SectionUsageReport.ps1" company="Microsoft">
 © Microsoft. All rights reserved.
 </copyright>
-----------------------------------------------------------------------
.Synopsis
    Generates section usage report

.Description
    The script will query all SDS created sections and write their properties to a file

.Parameter OutFolder
    The script will create a CSV file at this location

.Parameter AzureEnvironment
    The AAD environment. By default the script uses Azure cloud. For testing purposes this can use PPE
    environment

.Example
    .\Get-SectionUsageReport.ps1 -OutFolder "C:\temp"

#>

Param (
    [Parameter(Mandatory = $false)]
    [string] $OutFolder = ".",

    [ValidateSet('AzureCloud', 'AzurePPE')]
    [string] $AzureEnvironment = "AzureCloud"
)

# Azure enviroment variables
$GraphEndpointProd = "https://graph.microsoft.com"
$AuthEndpointProd = "https://login.windows.net"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"
$AuthEndpointPPE = "https://login.windows-ppe.net"
$DefaultForegroundColor = "White"
$CurrentTime = $(((get-date).ToUniversalTime()).ToString("yyyy-MM-dd_HH-mm-ssZ"))
$msgLogInstanceFilename = ("SectionReportLog_" + $CurrentTime + ".log")
$msgErrorLogInstanceFilename = ("SectionReportErrorLog_" + $CurrentTime + ".log")

# Authorization token constants
$clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
$redirectUri = [Uri] "urn:ietf:wg:oauth:2.0:oob"
$outputFilename = "SectionUsageReport.csv"

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
    $logFile = Join-Path $OutFolder $msgLogInstanceFilename
    $message | Out-File -FilePath $logFile -Append
}

<#
.Synopsis
    Writes messages to error log file
#>
function Write-ErrorLog($message) {
    $logFile = Join-Path $OutFolder $msgErrorLogInstanceFilename
    $errorMessage = ((get-date).ToUniversalTime()).ToString("yyyy-MM-dd_HH-mm-ssZ") + $message
    $errorMessage | Out-File -FilePath $logFile -Append
    Write-Log $errorMessage
}

<#
.Synopsis
    Sets the authentication result and sets it at the global scope. This is to Set an OAuth2token for graph API calls.
#>
function Set-AuthenticationResult($resourceAppIdURI) {
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $global:authority, $false
    $promptBehaviour = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Always
    $authParam = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList $($promptBehaviour)
    $asyncTask = $authContext.AcquireTokenAsync([string] $resourceAppIdURI, [string] $clientId, [Uri] $redirectUri, $authParam)
    $asyncTask.Wait()
    $global:authToken = $asyncTask.Result
    $global:blobAuth = $authContext.TokenCache.Serialize()
}

<#
.Synopsis
    Sets the authentication result from the refresh token and sets it at the global scope. This is to Set an OAuth2token for graph API calls.
#>
function Set-AuthenticationResultFromRefreshToken {
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $global:authority, $false
    $authContext.TokenCache.Deserialize($global:blobAuth);
    $asyncTask = $authContext.AcquireTokenSilentAsync([string] $($global:authToken.RefreshToken), [string] $clientId)
    $asyncTask.Wait()
    $global:authToken = $asyncTask.Result
    $global:blobAuth = $authContext.TokenCache.Serialize()
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
function Send-WebRequest($method, $uri, $payload) {
    $response = ""

    $expiresOn = $global:authToken.ExpiresOn.UtcDateTime.AddMinutes(-1)
    $now = (Get-Date).ToUniversalTime()
    if ($expiresOn -lt $now) {
        Get-AuthenticationResultFromRefreshToken
    }

    if ($method -ieq "get") {
        $headers = @{ "Authorization" = "Bearer " + $($global:authToken.AccessToken) }
        $response = Invoke-RestMethod -Method $method -Uri $uri -Headers $headers
    }
    else {
        $headers = @{ 
            "Authorization" = "Bearer " + $($global:authToken.AccessToken)
            "Content-Type"  = "application/json"
        }

        $response = Invoke-RestMethod -Method $method -Uri $uri -Headers $headers -Body $payload
    }

    return $response
}

<#
.Synopsis
    Loads modules and DLLs required to run this script.
    ADAL package is downloaded from nuget server if not available.
#>
function Import-ActiveDirectoryAuthenticationLibrary {
    $AdalPackageName = "Microsoft.IdentityModel.Clients.ActiveDirectory"
    $NugetClientLatest = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

    $modulePath = $env:Temp + "\AADGraph"
    $nugetPackagePath = $modulePath + "\Nugets"
    if (-not (Test-Path ($nugetPackagePath))) {
        Write-Message "[Load-ADAL] Creating directory $nugetPackagePath"
        New-Item -Path ($nugetPackagePath) -ItemType "Directory" | out-null
    }
    $adalPackageDirectories = (Get-ChildItem -Path ($nugetPackagePath) -Filter $($AdalPackageName + "*") -Directory)

    if ($null -eq $adalPackageDirectories -or $adalPackageDirectories.Length -eq 0) {
        Write-Message "[Load-ADAL] ADAL package directory not found in $nugetPackagePath"

        # Get latest nuget client
        Write-Message "[Load-ADAL] Downloading latest nuget client from $NugetClientLatest"
        $nugetClientPath = $modulePath + "\Nugets\nuget.exe"
        Remove-Item -Path $nugetClientPath -Force -ErrorAction Ignore
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($NugetClientLatest, $nugetClientPath);
        
        # Install ADAL nuget package
        $nugetDownloadExpression = $nugetClientPath + " install " + $AdalPackageName + " -OutputDirectory " + $nugetPackagePath
        Write-Message "[Load-ADAL] Active Directory Authentication Library Nuget doesn't exist. Downloading now: `n$nugetDownloadExpression"
        Invoke-Expression $nugetDownloadExpression
    }

    $adalPackageDirectories = (Get-ChildItem -Path ($nugetPackagePath) -Filter $($AdalPackageName + "*") -Directory)
    if ($null -eq $adalPackageDirectories -or $adalPackageDirectories.length -le 0) {
        Write-Message "Unable to download ADAL nuget package" Red
        return $false
    }

    $adal4_5Directory = Join-Path $adalPackageDirectories[$adalPackageDirectories.length - 1].FullName -ChildPath "lib\net45"
    $ADAL_Assembly = Join-Path $adal4_5Directory -ChildPath "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"

    if ($ADAL_Assembly.Length -gt 0) {
        Write-Message "[Load-ADAL] Loading ADAL Assemblies: `n`t$ADAL_Assembly `n`t$ADAL_WindowsForms_Assembly"
        Write-Debug "file path length for $ADAL_Assembly is $($ADAL_Assembly.Length)"
        [System.Reflection.Assembly]::LoadFrom($ADAL_Assembly) | out-null
        return $true
    }
    else {
        Write-Message "[Load-ADAL] Fixing Active Directory Authentication Library package directories ..."
        $adalPackageDirectories | Remove-Item -Recurse -Force | Out-Null
        $message = "Not able to load ADAL assembly. Delete the Nugets folder under " + $modulePath + " , restart PowerShell session and try again ..."
        Write-Message $message Red
    }

    return $false
}

<#
.Synopsis
    Generate section report
#>
function Get-Report (
    [Parameter(Mandatory = $false)]
    [string] $OutFolder = ".",

    [ValidateSet('AzureCloud', 'AzurePPE')]
    [string] $AzureEnvironment = "AzureCloud"
) {
    try {
        if ($AzureEnvironment -eq "AzurePPE") {
            $global:graphEndPoint = $GraphEndpointPPE
            $global:authEndPoint = $AuthEndpointPPE
        }
        else {
            $global:graphEndPoint = $GraphEndpointProd
            $global:authEndPoint = $AuthEndpointProd
        }
        $global:authority = $authEndPoint + "/common"

        if (!(Test-Path $OutFolder)) {
            mkdir $OutFolder;
        }

        # Connect to the tenant
        $adalLoaded = Import-ActiveDirectoryAuthenticationLibrary
        if ($adalLoaded) {
            Set-AuthenticationResult $global:graphEndPoint
        }
        else {
            Write-Error "Could not load dependent libraries required by the script."
            exit
        }

        $outputFilePath = [system.io.path]::Combine($OutFolder, $outputFilename);

        $uri = "https://graph.microsoft.com/beta/groups?$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'Section'";
        Remove-Item $outputFilePath -ErrorAction Ignore
        while ($null -ne $uri) {
            try {
                $result = Send-WebRequest -Method Get -Uri $uri -Payload $null
                $sections = $result.value
                $uri = $result.'@odata.nextLink'
                Write-Message "Received $($result.value.Count) sections"
                $outSections = $sections | Select-Object `
                @{label = "GraphId"; expression = { $_.id } }, `
                @{label = "SectionId"; expression = { $_.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId } }, `
                @{label = "Name"; expression = { $_.displayname } }, `
                    CreatedDateTime
                
                $outSections | ForEach-Object {
                    Export-Csv -InputObject $_ -Path $outputFilePath -Append -NoTypeInformation
                }
            }
            catch {
                if ($_.Exception.Message -like "*Unauthorized*") {
                    Set-AuthenticationResultFromRefreshToken
                }
                else {
                    throw
                }
            }
        }

        Write-Message -foregroundColor "Green"  -message "Report successfully generated at $outputFilePath."
    }
    catch {
        Write-Message "`n`nException occured while script execution. Please rerun the script.`n`n" Red
        throw
    }
}

# main
Get-Report $OutFolder $AzureEnvironment
