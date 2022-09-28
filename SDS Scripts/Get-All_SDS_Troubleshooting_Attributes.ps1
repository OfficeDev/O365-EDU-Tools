<#
.SYNOPSIS
This Script is designed to be a lighter version of the Get-All_SDS_Attributes.ps1 script, and contain only the attributes required for troubleshooting common SDS sync errors.

.DESCRIPTION
The result is 6 CSV files; however these CSV files are not in the standard SDS format documented at https://aka.ms/sdscsvattributes. The attributes exported are trimmed down, only contains pertinent attributes needed for troubleshooting. This output also contains attributes associated with standard Azure object types, such as DisplayName, and UserPrincipalName. This script focuses mainly on source anchor attributes, identity matching attributes, and pertinent object level azure attributes to easily identity objects in Azure AD, and troubleshoot sync issues.

.EXAMPLE
.\Get-All_SDS_Troubleshooting_Attributes.ps1
#>

Param (
    [string] $ExportSchools = $true,
    [string] $ExportStudents = $true,
    [string] $ExportTeachers = $true,
    [string] $ExportSections = $true,
    [string] $ExportStudentEnrollments = $true,
    [string] $ExportTeacherRosters = $true,
    [string] $OutFolder = "./SDS_TroubleshootingAttributesExport",
    [string] $graphVersion = "beta",
    [switch] $PPE = $false,
    [switch] $AppendTenantIdToFileName = $false,
    [string] $skipToken= ".",
    [switch] $downloadCommonFNs = $true
)

$GraphEndpointProd = "https://graph.windows.net"
$GraphEndpointPPE = "https://graph.ppe.windows.net"

$logFilePath = $OutFolder

$eduObjSchool = "School"
$eduObjSection = "Section"
$eduObjTeacher = "Teacher"
$eduObjStudent = "Student"

$eduRelStudentEnrollment = "StudentEnrollment"
$eduRelTeacherRoster = "TeacherRoster"

# Checking parameter to download common.ps1 file for required common functions
if ($downloadCommonFNs){
    # Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose
        "Grabbed 'common.ps1' to current directory"
    } 
    catch {
        throw "Unable to download common.ps1"
    }
}
    
# Import file with common functions
. .\common.ps1 

function Get-PrerequisiteHelp
{
    Write-Output @"
========================
 Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'

2.  Make sure to download common.ps1 to the same folder of the script which has common functions needed.  https://github.com/OfficeDev/O365-EDU-Tools/blob/master/SDS%20Scripts/common.ps1

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes User.Read.All, GroupMember.Read.All, Member.Read.Hidden, Group.Read.All, Directory.Read.All, AdministrativeUnit.Read.All" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up

4. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication" isn't working

(END)
========================
"@
}

function Export-SdsSchools
{
    $fileName = $eduObjSchool.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $tenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName

    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $data = Get-SdsSchools

    $cnt = ($data | Measure-Object).Count

    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Schools ..."
	    $SchoolCount = $cnt
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

    $initialUri = "$graphEndPoint/$graphVersion/directory/administrativeUnits?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"

    # Getting AUs for all schools
    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $allSchoolAUs = PageAll-GraphRequest $checkedUri $refreshToken 'GET' $graphscopes $logFilePath
    
    foreach ($au in $allSchoolAUs)
    {
        if ($au.id -ne $null)
        {
            $list += $au
        }
    }
    
    return $list
}

function Export-SdsSections
{
    $fileName = $eduObjSection.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $tenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $data = Get-SdsSections

    $cnt = ($data | Measure-Object).Count

    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Class Sections ..."
	    $sectionCount = $cnt
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
            "ObjectID" = $group.id
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

    $initialUri = "$graphEndPoint/$graphVersion/groups?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"

    $checkedUri = TokenSkipCheck $initialUri $logFilePath

    $groups = PageAll-GraphRequest $checkedUri $refreshToken 'GET' $graphscopes $logFilePath

    foreach ($group in $groups)
    {
        if ($group.id -ne $null)
        {
            $list += $group
        }
    }

    return $list
}

function Export-SdsTeacherRosters
{
    $fileName = $eduRelTeacherRoster.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $tenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $list = Get-Sections

    $data = @()

    foreach($item in $list)
    {
       $data += Format-SdsTeacherRoster $item (Get-TeacherRoster $item.id)
    }

    $cnt = ($data | Measure-Object).Count

    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Teacher Rosters ..."
        $data | Export-Csv $filePath -Force -NotypeInformation -ErrorAction SilentlyContinue
        Write-Host "`nTeacher Rosters exported to file $filePath `n" -ForegroundColor Green
        return $filePath
    }
    else
    {
        Write-Host "No Teacher Rosters found to export."
        return $null
    }
}

function Get-SdsTeacherRoster
{
    Param
    (
        $sectionId
    )

    $section = Get-SdsSection $sectionId
    $members = Get-TeacherRoster $section.id

    return Format-SdsTeacherRoster $section $members
}


function Format-SdsTeacherRoster
{
    Param
    (
        $section,
        $teachers
    )
    
    if ($section -eq $null -or $teachers -eq $null)
    {
        return $null
    }
    else
    {
        $data = @()

        foreach($teacher in $teachers)
        {
            $data += [pscustomobject]@{
                "SIS ID" = $teacher.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_TeacherId
                "Section SIS ID" = $section.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId
            }
        }
        return $data
    }
}

function Get-TeacherRoster
{
    Param
    (
        $objectId
    )

    $group = Get-Section $objectId

    if ($group -ne $null)
    {
        return Get-GroupMembership $objectId $eduObjTeacher
    }
    else
    {
        return $null
    }
}

function Export-SdsStudentEnrollments
{
    $fileName = $eduRelStudentEnrollment.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $tenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName

    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $list = Get-Sections

    $data = @()

    foreach($item in $list)
    {
       $data += Format-SdsStudentEnrollment $item (Get-StudentEnrollment $item.id)
    }

    $cnt = ($data | Measure-Object).Count
    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Student Enrollments ..."
        $data | Export-Csv $filePath -Force -NotypeInformation
        Write-Host "`nStudent Enrollments exported to file $filePath `n" -ForegroundColor Green
        return $filePath
    }
    else
    {
        Write-Host "No Student Enrollments found to export."
        return $null
    }
}

function Get-SdsStudentEnrollment
{
    Param
    (
        $sectionId
    )

    $section = Get-SdsSection $sectionId
    $members = Get-StudentEnrollment $section.id

    return Format-SdsStudentEnrollment $section $members
}

function Format-SdsStudentEnrollment
{
    Param
    (
        $section,
        $students
    )

    if ($section -eq $null -or $students -eq $null)
    {
        return $null
    }
    else
    {
        $data = @()

        foreach($student in $students)
        {
            $data += [pscustomobject]@{
                "SIS ID" = $student.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_StudentId
                "Section SIS ID" = $section.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId
            }
        }
        return $data
    }
}

function Get-StudentEnrollment
{
    Param
    (
        $objectId
    )

    $group = Get-Section $objectId

    if ($group -ne $null)
    {
        return Get-GroupMembership $objectId $eduObjStudent
    }
    else
    {
        return $null
    }
}

function Get-SdsSection
{
    Param
    (
        $sectionId
    )

    $initialUri = "$graphEndPoint/$graphVersion/groups?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId%20eq%20'$sectionId'"

    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $groups = PageAll-GraphRequest $checkedUri $refreshToken 'GET' $graphscopes $logFilePath

    foreach ($group in $groups)
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

    $initialUri = "$graphEndPoint/$graphVersion/groups/$objectId"

    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $group = PageAll-GraphRequest $checkedUri $refreshToken 'GET' $graphscopes $logFilePath
    
    return $group
}

function Get-GroupMembership
{
    Param
    (
        $groupObjectId,
        $eduObjectType
    )

    $list = @()

    if ($eduObjectType -eq $eduObjTeacher)
    {
         $initialUri = $graphEndPoint + '/' + $graphVersion + '/groups/' + $groupObjectId + '/owners'
    }
    else
    {
         $initialUri = $graphEndPoint + '/' + $graphVersion + '/groups/' + $groupObjectId + '/members'
    }
    
    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $groupMembers = PageAll-GraphRequest $checkedUri $refreshToken 'GET' $graphscopes $logFilePath

    foreach ($member in $groupMembers)
    {
        if ($member.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType -eq $eduObjectType)
        {
            $list += $member
        }
    }

    return $list
}

function Export-SdsTeachers
{
    $fileName = $eduObjTeacher.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $tenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName

    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $data = Get-SdsTeachers

    $cnt = ($data | Measure-Object).Count

    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Teachers ..."
		$TeacherCount = $cnt
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
	    "ObjectID" = $user.id
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
    $fileName = $eduObjStudent.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $tenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName

    Remove-Item -Path $filePath -Force -ErrorAction Ignore
    
    $data = Get-SdsStudents

    $cnt = ($data | Measure-Object).Count

    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Students ..."
	    $studentCount = $cnt
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
	    "ObjectID" = $user.id
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

    $initialUri = "$graphEndPoint/$graphVersion/users?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"

    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $users = PageAll-GraphRequest $checkedUri $refreshToken 'GET' $graphscopes $logFilePath
    
    foreach ($user in $users)
    {
        if ($user.id -ne $null)
        {
            $list += $user
        }
    }

    return $list
}

# Main
$graphEndPoint = $GraphEndpointProd

if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
}

$activityName = "Reading SDS objects in the directory"

$graphscopes = "User.Read.All, GroupMember.Read.All, Member.Read.Hidden, Group.Read.All, Directory.Read.All, AdministrativeUnit.Read.All"

try
{
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-PrerequisiteHelp | Out-String | Write-Error
    throw
}

# Connect to the tenant
Write-Progress -Activity $activityName -Status "Connecting to tenant"

Initialize | Out-Null

Write-Progress -Activity $activityName -Status "Connected. Discovering tenant information"

# Create output folder if it does not exist
if ((Test-Path $OutFolder) -eq 0)
{
	mkdir $OutFolder;
}


$tenantInfo = Get-MgOrganization
$tenantId =  $tenantInfo.Id
$tenantDisplayName = $tenantInfo.DisplayName
$tenantdd = (Get-MgDomain | ? {$_.id -like "*onmicrosoft*"}).id
$ClassLicenses = Get-MgSubscribedSku | ? {$_.SkuPartNumber -like "*STANDARDWOFFPACK`_IW`_*"}
$StudentLicenses = (Get-MgSubscribedSku | ? {$_.SkuPartNumber -like "*Student*"}).consumedUnits
$StudentLicensesApplied = ($StudentLicenses | Measure-Object -Sum).sum
$TeacherLicenses = (Get-MgSubscribedSku | ? {$_.SkuPartNumber -like "*Faculty*"}).consumedUnits
$TeacherLicensesApplied = ($TeacherLicenses | Measure-Object -Sum).sum

# Create output folder if it does not exist
if ((Test-Path $OutFolder) -eq 0)
{
	mkdir $OutFolder;
}

# Export all User of Edu Object Type Teacher/Student
Write-Progress -Activity $activityName -Status "Fetching Teachers ..."
Export-SdsTeachers | Out-Null

Write-Progress -Activity $activityName -Status "Fetching Students ..."
Export-SdsStudents | Out-Null

# Export all AUs of Edu Object Type School
Write-Progress -Activity $activityName -Status "Fetching Schools ..."
Export-SdsSchools | Out-Null

# Export all Groups of Edu Object Type Section
Write-Progress -Activity $activityName -Status "Fetching Class Sections ..."
Export-SdsSections | Out-Null

# Export all Group Owners for Teacher Roster
Write-Progress -Activity $activityName -Status "Fetching Teacher Rosters ..."
Export-SdsTeacherRosters | Out-Null

# Export all Groups Members for Student Enrollments
Write-Progress -Activity $activityName -Status "Fetching Student Enrollments ..."
Export-SdsStudentEnrollments | Out-Null

#Write Tenant Details to the PS screen
write-host -foregroundcolor green "Tenant Name is $tenantDisplayName"
write-host -foregroundcolor green "TenantID is $tenantId"
write-host -foregroundcolor green "Tenant default domain is $tenantdd"

If ($ClassLicenses) {
    write-host -foregroundcolor green "Tenant does contain Classroom Licenses"
    $CRLicensesApplied = ($ClassLicenses.consumedunits | Measure-Object -Sum).sum
    write-host -foregroundcolor green "The number of licenses currently applied is $CRLicensesApplied"
}
Else {
    write-host -foregroundcolor red "Tenant does not contain Classroom Licenses"
}

write-host -foregroundcolor green "The number of student licenses currently applied is $StudentLicensesApplied"
write-host -foregroundcolor green "The number of teacher licenses currently applied is $TeacherLicensesApplied"
Write-Output "`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"