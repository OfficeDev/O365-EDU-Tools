<#
.SYNOPSIS
This script is designed to get all SDS users, and update the Anchor IDs to facilitate the migration of users synced to v2.1 Sync profiles. This is required if you've previously synced users from v1 CSV, Clever CSV, PowerSchool API, or OneRoster API providers. You only need to run this script if you are creating users via SDS, otherwise your users will update to the correct values automatically when transitioning from v1 to v2. This script does require the Azure AD v2 PowerShell module.

.EXAMPLE
.\Update-AnchorID_Attributes.ps1

.NOTES
========================
 Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'

2.  Make sure to download common.ps1 to the same folder of the script which has common functions needed.  https://github.com/OfficeDev/O365-EDU-Tools/blob/master/SDS%20Scripts/common.ps1

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes User.ReadWrite.All" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up

5. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working

========================
#>


Param (
    [string] $outFolder = ".\SDSUsers",
    [switch] $PPE = $false,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory=$false)]
    [string] $downloadFcns = "y"
)

$graphEndpointProd = "https://graph.microsoft.com"
$graphEndpointPPE = "https://graph.microsoft-ppe.com"

$logFilePath = $outFolder

# Checking parameter to download common.ps1 file for required common functions
if ($downloadFcns -ieq "y" -or $downloadFcns -ieq "yes"){

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

function Get-Users
{
    Param
    (
        $refreshToken,
        $graphscopes,
        $logFilePath
    )

    $list = @()

    $userSelectClause = "?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'Student'%20or%20extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'Teacher'&`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType,extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId"

    $initialUri = "$graphEndPoint/beta/users$userSelectClause"

    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $users = PageAll-GraphRequest $checkedUri $refreshToken 'GET' $graphscopes $logFilePath
    
    $i = 0 # Counter for progress

    foreach ($user in $users)
    {
        if ($user.id -ne $null)
        {
            # Create object required for export-csv and add to array
            $obj = [pscustomobject]@{"userObjectId"=$user.Id; "userDisplayName"=$user.DisplayName; "userType"=$user.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType; "userAnchorId"=$user.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId}
            $list += $obj
        }
        $i++
        Write-Progress -Activity "Retrieving SDS Users" -Status "Progress ->" -PercentComplete ($i/$users.count*100)
    }

    return $list
}

Function Format-ResultsAndExport($graphscopes, $logFilePath) {

    $refreshToken = Initialize $graphscopes
    
    $users = Get-Users $refreshToken $graphscopes $logFilePath

    # Output to file
    if($skipToken -eq "."){
        Write-Output $users | Export-Csv -Path "$csvfilePath" -NoTypeInformation
    }
    else {
        Write-Output $users | Export-Csv -Path "$csvfilePath$($skiptoken.Length).csv" -NoTypeInformation
    }

    Out-File $logFilePath -Append -InputObject $global:nextLink
}

function Update-SDSUserAttributes
{
	Param
	(
        $refreshToken,
        $graphscopes,
		$userListFileName
	)

	Write-Host "WARNING: You are about to update user anchor id's created from SDS. `nIf you want to skip removing any users, edit the file now and update the corresponding lines before proceeding. `n" -ForegroundColor Yellow
	Write-Host "Proceed with removing all the SDS user anchor ids in $userListFileName (yes/no)?" -ForegroundColor White
	
    $choice = Read-Host
	if ($choice -ieq "y" -or $choice -ieq "yes")
	{
		$userList = Import-Csv $userListFileName
		$userCount = (gc $userListFileName | Measure-Object).count - 1
		$index = 1
        $saveToken = $refreshToken
		Foreach ($user in $userList) 
		{
            $saveToken = Refresh-Token $saveToken $graphscopes

			Write-Output "[$(Get-Date -Format G)] [$index/$userCount] Updating attribute [$($user.userAnchorId)] from user `"$($user.userDisplayName)`" " | Out-File $logFilePath -Append 
            
            $updateUrl = $graphEndPoint + '/beta/users/' + $user.userObjectId
            
            # Replacing anchor id Student_<sis id> and Teacher_<sis id) with User_<sis id>
            $oldAnchorId = $user.userAnchorId
            $newAnchorId = "User_" + $oldAnchorId.Split("_")[1]
			            
			$graphRequest = Invoke-GraphRequest -Method PATCH -Uri $updateUrl -Body "{`"extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId`": `"$($newAnchorId)`"}" 
			$index++
            Write-Progress -Activity "Updating SDS user anchor ids" -Status "Progress ->" -PercentComplete ($i/$userlist.count*100)
		}
	}
}

# Main
$graphEndPoint = $graphEndpointProd

if ($PPE)
{
    $graphEndPoint = $graphEndpointPPE
}

$logFilePath = "$outFolder\SDSUsers.log"
$csvFilePath = "$outFolder\SDSUsers.csv"

$activityName = "Connecting to Graph"

# List used to request access to data
$graphscopes = "User.ReadWrite.All"

try
{
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-Help -Name .\Update-AnchorID_Attributes.ps1 -Full | Out-String | Write-Error
    throw
}

# Connect to the tenant
Write-Progress -Activity $activityName -Status "Connecting to tenant"

Write-Progress -Activity $activityName -Status "Connected. Discovering tenant information"

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0)
{
	mkdir $outFolder;
}

Format-ResultsAndExport $graphscopes $logFilePath

Write-Host "`nSDS users logged to file $csvFilePath `n" -ForegroundColor Green

# Update School AU Memberships
Update-SDSUserAttributes $refreshToken $graphscopes $csvFilePath

Write-Output "`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"

