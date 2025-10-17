<#
.SYNOPSIS
This script is designed to remove all School Administrative Unit (AU) memberships created by SDS from an O365 tenant. The script connects to Microsoft Graph, retrieves all school AU memberships, exports them to a CSV file in the output folder, and then prompts for confirmation before removing the memberships. Users can edit the CSV file to exclude specific memberships before confirming deletion.
Once the script completes, CSV and log files will be created in the specified output folder detailing the school AU memberships that were removed.
 
.Example
.\Remove-SchoolAU_Memberships.ps1
 
.NOTES
========================
 Required Prerequisites
========================
 
1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'
 
2.  Make sure to download common.ps1 to the same folder of the script which has common functions needed.  https://github.com/OfficeDev/O365-EDU-Tools/blob/master/SDS%20Scripts/common.ps1
 
3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.
 
    a. Open a separate PowerShell session
   
    b. Execute: "connect-graph -scopes AdministrativeUnit.ReadWrite.All, User.Read.All" to bring up a sign in UI.
   
    c. Sign in with any tenant administrator credentials
   
    d. If you are returned to the PowerShell session without error, you are correctly set up
 
5. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working
 
========================
#>
 
Param (
    [switch] $PPE = $false,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\SDSSchoolAUMemberships",
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
 
function Get-AdministrativeUnitMemberships($refreshToken, $graphscopes, $logFilePath) {
 
    # Preparing uri string
    $auMemberAllSelectClause = "`$select=id,DisplayName,@data.type,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"
 
    $initialSDSSchoolAUsUri = "$graphEndPoint/beta/directory/administrativeUnits?$auMemberAllSelectClause"
   
    # Getting AUs for all schools
    $checkedSDSSchoolAUsUri = TokenSkipCheck $initialSDSSchoolAUsUri $logFilePath
    $allSchoolAUs = PageAll-GraphRequest $checkedSDSSchoolAUsUri $refreshToken 'GET' $graphscopes $logFilePath
 
    # Write to school AU count to log
    Write-Output "[$(Get-Date -Format G)] Retrieve $($allSchoolAUs.Count) school AUs." | out-file $logFilePath -Append
   
    $schoolAUMemberships = @() # Array of objects for memberships

 
    $i = 0 # Counter for progress
   
    # Looping through all school Aus
    foreach($au in $allSchoolAUs)
    {
        if ($au.id -ne $null)
        {
            # Getting members of each school au
            $auMembershipUri = $graphEndPoint + '/beta/directory/administrativeUnits/' + $au.id + '/members'
            $checkedAUMembershipUri = TokenSkipCheck $auMembershipUri $logFilePath
            $schoolAUMembers = PageAll-GraphRequest $checkedAUMembershipUri $refreshToken 'GET' $graphscopes $logFilePath
 
            # Getting info for each au member
            foreach ($auMember in $schoolAUMembers)
            {
                $auMemberType = $auMember.'@odata.type' # Some members are users and some are groups
               
                if ($auMemberType -eq '#microsoft.graph.user' -or $auMemberType -eq '#microsoft.graph.group')
                {
 
                    if ($auMember.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType -match 'school')
                    {        
                            # Create object required for export-csv and add to array
                            $obj = [pscustomobject]@{"AUObjectId"=$au.Id;"AUDisplayName"=$au.DisplayName;"AUMemberObjectId"=$auMember.Id; "AUMemberDisplayName"=$auMember.DisplayName;}
                            $schoolAUMemberships += $obj  
                    }
                }
            }
        }
        $i++
        Write-Progress -Activity "Retrieving school AU memberships" -Status "Progress ->" -PercentComplete ($i/$allSchoolAUs.count*100)
    }
 
    $results = $schoolAUMemberships
    return $results
}
 
function Remove-AdministrativeUnitMemberships
{
    Param
    (
        $graphScopes,
        $auMemberListFileName
    )
 
    Write-Host "WARNING: You are about to remove Administrative Unit memberships created from SDS. `nIf you want to skip removing any AU members, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all the AU memberships logged in $auMemberListFileName (yes/no)?" -ForegroundColor White
   
    $choice = Read-Host
    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        Write-Progress -Activity $activityName -Status "Deleting Administrative Unit Memberships"
        $auMemberList = Import-Csv $auMemberListFileName
        $auMemberCount = ($auMemberList).Count
 
        if ($auMemberCount -lt 1)
        {
            Write-Host "`nNo memberships found`n" -ForegroundColor Yellow
            break
        }
 
        $index = 1
        Foreach ($aum in $auMemberList)
        {
            $percentComplete = [math]::Round(($index / $auMemberCount) * 100, 2)
            Write-Progress -Activity $activityName -Status "Deleting [$index/$auMemberCount]" -PercentComplete $percentComplete
            Write-Output "[$(Get-Date -Format G)] [$index/$auMemberCount] Removing AU Member id [$($aum.AUMemberObjectId)] of `"$($aum.AUDisplayName)`" [$($aum.AUObjectId)] from directory" | Out-File $logFilePath -Append
            $removeUrl = $graphEndPoint + '/beta/directory/administrativeUnits/' + $aum.AUObjectId + '/members/' + $aum.AUMemberObjectId +'/$ref'
            PageAll-GraphRequest $removeUrl $refreshToken 'DELETE' $graphscopes $logFilePath | Out-Null
            $index++
        }
    }
}
 
Function Format-ResultsAndExport($graphscopes, $logFilePath) {
 
    $refreshToken = Initialize $graphscopes
   
    $allSchoolAUMemberships = Get-AdministrativeUnitMemberships $refreshToken $graphscopes $logFilePath
 
    if ($allSchoolAUMemberships -eq $null)
    {
        return
    }
 
    # Output to file
    if ($skipToken -eq ".")
    {
        Write-Output $allSchoolAUMemberships | Export-Csv -Path "$csvfilePath" -NoTypeInformation
    }
    else
    {
        $newCsvFilePath = "$outFolder\$((Get-ChildItem $csvfilePath).BaseName)$($skiptoken.length).csv"
        Write-Output $allSchoolAUMemberships | Export-Csv -Path $newCsvFilePath -NoTypeInformation
    }
 
    Out-File $logFilePath -Append -InputObject $global:nextLink
}
 
# Main
$graphEndPoint = $graphEndpointProd
 
if ($PPE)
{
    $graphEndPoint = $graphEndpointPPE
}
 
$activityName = "Cleaning up SDS Objects in Directory"
 
$logFilePath = "$outFolder\SchoolAuMemberships.log"
$csvFilePath = "$outFolder\SchoolAuMemberships.csv"
 
# List used to request access to data
$graphscopes = "AdministrativeUnit.ReadWrite.All, User.Read.All"
 
try
{
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-Help -Name .\Remove-SchoolAU_Memberships.ps1 -Full | Out-String | Write-Error
    throw
}
 
 # Create output folder if it does not exist
 if ((Test-Path $outFolder) -eq 0)
 {
    mkdir $outFolder;
 }
 
 
# Get all Members of all AU's of Edu Object Type School
Write-Progress -Activity "Reading SDS" -Status "Fetching School Administrative Unit Memberships"
 
Write-Host "`nSchool Administrative Units Memberships logged to file $csvFilePath `n" -ForegroundColor Green
Format-ResultsAndExport $graphscopes $logFilePath
 
# Remove School AU Memberships
Remove-AdministrativeUnitMemberships $graphscopes $csvFilePath
 
Write-Output "`nDone.  Logs can be reviewed at $logFilePath`n"
 
Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"