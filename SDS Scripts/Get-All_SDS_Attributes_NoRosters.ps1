<#
Script Name:
Get-All_SDS_Attributes_No_Rosters.ps1

Synopsis:
This script is designed to get all SDS objects and attributes, except for Rostering. The result is only 4 CSV files in a trimmed down version of the standard SDS format, as detailed on the page https://aka.ms/sdscsvattributes. The 4 CSV files generated are School.CSV, Section.CSV, Student.CSV, and Teacher.CSV. The 2 files not generated are StudentEnrollment.CSV and TeacherRoster.CSV. This reduces the run overall time of the SDS attributes script by about 80%. If you need all SDS attributes run the Get-All_SDS_Attributes.ps1 instead.

Syntax Examples and Options:
.\Get-All_SDS_Attributes_No_Rosters.ps1

Written By: 
Full/Original SDS attributes export script written by TJ Vering. This script was adapted by the Full/Original by Bill Sluss.

Change Log:
Version 1.0, 12/06/2016 - First Draft
#>

Param (
    [string] $ExportSchools = $true,
    [string] $ExportStudents = $true,
    [string] $ExportTeachers = $true,
    [string] $ExportSections = $true,
    [string] $ExportStudentEnrollments = $true,
    [string] $ExportTeacherRosters = $true,
    [string] $OutFolder = ".",
    [switch] $PPE = $false,
    [switch] $AppendTenantIdToFileName = $false
)

$GraphEndpointProd = "https://graph.windows.net"
$AuthEndpointProd = "https://login.windows.net"

$GraphEndpointPPE = "https://graph.ppe.windows.net"
$AuthEndpointPPE = "https://login.windows-ppe.net"

$NugetClientLatest = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

$eduObjSchool = "School"
$eduObjSection = "Section"
$eduObjTeacher = "Teacher"
$eduObjStudent = "Student"

$eduRelStudentEnrollment = "StudentEnrollment"
$eduRelTeacherRoster = "TeacherRoster"

function Get-PrerequisiteHelp
{
    Write-Output @"
========================
 Required Prerequisites
========================

1. Install Microsoft Online Services Sign-In Assistant v7.0 from http://www.microsoft.com/en-us/download/details.aspx?id=39267

2. Install the AAD PowerShell Module from http://msdn.microsoft.com/en-us/library/azure/jj151815.aspx#bkmk_installmodule

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "Connect-MsolService" to bring up a sign in UI 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell sesion without error, you are correctly set up

5. Retry this script.  If you still get an error about failing to load the MSOnline module, troubleshoot why "Import-Module MSOnline" isn't working

(END)
========================
"@
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
		$nugetDownloadExpression = $nugetClientPath + " install Microsoft.IdentityModel.Clients.ActiveDirectory -source https://www.nuget.org/api/v2/ -Version 2.19.208020213 -OutputDirectory " + $modulePath + "\Nugets"
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
	$ADAL_WindowsForms_Assembly = Join-Path $adal4_5Directory -ChildPath "Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"

	if($ADAL_Assembly.Length -gt 0 -and $ADAL_WindowsForms_Assembly.Length -gt 0){
		Write-Verbose "Loading ADAL Assemblies: `n`t$ADAL_Assembly `n`t$ADAL_WindowsForms_Assembly"
        Write-Debug "file path length for $ADAL_Assembly is $($ADAL_Assembly.Length)"
		[System.Reflection.Assembly]::LoadFrom($ADAL_Assembly) | out-null
		[System.Reflection.Assembly]::LoadFrom($ADAL_WindowsForms_Assembly) | out-null
		return $true
	}
	else{
		Write-Verbose "Fixing Active Directory Authentication Library package directories ..."
		$adalPackageDirectories | Remove-Item -Recurse -Force | Out-Null
		Write-Error "Not able to load ADAL assembly. Delete the Nugets folder under" $modulePath ", restart PowerShell session and try again ..."
	}

    return $false
}

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
 
  $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority,$false
  $promptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Always
  $platformParameter = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList $promptBehavior
  $authResult = $authContext.AcquireTokenAsync([string] $resourceAppIdURI, [string] $clientId, [Uri] $redirectUri, $platformParameter).Result
  
  Write-Output $authResult
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

function Export-SdsSchools
{
    $fileName = $eduObjSchool.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $authToken.TenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $data = Get-SdsSchools
    
    $cnt = ($data | Measure-Object).Count
    $SchoolCount = ($data | Measure-Object).Count
    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Schools ..."
        $data | Export-Csv $filePath -Force -NotypeInformation
        Write-Host "`nSchools exported to file $filePath `n" -ForegroundColor Green
        return $filePath
    }
    else
    {
        Write-Host "No Schools found to export."
        return $null
    }
}

function Get-SdsSchools
{
    $list = Get-Schools
    $data = @()
    foreach($au in $list)
    {
        $data += [pscustomobject]@{
            "SIS ID" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId
            "Name" = $au.DisplayName
            "School Number" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_SchoolNumber 
            "School NCES_ID" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_SchoolNationalCenterForEducationStatisticsId
        }
    }
    return $data
}

function Get-Schools
{
    return Get-AdministrativeUnits $eduObjSchool
}

function Get-AdministrativeUnits
{
    Param
    (
        $eduObjectType
    )

    $list = @()

    $firstPage = $true
    Do
    {
        if ($firstPage)
        {
            $uri = $graphEndPoint + "/" + $authToken.TenantId + "/administrativeUnits?api-version=beta&`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'%20and%20extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"
            #extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'%20and%20
            $firstPage = $false
        }
        else
        {
            $uri = $graphEndPoint + "/" + $authToken.TenantId + "/" + $responseObject.odatanextLink + "&api-version=beta"
        }

        $response = Send-WebRequest "Get" $uri
        $responseString = $response.Content.Replace("odata.", "odata")
        $responseObject = $responseString | ConvertFrom-Json
        foreach ($au in $responseObject.value)
        {
            $list += $au
        }
    }
    While ($responseObject.odatanextLink -ne $null)

    return $list
}

function Export-SdsSections
{
    $fileName = $eduObjSection.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $authToken.TenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $data = Get-SdsSections
    
    $cnt = ($data | Measure-Object).Count
    $SectionCount = ($data | Measure-Object).Count
    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Class Sections ..."
        $data | Export-Csv $filePath -Force -NotypeInformation
        Write-Host "`nClass Sections exported to file $filePath `n" -ForegroundColor Green
        return $filePath
    }
    else
    {
        Write-Host "No Class Sections found to export."
        return $null
    }
}

function Get-SdsSections
{
    $groups = Get-Sections
    $data = @()
    foreach($group in $groups)
    {
        $data += [pscustomobject]@{
            "SIS ID" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId
            "School SIS ID" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId
            "Section Name" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_SectionName                   
            "Section Number" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_SectionNumber
            "Term Name" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_TermName
            "Term StartDate" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_TermStartDate
            "Term EndDate" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_TermEndDate
            "Status" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_Status
            "ObjectID" = $group.objectID
        }
    }

    return $data
}

function Get-Sections
{
    return Get-Groups $eduObjSection 
}

function Get-Groups
{
    Param
    (
        $eduObjectType
    )

    $list = @()

    $firstPage = $true
    Do
    {
        if ($firstPage)
        {
            $uri = $graphEndPoint + "/" + $authToken.TenantId + "/groups?api-version=1.6&`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'%20and%20extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"
            #extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'%20and%20
            #"ObjectId, DisplayName, Mail, Source ID" | Out-File $filePath -Append
            $firstPage = $false
        }
        else
        {
            $uri = $graphEndPoint + "/" + $authToken.TenantId + "/" + $responseObject.odatanextLink + "&api-version=1.6"
        }
        # Write-Host "GET: $uri"

        $response = Send-WebRequest "Get" $uri
        $responseString = $response.Content.Replace("odata.", "odata")
        $responseObject = $responseString | ConvertFrom-Json
        foreach ($group in $responseObject.value)
        {
            $list += $group


            #$group.ObjectId + ", " + $group.DisplayName + ", " + $group.Mail + ", " + $group.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId | Out-File $filePath -Append
        }
    }
    While ($responseObject.odatanextLink -ne $null)

    return $list
}



function Get-SdsSection
{
    Param
    (
        $sectionId
    )
    $uri = $graphEndPoint + "/" + $authToken.TenantId + "/groups?api-version=1.6&`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'%20and%20extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId%20eq%20'$sectionId'"
    #extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'%20and%20
    #Write-Host $uri
    $response = Send-WebRequest "Get" $uri
    $responseString = $response.Content.Replace("odata.", "odata")
    $responseObject = $responseString | ConvertFrom-Json
    foreach ($group in $responseObject.value)
    {
        return $group
    }
    return $null
}

function Get-Section
{
    Param
    (
        $objectId
    )
    $uri = $graphEndPoint + "/" + $authToken.TenantId + "/groups/" + $objectId + "?api-version=1.6"
    #Write-Host $uri
    $response = Send-WebRequest "Get" $uri
    $responseString = $response.Content.Replace("odata.", "odata")
    $responseObject = $responseString | ConvertFrom-Json
    foreach ($group in $responseObject)
    {
        if ($group.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType = $eduObjSection)
        {
            return $group
        }
    }
    return $null
}


function Export-SdsTeachers
{
    $fileName = $eduObjTeacher.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $authToken.TenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $data = Get-SdsTeachers

    $cnt = ($data | Measure-Object).Count
    $TeacherCount = ($data | Measure-Object).Count
    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Teachers ..."
        $data | Export-Csv $filePath -Force -NotypeInformation
        Write-Host "`nTeachers exported to file $filePath `n" -ForegroundColor Green
        return $filePath
    }
    else
    {
        Write-Host "No Teachers found to export."
        return $null
    }
}

function Get-SdsTeachers
{
    $users = Get-Teachers
    $data = @()
    foreach($user in $users)
    {
        $data += [pscustomobject]@{
	    "DisplayName" = $user.DisplayName  
            "UserPrincipalName" = $user.userPrincipalName          
	    "SIS ID" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_TeacherId
            "School SIS ID" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId
            "Teacher Number" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_TeacherNumber
            "Status" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_TeacherStatus
            "Secondary Email" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_Email
	    "ObjectID" = $user.objectID
        }
    }
    return $data
}

function Get-Teachers
{
    return Get-Users $eduObjTeacher
}

function Export-SdsStudents
{
    $fileName = $eduObjStudent.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $authToken.TenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore
    
    $data = Get-SdsStudents

    $cnt = ($data | Measure-Object).Count
    $StudentCount = ($data | Measure-Object).Count
    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Students ..."
        $data | Export-Csv $filePath -Force -NotypeInformation
        Write-Host "`nStudents exported to file $filePath `n" -ForegroundColor Green
        return $filePath
    }
    else
    {
        Write-Host "No Students found to export."
        return $null
    }
}

function Get-SdsStudents
{
    $users = Get-Students
    $data = @()
    foreach($user in $users)
    {
        $data += [pscustomobject]@{
	    "DisplayName" = $user.displayname
	    "UserPrincipalName" = $user.userPrincipalName        
	    "SIS ID" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_StudentId
            "School SIS ID" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId
            "Student Number" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_StudentNumber
            "Status" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_StudentStatus
            "Secondary Email" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_Email
	    "ObjectID" = $user.ObjectID
        }
    }

    return $data
}

function Get-Students
{
    return Get-Users $eduObjStudent
}

function Get-Users
{
    Param
    (
        $eduObjectType
    )

    $list = @()

    $firstPage = $true
    Do
    {
        if ($firstPage)
        {
            $uri = $graphEndPoint + "/" + $authToken.TenantId + "/users?api-version=1.6&`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"
            #extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'%20and%20
            $firstPage = $false
        }
        else
        {
            $uri = $graphEndPoint + "/" + $authToken.TenantId + "/" + $responseObject.odatanextLink + "&api-version=1.6"
        }
        # Write-Host "GET: $uri"

        $response = Send-WebRequest "Get" $uri
        $responseString = $response.Content.Replace("odata.", "odata")
        $responseObject = $responseString | ConvertFrom-Json

        foreach ($user in $responseObject.value)
        {
            $list += $user
        }
    }
    While ($responseObject.odatanextLink -ne $null)

    return $list
}

# Main
$graphEndPoint = $GraphEndpointProd
$authEndPoint = $AuthEndpointProd
if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
    $authEndPoint = $AuthEndpointPPE
}

$activityName = "Reading SDS objects in the directory"

try
{
    Import-Module MSOnline | Out-Null
}
catch
{
    Write-Error "Failed to load MSOnline PowerShell Module."
    Get-PrerequisiteHelp | Out-String | Write-Error
    throw
}

# Connect to the tenant
Write-Progress -Activity $activityName -Status "Connecting to tenant"

Get-MsolDomain -ErrorAction SilentlyContinue | Out-Null
if(-Not $?)
{
    Connect-MsolService -ErrorAction Stop
}

$adalLoaded = Load-ActiveDirectoryAuthenticationLibrary
if ($adalLoaded)
{
    $authToken = Get-AuthenticationResult
    if ($authToken -eq $null)
    {
        Write-Error "Could not authenticate and obtain token from AAD tenant."
        Get-PrerequisiteHelp | Out-String | Write-Error
        Exit
    }
}
else
{
    Write-Error "Could not load dependent libraries required by the script."
    Get-PrerequisiteHelp | Out-String | Write-Error
    Exit
}

Write-Progress -Activity $activityName -Status "Connected. Discovering tenant information"
$tenantInfo = Get-MsolCompanyInformation
$tenantId =  $tenantInfo.ObjectId
$tenantDisplayName = $tenantInfo.DisplayName
$tenantdd = (get-msoldomain | ? {$_.name -like "*onmicrosoft*"}).name
$ClassLicenses = get-msolaccountsku | ? {$_.accountskuid -like "*CLASSDASH*"}
$StudentLicenses = (Get-MsolAccountSku | ? {$_.accountskuid -like "*Student*"}).consumedunits
$StudentLicensesApplied = ($StudentLicenses | Measure-Object -Sum).sum
$TeacherLicenses = (Get-MsolAccountSku | ? {$_.accountskuid -like "*Faculty*"}).consumedunits
$TeacherLicensesApplied = ($TeacherLicenses | Measure-Object -Sum).sum

# Create output folder if it does not exist
if ((Test-Path $OutFolder) -eq 0)
{
	mkdir $OutFolder;
}

    # Export all User of Edu Object Type Teacher/Student
    Write-Progress -Activity $activityName -Status "Fetching Teachers ..."
    Export-SdsTeachers | out-null

    Write-Progress -Activity $activityName -Status "Fetching Students ..."
    Export-SdsStudents | out-null

    # Export all AUs of Edu Object Type School
    Write-Progress -Activity $activityName -Status "Fetching Schools ..."
    Export-SdsSchools | out-null
    
    # Export all Groups of Edu Object Type Section
    Write-Progress -Activity $activityName -Status "Fetching Class Sections ..."
    Export-SdsSections | out-null
    
#Write Tenant Details to the PS screen
write-host -foregroundcolor green "Tenant Name is $tenantDisplayName"
write-host -foregroundcolor green "TenantID is $tenantId"
write-host -foregroundcolor green "Tenant default domain is $tenantdd"

If ($ClassLicenses) {
write-host -foregroundcolor green "Tenant does contain Classroom Licenses"
$CRLicensesApplied = ($ClassLicenses).consumedunits
write-host -foregroundcolor green "The number of classroom licenses currently applied is $CRLicensesApplied"
}
Else {
write-host -foregroundcolor red "Tenant does not contain Classroom Licenses"
}

write-host -foregroundcolor green "The number of student licenses currently applied is $StudentLicensesApplied"
write-host -foregroundcolor green "The number of teacher licenses currently applied is $TeacherLicensesApplied"
Write-Output "`nDone.`n"
