﻿<#
-----------------------------------------------------------------------
 <copyright file="Get-Guardians.ps1" company="Microsoft">
 Â© Microsoft. All rights reserved.
 </copyright>
-----------------------------------------------------------------------
.Synopsis
    Gets all guardians associated with a singe student synced from SDS.
.Description
    This script will query for a single SDS synced student and export the guardians associated with them to a CSV file.
.Parameter OutFolder
    The script will output log file here
.Parameter clientId
    The application Id that has EduRoster.ReadWrite.All permission
.Parameter clientSecret
    The secret of the application Id that has EduRoster.ReadWrite.All permission
.Parameter tenantDomain
    The domain name of the tenant (ex. contoso.onmicrosoft.com)
.Parameter studentAadObjectIds
    The AAD object Id(s) of the student(s) for whom the guardians needs to be retrieved. 
.Example
    Get guardian for one student: .\Get-Guardians.ps1 -OutFolder . -clientId "743f3d66-95aa-41d9-237d-45e961251889" -clientSecret "8bK]-[p19402Ac;Y+7<b>5b" -tenantDomain "contoso.onmicrosoft.com" -studentAadObjectIds "ab043123-00aa-60d9-2ab4-12e961702abc"
.Notes
========================
 Required Prerequisites
========================
1. App must be created in customer's Azure account with appropriate app permissions and scopes (Directory.Read.All,EduRoster.Read.All,EduRoster.ReadWrite.All)
2. App must contain a certificate and clientSecret.
3. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'
4. Connect-MgGraph -ClientID 743f3d66-95aa-41d9-237d-45e961251889 -TenantId 8a572b06-4f46-432f-9185-258f6a8d67e6 -CertificateThumbprint <CertificateThumbprint>
5. Import-Module Microsoft.Graph.Education
6. Related Contacts must exist in the uploaded customer CSV files.
========================
#>

Param (
    [Parameter(Mandatory = $false)]
    [string] $OutFolder = ".",
    # [string] $outFolder = ".\GuardiansExport", 

    [Parameter(Mandatory = $true)]
    [string] $clientId,

    [Parameter(Mandatory = $true)]
    [string] $clientSecret,

    [Parameter(Mandatory = $true)]
    [string] $tenantDomain,

    [Parameter(Mandatory = $false)]
    [string] $studentAadObjectIds
)

function Refresh-AccessToken($authToken, $lastRefreshed) {    
    $dateNow = get-date
    if ($lastRefreshed -eq $null -or ($dateNow - $lastRefreshed).Minutes -gt 55) {
        Write-Host "Refreshing Access token"
        $authToken, $lastRefreshed = Get-AccessToken       
    } 

    return $authToken, $lastRefreshed
}

function Get-AccessToken() {
    $tokenUrl = "https://login.windows.net/$tenantDomain/oauth2/token"
    try {
    $tokenBody = @{
        client_id = "$clientId"
        client_secret = "$clientSecret"
        grant_type = "client_credentials"
        resource = "https://graph.microsoft.com"
    }

    Write-Host "Getting access token"
    $tokenResponse = Invoke-RestMethod -Method POST -Uri $tokenUrl -Body $tokenBody
    $authToken = $tokenResponse.access_token
    $lastRefreshed = get-date    
    } catch {
        Write-Error -Exception $_ -Message "Failed to get authentication token for Microsoft Graph. Please check the client Id and secret provided."
        $authToken = $null
    }

    return $authToken, $lastRefreshed
}

function Get-GuardiansForUser($userId, $authToken, $lastRefreshed) {
    $authToken, $lastRefreshed = Refresh-AccessToken -authToken $authToken -lastRefreshed $lastRefreshed
    Write-Progress -Activity "Getting guardians for user $userId"

    $user = invoke-graphrequest -method GET -uri "https://graph.microsoft.com/beta/education/users/$($userid)?`$select=relatedContacts,id,displayName"

    $allContacts = $user.relatedContacts

    $data = @()
    
    foreach($contact in $allContacts)
    {
        $data += [pscustomobject]@{
            "Mobile Phone" = $contact.mobilePhone
            "Relationship" = $contact.relationship
            "Email Address" = $contact.emailAddress
            "DisplayName" = $contact.displayName
            "Access Consent" = $contact.accessConsent
        }
    }

    #Create CSV file
    $fileName = $user.displayName + "-Guardians.csv"
    $filePath = Join-Path $outFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $cnt = ($data | Measure-Object).Count
    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Guardians ..."
        $data | Export-Csv $filePath -Force -NoTypeInformation
        Write-Host "`nGuardians exported to file $filePath `n" -ForegroundColor Green
        return $filePath
    }
    else
    {
        Write-Host "No Guardians found to export."
        return $null
    }
}

$authToken, $lastRefreshed = Get-AccessToken

if ($authToken -eq $null) {
    Write-Host "Authentication Failed"
    return
}

if ($studentAadObjectIds -ne "") {
    $studentAadObjectIdsArr = $studentAadObjectIds.split(',')
    foreach($studentAadObjectId in $studentAadObjectIdsArr) {
        Write-Host "Getting guardians for student object Id $studentAadObjectId"
        Get-GuardiansForUser -userId $studentAadObjectId -authToken $authToken -lastRefreshed $lastRefreshed
    }    
} 

Write-Output "Please run 'Disconnect-Graph' if you are finished.`n"