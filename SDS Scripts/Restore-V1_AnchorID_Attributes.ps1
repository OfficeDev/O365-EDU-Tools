<#
.SYNOPSIS
This script will allow customers who have migrated to SDS v2.1 model to migrate back - customers running new SDS with a create user outbound flow can run this new script to update the anchorIDs back to the legacy format, from user_<SIS ID> back to the legacy required format of student_<SIS ID> and teacher_<SIS ID> for the anchorIDs on each.

.PARAMETER skipToken
Used to start where the script left off fetching the users in case of interruption.  The value used is nextLink in the log file, otherwise use default value of "" to start from the beginning.

.PARAMETER outFolder
Path where to put the csv file.

.PARAMETER skipDownloadCommonFunctions
Parameter to specify whether to download the script with common functions or not.

.PARAMETER graphVersion
The version of the Graph API. 

.EXAMPLE
.\Restore-V1_AnchorID_Attributes.ps1

.NOTES
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
    [string] $outFolder = ".\SDSUsers",
    [switch] $PPE = $false,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    [switch] $skipDownloadCommonFunctions
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0)
{
	mkdir $outFolder;
}

$logFilePath = "$outFolder\SDSUsers.log"
$csvFilePath = "$outFolder\SDSUsers.csv"

if ($skipDownloadCommonFunctions -eq $false) {
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

function Get-Users
{
    Param
    (
        $refreshToken,
        $graphScopes,
        $logFilePath
    )

    $list = @()

    $userSelectClause = "?`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType,extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId"

    $initialUri = "$graphEndPoint/$graphVersion/users$userSelectClause"

    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $users = PageAll-GraphRequest $checkedUri $refreshToken 'GET' $graphScopes $logFilePath
    
    $i = 0 #counter for progress

    foreach ($user in $users)
    {
        if (($user.id -ne $null) -and ($user.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType -ne $null) -and ($user.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId -match 'User_'))
        {
            #create object required for export-csv and add to array
            $obj = [pscustomobject]@{"userObjectId"=$user.Id; "userDisplayName"=$user.DisplayName; "userType"=$user.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType; "userAnchorId"=$user.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId}
            $list += $obj
        }
        $i++
        Write-Progress -Activity "Retrieving SDS Users" -Status "Progress ->" -PercentComplete ($i/$users.count*100)
    }

    return $list
}

Function Format-ResultsAndExport($graphScopes, $logFilePath) {

    $refreshToken = Initialize $graphScopes
    
    $users = Get-Users $refreshToken $graphScopes $logFilePath

    if($users) {
        #output to file
        if($skipToken -eq "."){
            Write-Output $users | Export-Csv -Path "$csvfilePath" -NoTypeInformation
        }
        else {
            Write-Output $users | Export-Csv -Path "$csvfilePath$($skiptoken.Length).csv" -NoTypeInformation
        }
    } 
    else {
        Write-Output "`nNo users found!"
        Write-Output "`nDone.  Logs can be reviewed at $logFilePath`n"
        Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"
        Exit
    }

    Out-File $logFilePath -Append -InputObject $global:nextLink
}

function Update-SDSUserAttributes
{
	Param
	(
        $refreshToken,
        $graphScopes,
		$userListFileName
	)

	Write-Host "WARNING: You are about to update user anchor id's created from SDS. `nIf you want to skip removing any users, edit the file now and update the corresponding lines before proceeding. `n" -ForegroundColor Yellow
	Write-Host "Proceed with removing all the SDS user anchor ids in $userListFileName (yes/no)?" -ForegroundColor White
	
    $choice = Read-Host
	if ($choice -ieq "y" -or $choice -ieq "yes")
	{
		$userList = Import-Csv $userListFileName
		$userCount = (gc $userListFileName | measure-object).count - 1
		$index = 0
        $saveToken = $refreshToken
		Foreach ($user in $userList)
		{
            $saveToken = Refresh-Token $saveToken $graphScopes

			Write-Output "[$(get-date -Format G)] [$index/$userCount] Updating attribute [$($user.userAnchorId)] for user `"$($user.userDisplayName)`" " | Out-File $logFilePath -Append -Encoding "UTF8"
            
            $updateUrl = $graphEndPoint + '/'+$graphVersion+'/users/' + $user.userObjectId

            $existingAnchorId = $user.userAnchorId
            
            #replacing anchor id User_<sis id> with Student_<sis id> for Students
            if($user.userType -eq 'Student') {
                $newAnchorId = "Student_" + $existingAnchorId.Split("_")[1]
            } else {
                #replacing anchor id User_<sis id> with Teacher_<sis id> for users other than student
                $newAnchorId = "Teacher_" + $existingAnchorId.Split("_")[1]
            }

            Invoke-GraphRequest -Method PATCH -Uri $updateUrl -Body "{`"extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId`": `"$($newAnchorId)`"}"
            $index++
            Write-Progress -Activity "Updating SDS user anchor ids" -Status "Progress ->" -PercentComplete ($index/$userCount*100)
		}
	}
}

# Main
$graphEndPoint = $GraphEndpointProd

if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
}

$activityName = "Connecting to Graph"

#list used to request access to data
$graphScopes = "User.ReadWrite.All"

try
{
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-Help -Name .\Restore-V1_AnchorID_Attributes.ps1 -Full | Out-String | Write-Error
    throw
}

# Connect to the tenant
Write-Progress -Activity $activityName -Status "Connecting to tenant"

Write-Progress -Activity $activityName -Status "Connected. Discovering tenant information"

Format-ResultsAndExport $graphScopes $logFilePath

Write-Host "`nSDS users logged to file $csvFilePath `n" -ForegroundColor Green

# update AnchorID
Update-SDSUserAttributes $refreshToken $graphScopes $csvFilePath

Write-Output "`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"