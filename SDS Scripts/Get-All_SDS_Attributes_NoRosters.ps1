<#
.SYNOPSIS
    This script is designed to get all SDS objects and attributes, except for Rostering. The result is only 4 CSV files in a trimmed down version of the standard SDS format, as detailed on the page https://aka.ms/sdscsvattributes. The 4 CSV files generated are School.CSV, Section.CSV, Student.CSV, and Teacher.CSV. The 2 files not generated are StudentEnrollment.CSV and TeacherRoster.CSV. This reduces the run overall time of the SDS attributes script by about 80%. If you need all SDS attributes run the Get-All_SDS_Attributes.ps1 instead.

.PARAMETER outFolder
    Path where to put the log and csv file with the fetched users.

.PARAMETER graphVersion
    The version of the Graph API.

.EXAMPLE
    .\Get-All_SDS_Attributes_NoRosters.ps1

.NOTES
***This script may take a while.***

========================
Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'.
PowerShell 7 and later is the recommended PowerShell version for use with the Microsoft Graph PowerShell SDK on all platforms (https://docs.microsoft.com/en-us/graph/powershell/installation#supported-powershell-versions).

2. Make sure to download common.ps1 to the same folder of the script which has common functions needed.  https://github.com/OfficeDev/O365-EDU-Tools/blob/master/SDS%20Scripts/common.ps1
Command to download the function: Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes GroupMember.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All" to bring up a sign in UI.
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up

4. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working
#>

Param (
    [string] $outFolder = "./SDSAttributesExport",
    [switch] $PPE = $false,
    [switch] $AppendTenantIdToFileName = $false,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory=$false)]
    [string] $graphVersion= "beta",
    [switch] $skipDownloadCommonFunctions
)

$GraphEndpointProd = "https://graph.windows.net"
$GraphEndpointPPE = "https://graph.ppe.windows.net"

$logFilePath = "$outFolder/Get-All_SDS_Attributes_NoRosters.log"

$eduObjSchool = "School"
$eduObjSection = "Section"
$eduObjTeacher = "Teacher"
$eduObjStudent = "Student"

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0) {
    mkdir $outFolder | Out-Null;
}

#checking parameter to download common.ps1 file for required common functions
if ($skipDownloadCommonFunctions -eq $false) {
    # Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose
        "Grabbed 'common.ps1' to the directory alongside the executing script"
        Write-Output "[$(get-date -Format G)] Grabbed 'common.ps1' to the directory alongside the executing script. common.ps1 script contains common functions, which can be used by other SDS scripts" | out-file $logFilePath -Append

    }
    catch {
        throw "Unable to download common.ps1"
    }
}

#import file with common functions
. .\common.ps1

function Export-SdsSchools
{
    $fileName = $eduObjSchool.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $authToken.TenantId } else { "" }) +".csv"
	$filePath = Join-Path $outFolder $fileName
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

    $initialUri = "$graphEndPoint/$graphVersion/directory/administrativeUnits?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"

    #getting AUs for all schools
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
    $fileName = $eduObjSection.ToLower() + $(if ($AppendTenantIdToFileName) { "-" + $authToken.TenantId } else { "" }) +".csv"
	$filePath = Join-Path $outFolder $fileName
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
	$filePath = Join-Path $outFolder $fileName
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
	$filePath = Join-Path $outFolder $fileName
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

$graphscopes = "User.Read.All, GroupMember.Read.All, Group.Read.All, Directory.Read.All, AdministrativeUnit.Read.All"

try
{
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-Help -Name .\Get-All_SDS_Attributes_NoRosters.ps1 -Full | Out-String | Write-Error
    throw
}

# Connect to the tenant
Write-Progress -Activity $activityName -Status "Connecting to tenant"

Initialize

Write-Progress -Activity $activityName -Status "Connected. Discovering tenant information"

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

Write-Output "`nDone.`n"

Write-Output "Please run 'disconnect-graph' if you are finished making changes.`n"
