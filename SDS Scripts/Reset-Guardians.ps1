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
.Parameter outFolder
    The script will output log file here
.Parameter clientId
    The application Id that has User.Read.All and EduRoster.ReadWrite.All permission
.Parameter tenantId
    The Id of the tenant.
.Parameter studentAadObjectIds
    The AAD object Id(s) of the student(s) for whom the guardians needs to be reset. 
.Parameter studentAadObjectIdsCsvFile
    CSV file which has the AAD object Ids of the students for whom the guardians needs to be reset
.PARAMETER skipToken
    Used to start where the script left off fetching the users in case of interruption.  The value used is nextLink in the log file, otherwise use default value of "" to start from the beginning.
.PARAMETER graphVersion
    The version of the Graph API. 
.Example
    Reset guardian for one student: .\Reset-Guardians.ps1 -clientId "743f3d66-95aa-41d9-237d-45e961251889" -certificateThumbprint <CertificateThumbprint> -tenantId 8a572b06-4f46-432f-9185-258f6a8d67e6 -studentAadObjectIds "ab043123-00aa-60d9-2ab4-12e961702abc"
    Reset guardian for multiple students (Student AAD object Ids in a comma separated format): .\Reset-Guardians.ps1 -clientId "743f3d66-95aa-41d9-237d-45e961251889" -certificateThumbprint <CertificateThumbprint> -tenantId 8a572b06-4f46-432f-9185-258f6a8d67e6 -studentAadObjectIds "ab043123-00aa-60d9-2ab4-12e961702abc,df043123-00aa-60d9-2ab4-12e961702xyz"
    Reset guardian for students mentioned in the csv file (Make sure the csv file column header name is studentAadObjectId): .\Reset-Guardians.ps1 -clientId "743f3d66-95aa-41d9-237d-45e961251889" -certificateThumbprint <CertificateThumbprint> -tenantId 8a572b06-4f46-432f-9185-258f6a8d67e6 -studentAadObjectIdsCsvFile "studentAadObjectIds.csv"
    Reset guardian for all SDS synced students : .\Reset-Guardians.ps1 -clientId "743f3d66-95aa-41d9-237d-45e961251889" -certificateThumbprint <CertificateThumbprint> -tenantId 8a572b06-4f46-432f-9185-258f6a8d67e6
#>

Param (
    [switch] $PPE = $false,

    [Parameter(Mandatory = $false)]
    [string] $outFolder = ".\ResetGuardians",

    [Parameter(Mandatory = $true)]
    [string] $clientId,

    [Parameter(Mandatory = $true)]
    [string] $tenantId,

    [Parameter(Mandatory = $true)]
    [string] $certificateThumbprint,

    [Parameter(Mandatory = $false)]
    [string] $studentAadObjectIds,

    [Parameter(Mandatory = $false)]
    [string] $studentAadObjectIdsCsvFile,

    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",

    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta" 
)

$graphEndpointProd = "https://graph.microsoft.com"
$graphEndpointPPE = "https://graph.microsoft-ppe.com"

$logFilePath = "$outFolder\ResetGuardians.log"

function Get-PrerequisiteHelp
{
    Write-Output @"
========================
 Required Prerequisites
========================

1. An app must be created in customer's Azure account with appropriate app permissions and scopes (User.Read.All, EduRoster.ReadWrite.All)

2. The app must contain a certificate https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-configure-app-access-web-apis

3. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'

4. Make sure to download common.ps1 to the same folder of the script which has common functions needed.  https://github.com/OfficeDev/O365-EDU-Tools/blob/master/SDS%20Scripts/common.ps1

5. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "Connect-Graph -Scopes User.Read.All, EduRoster.ReadWrite.All" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up

6. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working

(END)
========================
"@
}

function Reset-GuardiansForUser($userId) {
   
    $noContacts = @{
        relatedContacts = @()
    }

    Write-Progress -Activity "Resetting guardians for user $userId"    
    $noContactsBody = ConvertTo-Json $noContacts
    Invoke-GraphRequest -Method PATCH -Uri "$graphEndPoint/$graphVersion/education/users/$userId" -Body $noContactsBody -ContentType "application/json" | out-file $logFilePath -Append
}

function Get-AllStudents($authToken) {
    Write-Host "Getting All SDS synced students"
    $students = @()
    $initialUri = "$graphEndPoint/$graphVersion/users/?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType eq 'Student'&`$select=id,displayName"

    $checkedUri = TokenSkipCheck $initialUri $logFilePath

    $graphStudents = PageAll-GraphRequest $checkedUri $authToken 'GET' $logFilePath

    foreach ($student in $graphStudents)
    {
        if ($null -ne $student.id)
        {
            $students += $student
        }
    }

    return $students
}

function Initialize($graphScopes) {
    import-module Microsoft.Graph.Authentication -MinimumVersion 0.9.1
    $null = Write-Output "If prompted, please use a tenant admin-account to grant access to $graphScopes privileges"
    $firstToken = Refresh-Token $null
    return $firstToken
}
function Refresh-Token($lastRefreshed) {
    $currentDT = get-date
    if ($lastRefreshed -eq $null -or (New-TimeSpan -Start $currentDT -End $lastRefreshed).Minutes -gt 10) {
        Connect-MgGraph -ClientID $clientId -TenantId $tenantId -CertificateThumbprint $certificateThumbprint | Out-Null

        $lastRefreshed = Get-Date
    }
    return $lastRefreshed
}

# Gets data from all pages
function PageAll-GraphRequest($initialUri, $refreshToken, $method, $logFilePath) {

    $result = @()

    $currentUrl = $initialUri
    
    while ($currentUrl -ne $null) {
        Refresh-Token $refreshToken
        $response = Invoke-GraphRequest -Method $method -Uri $currentUrl -ContentType "application/json"
        $result += $response.value
        $currentUrl = $response.'@odata.nextLink'
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

# Main
$graphEndPoint = $GraphEndpointProd

if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
}

# List used to request access to data
$graphScopes = "User.Read.All, EduRoster.ReadWrite.All"

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

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0)
{
    mkdir $outFolder;
}

# Connect to the tenant
Write-Progress -Activity "Connecting to Graph" -Status "Connecting to tenant"

$refreshToken = Initialize $graphScopes

if ($studentAadObjectIds -ne "") {
    $studentAadObjectIdsArr = $studentAadObjectIds.split(',')
    foreach($studentAadObjectId in $studentAadObjectIdsArr) {
        $refreshToken = Refresh-Token $refreshToken
        Write-Host "Resetting guardians for student object Id $studentAadObjectId"
        Reset-GuardiansForUser -userId $studentAadObjectId -authToken $refreshToken -lastRefreshed $lastRefreshed
    }    
} elseif ($studentAadObjectIdsCsvFile -ne "") {
    $studentAadObjectIdList = Import-Csv $studentAadObjectIdsCsvFile
    foreach($studentAadObject in $studentAadObjectIdList) {
        $refreshToken = Refresh-Token $refreshToken
        Write-Host "Resetting guardians for student object Id $($studentAadObject.studentAadObjectId)"
        Reset-GuardiansForUser -userId $studentAadObject.studentAadObjectId -authToken $refreshToken -lastRefreshed $lastRefreshed
    }    
} else {
    $students = Get-AllStudents -authToken $refreshToken -lastRefreshed $lastRefreshed
    $reply = Read-Host -Prompt "Will reset guardians for $($students.length) students. Continue? [y/n]"
    if ($reply -match "[yY]") {
        foreach($student in $students) {
            $refreshToken = Refresh-Token $refreshToken
            Write-Host "Resetting guardians for $($student.displayName), id $($student.id)"
            Reset-GuardiansForUser -userId $student.id -authToken $refreshToken -lastRefreshed $lastRefreshed
        }    
    }
}

Write-Output "`n`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"