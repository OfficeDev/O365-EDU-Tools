function Get-AllPageQueried() {

}


function Initialize($graphscopes) {
    import-module Microsoft.Graph.Authentication -MinimumVersion 0.9.1
    Write-Output "If prompted, please use a tenant admin-account to grant access to $graphscopes privileges"
    #$lastRefreshed = $null
    Refresh-Token $null $graphscopes
}
function Refresh-Token($lastRefreshed, $graphscopes) {
    if ($lastRefreshed -eq $null -or (get-date - $lastRefreshed).Minutes -gt 10) {
        connect-graph -scopes $graphscopes
        $lastRefreshed = get-date
    }
    return $lastRefreshed
}

# Gets data from all pages
function PageAll-GraphRequest($initialUri, $refreshToken, $method, $graphscopes, $logFilePath) {

    $result = @()

    $currentUrl = $initialUri
    
    while ($currentUrl -ne $null) {
        Refresh-Token $lastRefreshed $graphscopes
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