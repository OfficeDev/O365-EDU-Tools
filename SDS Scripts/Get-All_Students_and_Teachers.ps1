<#
Script Name:
Get-All_Students_and_Teachers.ps1

Synopsis:
Description: This script is designed to export all students and teachers, into 2 CSV files (Student.csv and Teacher.csv). This script contains a mix of SDS attributes and standard Azure user object attributes. 

Syntax Examples and Options:
.\Get-All_Students_and_Teachers.ps1

Written By: 
Orginal/Full Script written by TJ Vering. This script was adapted from the orginal by Bill Sluss.

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
