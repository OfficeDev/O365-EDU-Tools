<#
.SYNOPSIS
This script is designed to remove all Schools created by SDS from an O365 tenant. You will need to enter your credentials 2 times as the script sets up the connection to Azure, and then confirm you want to run the script with a "y". Once the script completes, a folder called "true" will be created in the same directory as the script itself, and contain an output file which details the schools removed.

.PARAMETER skipToken

Used to start where the script left off fetching the users in case of interruption.  The value used is nextLink in the log file, otherwise use default value of "" to start from the beginning.

.PARAMETER outFolder

Path where to put the log and csv file with the fetched users.

.PARAMETER graphVersion

The version of the Graph API.

.EXAMPLE
.\Remove-All_Schools.ps1

#>

Param (
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\SDS_Schools",
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    [Parameter(Mandatory=$false)]
    [string] $skipToken= "",
    [switch] $PPE = $false
)

$graphEndpointProd = "https://graph.windows.com"
$graphEndpointPPE = "https://graph.ppe.windows.com"

function Get-PrerequisiteHelp
{
    Write-Output @"
========================
 Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module with the command 'Install-Module Microsoft.Graph'

2. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "Connect-Graph" to bring up a sign-in UI. 
    
    c. Sign in with any tenant administrator credentials.
    
    d. If you are returned to the PowerShell session without error, you are correctly set up.

3.  Ensure that you have application setup correctly in Azure Active Directory with the following permission scopes: AdministrativeUnit.Read.All, Directory.Read.All, AdministrativeUnit.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All

4.  Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication" isn't working.

(END)
========================
"@
}

function Get-AdministrativeUnits
{
    Param
    (
        $eduObjectType
    )

    $fileName = $eduObjectType + "-AUs-" + $tenantId +".csv"
	$csvfilePath = Join-Path $outFolder $fileName
    Remove-Item -Path $csvfilePath -Force -ErrorAction Ignore
    
    # Removes csv file unless link is provided to resume
    if ((Test-Path $csvFilePath) -and ($skipToken -eq "."))
    {
 	    Remove-Item $csvFilePath;
    }

    $auList = @() # Array of objects for AUs
    $pageCnt = 1 # Counts the number of pages of AUs retrieved
    $lastRefreshed = $null # Used for refreshing connection

    # Get all AU's of Edu Object Type School
    Write-Progress -Activity "Reading AAD" -Status "Fetching School Administrative Units"

    do {
        # Check if need to renew connection
        $currentDT = Get-Date
        if ($lastRefreshed -eq $null -or (New-TimeSpan -Start $currentDT -End $lastRefreshed).Minutes -gt 10) {
            Connect-Graph -scopes "AdministrativeUnit.Read.All, Directory.Read.All, AdministrativeUnit.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All" | Out-Null
            $lastRefreshed = Get-Date
        }

        $auUri = "$graphEndPoint/$graphVersion/directory/administrativeUnits?`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"

        if ($skipToken -ne "" ) {
            $auUri = $skipToken
        }

        $auResponse = Invoke-GraphRequest -Method GET -Uri $auUri
        $aus = $auResponse.value

        $auCtr = 1 # Counter for AUs retrieved

        foreach ($au in $aus) {
            if ( ($au.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType -eq $eduObjectType) ) { # Filtering out AU already with SDS attribute
                $obj = [pscustomobject]@{"ObjectId"=$au.Id;"DisplayName"=$au.DisplayName;}
                $auList += $obj
                $auCtr++
            }
        }

        Write-Progress -Activity "Retrieving School Administrative Units..." -Status "Retrieved $auCtr AUs from $pageCnt pages"

        # Write nextLink to log if need to restart from previous page
        Write-Output "[$(Get-Date -Format G)] Retrieved $pageCnt pages. nextLink: $($graphResponse.'@odata.nextLink')" | Out-File $logFilePath -Append
        $pageCnt++

    } while ($auResponse.'@odata.nextLink')  

    $auList | Export-Csv $csvFilePath -Append -NoTypeInformation

    return $csvFilePath
}

function Remove-AdministrativeUnits
{
    Param
    (
        $auListFileName
    )

    Write-Host "WARNING: You are about to remove Administrative Units and its memberships created from SDS. `nIf you want to skip removing any AUs, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all the AUs logged in $auListFileName (yes/no)?" -ForegroundColor White

    $choice = Read-Host

    if ($choice -ieq "y" -or $choice -ieq "yes") {
        Write-Progress -Activity $activityName -Status "Deleting Administrative Units"
        $auList = import-csv $auListFileName
        $auCount = $auList.Length
        $index = 1

        foreach ($au in $auList) {
            Write-Output "[$index/$auCount] Removing AU `"$($au.DisplayName)`" [$($au.ObjectId)] from directory" | Out-File $logFilePath -Append
            Remove-MgDirectoryAdministrativeUnit -AdministrativeUnitId $au.ObjectId -Confirm:$false
            Write-Progress -Activity "Removing School Administrative Units..." -Status "Progress ->" -PercentComplete ($index/$auList.count*100)
            $index++
        }
    }
}


# Main
$graphEndPoint = $graphEndpointProd
$graphScopes = "AdministrativeUnit.Read.All, Directory.Read.All, AdministrativeUnit.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All"
$logFilePath = "$outFolder\Remove-All_Schools.log"

$graphEndPoint = $GraphEndpointProd

if ($PPE) {
    $graphEndPoint = $GraphEndpointPPE
}

try
{
    Import-Module Microsoft.Graph.Authentication | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-PrerequisiteHelp | Out-String | Write-Error
    throw
}

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0) {
	mkdir $outFolder;
}

# Connecting to resources
Connect-Graph -scopes $graphScopes

$tenantInfo = Get-MgOrganization
$tenantId =  $tenantInfo.Id

$activityName = "Cleaning up SDS Objects in Directory"

Write-Progress -Activity $activityName -Status "Connected. Discovering tenant information"
Write-Host "`nActivity logged to file $logFilePath `n" -ForegroundColor Green

# Get all AUs of Edu Object Type School
Write-Progress -Activity $activityName -Status "Fetching School Administrative Units"
$outputFileName = Get-AdministrativeUnits "School"
Write-Host "`nSchool Administrative Units logged to file $outputFileName `n" -ForegroundColor Green

# Delete School AUs
Remove-AdministrativeUnits $outputFileName

Write-Output "`n`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"
