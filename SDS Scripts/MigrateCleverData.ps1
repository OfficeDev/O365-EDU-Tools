<#
-----------------------------------------------------------------------
 <copyright file="MigrateCleverData.ps1" company="Microsoft">
 © Microsoft. All rights reserved.
 </copyright>
-----------------------------------------------------------------------
.Synopsis
    Helps in migrating data synced using the Clever API format using Microsoft School Data Sync to the Clever CSV format
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$True)]
    [string] $cleverFormatSchoolFilePath,

    [string] $OutFolder = ".",

    [string] $ArchivedSectionsPrefix = "SDSArchived",
    
    [ValidateSet('AzureCloud', 'AzurePPE')]
    [string] $AzureEnvironment = "AzureCloud"
)

# Azure enviroment variables
$GraphEndpointProd = "https://graph.microsoft.com"
$AuthEndpointProd = "https://login.windows.net"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"
$AuthEndpointPPE = "https://login.windows-ppe.net"
$GraphVersion = "beta"
$BatchSize = 5

$NugetSource = "https://www.nuget.org/api/v2/"
$AdalPackageName = "Microsoft.IdentityModel.Clients.ActiveDirectory"
$AdalNugetVersion = "2.28.1"
$NugetClientLatest = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$LogInstanceFileName = ("MigrationLog.log")
$ErrorLogInstanceFileName = ("MigrationErrorLog.log")
$DefaultForegroundColor = "White"

# Authorization token constants
$ClientId = "1950a258-227b-4e31-a9cf-717495945fc2"
$RedirectUri = [Uri] "urn:ietf:wg:oauth:2.0:oob"

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
        $messageToLog = "[$type]: $message"
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
            $foregroundColor = $DefaultForegroundColor
        }

        Write-Host $message -ForegroundColor $foregroundColor
    }
    catch { } 
}

<#
.Synopsis
    Writes messages to log file only
#>
function Write-Log($message)
{
    $logFile = Join-Path $OutFolder $LogInstanceFileName
    $message | Out-File -FilePath $logFile -Append
}

<#
.Synopsis
    Writes messages to error log file
#>
function Write-ErrorLog($message)
{
    $logFile = Join-Path $OutFolder $ErrorLogInstanceFileName
    $errorMessage = ((get-date).ToUniversalTime()).ToString("yyyy-MM-dd_HH-mm-ssZ") + $message
    $errorMessage | Out-File -FilePath $logFile -Append
    Write-Log $errorMessage
}

<#
.Synopsis
    Gets the object count in a CSV
#>
function Get-CSVObjectCount($objects)
{
    $result =  $objects | Measure-Object
    return $result.Count
}

<#
.Synopsis
    Loads modules and DLLs required to run this script.
    ADAL package is downloaded from nuget server if not available.
#>
function Load-ActiveDirectoryAuthenticationLibrary 
{
    $modulePath = $ENV:Temp + "\AADGraph"
    $nugetPackagePath = $modulePath + "\Nugets"
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
        Write-Message "[Load-ADAL] Active Directory Authentication Library Nuget doesn't exist. Downloading now: $nugetDownloadExpression"
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
    Acquires the authentication result and sets it at the global scope. This is to acquire an OAuth2token for graph API calls.
#>
function Acquire-AuthenticationResult($resourceAppIdURI)
{
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $global:authority,$false
    $promptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Always
    $global:authToken = $authContext.AcquireToken([string] $resourceAppIdURI, [string] $ClientId, [Uri] $RedirectUri, $promptBehavior)
}

<#
.Synopsis
    Acquires the authentication result from the refresh token and sets it at the global scope. This is to acquire an OAuth2token for graph API calls.
#>
function Acquire-AuthenticationResultFromRefreshToken
{
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $global:authority,$false
    $global:authToken = $authContext.AcquireTokenByRefreshToken([string] $($global:authToken.RefreshToken), [string] $ClientId)
}

<#
.Synopsis
    Invoke web request. Based on http request method, it constructs request headers using $global:authToken.
    Response is in json format. If token expired, it will ask user to refresh token. Max retry time is 5.
.Parameter method
    Http request method
.Parameter uri
    Http request uri
.Parameter payload
    Http request payload. Not used if method is Get.
#>
function Send-WebRequest ($method, $uri, $payload)
{
    $response = ""
    $expiresOn = $global:authToken.ExpiresOn.UtcDateTime.AddMinutes(-1)
    $now = (Get-Date).ToUniversalTime()
    if ($expiresOn -lt $now) {
        Get-AuthenticationResultFromRefreshToken
    }

    if ($method -ieq "get") {
        $headers = @{ "Authorization" = "Bearer " + $global:authToken.AccessToken }
        $response = Invoke-WebRequest -Method $method -Uri $uri -Headers $headers
    }
    else {
        $headers = @{ 
            "Authorization" = "Bearer " + $global:authToken.AccessToken
            "Content-Type" = "application/json"
        }

        $response = Invoke-WebRequest -Method $method -Uri $uri -Headers $headers -Body $payload
    }

    return $response
}

<#
.Synopsis
    Generates a batch request for the graph calls.
#>
function Generate-BatchRequestContent($id, $method, $uri, $payload)
{
    $headers = New-Object System.Object
    $headers | Add-Member -type NoteProperty -name "Content-Type" -value "application/json"
    
    $request = New-Object System.Object
    $request | Add-Member -type NoteProperty -name "id" -value $id
    $request | Add-Member -type NoteProperty -name "method" -value $method
    $request | Add-Member -type NoteProperty -name "url" -value $uri
    $request | Add-Member -type NoteProperty -name "headers" -value $headers

    $body = New-Object System.Object
    foreach ($key in $payload.Keys)
    {
        $body | Add-Member -type NoteProperty -name $key -value $payload[$key]
    }
    $request | Add-Member -type NoteProperty -name "body" -value $body

    return $request
}

<#
.Synopsis
    Sends a batch request for the graph calls and returns if all calls were a success or not
#>
function Send-BatchRequest($requests)
{
    $requestsJson = $requests | ConvertTo-Json
    if($requests.Count -gt 1)
    {
        $requestJson = [string]::Format("{{`"requests`":{0}}}", $requestsJson)
    }
    else
    {
        $requestJson = [string]::Format("{{`"requests`":[{0}]}}", $requestsJson)
    }

    $uri = [string]::Format("{0}/beta/`$batch", $global:graphEndPoint)
    $responses = Send-WebRequest -uri $uri -method "POST" -payload $requestJson
    
    $responseObject = $responses.Content | ConvertFrom-Json

    $isSuccess = $true
    foreach ($response in $responseObject.responses) 
    {
        Write-Log ([string]::Format("{0} : StatusCode: {1}",$($response.id), $($response.status)))
        if ($response.status -ne 204)
        {
            $errorMsg = [string]::Format("{0} : StatusCode: {1} Code: {2}`nMessage: {3}`nRequestId: {4}`n",$($response.id), $($response.status), $($response.body.error.code), $($response.body.error.message), $($response.body.error.innerError.'request-id'))
            Write-ErrorLog $errorMsg
            $request = $requests | Where-Object {$_.id -ieq $response.id} | Select-Object -First 1
            Write-Log $request
            $msg = [string]::Format("Failed to update object with index: {0}",$($response.id))
            Write-Message $msg Red
            $isSuccess = $false
        }
    }

    return $isSuccess
}

<#
.Synopsis
    Gets the administrative unit of type School from Graph
#>
function Get-AdministrativeUnits
{
    $fileName = "School-AUs-" + $global:authToken.TenantId +".csv"
    $filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore
    
    $firstPage = $true
    do
    {
        if ($firstPage)
        {
            $queryParams = "`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'School'%20and%20extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'Clever'" +
                            "&`$select=id,DisplayName,extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId"
            $uri = [string]::Format("{0}/{1}/administrativeUnits?{2}", $global:graphEndPoint, $GraphVersion, $queryParams);

            "ObjectId, DisplayName, AnchorId, SyncSource, SchoolId" | Out-File $filePath -Append
            $firstPage = $false
        }
        else
        {
            $uri = $responseObject.odatanextLink
        }

        $response = Send-WebRequest "Get" $uri
        $responseString = $response.Content.Replace("@odata.", "odata")
        $responseObject = $responseString | ConvertFrom-Json
        foreach ($au in $responseObject.value)
        {
            $au.id + ", " + 
            $au.DisplayName + ", " + 
            $au.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId + ", " + 
            $au.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource + ", " +
            $au.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId | Out-File $filePath -Append
        }
    }
    while ($responseObject.odatanextLink -ne $null)

    return $filePath
}

<#
.Synopsis
    Gets the section groups for the given school clever Id. Returns the file path of the logged sections.
#>
function Get-SectionGroups ($schoolCleverId, $eduObjectType = "Section")
{
    $fileName = $eduObjectType + "-Groups-" + $global:authToken.TenantId + "-" + $schoolCleverId + ".csv"
    $filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore
    
    $firstPage = $true
    do
    {
        if ($firstPage)
        {
            $queryParams = "`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'Clever'%20and%20extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'" 
            if ($schoolCleverId -ne $null)
            {
                $queryParams = $queryParams + "%20and%20extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId%20eq%20'$schoolCleverId'"
            }
            $queryParams = $queryParams + "&`$select=id,DisplayName,Mail,extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId"
            $uri = [string]::Format("{0}/{1}/groups?{2}", $global:graphEndPoint, $GraphVersion, $queryParams);
            
            "ObjectId, DisplayName, Mail, AnchorId, SyncSource, SectionId, SchoolId" | Out-File $filePath -Append
            $firstPage = $false
        }
        else
        {
            $uri = $responseObject.odatanextLink
        }

        $response = Send-WebRequest "Get" $uri
        $responseString = $response.Content.Replace("@odata.", "odata")
        $responseObject = $responseString | ConvertFrom-Json
        foreach ($group in $responseObject.value)
        {
            $group.id + ", " + 
            $group.DisplayName + ", " + 
            $group.Mail + ", " + 
            $group.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId + ", " + 
            $group.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource + ", " +
            $group.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId + ", " + 
            $group.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId | Out-File $filePath -Append
        }
    }
    while ($responseObject.odatanextLink -ne $null)

    return $filePath
}


<#
.Synopsis
    Gets the users of type Student/Teacher defined as per $eduObjectType for the given school clever Id. Returns the file path of the logged users.
#>
function Get-Users ($schoolCleverId, $eduObjectType)
{
    $fileName = $eduObjectType + "-Users-" + $global:authToken.TenantId + "-" + $schoolCleverId + ".csv"
    $filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore
    
    $firstPage = $true
    do
    {
        if ($firstPage)
        {
            $queryParams = "`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'Clever'%20and%20extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'" 
            if ($schoolCleverId -ne $null)
            {
                $queryParams = $queryParams + "%20and%20extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId%20eq%20'$schoolCleverId'"
            }
            $queryParams = $queryParams + "&`$select=id,DisplayName,Mail,extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_StudentId,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_TeacherId,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"
            $uri = [string]::Format("{0}/{1}/users?{2}", $global:graphEndPoint, $GraphVersion, $queryParams);

            "ObjectId, DisplayName, Mail, AnchorId, SyncSource, StudentId, TeacherId, SchoolId, ObjectType" | Out-File $filePath -Append
            $firstPage = $false
        }
        else
        {
            $uri = $responseObject.odatanextLink
        }

        $response = Send-WebRequest "Get" $uri
        $responseString = $response.Content.Replace("@odata.", "odata")
        $responseObject = $responseString | ConvertFrom-Json
        foreach ($user in $responseObject.value)
        {
            $user.Id + ", " + 
            $user.DisplayName + ", " + 
            $user.Mail + ", " + 
            $user.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId + ", " + 
            $user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource + ", " +
            $user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_StudentId + ", " + 
            $user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_TeacherId + ", " + 
            $user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId + ", " + 
            $user.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType | Out-File $filePath -Append
        }
    }
    while ($responseObject.odatanextLink -ne $null)

    return $filePath
}

<#
.Synopsis
    Updates the school administrative units present in the $auListFileName for those schools present in the $schoolsToUpdate list. The corresponding SIS Ids are present in the $schoolsMapping dictionary. 
#>
function Update-AdminstrativeUnits ($auListFileName, $schoolsToUpdate, $schoolsMapping)
{
    $isSuccess = $true
    try {
        Write-Progress -Activity $global:activityName -Status "Updating Adminitrative Units"
        $auList = import-csv $auListFileName
        $auCount = Get-CSVObjectCount $auList
        $index = 1
        $updateRequests = @()
        foreach ($au in $auList) 
        {
            $complete = [int]($index/$auCount * 100)
            Write-Progress -Activity $global:activityName -Status "Updating School Adminitrative Units [$index/$auCount]" -PercentComplete $complete

            $schoolId = $au.SchoolId
            if ($schoolsToUpdate -contains $schoolId) {
                Write-Message "[$index/$auCount] Updating Administrative Unit `"$($au.DisplayName)`" [$($au.ObjectId)] from directory" Cyan

                $updateUrl = [string]::Format("/administrativeUnits/{0}", $au.ObjectId)
                Write-Log ([string]::Format("{0} :{1}",$index, $updateUrl))
                $updatePayload = @{}
                $updatePayload.Add("extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId", "School_"  + $schoolsMapping[$schoolId])
                $updatePayload.Add("extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource", "SIS")
                
                $request = Generate-BatchRequestContent $index "PATCH" $updateUrl $updatePayload
                $updateRequests = $updateRequests + $request
            }
            else {
                Write-Message "School Adminitrative Unit for $($au.DisplayName) will not be updated as all the referenced objects of this school were not successfully migrated." Red
            }

            if (($updateRequests.Count -eq $BatchSize) -or ($index -eq $auCount))
            {
                $requestSuccessful = Send-BatchRequest $updateRequests
                $isSuccess = $isSuccess -and $requestSuccessful
                $updateRequests = @()
            }

            $index++
        }
    }
    catch {
        Write-ErrorLog $_.Exception.Message
        $isSuccess = $false
    }

    return $isSuccess
}

<#
.Synopsis
    Updates the sections present in the $groupListFileName. The corresponding SIS Id for the school of these section is given by the $schoolId. 
#>
function Update-Groups ($groupListFileName, $schoolId)
{
    $isSuccess = $true
    try {
        Write-Progress -Activity $global:activityName -Status "Updating Groups"
        $groupList = import-csv $groupListFileName
        $groupCount = Get-CSVObjectCount $groupList
        $index = 1
        $updateRequests = @()
        foreach ($group in $groupList) 
        {
            $complete = [int]($index/$groupCount * 100)
            Write-Progress -Activity $global:activityName -Status "Updating Section Groups [$index/$groupCount]" -PercentComplete $complete
            Write-Message "[$index/$groupCount] Updating Group `"$($group.DisplayName)`" [$($group.ObjectId)] from directory" Cyan
            
            if($ArchivedSectionsPrefix.EndsWith(' '))
            {
                $archivedSectionName = $ArchivedSectionsPrefix + $group.DisplayName
            }
            else
            {
                $archivedSectionName = $ArchivedSectionsPrefix + " "  +  $group.DisplayName
            }

            $updateUrl = [string]::Format("/groups/{0}", $group.ObjectId)
            Write-Log ([string]::Format("{0} :{1}",$index, $updateUrl))
            $updatePayload = @{}
            $updatePayload.Add("extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId", $schoolId)
            $updatePayload.Add("extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId", "SDSArchived_"  + $group.AnchorId)
            $updatePayload.Add("displayName", $archivedSectionName)
            $updatePayload.Add("extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource", "SIS")
            $updatePayload.Add("extension_fe2174665583431c953114ff7268b7b3_Education_Status", "Archived")
            
            $request = Generate-BatchRequestContent $index "PATCH" $updateUrl $updatePayload
            $updateRequests = $updateRequests + $request

            if (($updateRequests.Count -eq $BatchSize) -or ($index -eq $groupCount))
            {
                $requestSuccessful = Send-BatchRequest $updateRequests
                $isSuccess = $isSuccess -and $requestSuccessful
                $updateRequests = @()
            }
            
            $index++
        }
    }
    catch {
        Write-ErrorLog $_.Exception.Message
        $isSuccess = $false
    }

    return $isSuccess
}

<#
.Synopsis
    Updates the users present in the $userListFileName. The corresponding SIS Id for the school of these users is given by the $schoolId. 
#>
function Update-Users ($userListFileName, $schoolId)
{
    $isSuccess = $true
    try {
        Write-Progress -Activity $global:activityName -Status "Updating Users"
        $userList = import-csv $userListFileName
        $userCount = Get-CSVObjectCount $userList
        $index = 1
        $updateRequests = @()
        foreach ($user in $userList) 
        {
            $complete = [int]($index/$userCount * 100)
            Write-Progress -Activity $global:activityName -Status "Updating Users [$index/$userCount]" -PercentComplete $complete
            Write-Message "[$index/$userCount] Updating User `"$($user.DisplayName)`" [$($user.ObjectId)] from directory" Cyan
            if ($user.ObjectType -eq "Student")
            {
                $anchorId = "Student_" + $user.StudentId
            }
            else {
                $anchorId = "Teacher_" + $user.TeacherId
            }

            $updateUrl = [string]::Format("/users/{0}", $user.ObjectId)
            Write-Log ([string]::Format("{0} :{1}",$index, $updateUrl))
            $updatePayload = @{}
            $updatePayload.Add("extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId", $schoolId)
            $updatePayload.Add("extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId", $anchorId)
            $updatePayload.Add("extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource", "SIS")

            $request = Generate-BatchRequestContent $index "PATCH" $updateUrl $updatePayload
            $updateRequests = $updateRequests + $request

            if (($updateRequests.Count -eq $BatchSize) -or ($index -eq $userCount))
            {
                $requestSuccessful = Send-BatchRequest $updateRequests
                $isSuccess = $isSuccess -and $requestSuccessful
                $updateRequests = @()
            }

            $index++
        }
    }
    catch {
        Write-ErrorLog $_.Exception.Message
        $isSuccess = $false
    }

    return $isSuccess
}

<#
.Synopsis
    Maps the schools present in AAD and the file on thier name and creates a mapping for each school clever id with the corresponding school sis id.  
#>
function Map-AdministrativeUnits ($schoolFilePath, $cleverFormatSchoolFilePath)
{
    Write-Progress -Activity $global:activityName -Status "Mapping existing School Administrative Units to the school.csv file"
    $auList = import-csv $schoolFilePath
    $csvList = import-csv $cleverFormatSchoolFilePath | select School_id, School_name
    $totalSchoolsInCleverCSVFile = Get-CSVObjectCount $csvList
    $mapping = @{}
    foreach ($au in $auList) 
    {
        if ($csvList.School_name -contains $au.DisplayName)
        {
            if ($totalSchoolsInCleverCSVFile -gt 1)
            {
                $schoolId = $csvList.Where({$PSItem.School_name -eq $au.DisplayName}).School_id
            }
            else 
            {
                $schoolId = $csvList.School_id
            }

            $message = "School " + $au.DisplayName + " found in csv with SIS Id as " + $schoolId + " and Clever Id as " + $au.SchoolId
            Write-Message $message Cyan
            $mapping.Add($au.SchoolId, $schoolId)
        }
        else
        {
            $message = "School " + $au.DisplayName + " not found in csv."
            Write-Message $message Red
        }
    }

    return $mapping
}

<#
.Synopsis
     Processes the Sections, Students and Teachers of the school by fetching and updating them.
#>
function Process-AADObjects ($schoolCleverId, $schoolSisId, $schoolName)
{
    Write-Progress -Activity $global:activityName -Status "Fetching all Section Groups of $schoolName"
    $sectionFilePath = Get-SectionGroups $schoolCleverId
    $isSectionUpdateSuccessful = Update-Groups $sectionFilePath $schoolSisId
    if($isSectionUpdateSuccessful)
    {
        Write-Message "$schoolName : Section Groups updation completed successfully from file $sectionFilePath" Green
    }
    else
    {
        Write-Message "$schoolName : Section Groups updation completed with errors from file $sectionFilePath" Red
    }

    Write-Progress -Activity $global:activityName -Status "Fetching all Student Users of $schoolName"
    $studentFilePath = Get-Users $schoolCleverId "Student"
    $isStudentUpdateSuccessful = Update-Users $studentFilePath $schoolSisId
    if($isStudentUpdateSuccessful)
    {
        Write-Message "$schoolName : Student Users updation completed successfully from file $studentFilePath" Green
    }
    else
    {
        Write-Message "$schoolName : Student Users updation completed with errors from file $studentFilePath" Red
    }

    Write-Progress -Activity $global:activityName -Status "Fetching all Teacher Users of $schoolName"
    $teacherFilePath = Get-Users $schoolCleverId "Teacher"
    $isTeacherUpdateSuccessful = Update-Users $teacherFilePath $schoolSisId
    if($isTeacherUpdateSuccessful)
    {
        Write-Message "$schoolName : Teacher Users updation completed successfully from file $teacherFilePath" Green
    }
    else
    {
        Write-Message "$schoolName : Teacher Users updation completed with errors from file $teacherFilePath" Red
    }

    $isUpdateSuccessful = $isSectionUpdateSuccessful -and $isStudentUpdateSuccessful -and $isTeacherUpdateSuccessful
    return $isUpdateSuccessful
}


# Main
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

    # Create output folder if it does not exist
    $dateTime = Get-Date -Format FileDateTime
    $folderName = "MigrateCleverData-" + $dateTime
    $OutFolder = Join-Path $OutFolder $folderName
    if (!(Test-Path $OutFolder))
    {
        $folder = mkdir $OutFolder;
    }

    if ($ArchivedSectionsPrefix.Length -lt 2)
    {
        Write-Message "`nThe archived sections prefix cannot be less than 2 characters.`n`n" Red
        exit -1
    }

    if ($ArchivedSectionsPrefix.Length -gt 15)
    {
        Write-Message "`nThe archived sections prefix cannot be more than 15 characters.`n`n" Red
        exit -1
    }

    $global:activityName = "Performing pre-requisite checks..."

    Write-Progress -Activity $global:activityName -Status "Checking for Clever format file schools.csv"
    if (!(Test-Path $CleverFormatSchoolFilePath))
    {
        Write-Message "The path to the Clever format CSV file schools.csv id {$CleverFormatSchoolFilePath} is incorrect. Please provide the correct file path. [Eg: `"C:\Data\schools.csv`"]" Red
        exit -1
    }
    $cleverFormatFileName = (Get-Item $CleverFormatSchoolFilePath).Name
    if ($cleverFormatFileName -ne "schools.csv")
    {
        Write-Message "The Clever format file path should contain schools.csv at the end. [Eg: `"C:\Data\schools.csv`"]" Red
        exit -1
    }

    # Connect to the tenant
    Write-Progress -Activity $global:activityName -Status "Connecting to tenant"
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
    Write-Progress -Activity $global:activityName -Status "Connected"
    $global:activityName = "Fetching SDS Objects in Directory"

    # Get all AUs of Edu Object Type School
    Write-Progress -Activity $global:activityName -Status "Fetching all School Administrative Units"
    $schoolFilePath = Get-AdministrativeUnits
    Write-Message "`nSchool Administrative Units logged to file $OutputFileName `n" Green

    Write-Progress -Activity $global:activityName -Status "Mapping existing School Administrative Units to the school.csv file"
    $schoolMapping = Map-AdministrativeUnits $schoolFilePath $CleverFormatSchoolFilePath
    $schools = import-csv $schoolFilePath
    $totalSchools = Get-CSVObjectCount $schools
    $schoolsMapped = $schoolMapping.Keys.Count
    if($schoolsMapped -gt 0)
    {
        Write-Message "Successfully mapped [$schoolsMapped/$totalSchools] School Administrative Units `n" Green
    }

    $index = 1
    $successfulSchools = @()
    $isSchoolsUpdateSuccessful = $true
    if ($schoolsMapped -gt 0)
    {
        foreach ($schoolCleverId in $schoolMapping.Keys)
        {
            if($totalSchools -gt 1)
            {
                $schoolRow = $schools.Where({$PSItem.SchoolId -eq $schoolCleverId})
                $schoolName = $schoolRow.DisplayName
            }
            else
            {
                $schoolName = $schools.DisplayName
            }

            $global:activityName = "Processing school [$index/$schoolsMapped] : $schoolName"
            
            $isUpdateSuccessful = Process-AADObjects $schoolCleverId $schoolMapping[$schoolCleverId] $schoolName
            
            if($isUpdateSuccessful) {
                Write-Message "All sections, students and teachers of $schoolName updated succssfully.`n" Green
                $successfulSchools += $schoolCleverId
            }
            else {
                Write-Message "Some sections, students and teachers of school $schoolName did not update succssfully.`n" Red
            }

            $index++
        }

        Write-Progress -Activity $global:activityName -Status "Updating schools"
        $isSchoolsUpdateSuccessful = Update-AdminstrativeUnits $schoolFilePath $successfulSchools $schoolMapping
    }

    $processUnmappedObjects = $true
    if ($isSchoolsUpdateSuccessful -and $successfulSchools.Count -eq $totalSchools) {
        Write-Message "`nAll schools, sections, students and teachers have been successfully migrated.`n`n" Green
    }
    else {
        Write-Message "`nSome schools, sections, students or teachers did not migrate. Please rerun the script.`n`n" Red
        $processUnmappedObjects = $false
    }

    if($processUnmappedObjects)
    {
        $global:activityName = "Processing unampped schools in directory"
        $isUpdateSuccessful = Process-AADObjects $null "Unmapped" "Unmapped School"

        if($isUpdateSuccessful) {
            Write-Message "Migration completed succssfully.`n" Green
        }
        else {
            Write-Message "Please rerun the script as some objects did not migrate.`n" Red
        }
    }
}
catch 
{
    Write-ErrorLog $_.Exception.Message
    Write-Message "`n`nException occured while script execution. Please rerun the script.`n`n" Red
}