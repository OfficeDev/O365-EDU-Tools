<#
-----------------------------------------------------------------------
 <copyright file="Reset-Guardians.ps1" company="Microsoft">
 Â© Microsoft. All rights reserved.
 </copyright>
-----------------------------------------------------------------------
.Synopsis
    Deletes all guardians associated with SDS synced students

.Description
    This script will query for all SDS synced students and delete all guardians associated with them

.Parameter OutFolder
    The script will output log file here

.Parameter clientId
    The application Id that has EduRoster.ReadWrite.All permission

.Parameter clientSecret
    The secret of the application Id that has EduRoster.ReadWrite.All permission

.Parameter tenantDomain
    The domain name of the tenant (ex. contoso.onmicrosoft.com)

.Parameter studentAadObjectId
    The AAD object Id of the student for whom the guardians needs to be reset

.Example
    .\Reset-Guardians.ps1 -OutFolder . -clientId "940e3d66-95aa-41d9-237d-45e961889107" -clientSecret "2cJ]-[p19402Ac;Y+7<b>5b" -tenantDomain "contoso.onmicrosoft.com" -studentAadObjectId "ab043123-00aa-60d9-2ab4-12e961702abc"
    .\Reset-Guardians.ps1 -OutFolder . -clientId "940e3d66-95aa-41d9-237d-45e961889107" -clientSecret "2cJ]-[p19402Ac;Y+7<b>5b" -tenantDomain "contoso.onmicrosoft.com"
#>

Param (
    [Parameter(Mandatory = $false)]
    [string] $OutFolder = ".",

    [Parameter(Mandatory = $true)]
    [string] $clientId,

    [Parameter(Mandatory = $true)]
    [string] $clientSecret,

    [Parameter(Mandatory = $true)]
    [string] $tenantDomain,

    [Parameter(Mandatory = $false)]
    [string] $studentAadObjectId
)

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
    return $tokenResponse.access_token
    } catch {
        Write-Error -Exception $_ -Message "Failed to get authentication token for Microsoft Graph. Please check the client Id and secret provided."
        return $null
    }
}

function Reset-GuardiansForUser($userId, $authToken) {
    $noContacts = @{
        relatedContacts = @()
    }

    $noContactsBody = ConvertTo-Json $noContacts
    Invoke-RestMethod -Method Patch -Uri "https://graph.microsoft.com/beta/education/users/$userId" -Body $noContactsBody -Headers @{'Authorization'="Bearer $authToken"} -ContentType "application/json" | out-null
}

function Add-Guardian($userId, $email, $displayName, $phone, $relationship, $authToken) {
    $guardian = @{
        DisplayName = $displayName;
        MobilePhone = $phone;
        EmailAddress = $email;
        Relationship = $relationship;
    }

    $guardians = @{
        relatedContacts = @($guardian)
    }

    $guardianJson = ConvertTo-Json $guardians

    Invoke-RestMethod -Method Patch -Uri "https://graph.microsoft.com/beta/education/users/$userId" -Body $guardianJson -Headers @{'Authorization'="Bearer $authToken"} -ContentType "application/json"
}

function Get-AllStudents() {
    $students = @()
    $nextLink = "https://graph.microsoft.com/beta/users/?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType eq 'Student'&`$select=id,displayName"
    while ($nextLink -ne $null) {
        $response = Invoke-RestMethod -Method Get -Uri $nextLink -Headers @{'Authorization'="Bearer $authToken"}
        $students += $response.value
        $nextLink = $response.'@odata.nextLink'
    }
    return $students
}

$authToken = Get-AccessToken

if ($studentAadObjectId -ne "") {
    if ($authToken -eq $null) {
        Write-Host "Authtoken is null"
        return
    }
    Reset-GuardiansForUser -userId $studentAadObjectId -authToken $authToken
} else {
    $students = Get-AllStudents
    $reply = Read-Host -Prompt "Will reset guardians for $($students.length) students. Continue? [y/n]"
    if ($reply -match "[yY]") {
        foreach($student in $students) {
            Write-Host "Resetting guardians for $($student.displayName), id $($student.id)"
            Reset-GuardiansForUser -userId $student.id -authToken $authToken
        }    
    }
}
