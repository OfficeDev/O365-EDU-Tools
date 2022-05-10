<#
.SYNOPSIS
This script is designed to create information barrier policies for each administrative unit and security groups from an O365 tenant.

.DESCRIPTION
This script will read from Azure, and output the administrative units and security groups to CSVs.  Afterwards, you are prompted to confirm that you want to create the organization segments needed, then create and apply the information barrier policies.  A folder will be created in the same directory as the script itself and contains a log file which details the organization segments and information barrier policies created.  The rows of the csv files can be reduced to only target specific administrative units and security groups.  Nextlink in the log can be used for the skipToken script parameter to continue where the script left off in case it does not finish. 

.PARAMETER all
Executes script without confirmation prompts

.PARAMETER auOrgSeg
Bypasses confirmation prompt to create organization segments from records in the administrative units file.  

.PARAMETER auIB
Bypasses confirmation prompt to create information barriers from records in the administrative units file.  

.PARAMETER sgOrgSeg
Bypasses confirmation prompt to create organization segments from records in the security groups file. 

.PARAMETER sgIB
Bypasses confirmation prompt to create information barriers from records in the security groups file.

.PARAMETER csvFilePathAU

The path for the csv file containing the administrative units in the tenant.  When provided, the script will attempt to create the organization segments and information barrier policies from the records in the file.  Each record should contain the AAD ObjectId and DisplayName.

.PARAMETER csvFilePathSG

The path for the csv file containing the security groups in the tenant.  When provided, the script will attempt to create the organization segments and information barrier policies from the records in the file.  Each record should contain the AAD ObjectId and DisplayName.

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
    [string] $upn,

    [Alias("a")]
    # Next 5 switches used to bypass confirmation prompt
    [switch]$all = $false,
    [switch]$auOrgSeg = $false,
    [switch]$auIB = $false,
    [switch]$sgOrgSeg = $false,
    [switch]$sgIB = $false,
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

#Used for refreshing connection
$connectTypeGraph = "Graph"
$connectTypeIPPSSession = "IPPSSession"
$connectGraphDT = Get-Date -Date "1970-01-01T00:00:00"
$connectIPPSSessionDT = Get-Date -Date "1970-01-01T00:00:00"

# Try to use the most session time for large datasets
$timeout = (New-Timespan -Hours 0 -Minutes 0 -Seconds 43200)
$pssOpt = new-PSSessionOption -IdleTimeout $timeout.TotalMilliseconds

function Set-Connection($connectDT, $connectionType) {
    # Check if need to renew connection
    $currentDT = Get-Date
    $lastRefreshedDT = $connectDT

    if ((New-TimeSpan -Start $lastRefreshedDT -End $currentDT).TotalMinutes -gt $timeout.TotalMinutes)
    {
        if ($connectionType -ieq $connectTypeIPPSSession)
        {
            $sessionIPPS = Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange" -and $_.State -eq "Opened"}
            
            if ($sessionIPPS.count -eq 3) # Exchange Online allows 3 sessions max
            {
                Disconnect-ExchangeOnline -confirm:$false | Out-Null
            }
            else {   
                if (!($upn))
                {
                    Connect-IPPSSession -PSSessionOption $pssOpt | Out-Null
                }
                else
                {
                    Connect-IPPSSession -PSSessionOption $pssOpt -UserPrincipalName $upn | Out-Null
                }
            }
        }
        else
        {
            Connect-Graph -scopes $graphScopes | Out-Null

            if (!($upn)) # Get upn for Connect-IPPSSession to avoid entering again
            {
                $connectedGraphUser = Invoke-GraphRequest -method get -uri "$graphEndpoint/$graphVersion/me"
                $connectedGraphUPN = $connectedGraphUser.userPrincipalName
                $upn = $connectedGraphUPN
            }
        }
    }
    return Get-Date
}
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

            $response = Invoke-GraphRequest -Uri $graphUri -Method GET
            $records = $response.value

            $ctr = 0 # Counter for security groups retrieved

            foreach ($record in $records) {
                # if ( !($record.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType) ) {
                    $recordList += [pscustomobject]@{"ObjectId"=$record.Id;"DisplayName"=$record.DisplayName}
                    $ctr++
                # }
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

function Create-OrganizationSegments ($aadObjectType, $csvfilePath) {
    
    if ( $all -or ( $auOrgSeg -and ($aadObjectType -eq $aadObjAU)) -or ($sgOrgSeg -and ($aadObjectType -eq $aadObjSG)))
    {
        $choiceIB = "y"
    }
    else
    {
        Write-Host "`nYou are about to create organization segments from $aadObjectType's. `nIf you want to skip any $aadObjectType's, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
        Write-Host "Proceed with creating an organization segments from $aadObjectType's logged in $csvFilePath (yes/no) or ^+c to exit script?" -ForegroundColor Yellow

        $choiceIB = Read-Host
    }

    if ($choiceIB -ieq "y" -or $choiceIB -ieq "yes") {

        $allRecords = Import-Csv $csvfilePath #| Sort-Object * -Unique # Import data retrieved from Graph and remove dupes if occurred from skipToken retry.

        Write-Host "`nCreating $($allRecords.count) organization segments from $aadObjectType's.  Check $logFilePath to view progress`n" -ForegroundColor Yellow

        $batch = 50
        # Looping through all records
        for ($i=0; $i -lt $allRecords.count; $i+=$batch){
    
            $recPart = $allRecords | Select-Object $_ -skip $i -first $batch

            switch ($aadObjectType) {
                $aadObjAU { 
                    try {
                        $recPart | foreach-object {New-OrganizationSegment -Name $_.DisplayName -UserGroupFilter "AdministrativeUnits -eq '$($_.ObjectId)'" | select-object whenchanged, type, name, guid | ConvertTo-json -compress | out-file $logFilePath -Append}
                    }
                    catch {
                        Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
                    }
                }
                $aadObjSG { 
                    try {
                        $recPart | foreach-object {New-OrganizationSegment -Name $_.DisplayName -UserGroupFilter "MemberOf -eq '$($record.ObjectId)'" | select-object whenchanged, type, name, guid | ConvertTo-json -compress | out-file $logFilePath -Append}
                    }
                    catch {
                        Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
                    }
                }
            }
                
            Start-Sleep -Seconds 10
            Write-Progress -Activity "`nCreating Organization Segments based from $aadObjectType's" -Status "Progress ->" -PercentComplete ($i/$allRecords.count*100)
        }
    } 
    return
}

function Create-InformationBarriers ($aadObjectType, $csvfilePath) {

    if ( $all -or ( $auIB -and ($aadObjectType -eq $aadObjAU)) -or ($sgIB -and ($aadObjectType -eq $aadObjSG)))
    {
        $choiceIB = "y"
    }
    else
    {
        Write-Host "`nYou are about to create information barrier policies from $aadObjectType's. `nIf you want to skip any $aadObjectType's, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
        Write-Host "Proceed with creating information barrier policies from $aadObjectType's logged in $csvFilePath (yes/no) or ^+c to exit script?" -ForegroundColor Yellow

        $choiceIB = Read-Host
    }

    if ($choiceIB -ieq "y" -or $choiceIB -ieq "yes") {

        $allRecords = Import-Csv $csvfilePath #| Sort-Object * -Unique # Import data retrieved from Graph and remove dupes if occurred from skipToken retry.

        Write-Host "`nCreating $($allRecords.count) information barrier policies from $aadObjectType's.  Check $logFilePath to view progress`n" -ForegroundColor Yellow

        $batch = 50
        # Looping through all records
        for ($i=0; $i -lt $allRecords.count; $i+=$batch){
            $recPart = $allRecords | Select-Object $_ -skip $i -first $batch

            try {
                $recPart | foreach-object {New-InformationBarrierPolicy -Name "$($_.DisplayName) - IB" -AssignedSegment $_.DisplayName -SegmentsAllowed $_.DisplayName -State Active -Force -ErrorAction Stop | select-object whenchanged, type, name, guid | ConvertTo-json -compress | out-file $logFilePath -Append}
            }
            catch {
                Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
            }

            Start-Sleep -Seconds 10           
            $i++
            Write-Progress -Activity "`nCreating information barrier policies based from $aadObjectType's" -Status "Progress ->" -PercentComplete ($i/$allRecords.count*100)
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

if ( $all -or $csvFilePathAU -eq "" ) {
    $connectGraphDT = Set-Connection $connectGraphDT $connectTypeGraph
    $csvFilePathAU = Get-AUsAndSGs $aadObjAU
}

if ( $all -or $csvFilePathAU -ne "" ) {
    if (Test-Path $csvFilePathAU) {
        $connectIPPSSessionDT = Set-Connection $connectIPPSSessionDT $connectTypeIPPSSession
        Create-OrganizationSegments $aadObjAU $csvFilePathAU 
        Create-InformationBarriers $aadObjAU $csvFilePathAU
    }
    else {
        Write-Error "Path for $csvFilePathAU is not found."
    }
}

if ( $all -or $csvFilePathSG -eq "" ) {
    $connectGraphDT = Set-Connection $connectGraphDT $connectTypeGraph
    $csvFilePathSG = Get-AUsAndSGs $aadObjSG
}

if ( $all -or $csvFilePathSG -ne "" ) {
    if (Test-Path $csvFilePathSG) {
        $connectTypeIPPSSession = Set-Connection $connectIPPSSessionDT $connectTypeIPPSSession
        Create-OrganizationSegments $aadObjAU $csvFilePathAU 
        Create-InformationBarriers $aadObjSG $csvFilePathSG
    }
    else {
        Write-Error "Path for $csvFilePathSG is not found."
    }
}

if ( !($all) ) {
    Write-Host "`nProceed with starting the information barrier policies application (yes/no)?" -ForegroundColor Yellow
    $choiceStartIB = Read-Host
}
else{
    $choiceStartIB = "y"
}

if ($choiceStartIB -ieq "y" -or $choiceStartIB -ieq "yes") {
    $connectTypeIPPSSession = Set-Connection $connectDT $connectTypeIPPSSession
    Start-InformationBarrierPoliciesApplication | Out-Null
    Write-Output "Done.  Please allow ~30 minutes for the system to start the process of applying Information Barrier Policies. `nUse Get-InformationBarrierPoliciesApplicationStatus to check the status"
}

Write-Output "`n`nDone.  Please run 'Disconnect-Graph' and 'Disconnect-ExchangeOnline' if you are finished`n"
