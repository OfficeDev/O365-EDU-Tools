<#
.SYNOPSIS
This script is designed to create Information Barrier Policies for each SDS School AU and the 'All Teachers' Security Group created by SDS from an O365 tenant. 

.DESCRIPTION
This script will read from Azure, and output the administrative units to a csv.  Afterwards, you are prompted to confirm that you want to create the organization segments needed, then create and apply the information barrier policies.  A folder will be created in the same directory as the script itself and contains a log file which details the organization segments and information barrier policies created.  Nextlink in the log can be used for the skipToken script parameter to continue where the script left off in case it does not finish.  

.PARAMETER upns
Upn used for Connect-IPPSSession to try to avoid reentering credentials when renewing connection.  Multiple upns separated by commas can be used for parallel jobs. Recommend the maximum amount of 3 for large datasets.  See ** in Notes

.PARAMETER all
Executes script without confirmation prompts

.PARAMETER auOrgSeg
Bypasses confirmation prompt to create organization segments from records in the administrative units file.

.PARAMETER auIB
Bypasses confirmation prompt to create information barriers from records in the administrative units file.

.PARAMETER allTeachers
Bypasses confirmation prompt to create an organization segment and information barrier policy from the All Teachers security group.

.PARAMETER maxParallelJobs 
Maximum number of jobs to run in parallel using ExchangeOnline Module.  We use 1 job per session.  Max sessions is 3 for ExchangeOnline.  Do not run more threads than there are upns.

.PARAMETER maxAttempts
Number of times we attempt to add all compliance objects.

.PARAMETER maxTimePerAttemptMins
Maximum time allowed to attempt to add all compliance objects using parallel jobs.  May need to adjust to several hours for large datasets.

.PARAMETER skipToken
Used to start where the script left off fetching from Graph in case of interruption.  The value used is nextLink in the log file, otherwise use default value of "" to start from the beginning.

.PARAMETER outFolder
Path where to put the log and csv file with the fetched data from Graph.

.PARAMETER graphVersion
The version of the Graph API.

.EXAMPLE
PS> .\Create-SDS_Information_Barriers.ps1

.EXAMPLE
PS> .\Create-SDS_Information_Barriers.ps1 -all:$true -upns upnOne@contoso.com,upnTwo@contoso.com,upnThree@contoso.com -maxParallelJobs 3

.NOTES
========================
 Required Prerequisites
========================
**Because the script must require the Exchange Online PowerShell module and can time out after running for a period of time, it will cache the credentials for use to re-start the connection. This means it will not be useable with MFA.

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
    [array] $upns = @(),

    [Alias("a")]
    [switch]$all = $false,
    [switch]$auOrgSeg = $false,
    [switch]$auIB = $false,
    [switch]$sgOrgSeg = $false,
    [switch]$sgIB = $false,
    [int]$maxParallelJobs = 1,
    [int]$maxAttempts = 2,
    [int]$maxTimePerAttemptMins = 180,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= "",
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\SDS_InformationBarriers",
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    [switch] $PPE = $false
)

$graphEndpointProd = "https://graph.microsoft.com"
$graphEndpointPPE = "https://graph.microsoft-ppe.com"

# Used for refreshing connection
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

            # Exchange Online allows 3 sessions max
            if ($sessionIPPS.count -eq 3) 
            {
                Disconnect-ExchangeOnline -confirm:$false | Out-Null
            }
            else {   
                if ($upns.count -eq 0)
                {
                    Connect-IPPSSession -PSSessionOption $pssOpt | Out-Null
                }
                else
                {
                    if ($ippsCreds.count -eq 0)
                    {
                        Connect-IPPSSession -PSSessionOption $pssOpt -UserPrincipalName $upns[0] | Out-Null
                    }
                    else
                    {
                        Connect-IPPSSession -PSSessionOption $pssOpt -Credential $ippsCreds[0] | Out-Null
                    }
                }
            }
        }
        else
        {
            Connect-Graph -scopes $graphScopes | Out-Null

            # Get upn for Connect-IPPSSession to avoid reentering creds
            if ($upns.count -eq 0)
            {
                $connectedGraphUser = Invoke-GraphRequest -method get -uri "$graphEndpoint/$graphVersion/me"
                $connectedGraphUPN = $connectedGraphUser.userPrincipalName
                $upns += $connectedGraphUPN
            }
        }
    }
    return Get-Date
}

function Get-AllSchoolAUs {

    # Remove temp csv file with school AUs if not resuming from last token
    if ((Test-Path $csvFilePath) -and ($skipToken -eq ""))
    {
 	    Remove-Item $csvFilePath;
    }

    # Preparing uri string
    $auSelectClause = "`$select=id,displayName"
    $currentUri = "$graphEndPoint/$graphVersion/directory/administrativeUnits?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'School'&$auSelectClause"
        
    #Getting AUs for all schools
    Write-Output "`nRetrieving SDS School Administrative Units`n"
    
    $pageCnt = 1 #Counts the number of pages of school AUs Retrieved

    #Get all AU's of Edu Object Type School
    do {
        
        if ($skipToken -ne "" ) {
            $currentUri = $skipToken
        }

        $allSchoolAUs = @() #array of objects for pages of school AUs
        $graphResponse = Invoke-GraphRequest -Method GET -Uri $currentUri -ContentType "application/json"
        $schoolAUs = $graphResponse.value

        $ctr = 0 # Counter for security groups retrieved

        #Write school AU count to log
        Write-Output "[$(Get-Date -Format G)] Retrieved $($schoolAUs.count) school AUs in page $pageCnt" | Out-File $logFilePath -Append
    
        #Write school Aus found to temp csv file
        foreach($au in $schoolAUs)
        {
            #Create object required for export-csv and add to array
            $obj = [pscustomobject]@{"ObjectId"=$au.id;"DisplayName"=$au.displayName;}
            $allSchoolAUs += $obj
            $ctr++
        }
        
        $allSchoolAUs | Export-Csv -Path "$csvfilePath" -Append -NoTypeInformation
        Write-Progress -Activity "Fetching School Administrative Units" -Status "Retrieved $ctr AU's from $pageCnt pages" -Id 1

        #Write nextLink to log if need to restart from previous page
        Write-Output "[$(Get-Date -Format G)] nextLink: $($graphResponse.'@odata.nextLink')" | Out-File $logFilePath -Append
        $pageCnt++
        $currentUri = $graphResponse.'@odata.nextLink'

    } while($graphResponse.'@odata.nextLink')
    
    Start-Sleep 1 # Delay to refresh screen for progress
    Write-Progress "Fetching AU's complete" -Id 1 -Completed

}

$NewAUOrgSegmentsJob = {

    Param ($aus, $startIndex, $count, $thisJobId, $defaultDelay, $addDelay, $timeout, $cred, $logFilePath)
    
    $sb = [System.Text.StringBuilder]::new()

    $pssOptJob = new-PSSessionOption -IdleTimeout $timeout.TotalMilliseconds
    
    $delay = $defaultDelay
    
    for ($i = $startIndex; $i -lt $startIndex+$count; $i++)
    {

        $au = $aus[$i]
        $displayName = $au.DisplayName
        $objectId = $au.ObjectId
        
        $currentJobDt = Get-Date
        
        # Check if need to renew connection
        if ($lastJobRefreshedDT -eq $null -or (New-TimeSpan -Start $lastJobRefreshedDT -End $currentJobDT).TotalMinutes -gt $timeout.TotalMinutes)
        {
            $sessionJobIPPS = Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange" -and $_.State -eq "Opened"}

            # Exchange Online allows 3 sessions max
            if ($sessionJobIPPS.count -eq 3) 
            {
                Disconnect-ExchangeOnline -confirm:$false | Out-Null
            }

            Connect-IPPSSession -PSSessionOption $pssOptJob -Credential $cred | Out-Null
            $lastJobRefreshedDT = Get-Date
        }

        Write-Output "[$($i-$startIndex+1)/$count/$thisJobId] [$(Get-Date -Format G)] Creating organization segment $displayName ($objectId) from administrative unit with $($cred.UserName)"
        $logstr = Invoke-Command { New-OrganizationSegment -Name $displayName -UserGroupFilter "AdministrativeUnits -eq '$($objectId)'" } -ErrorAction Stop -ErrorVariable err -WarningAction SilentlyContinue -WarningVariable warning | Select-Object WhenCreated, WhenChanged, Type, Name, Guid | ConvertTo-json -compress

        $sb.AppendLine($logstr) | Out-Null

        if ($err) 
        {
            $sb.AppendLine("[$(Get-Date -Format G)] ERROR: " + $err) | Out-Null
        }

        if ($warning) 
        {
            $sb.AppendLine("[$(Get-Date -Format G)] WARNING: " + $warning) | Out-Null
        }

        if ($warning | Select-String -Pattern 'GlobalThrottlingPolicy' -SimpleMatch )
        {
            $delay += $addDelay
        }
        else 
        {
            $delay = $defaultDelay
        }

        $sb.ToString() | Out-File $logFilePath -Append
        Start-Sleep -Seconds $delay
    }
}

$NewAUInformationBarriersJob = {

    Param ($aus, $startIndex, $count, $thisJobId, $defaultDelay, $addDelay, $timeout, $cred, $logFilePath)

    $sb = [System.Text.StringBuilder]::new()

    $pssOptJob = new-PSSessionOption -IdleTimeout $timeout.TotalMilliseconds

    $delay = $defaultDelay

    for ($i = $startIndex; $i -lt $startIndex+$count; $i++)
    {
        $au = $aus[$i]
        $displayName = $au.DisplayName
        $objectId = $au.ObjectId

        $currentJobDt = Get-Date

        # Check if need to renew connection
        if ($lastJobRefreshedDT -eq $null -or (New-TimeSpan -Start $lastJobRefreshedDT -End $currentJobDT).TotalMinutes -gt $timeout.TotalMinutes)
        {
            $sessionJobIPPS = Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange" -and $_.State -eq "Opened"}

            # Exchange Online allows 3 sessions max
            if ($sessionJobIPPS.count -eq 3) 
            {
                Disconnect-ExchangeOnline -confirm:$false | Out-Null
            }

            Connect-IPPSSession -PSSessionOption $pssOptJob -Credential $cred | Out-Null
            $lastJobRefreshedDT = Get-Date
        }

        Write-Output "[$($i-$startIndex+1)/$count/$thisJobId] [$(Get-Date -Format G)] Creating information barrier policy $displayName ($objectId) from administrative unit with $($cred.UserName)"
        $logstr = Invoke-Command { New-InformationBarrierPolicy -Name "$displayName - IB" -AssignedSegment $displayName -SegmentsAllowed $displayName -State Active -Force } -ErrorAction Stop -ErrorVariable err -WarningAction SilentlyContinue -WarningVariable warning | Select-Object WhenCreated, WhenChanged, Type, Name, Guid | ConvertTo-json -compress
        $sb.AppendLine($logstr) | Out-Null

        if ($err) 
        {
            $sb.AppendLine("[$(Get-Date -Format G)] ERROR: " + $err) | Out-Null
        }

        if ($warning) 
        {
            $sb.AppendLine("[$(Get-Date -Format G)] WARNING: " + $warning) | Out-Null
        }

        if ($warning | Select-String -Pattern 'GlobalThrottlingPolicy' -SimpleMatch )
        {
            $delay += $addDelay
        }
        else 
        {
            $delay = $defaultDelay
        }

        $sb.ToString() | Out-File $logFilePath -Append
        Start-Sleep -Seconds $delay
    }
}

function Add-AllIPPSObjects($ippsObjectType)
{

    if ($ippsCreds.count -ne $maxParallelJobs) 
    {
        Write-Host "Please ensure the maxParallelJobs parameter equals the number of UPNs entered" -ForegroundColor Red
        exit
    }

    Write-Host "`n=====================================================" -ForegroundColor Cyan
    Write-Host "Adding $ippsObjectType's in Tenant" -ForegroundColor Cyan
    
    $jobDelay = 30;
    $addJobDelay = 15;
    $attempts = 1;

    $aucsv = Import-Csv $csvFilePath

    while ($true)
    {
        $scriptBlock = $null
        $aus = $null
        $totalObjectCount = 0
        $loopStartTime = Get-Date

        switch ($ippsObjectType)
        {
            $ippsObjOS
            {
                $scriptBlock = $NewAUOrgSegmentsJob
                $createdObjs = Get-OrganizationSegment
                $aus = $aucsv | Where-Object { "AdministrativeUnits -eq '$($_.ObjectId)'" -notin $createdObjs.UserGroupFilter }
            }
            $ippsObjIB
            {
                $scriptBlock = $NewAUInformationBarriersJob
                $createdObjs = Get-InformationBarrierPolicy
                $aus = $aucsv | Where-Object { "$($_.DisplayName) - IB" -notin $createdObjs.Name }
            }
        }

        $totalObjectCount = $aus.count
        Write-Host "Creating $totalObjectCount $ippsObjectType's from administrative units. [Attempt #$attempts]" -ForegroundColor Green

        if ($totalObjectCount -eq 0 -or $attempts -gt $maxAttempts)
        {   
            if ($totalObjectCount -eq 0)
            {
                Write-Host "`nDone adding $ippsObjectType `n" -ForegroundColor Green
            }    
            else
            {
            
                Write-Host "`n Could not add all $ippsObjectType's. Giving up after $attempts attempts.`n" -ForegroundColor Red
            }
            break;
        }

        # Split task into equal sized jobs and start executing in parallel
        $startIndex = 0
        [Int]$jobSize = [math]::truncate($totalObjectCount / $maxParallelJobs)
        [Int]$remainder = $totalObjectCount % $maxParallelJobs

        for ($i = 0; $i -lt $maxParallelJobs -and $i -lt $totalObjectCount; $i++)
        {
            $count = $jobSize
            if ($remainder -gt 0)
            {
                $count++
                $Remainder--
            }

            $jobID = $i+1
            $sessionNum = $i
            $threadLogFilePath = $logFilePath -replace ".log$", "-thread$JobId.log"

            Write-Host "Spawning job $jobID to add $count $ippsObjectType's starting at $startIndex; End Index: $($startIndex+$count-1); UPN: $($upns[$sessionNum])" -ForegroundColor Cyan
            Start-Job $scriptBlock -ArgumentList $aus, $startIndex, $count, $jobID, $jobDelay, $addJobDelay, $timeout, $ippsCreds[$sessionNum], $threadLogFilePath
            "[$(Get-Date -Format G)] Check $threadLogFilePath for thread activity" | Tee-Object -FilePath $logFilePath -Append | Write-Host
            $startIndex += $count
        }

        $currentTimeInLoop = Get-Date
        $timeInLoopMins = ($currentTimeInLoop - $loopStartTime).Minutes
        
        # Wait for all jobs to complete or till time out
        While ((Get-Job -State "Running") -and $timeInLoopMins -le $maxTimePerAttemptMins)
        {
            # Display output from all jobs every 10 seconds
            Get-Job | Receive-Job
            Write-Host ""
            Start-Sleep 10
        }

        if ($timeInLoopMins -gt $maxTimePerAttemptMins)
        {
            Write-Host "Attempt timed out, removing any hung jobs" -ForegroundColor Yellow
        }

        # Clean-up any hung jobs
        Get-Job | Receive-Job
        Stop-Job *
        Remove-Job * -Force

        $attempts = $attempts + 1;
    }
}

function Get-AllTeacherSG {
    #preparing uri string
    $grpTeacherSelectClause = "?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'AllTeachersSecurityGroup'&`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"
    $teacherSGUri = "$graphEndPoint/$graphVersion/groups$grpTeacherSelectClause"

    try {
        $graphResponse = Invoke-GraphRequest -Method GET -Uri $teacherSGUri -ContentType "application/json"
        $teacherSG = $graphResponse.value
        
        #Write All Teachers security group retrieved to log
        Write-Output "[$(Get-Date -Format G)] Retrieved $($teacherSG.displayName)." | Out-File $logFilePath -Append
    }
    catch{
        Write-Output "[$(Get-Date -Format G)] $($_.Exception.Message)" | Out-File $logFilePath -Append
        throw "Could not retrieve 'All Teachers' Security Group.  Please make sure that it is enabled in SDS."
    }
    return $teacherSG
}

function Create-InformationBarriersFromTeacherSG($teacherSG) {
    
    Write-Host "Creating organization segment from 'All Teachers' Security Group`n"  

    try {
        New-OrganizationSegment -Name $teacherSG.displayName -UserGroupFilter "MemberOf -eq '$($teacherSG.id)'" | Out-Null
        Write-Output "[$(Get-Date -Format G)] Created organization segment $($teacherSG.displayName) from security group." | Out-File $logFilePath -Append
    }
    catch{
        throw "Error creating organization segment"
    }

    Write-Host "Creating information barrier policy from 'All Teachers' Security Group"
    try {
        New-InformationBarrierPolicy -Name "$($teacherSG.displayName) - IB" -AssignedSegment $teacherSG.displayName -SegmentsAllowed $teacherSG.displayName -State Active -Force | Out-Null
        Write-Output "[$(Get-Date -Format G)] Created Information Barrier Policy $($teacherSG.displayName) from organization segment" | Out-File $logFilePath -Append
    }
    catch {
        throw "Error creating information barrier policy for security group $($teacherSG.displayName)"
    }
}

function Get-IPPSCreds($ippsUPNs)
{
    $creds = @()

    $ippsUPNs | ForEach-Object {
        $creds += Get-Credential -Username $_ -Message "Please enter credentials to IPPSSession for creating organization segments and information barrier policies."
    }
    return $creds
}

# Main
$graphEndPoint = $graphEndpointProd

if ($PPE)
{
    $graphEndPoint = $graphEndpointPPE
}

$activityName = "Creating information barrier policies"

 #Create output folder if it does not exist
 if ((Test-Path $outFolder) -eq 0)
 {
 	mkdir $outFolder | Out-Null;
 }

$logFilePath = "$(Resolve-Path $outFolder)\SDS_InformationBarriers.log"
$csvFilePath = "$(Resolve-Path $outFolder)\SDS_SchoolAUs.csv"

$ippsObjOS = 'OS'
$ippsObjIB = "IB"

#List used to request access to data
$graphScopes = "AdministrativeUnit.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All"

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

try 
{
    Import-Module ExchangeOnlineManagement | Out-Null
}
catch
{
    Write-Error "Failed to load Exchange Online Management Module for creating Information Barriers"
    Get-PrerequisiteHelp | Out-String | Write-Error
    throw
}

Write-Host "`nActivity logged to file $logFilePath `n" -ForegroundColor Green

if ($all)
{
    $connectGraphDT = Set-Connection $connectGraphDT $connectTypeGraph
    Get-AllSchoolAUs     
}
else
{
    Write-Host "Proceed with fetching SDS school administrative units?  Skip if you want to use a previously generated $csvFilePath (yes/no)?" -ForegroundColor Yellow
    $choiceSchoolAU = Read-Host
    if ($choiceSchoolAU -ieq "y" -or $choiceSchoolAU -ieq "yes") {
        $connectGraphDT = Set-Connection $connectGraphDT $connectTypeGraph
        Get-AllSchoolAUs 
    }
}

if($upns.count -gt 0)
{
    $ippsCreds = Get-IPPSCreds $upns
}
else
{
    Write-Host "Please run script with upns parameter for connecting with IPPSSession" -ForegroundColor Red
    exit
}

$connectIPPSSessionDT = Set-Connection $connectIPPSSessionDT $connectTypeIPPSSession

if ($all -or $auOrgSeg)
{
    Add-AllIPPSObjects $ippsObjOS
}
else
{
    Write-Host "`nYou are about to create organization segments from SDS school administrative units. `nIf you want to skip any administrative units, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with creating organization segments from SDS school administrative units logged in $csvFilePath (yes/no)?" -ForegroundColor Yellow
    
    $choiceSchoolOS = Read-Host
    if ($choiceSchoolOS -ieq "y" -or $choiceSchoolOS -ieq "yes") {
        Add-AllIPPSObjects $ippsObjOS
    }
}

if ($all -or $auIB)
{
    Add-AllIPPSObjects $ippsObjIB
}
else
{
    Write-Host "`nYou are about to create information barrier policies from SDS school administrative units. `nIf you want to skip any administrative units, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with creating information barrier policies from SDS school administrative units logged in $csvFilePath (yes/no)?" -ForegroundColor Yellow
    
    $choiceSchoolIB = Read-Host
    if ($choiceSchoolIB -ieq "y" -or $choiceSchoolIB -ieq "yes") {
        Add-AllIPPSObjects $ippsObjIB
    }
}

if ($all -or $allTeachers)
{
    $connectGraphDT = Set-Connection $connectGraphDT $connectTypeGraph
    $allTeacherSG = Get-AllTeacherSG
    $connectIPPSSessionDT = Set-Connection $connectIPPSSessionDT $connectTypeIPPSSession
    Create-InformationBarriersFromTeacherSG $allTeacherSG
}
else
{
    Write-Host "`nYou are about to create an organization segment and information barrier policy from the 'All Teachers' Security Group. `nNote: You need to have the group created via a toggle in the SDS profile beforehand.`n" -ForegroundColor Yellow
    Write-Host "Proceed with creating an organization segments and information barrier policy from the 'All Teachers' Security Group. (yes/no)?" -ForegroundColor Yellow
    $choiceTeachersIB = Read-Host
    if ($choiceTeachersIB -ieq "y" -or $choiceTeachersIB -ieq "yes") {
        $connectGraphDT = Set-Connection $connectGraphDT $connectTypeGraph
        $allTeacherSG = Get-AllTeacherSG
        $connectIPPSSessionDT = Set-Connection $connectIPPSSessionDT $connectTypeIPPSSession
        Create-InformationBarriersFromTeacherSG $allTeacherSG
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
    $connectIPPSSessionDT = Set-Connection $connectIPPSSessionDT $connectTypeIPPSSession
    Start-InformationBarrierPoliciesApplication | Out-Null
    Write-Output "Done.  Please allow ~30 minutes for the system to start the process of applying Information Barrier Policies. `nUse Get-InformationBarrierPoliciesApplicationStatus to check the status"
}

Write-Output "`n`nDone.  Logs can be reviewed at $outFolder`n"
Write-OutPut "Please run 'Disconnect-Graph' and 'Disconnect-ExchangeOnline' if you are finished`n"