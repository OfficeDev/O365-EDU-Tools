<#
.SYNOPSIS
This script is designed to create information barrier policies for each administrative unit and security Group not created by SDS from an O365 tenant.

.DESCRIPTION
This script will read from Azure, and output the administrative units and security groups to CSVs.  Afterwards, you are prompted to confirm that you want to create the organization segments needed, then create and apply the information barrier policies.  A folder will be created in the same directory as the script itself and contains a log file which details the organization segments and information barrier policies created.  The rows of the csv files can be reduced to only target specific administrative units and security groups.  Nextlink in the log can be used for the skipToken script parameter to continue where the script left off in case it does not finish. 

.PARAMETER csvFilePathAU

The path for the csv file containing the non-SDS administrative units in the tenant.  When provided, the script will attempt to create the organization segments and information barrier policies from the records in the file.  Each record should contain the AAD ObjectId and DisplayName.

.PARAMETER csvFilePathSG

The path for the csv file containing the non-SDS security groups in the tenant.  When provided, the script will attempt to create the organization segments and information barrier policies from the records in the file.  Each record should contain the AAD ObjectId and DisplayName.

.PARAMETER skipToken

Used to start where the script left off fetching the users in case of interruption.  The value used is nextLink in the log file, otherwise use default value of "" to start from the beginning.

.PARAMETER outFolder

Path where to put the log and csv file with the fetched data from Graph.

.PARAMETER graphVersion

The version of the Graph API.

.EXAMPLE
PS> .\Create-non_SDS_Information_Barriers.ps1

.NOTES
========================
 Required Prerequisites
========================

1. This script uses features that require Information Barriers version 3 or above to be enabled in your tenant.

    a. Existing Organization Segments and Information Barriers created by a legacy version should be removed prior to upgrading.

2. Install Microsoft Graph Powershell Module and Exchange Online Management Module with commands 'Install-Module Microsoft.Graph' and 'Install-Module ExchangeOnlineManagement'

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes AdministrativeUnit.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All" to bring up a sign-in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up.

4.  Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working and do the same for the Exchange Online Management Module.
#>

Param (
    [Parameter(Mandatory=$false)]
    [string] $skipToken= "",
    [Parameter(Mandatory=$false)]
    [string] $csvFilePathAU = "",
    [Parameter(Mandatory=$false)]
    [string] $csvFilePathSG = "",
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\non_SDS_InformationBarriers",
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    [switch] $PPE = $false
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

function Get-AUsAndSGs ($aadObjectType) {

    $csvFilePath = "$outFolder\$aadObjectType.csv"

    # Removes csv file unless link is provided to resume
    if ((Test-Path $csvFilePath) -and ($skipToken -eq ""))
    {
 	    Remove-Item $csvFilePath;
    }

    $pageCnt = 1 # Counts the number of pages of SGs retrieved
    $lastRefreshed = $null # Used for refreshing connection

    # Uri string for AU's
    $auUri = "$graphEndPoint/$graphVersion/directory/administrativeUnits?`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"

    # Preparing uri string for groups
    $grpSelectClause = "`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"
    $grpUri = "$graphEndPoint/$graphVersion/groups?`$filter=securityEnabled%20eq%20true&$grpSelectClause"

    # Determine either AU or SG uri to use
    switch ($aadObjectType) {
        $aadObjAU {
            $graphUri = $auUri
        }
        $aadObjSG {
            $graphUri = $grpUri
        }
    }

    Write-Progress -Activity "Reading AAD" -Status "Fetching $aadObjectType's"

    do {
        if ($skipToken -ne "" ) {
            $graphUri = $skipToken
        }

        $recordList = @() # Array of objects for SGs

        # Check if need to renew connection
        $currentDT = Get-Date
        if ($lastRefreshed -eq $null -or (New-TimeSpan -Start $currentDT -End $lastRefreshed).Minutes -gt 10) {
            Connect-Graph -scopes $graphScopes | Out-Null
            $lastRefreshed = Get-Date
        }

        $response = Invoke-GraphRequest -Uri $graphUri -Method GET
        $records = $response.value

        $ctr = 0 # Counter for security groups retrieved

        foreach ($record in $records) {
            if ( !($record.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType) ) {
                $recordList += [pscustomobject]@{"ObjectId"=$record.Id;"DisplayName"=$record.DisplayName}
                $ctr++
            }
        }

        $recordList | Export-Csv $csvFilePath -Append -NoTypeInformation
        Write-Progress -Activity "Retrieving $aadObjectType's..." -Status "Retrieved $ctr $aadObjectType's from $pageCnt pages"

        # Write nextLink to log if need to restart from previous page
        Write-Output "[$(Get-Date -Format G)] Retrieved $pageCnt $aadObjectType's. nextLink: $($response.'@odata.nextLink')" | Out-File $logFilePath -Append
        $pageCnt++
        $skipToken = $response.'@odata.nextLink'

    } while ($response.'@odata.nextLink')

    return $csvFilePath
}

function Create-InformationBarriers ($aadObjectType, $csvfilePath) {

    Write-Host "`nYou are about to create an organization segment and information barrier policy from $aadObjectType's. `nIf you want to skip any security groups, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with creating an organization segments and information barrier policy from $aadObjectType' logged in $csvFilePath (yes/no) or ^+c to exit script?" -ForegroundColor Yellow

    $choiceIB = Read-Host
    if ($choiceIB -ieq "y" -or $choiceIB -ieq "yes") {

        $allRecords = Import-Csv $csvfilePath | Sort-Object * -Unique # Import data retrieved from Graph and remove dupes if occurred from skipToken retry.
        $i = 0 # Counter for progress of IB creation

        Write-Output "Creating Information Barrier Policy from $aadObjectType's`n"

        # Looping through all records
        foreach($record in $allRecords) {

            # Determining which organization segment filter to use
            if ( $record.ObjectId -ne $null ) {
                switch ($aadObjectType) {
                    $aadObjAU { 
                        $segmentFilter = "AdministrativeUnits -eq '$($record.DisplayName)'" 
                    }
                    $aadObjSG { 
                        $segmentFilter = "MemberOf -eq '$($record.ObjectId)'" 
                    }
                }

                # Creating organization segments for the information barriers
                try {
                    New-OrganizationSegment -Name $record.DisplayName -UserGroupFilter $segmentFilter | Out-Null 
                    Write-Output "[$(Get-Date -Format G)] Created organization segment $($record.DisplayName) from $($aadObjectType)." | Out-File $logFilePath -Append
                }
                catch {
                    Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
                }

                # Creating information barrier policies
                try {
                    New-InformationBarrierPolicy -Name "$($record.DisplayName) - IB" -AssignedSegment $record.DisplayName -SegmentsAllowed $record.DisplayName -State Active -Force -ErrorAction Stop | Out-Null
                    Write-Output "[$(Get-Date -Format G)] Created Information Barrier Policy $($record.DisplayName) from organization segment" | Out-File $logFilePath -Append
                }
                catch {
                    Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
                }
            }
            $i++
            Write-Progress -Activity "`nCreating Organization Segments and Information Barrier Policies based from $aadObjectType's" -Status "Progress ->" -PercentComplete ($i/$allRecords.count*100)
        }
    }    
    return
}

# Main
$graphEndPoint = $GraphEndpointProd

if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
}

$logFilePath = "$outFolder\create_non_SDS_InformationBarriers.log"

$aadObjAU = "AU"
$aadObjSG = "SG"

# List used to request access to data
$graphScopes = "AdministrativeUnit.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All"

try 
{
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-Help -Name .\Create-non_SDS_Information_Barriers.ps1 -Full | Out-String | Write-Error
    throw
}

try 
{
    Import-Module ExchangeOnlineManagement | Out-Null
}
catch
{
    Write-Error "Failed to load Exchange Online Management Module for creating Information Barriers"
    Get-Help -Name .\Create-non_SDS_Information_Barriers.ps1 -Full | Out-String | Write-Error
    throw
}

 # Create output folder if it does not exist
 if ((Test-Path $outFolder) -eq 0) {
 	mkdir $outFolder | Out-Null;
 }

Write-Host "`nActivity logged to file $logFilePath `n" -ForegroundColor Green

Connect-Graph -scopes $graphScopes | Out-Null
Connect-IPPSSession | Out-Null


if ( $csvFilePathAU -eq "" ) {
    $csvFilePathAU = Get-AUsAndSGs $aadObjAU
}

if ( $csvFilePathAU -ne "" ) {
    if (Test-Path $csvFilePathAU) {
        Create-InformationBarriers $aadObjAU $csvFilePathAU
    }
    else {
        Write-Error "Path for $csvFilePathAU is not found."
    }
}

if ( $csvFilePathSG -eq "" ) {
    $csvFilePathSG = Get-AUsAndSGs $aadObjSG
}

if ( $csvFilePathSG -ne "" ) {
    if (Test-Path $csvFilePathSG) {
        Create-InformationBarriers $aadObjSG $csvFilePathSG
    }
    else {
        Write-Error "Path for $csvFilePathSG is not found."
    }
}

Write-Host "`nProceed with starting the information barrier policies application (yes/no)?" -ForegroundColor Yellow
$choiceStartIB = Read-Host

if ($choiceStartIB -ieq "y" -or $choiceStartIB -ieq "yes") {
    Start-InformationBarrierPoliciesApplication | Out-Null
    Write-Output "Done.  Please allow ~30 minutes for the system to start the process of applying Information Barrier Policies. `nUse Get-InformationBarrierPoliciesApplicationStatus to check the status"
}

Write-Output "`n`nDone.  Please run 'Disconnect-Graph' and 'Disconnect-ExchangeOnline' if you are finished`n"
