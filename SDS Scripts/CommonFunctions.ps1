<#
.Synopsis
    Get authentication result. This is to acquire an OAuth2token for graph API calls.
#>
function Get-AuthenticationResult()
{
  $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
  $redirectUri = [Uri] "urn:ietf:wg:oauth:2.0:oob"
  $resourceClientId = "00000002-0000-0000-c000-000000000000"
  $resourceAppIdURI = $graphEndPoint
  $authority = $authEndPoint + "/common"
 
  $promptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Always 
  $platformParams = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList $promptBehavior
  $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority,$false
  
  $authResult = $authContext.AcquireTokenAsync([string] $resourceAppIdURI, [string] $clientId, [Uri] $redirectUri, $platformParams).Result
  
  Write-Output $authResult
}

function Send-WebRequest
{
    Param
    (
        $method,
        $uri,
        $payload
    )

    $response = ""
    $tokenExpiredRetryCount = 0
    Do {
        if ($tokenExpiredRetryCount -gt 0) {
            $authToken = Get-AuthenticationResult
        }

        if ($method -ieq "get") {
            $headers = @{ "Authorization" = "Bearer " + $authToken.AccessToken }
			Write-Output $uri
            $response = Invoke-WebRequest -Method $method -Uri $uri -Headers $headers
        }
        else {
            $headers = @{ 
                "Authorization" = "Bearer " + $authToken.AccessToken
                "Accept" = "application/json;odata=minimalmetadata"
                "Content-Type" = "application/json"
            }

            $response = Invoke-WebRequest -Method $method -Uri $uri -Headers $headers -Body $payload
        }

        $tokenExpiredRetryCount++
    } While (($response -contains "Authentication_ExpiredToken") -and  ($tokenExpiredRetryCount -lt 5))

    Write-Output $response
}


function Load-ActiveDirectoryAuthenticationLibrary 
{
	$moduleDirPath = ($ENV:PSModulePath -split ';')[0]
	$modulePath = $moduleDirPath + "\AADGraph"
	if(-not (Test-Path ($modulePath+"\Nugets"))) {New-Item -Path ($modulePath+"\Nugets") -ItemType "Directory" | out-null}
	$adalPackageDirectories = (Get-ChildItem -Path ($modulePath+"\Nugets") -Filter "Microsoft.IdentityModel.Clients.ActiveDirectory*" -Directory)
	if($adalPackageDirectories.Length -eq 0){
        # Get latest nuget client
        $nugetClientPath = $modulePath + "\Nugets\nuget.exe"
        Remove-Item -Path $nugetClientPath -Force -ErrorAction Ignore
		Write-Verbose "Downloading latest nuget client from $NugetClientLatest"
		$wc = New-Object System.Net.WebClient
		$wc.DownloadFile($NugetClientLatest, $nugetClientPath);
		
        # Install ADAL nuget package
		$nugetDownloadExpression = $nugetClientPath + " install Microsoft.IdentityModel.Clients.ActiveDirectory -source https://www.nuget.org/api/v2/ -Version 3.19.8 -OutputDirectory " + $modulePath + "\Nugets"
        Write-Verbose "Active Directory Authentication Library Nuget doesn't exist. Downloading now: `n$nugetDownloadExpression"
		Invoke-Expression $nugetDownloadExpression
	}

	$adalPackageDirectories = (Get-ChildItem -Path ($modulePath+"\Nugets") -Filter "Microsoft.IdentityModel.Clients.ActiveDirectory*" -Directory)
    if ($adalPackageDirectories -eq $null -or $adalPackageDirectories.length -le 0)
    {
        Write-Error "Unable to download ADAL nuget package"
        return $false
    }

    $adal4_5Directory = Join-Path $adalPackageDirectories[$adalPackageDirectories.length-1].FullName -ChildPath "lib\net45"
	$ADAL_Assembly = Join-Path $adal4_5Directory -ChildPath "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
	
	if($ADAL_Assembly.Length -gt 0){
		Write-Verbose "Loading ADAL Assembly: `n`t$ADAL_Assembly"
        Write-Debug "file path length for $ADAL_Assembly is $($ADAL_Assembly.Length)"
		[System.Reflection.Assembly]::LoadFrom($ADAL_Assembly) | out-null		
		return $true
	}
	else{
		Write-Verbose "Fixing Active Directory Authentication Library package directories ..."
		$adalPackageDirectories | Remove-Item -Recurse -Force | Out-Null
		Write-Error "Not able to load ADAL assembly. Delete the Nugets folder under" $modulePath ", restart PowerShell session and try again ..."
	}

    return $false
}
