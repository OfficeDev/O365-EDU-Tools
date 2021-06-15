<#
Script Name:
Get-All_SDS_Attributes.ps1

Synopsis:
This script is designed to export all SDS objects and attributes. The result is a set of 6 CSV files in the standard SDS format, as documented on the page https://aka.ms/sdscsvattributes.

Syntax Examples and Options:
.\Get-All_SDS_Attributes.ps1 

Written By: 
TJ Vering

Change Log:
Version 1.0, 12/06/2016 - First Draft
Version 2.0, 04/06/2021 - Change to MS Graph Moddule - Ayron Johnson

#>

Param (
    [string] $ExportSchools = $true,
    [string] $ExportStudents = $true,
    [string] $ExportTeachers = $true,
    [string] $ExportSections = $true,
    [string] $ExportStudentEnrollments = $true,
    [string] $ExportTeacherRosters = $true,
    [string] $OutFolder = "./SDSAttributesExport",
    [switch] $PPE = $false,
    [switch] $AppendTenantIdToFileName = $false,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= "."
)


$logFilePath = $OutFolder

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

1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes AdministrativeUnit.ReadWrite.All,User.Read.All" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell sesion without error, you are correctly set up

5. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working

(END)
========================
"@
}


function Initialize() {
    import-module Microsoft.Graph.Authentication -MinimumVersion 0.9.1
    Write-Output "If prompted, please use a tenant admin-account to grant access to User.Read.All, GroupMember.Read.All, Group.Read.All, Directory.Read.All, AdministrativeUnit.Read.All"
    Refresh-Token
}

$lastRefreshed = $null
function Refresh-Token() {
    if ($lastRefreshed -eq $null -or (get-date - $lastRefreshed).Minutes -gt 10) {
        connect-graph -scopes User.Read.All, GroupMember.Read.All, Group.Read.All, Directory.Read.All, AdministrativeUnit.Read.All
        $lastRefreshed = get-date
    }
}

# Gets data from all pages
function PageAll-GraphRequest($initialUri, $logFilePath) {

    # Connect to the tenant
    #Write-Progress -Activity $activityName -Status "Connecting to tenant"

    $result = @()

    $currentUrl = $initialUri
    $i = 1
    
    while (($currentUrl -ne $null) -and ($i -ile 4999)) {
        Refresh-Token
        $response = invoke-graphrequest -Method GET -Uri $currentUrl -ContentType "application/json"
        $result += $response.value
        $currentUrl = $response.'@odata.nextLink'
        $i++
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

function Export-SdsSchools
{
    $fileName = $eduObjSchool.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $authToken.TenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $data = Get-SdsSchools
    
    $cnt = ($data | Measure-Object).Count
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
        #SIS ID,Name,School Number,School NCES_ID,State ID,Grade Low,Grade High,Principal SIS ID,Principal Name,Principal Secondary Email,Address,City,State,Zip,Phone,Zone,Country
        $data += [pscustomobject]@{
            "SIS ID" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId
            "Name" = $au.DisplayName
            "School Number" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_SchoolNumber 
            "School NCES_ID" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_SchoolNationalCenterForEducationStatisticsId
            "State ID" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_StateId
            "Grade Low" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_LowestGrade
            "Grade High" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_HighestGrade
            "Principal SIS ID" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_SchoolPrincipalSyncSourceId
            "Principal Name" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_SchoolPrincipalName
            "Principal Secondary Email" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_SchoolPrincipalEmail
            "Address" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_Address
            "City" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_City
            "State" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_State
            "Zip" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_Zip
            "Phone" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_Phone
            "Zone" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_SchoolZone
            "Country" = $au.extension_fe2174665583431c953114ff7268b7b3_Education_Country
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

    $initialUri = "https://graph.microsoft.com/beta/directory/administrativeUnits?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"

    #getting AUs for all schools
    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $allSchoolAUs = PageAll-GraphRequest $checkedUri $logFilePath
    
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
    $fileName = $eduObjSection.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $authToken.TenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $data = Get-SdsSections
    
    $cnt = ($data | Measure-Object).Count
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
            "Section Name" = $group.DisplayName
            #"Name" = $au.DisplayName                    
            "Section Number" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_SectionNumber
 
            "Term SIS ID" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_TermId
            "Term Name" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_TermName
            "Term StartDate" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_TermStartDate
            "Term EndDate" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_TermEndDate
            "Course SIS ID" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_CourseId
            "Course Name" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_CourseName
            "Course Number" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_CourseNumber
            "Course Description" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_CourseDescription
            "Course Subject" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_CourseSubject
            "Periods" = $group.extension_fe2174665583431c953114ff7268b7b3_Education_Period
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

    $initialUri = "https://graph.microsoft.com/beta/groups?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"


    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $groups = PageAll-GraphRequest $checkedUri $logFilePath

        foreach ($group in $groups)
        {
            if ($group.id -ne $null)
            {
                $list += $group
            }
            #$group.ObjectId + ", " + $group.DisplayName + ", " + $group.Mail + ", " + $group.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId | Out-File $filePath -Append
        }


    return $list
}

function Export-SdsTeacherRosters
{
    $fileName = $eduRelTeacherRoster.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $authToken.TenantId } else { "" }) +".csv"
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
    $fileName = $eduRelStudentEnrollment.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $authToken.TenantId } else { "" }) +".csv"
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

    $initialUri = "https://graph.microsoft.com/beta/groups?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SectionId%20eq%20'$sectionId'"

    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $groups = PageAll-GraphRequest $checkedUri $logFilePath
    
    #extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'%20and%20
    
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

    $initialUri = "https://graph.microsoft.com/beta/groups/$objectId"

    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $group = PageAll-GraphRequest $checkedUri $logFilePath
    
    # foreach ($group in $groups) #not necessary since specifying single group
    # {
        #if ($group.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType -eq $eduObjSection) #object type not working
        #{
            return $group
        #}
    # }
    #return $null
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
        #$filterClause = "?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjTeacher'"
         $initialUri = "https://graph.microsoft.com/beta/groups/" + $groupObjectId + '/owners'
    }
    else
    {
        #$filterClause = "?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjStudent'"
         $initialUri = "https://graph.microsoft.com/beta/groups/" + $groupObjectId + '/members'
    }
    
    #$initialUri = "https://graph.microsoft.com/beta/groups/" + $groupObjectId + '/members' + "$filterClause" # filter not working

    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $groupMembers = PageAll-GraphRequest $checkedUri $logFilePath

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
    $fileName = $eduObjTeacher.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $authToken.TenantId } else { "" }) +".csv"
	$filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $data = Get-SdsTeachers

    $cnt = ($data | Measure-Object).Count
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
        #SIS ID,School SIS ID,Username,First Name,Last Name,Middle Name,Teacher Number,State ID,Status,Secondary Email,Title,Qualification,Password
        $data += [pscustomobject]@{
            "SIS ID" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_TeacherId
            "School SIS ID" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId
            "Username" = $user.userPrincipalName
            "First Name" = $user.givenName
            "Last Name" = $user.surName
            "Middle Name" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_MiddleName
            "Teacher Number" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_TeacherNumber
            "State ID" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_StateId
            "Status" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_TeacherStatus
            "Secondary Email" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_Email
            "Title" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_Title
            "Qualification" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_TeacherQualification
            "Password" = ""
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
        #SIS ID,School SIS ID,Username,First Name,Last Name,Middle Name,Student Number,Status,State ID,Mailing Address,Mailing City,Mailing State,Mailing Zip,Mailing Latitude,Mailing Longitude,Mailing Country
        #Residence Address,Residence City,Residence State,Residence Zip,Residence Latitude,Residence Longitude,Residence Country,Gender,Birthdate,Grade,ELL Status,FederalRace,Secondary Email,Graduation Year,Password
        $data += [pscustomobject]@{
            "SIS ID" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_StudentId
            "School SIS ID" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId
            "Username" = $user.userPrincipalName
            "First Name" = $user.givenName
            "Last Name" = $user.surName
            "Middle Name" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_MiddleName
            "Student Number" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_StudentNumber
            "Status" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_StudentStatus
            "State ID" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_StateId
            "Mailing Address" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_MailingAddress
            "Mailing City" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_MailingCity
            "Mailing State" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_MailingState
            "Mailing Zip" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_MailingZip
            "Mailing Latitude" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_MailingLatitude
            "Mailing Longitude" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_MailingLongitude
            "Mailing Country" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_MailingCountry
            "Resident Address" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_ResidentAddress
            "Resident City" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_ResidentCity
            "Resident State" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_ResidentState
            "Resident Zip" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_ResidentZip
            "Resident Latitude" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_ResidentLatitude
            "Resident Longitude" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_ResidentLongitude
            "Resident Country" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_ResidentCountry
            "Gender" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_Gender
            "Birthdate" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_DateOfBirth
            "Grade" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_Grade
            "ELL Status" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_EnglishLanguageLearnersStatus
            "FederalRace" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_FederalRace
            "Secondary Email" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_Email
            "Graduation Year" = $user.extension_fe2174665583431c953114ff7268b7b3_Education_GraduationYear
            "Password" = ""
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

    $initialUri = "https://graph.microsoft.com/beta/users?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"
            #extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'%20and%20


    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $users = PageAll-GraphRequest $checkedUri $logFilePath


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

$activityName = "Reading SDS objects in the directory"

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

Initialize

Write-Progress -Activity $activityName -Status "Connected. Discovering tenant information"
# $tenantInfo = Get-MgOrganization
# $tenantId =  $tenantInfo.ObjectId
# $tenantDisplayName = $tenantInfo.DisplayName

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

Write-Output "`nDone.`n"

Write-Output "Please run 'disconnect-graph' if you are finished making changes.`n"
