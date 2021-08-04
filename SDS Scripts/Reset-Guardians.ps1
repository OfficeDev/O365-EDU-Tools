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
.Parameter studentAadObjectIds
    The AAD object Id(s) of the student(s) for whom the guardians needs to be reset. 
.Parameter studentAadObjectIdsCsvFile
    CSV file which has the AAD object Ids of the students for whom the guardians needs to be reset
.Example
    Reset guardian for one student: .\Reset-Guardians.ps1 -OutFolder . -clientId "743f3d66-95aa-41d9-237d-45e961251889" -clientSecret "8bK]-[p19402Ac;Y+7<b>5b" -tenantDomain "contoso.onmicrosoft.com" -studentAadObjectIds "ab043123-00aa-60d9-2ab4-12e961702abc"
    Reset guardian for multiple students (Student AAD object Ids in a comma separated format): .\Reset-Guardians.ps1 -OutFolder . -clientId "743f3d66-95aa-41d9-237d-45e961251889" -clientSecret "8bK]-[p19402Ac;Y+7<b>5b" -tenantDomain "contoso.onmicrosoft.com" -studentAadObjectIds "ab043123-00aa-60d9-2ab4-12e961702abc,df043123-00aa-60d9-2ab4-12e961702xyz"
    Reset guardian for students mentioned in the csv file (Make sure the csv file column header name is studentAadObjectId): .\Reset-Guardians.ps1 -OutFolder . -clientId "743f3d66-95aa-41d9-237d-45e961251889" -clientSecret "8bK]-[p19402Ac;Y+7<b>5b" -tenantDomain "contoso.onmicrosoft.com" -studentAadObjectIdsCsvFile "studentAadObjectIds.csv"
    Reset guardian for all SDS synced students : .\Reset-Guardians.ps1 -OutFolder . -clientId "743f3d66-95aa-41d9-237d-45e961251889" -clientSecret "8bK]-[p19402Ac;Y+7<b>5b" -tenantDomain "contoso.onmicrosoft.com"
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
    [string] $studentAadObjectIds,

    [Parameter(Mandatory = $false)]
    [string] $studentAadObjectIdsCsvFile
)

$logFilePath = "$OutFolder\ResetGuardians.log"

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

function Reset-GuardiansForUser($userId, $authToken, $lastRefreshed) {
    $authToken, $lastRefreshed = Refresh-AccessToken -authToken $authToken -lastRefreshed $lastRefreshed
    $noContacts = @{
        relatedContacts = @()
    }
    Write-Progress -Activity "Resetting guardians for user $userId"    
    $noContactsBody = ConvertTo-Json $noContacts    
    Invoke-RestMethod -Method Patch -Uri "https://graph.microsoft.com/beta/education/users/$userId" -Body $noContactsBody -Headers @{'Authorization'="Bearer $authToken"} -ContentType "application/json" | out-file $logFilePath -Append
}

function Get-AllStudents($authToken, $lastRefreshed) {
    Write-Host "Getting All SDS synced students"
    $students = @()
    $nextLink = "https://graph.microsoft.com/beta/users/?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType eq 'Student'&`$select=id,displayName"
    while ($nextLink -ne $null) {               
        $response = Invoke-RestMethod -Method Get -Uri $nextLink -Headers @{'Authorization'="Bearer $authToken"}
        $students += $response.value
        $nextLink = $response.'@odata.nextLink'
        $authToken, $lastRefreshed = Refresh-AccessToken -authToken $authToken -lastRefreshed $lastRefreshed        
    }
    return $students
}

$authToken, $lastRefreshed = Get-AccessToken

if ($authToken -eq $null) {
    Write-Host "Authentication Failed"
    return
}

if ($studentAadObjectIds -ne "") {
    $studentAadObjectIdsArr = $studentAadObjectIds.split(',')
    foreach($studentAadObjectId in $studentAadObjectIdsArr) {
        Write-Host "Resetting guardians for student object Id $studentAadObjectId"
        Reset-GuardiansForUser -userId $studentAadObjectId -authToken $authToken -lastRefreshed $lastRefreshed
    }    
} elseif ($studentAadObjectIdsCsvFile -ne "") {
    $studentAadObjectIdList = import-csv $studentAadObjectIdsCsvFile
    foreach($studentAadObject in $studentAadObjectIdList) {
        Write-Host "Resetting guardians for student object Id $($studentAadObject.studentAadObjectId)"
        Reset-GuardiansForUser -userId $studentAadObject.studentAadObjectId -authToken $authToken -lastRefreshed $lastRefreshed
    }    
} else {
    $students = Get-AllStudents -authToken $authToken -lastRefreshed $lastRefreshed
    $reply = Read-Host -Prompt "Will reset guardians for $($students.length) students. Continue? [y/n]"
    if ($reply -match "[yY]") {
        foreach($student in $students) {
            Write-Host "Resetting guardians for $($student.displayName), id $($student.id)"
            Reset-GuardiansForUser -userId $student.id -authToken $authToken -lastRefreshed $lastRefreshed
        }    
    }
}