<#
.SYNOPSIS
This script is designed to remove all School SG Memberships created by SDS from an O365 tenant. The script sets up the connection to Azure, and then confirm you want to run the script with a "y". 
Once the script completes, a file will be created in the same directory as the script itself, and contain an output file which details the school SG memberships removed.

.EXAMPLE
.\Remove-SchoolSG_Memberships.ps1

.NOTES
========================
 Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'

2.  Make sure to download common.ps1 to the same folder of the script which has common functions needed.  https://github.com/OfficeDev/O365-EDU-Tools/blob/master/SDS%20Scripts/common.ps1

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes GroupMember.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up

4. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working

========================
#>

Param (
    [switch] $PPE = $false,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\SDSSchoolSGMemberships",
    [Parameter(Mandatory=$false)]
    [string] $downloadFcns = "y"
)

$graphEndpointProd = "https://graph.microsoft.com"
$graphEndpointPPE = "https://graph.microsoft-ppe.com"

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

function Get-SecurityGroupMemberships($refreshToken, $graphscopes, $logFilePath) {

    # Preparing uri string
    $grpMemberTeacherSelectClause = "?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'SchoolTeachersSG'&`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"
    $grpMemberStudentSelectClause = "?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'SchoolStudentsSG'&`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"
    $grpMemberSelectClause = "?`$select=id,displayName,@data.type,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource"

    Write-Host "`nTarget students or teachers in SDS school created SGs (teachers/students)?.  Default: students" -ForegroundColor White
    $choice = Read-Host
    if ($choice -ieq "teachers")
    {
        $grpSelectClause = $grpMemberTeacherSelectClause
    }
    else
    {
        $grpSelectClause = $grpMemberStudentSelectClause
    }

    $initialSDSSchoolSGsUri = "$graphEndPoint/beta/groups$grpSelectClause"
    
    # Getting SGs for all schools
    $checkedSDSSchoolSGsUri = TokenSkipCheck $initialSDSSchoolSGsUri $logFilePath
    $schoolSGs = PageAll-GraphRequest $checkedSDSSchoolSGsUri $refreshToken 'GET' $graphscopes $logFilePath

    # Write to school SG count to log
    Write-Output "[$(Get-Date -Format G)] Retrieve $($schoolSGs.Count) school SGs." | out-file $logFilePath -Append
    
    $schoolSGMemberships = @() # Array of objects for memberships

    $i = 0 # Counter for progress

    # Looping through all school SGs
    foreach($grp in $schoolSGs)
    {
        if ($grp.id -ne $null)
        {

            # Getting members of each school SG
            $grpMembershipUri = $graphEndPoint + '/beta/groups/' + $grp.id + '/members' + $grpMemberSelectClause
            $checkedSGMembershipUri = TokenSkipCheck $grpMembershipUri $logFilePath
            $schoolSGMembers = PageAll-GraphRequest $checkedSGMembershipUri $refreshToken 'GET' $graphscopes $logFilePath

            # Getting info for each SG member
            foreach ($grpMember in $schoolSGMembers)
            {
                $grpMemberType = $grpMember.'@odata.type' # Some members are users and some are groups
                
                if ($grpMemberType -eq '#microsoft.graph.user')
                {
                    # Users created by sds have this extension
                    if ($grpMember.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource -ne $null)
                    {
                        # Create object required for export-csv and add to array
                        $obj = [pscustomobject]@{"SGObjectId"=$grp.id;"SGDisplayName"=$grp.displayName;"SGMemberObjectId"=$grpMember.id; "SGMemberDisplayName"=$grpMember.displayName}
                        $schoolSGMemberships += $obj
                    }
                }
            }
        }
        $i++
        Write-Progress -Activity "Retrieving school SG memberships" -Status "Progress ->" -PercentComplete ($i/$schoolSGs.count*100)
    }

    $results = $schoolSGMemberships
    return $results
}

function Remove-SecurityGroupMemberships
{
    Param
    (
        $refreshToken,
        $graphscopes,
        $grpMemberListFileName
    )

    Write-Host "WARNING: You are about to remove Security Group Memberships created from SDS. `nIf you want to skip removing any SG members, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all the SG memberships logged in $grpMemberListFileName (yes/no)?" -ForegroundColor White
    
    $choice = Read-Host
    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        Write-Progress -Activity $activityName -Status "Deleting Security Group Memberships"
        $grpMemberList = Import-Csv $grpMemberListFileName
        $grpMemberCount = (gc $grpMemberListFileName | Measure-Object).count - 1
        
        if ($grpMemberCount -lt 1)
        {
            Write-Host "`nNo memberships found`n" -ForegroundColor Yellow
            break
        }

        $index = 1
        Foreach ($grpm in $grpMemberList)
        {
            Write-Output "[$(Get-Date -Format G)] [$index/$grpMemberCount] Removing SG Member id [$($grpm.SGMemberObjectId)] of `"$($grpm.SGDisplayName)`" [$($grpm.SGObjectId)] from directory" | Out-File $logFilePath -Append 
            $removeUrl = $graphEndPoint + '/beta/groups/' + $grpm.SGObjectId + '/members/' + $grpm.SGMemberObjectId +'/$ref'
            PageAll-GraphRequest $removeUrl $refreshToken 'DELETE' $graphscopes $logFilePath | Out-Null
            $index++
        }
    }
}

Function Format-ResultsAndExport($graphscopes, $logFilePath) {
    
    $refreshToken = Initialize $graphscopes
    
    $allSchoolSGMemberships = Get-SecurityGroupMemberships $refreshToken $graphscopes $logFilePath

    if ($allSchoolSGMemberships -eq $null)
    {
        return
    }

    # Output to file
    if ($skipToken -eq ".")
    {
        Write-Output $allSchoolSGMemberships | Export-Csv -Path "$csvfilePath" -NoTypeInformation
    }
    else
    {
        $newCsvFilePath = "$outFolder\$((Get-ChildItem $csvfilePath).BaseName)$($skiptoken.length).csv"
        Write-Output $allSchoolSGMemberships | Export-Csv -Path $newCsvFilePath -NoTypeInformation
    }

    Out-File $logFilePath -Append -InputObject $global:nextLink
}

# Main
$graphEndPoint = $graphEndpointProd

if ($PPE)
{
    $graphEndPoint = $graphEndpointPPE
}

$logFilePath = "$outFolder\SchoolSGMemberships.log"
$csvFilePath = "$outFolder\SchoolSGMemberships.csv"

$activityName = "Cleaning up SDS Objects in Directory"

# List used to request access to data
$graphscopes = "GroupMember.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All"

try
{
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-Help -Name .\Remove-SchoolSG_Memberships.ps1 -Full | Out-String | Write-Error
    throw
}

 # Create output folder if it does not exist
 if ((Test-Path $outFolder) -eq 0)
 {
 	mkdir $outFolder;
 }

# Get all Members of all SG's of Edu Object Type School
Write-Progress -Activity $activityName -Status "Fetching School Security Group Memberships"
Format-ResultsAndExport $graphscopes $logFilePath
Write-Host "`nSchool Security Group Memberships logged to file $csvFilePath `n" -ForegroundColor Green

# Remove School SG Memberships
Remove-SecurityGroupMemberships $refreshToken $graphscopes $csvFilePath

Write-Output "`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"