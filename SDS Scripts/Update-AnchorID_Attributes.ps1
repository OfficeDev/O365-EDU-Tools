<#
Script Name:
Update-AnchrorID_Attributes.ps1

Synopsis:
This script is designed to get all SDS users, and update the Anchor IDs to facilitate the migration of users synced to v2.1 Sync profiles. This is required if you've previously synced users from v1 CSV, Clever CSV, PowerSchool API, or OneRoster API providers. You only need to run this script if you are creating users via SDS, otherwise your users will update to the correct values automatically when transitioning from v1 to v2. This script does require the Azure AD v2 PowerShell module.

Syntax Examples and Options:
.\Update-AnchorID_Attributes.ps1

Written By:
Bill Sluss

Change Log:
Version 1.0, 05/4/2021 - First Draft
Version 2.0, 05/4/2021 - Ayron Johnson - switch to MS Graph Module
#>


Param (
    [string] $OutFolder = "./SDSUsers",
    [switch] $PPE = $false,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= "."
)


$logFilePath = $OutFolder

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
    Write-Output "If prompted, please use a tenant admin-account to grant access to User.ReadWrite.All"
    Refresh-Token
}

$lastRefreshed = $null
function Refresh-Token() {
    if ($lastRefreshed -eq $null -or (get-date - $lastRefreshed).Minutes -gt 10) {
        connect-graph -scopes User.ReadWrite.All
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

function Get-Users
{
    Param
    (
        $logFilePath
    )

    $list = @()

    $userSelectClause = "?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'&`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType,extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId"

    $initialUri = "https://graph.microsoft.com/beta/users$userSelectClause"


    $checkedUri = TokenSkipCheck $initialUri $logFilePath
    $users = PageAll-GraphRequest $checkedUri $logFilePath
    
    $i = 0 #counter for progress


        foreach ($user in $users)
        {
            if ($user.id -ne $null)
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

Function Format-ResultsAndExport($logFilePath) {

    Initialize
    
    $users = Get-Users $logFilePath

    #output to file
    if($skipToken -eq "."){
        write-output $users | Export-Csv -Path "$csvfilePath" -NoTypeInformation
    }
    else {
        write-output $users | Export-Csv -Path "$csvfilePath$($skiptoken.Length).csv" -NoTypeInformation
    }


    Out-File $logFilePath -Append -InputObject $global:nextLink
}

function Update-SDSUserAttributes
{
	Param
	(
		$userListFileName
	)

	Write-Host "WARNING: You are about to update user anchor id's created from SDS. `nIf you want to skip removing any users, edit the file now and update the corresponding lines before proceeding. `n" -ForegroundColor Yellow
	Write-Host "Proceed with removing all the SDS user anchor ids in $userListFileName (yes/no)?" -ForegroundColor White
	$choice = Read-Host
	if ($choice -ieq "y" -or $choice -ieq "yes")
	{
		Write-Progress -Activity $activityName -Status "Updating SDS user anchor ids"
		$userList = import-csv $userListFileName
		$userCount = $userList.Length
		$index = 1
		Foreach ($user in $userList) 
		{
			Write-Output "[$index/$userCount] Updating attribute [$($user.userAnchorId)] from user `"$($user.userDisplayName)`" "
            
            $updateUrl = 'https://graph.microsoft.com/beta/users/' + $user.userObjectId
            
            #replacing anchor id Student_<sis id> and Teacher_<sis id) with User_<sis id>
            $oldAnchorId = $user.userAnchorId
            $newAnchorId = "User_" + $oldAnchorId.Split("_")[1]
			            
			$graphRequest = invoke-graphrequest -Method PATCH -Uri $updateUrl -Body "{`"extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId`": `"$($newAnchorId)`"}" 
            
            #removing the anchor id
            # $graphRequest = invoke-graphrequest -Method PATCH -Uri $updateUrl -Body '{"extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId": null}' 

			$index++
		}
	}
}

# Main

$logFilePath = "$OutFolder\SDSUsers.log"
$csvFilePath = "$OutFolder\SDSUsers.csv"

$activityName = "Connecting to Graph"

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


# Create output folder if it does not exist
if ((Test-Path $OutFolder) -eq 0)
{
	mkdir $OutFolder;
}

    Format-ResultsAndExport $logFilePath

    Write-Host "`nSDS users logged to file $csvFilePath `n" -ForegroundColor Green


# update School AU Memberships
update-SDSUserAttributes $csvFilePath

Write-Output "`nDone.`n"

Write-Output "Please run 'disconnect-graph' if you are finished making changes.`n"

