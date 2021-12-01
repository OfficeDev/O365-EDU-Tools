<#
Script Name:
common.ps1

Synopsis:
Contains functions common to SDS Scripts.  Must be downloaded into same folder where the scripts are run.  

Written By:
Ayron Johnson

Change Log:
Version 1.0, 07/26/2021 - First Draft
#>

function Initialize($graphscopes) {
    import-module Microsoft.Graph.Authentication -MinimumVersion 0.9.1
    $null = Write-Output "If prompted, please use a tenant admin-account to grant access to $graphscopes privileges"
    $firstToken = Refresh-Token $null $graphscopes
    return $firstToken
}
function Refresh-Token($lastRefreshed, $graphscopes) {
    $currentDT = get-date
    if ($lastRefreshed -eq $null -or (New-TimeSpan -Start $currentDT -End $lastRefreshed).Minutes -gt 10) {
        connect-graph -scopes $graphscopes | Out-Null
        $lastRefreshed = get-date
    }
    return $lastRefreshed
}

# Gets data from all pages
function PageAll-GraphRequest($initialUri, $refreshToken, $method, $graphscopes, $logFilePath) {

    $result = @()

    $currentUrl = $initialUri
    
    while ($currentUrl -ne $null) {
        Refresh-Token $refreshToken $graphscopes
        $response = invoke-graphrequest -Method $method -Uri $currentUrl -ContentType "application/json"
        $result += $response.value
        $currentUrl = $response.'@odata.nextLink'
    }
    $global:nextLink = $response.'@odata.nextLink'
    return $result
}

function TokenSkipCheck ($uriToCheck, $logFilePath)
{
    if ($skipToken -eq "." ) {
        $checkedUri = $uriToCheck
    }
    else {
        $checkedUri = $skipToken
    }
    
    return $checkedUri
}