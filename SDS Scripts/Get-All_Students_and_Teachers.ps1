<#
.Synopsis
This script is designed to export all students and teachers, into 2 CSV files (Student.csv and Teacher.csv). This script contains a mix of SDS attributes and standard Azure user object attributes. 

.Example
.\Get-All_Students_and_Teachers.ps1

.Notes
========================
 Required Prerequisites
========================
1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'
2. Make sure to download common.ps1 to the same folder of the script which has common functions needed.  https://github.com/OfficeDev/O365-EDU-Tools/blob/master/SDS%20Scripts/common.ps1
3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.
    
    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes User.Read.All, GroupMember.Read.All, Member.Read.Hidden, Group.Read.All, Directory.Read.All, AdministrativeUnit.Read.All" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up

4. Retry this script. If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working

========================

#>

Param (
    [Parameter(Mandatory=$false)]
    [string] $skipToken = ".",
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\StudentsTeachersExport",  
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    [switch] $PPE = $false,
    [switch] $appendTenantIdToFileName = $false,
    [switch] $downloadCommonFNs = $false
)

$graphEndpointProd = "https://graph.windows.net"
$graphEndpointPPE = "https://graph.ppe.windows.net"

$logFilePath = "$outFolder\StudentsTeachersExport.log"

$eduObjTeacher = "Teacher"
$eduObjStudent = "Student"

#checking parameter to download common.ps1 file for required common functions
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
    
#import file with common functions
. .\common.ps1 

function Export-SdsTeachers
{
    $fileName = $eduObjTeacher.ToLower() + $(if ($appendTenantIdToFileName) { "-" + $tenantInfo.Id } else { "" }) +".csv"
	$filePath = Join-Path $outFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $data = Get-SdsTeachers

    $cnt = ($data | Measure-Object).Count
    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Teachers ..."
        $data | Export-Csv $filePath -Force -NoTypeInformation
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
        #DisplayName,UserPrincipalName,SIS ID,School SIS ID,Teacher Number,Status,Secondary Email,ObjectID
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
    $fileName = $eduObjStudent.ToLower() + $(if ($appendTenantIdToFileName) { "-" + $tenantInfo.Id } else { "" }) +".csv"
	$filePath = Join-Path $outFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore
    
    $data = Get-SdsStudents

    $cnt = ($data | Measure-Object).Count
    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Students ..."
        $data | Export-Csv $filePath -Force -NoTypeInformation
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
        #DisplayName,UserPrincipalName,SIS ID,School SIS ID,Student Number,Status,Secondary Email
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
        if ($null -ne $user.id)
        {
            $list += $user
        }
    }
    return $list
}

# Main
$graphEndPoint = $graphEndpointProd

if ($PPE)
{
    $graphEndPoint = $graphEndpointPPE
}

$activityName = "Reading SDS objects in the directory"

$graphScopes = "User.Read.All, GroupMember.Read.All, Member.Read.Hidden, Group.Read.All, Directory.Read.All, AdministrativeUnit.Read.All"

try
{
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-Help -Name .\Get-All_Students_and_Teachers.ps1 -Full | Out-String | Write-Error
    throw
}

# Connect to the tenant
Write-Progress -Activity $activityName -Status "Connecting to tenant"

Initialize

Write-Progress -Activity $activityName -Status "Connected. Discovering tenant information"
$tenantDomain = Get-MgDomain
$tenantInfo = Get-MgOrganization
$tenantId =  $tenantInfo.Id
$tenantDisplayName = $tenantInfo.DisplayName
$tenantdd =  $tenantDomain.Id

$studentLicenses = (Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -match "STANDARDWOFFPACK_IW_STUDENT"}).consumedunits
$studentLicensesApplied = ($studentLicenses | Measure-Object -Sum).sum
$teacherLicenses = (Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -match "STANDARDWOFFPACK_IW_FACULTY"}).consumedunits
$teacherLicensesApplied = ($teacherLicenses | Measure-Object -Sum).sum

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0)
{
	mkdir $outFolder;
}

# Export all User of Edu Object Type Teacher/Student
Write-Progress -Activity $activityName -Status "Fetching Teachers ..."
Export-SdsTeachers | Out-Null

Write-Progress -Activity $activityName -Status "Fetching Students ..."
Export-SdsStudents | Out-Null


#Write Tenant Details to the PS screen
Write-Host -foregroundcolor green "Tenant Name is $tenantDisplayName"
Write-Host -foregroundcolor green "TenantID is $tenantId"
Write-Host -foregroundcolor green "Tenant default domain is $tenantdd"


Write-Host "The number of student licenses currently applied is $studentLicensesApplied"
Write-Host "The number of teacher licenses currently applied is $teacherLicensesApplied"

Write-Output "`n`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"