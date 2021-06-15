<#
Script Name:
Remove-All_SchoolAU_Memberships.ps1

Synopsis:
This script is designed to remove all School AU Membershipss created by SDS from an O365 tenant. The script sets up the connection to Azure, and then confirm you want to run the script with a "y". Once the script completes, a file will be created in the same directory as the script itself, and contain an output file which details the school AU memberships removed.

Syntax Examples and Options:
.\Remove-SchoolAU_Memberships.ps1

Written By: 
SDS Team, and adapted by Ayron Johnson

Change Log:
Version 1, 3/26/21 - First Draft

#>

Param (
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory=$false)]
    [string] $OutFolder = ".\SDSSchoolAUMemberships"
)


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
    Write-Output "If prompted, please use a tenant admin-account to grant access to 'AdministrativeUnit.ReadWrite.All' and 'User.Read.All' privileges"
    Refresh-Token
}

$lastRefreshed = $null
function Refresh-Token() {
    if ($lastRefreshed -eq $null -or (get-date - $lastRefreshed).Minutes -gt 10) {
        connect-graph -scopes AdministrativeUnit.ReadWrite.All, User.Read.All
        $lastRefreshed = get-date
    }
}

# Gets data from all pages
function PageAll-GraphRequest($initialUri, $logFilePath) {

    # Connect to the tenant
    #Write-Progress -Activity "Graph Request" -Status "Connecting to tenant"

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

function Get-AdministrativeUnitMemberships($logFilePath) {

    #preparing uri string
    $auSelectClause = "`$select=id,displayName"
    $auMemberAllSelectClause = "`$select=id,DisplayName,@data.type,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId"
    $auMemberStudentSelectClause = "`$select=id,DisplayName,@data.type,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_StudentId"

    $initialSDSSchoolAUsUri = "https://graph.microsoft.com/beta/directory/administrativeUnits?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'School'&$auSelectClause"
    
    #getting AUs for all schools
    $checkedSDSSchoolAUsUri = TokenSkipCheck $initialSDSSchoolAUsUri $logFilePath
    $allSchoolAUs = PageAll-GraphRequest $checkedSDSSchoolAUsUri $logFilePath

    #write to school AU count to log
    write-output "Retrieve $($allSchoolAUs.Count) school AUs." | out-file $logFilePath -Append
    
    $schoolAUMemberships = @() #array of objects for memberships

    $i = 0 #counter for progress

    Write-Host "`nTarget both students and teachers in SDS school created AUs (yes/no)?.  Default: students only" -ForegroundColor White
    $choice = Read-Host
    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        $auMemberSelectClause = $auMemberAllSelectClause
    }
    else
    {
        $auMemberSelectClause = $auMemberStudentSelectClause
    }

    #looping through all school Aus
    foreach($au in $allSchoolAUs)
    {
        if ($au.id -ne $null)
        {

            #getting members of each school au
            $auMembershipUri = 'https://graph.microsoft.com/beta/directory/administrativeUnits/' + $au.id + '/members'
            $checkedAUMembershipUri = TokenSkipCheck $auMembershipUri $logFilePath
            $schoolAUMembers = PageAll-GraphRequest $checkedAUMembershipUri $logFilePath
            #$schoolAUMembers = invoke-graphrequest -Method GET -Uri $auMembershipUri -ContentType "application/json"

            #write member count to log
            #write-output "Retrieve $($schoolAUMembers.Count) school AU memberships." | out-file $logFilePath -Append

            #getting info for each au member
            foreach ($auMember in $schoolAUMembers)
            {
                $auMemberType = $auMember.'@odata.type' #some members are users and some are groups
                
                if ($auMemberType -eq '#microsoft.graph.user')
                {

                    $userUri = "https://graph.microsoft.com/beta/users/" + $auMember.Id + "?$auMemberSelectClause"
                    $user = invoke-graphrequest -Method GET -Uri $userUri -ContentType "application/json"

                    #users created by sds have this extension
                    if ($user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId -ne $null)
                    {
                        #write to log
                        #$aum = $au.Id + "," + $au.DisplayName + "," + $auMember.Id | Out-File $logFilePath -Append

                        #create object required for export-csv and add to array
                        $obj = [pscustomobject]@{"AUObjectId"=$au.Id;"AUDisplayName"=$au.DisplayName;"AUMemberObjectId"=$user.Id; "AUMemberDisplayName"=$user.DisplayName}
                        $schoolAUMemberships += $obj
                    }
                }
            }
        }
        $i++
        Write-Progress -Activity "Retrieving school AU memberships" -Status "Progress ->" -PercentComplete ($i/$allSchoolAUs.count*100)
    }

    $results = $schoolAUMemberships -ne "Welcome To Microsoft Graph!"
    return $results
}

function Remove-AdministrativeUnitMemberships
{
    Param
    (
        $auMemberListFileName
    )

    Write-Host "WARNING: You are about to remove Administrative Unit memberships created from SDS. `nIf you want to skip removing any AU members, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all the AU memberships logged in $auMemberListFileName (yes/no)?" -ForegroundColor White
    $choice = Read-Host
    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        Write-Progress -Activity $activityName -Status "Deleting Administrative Unit Memberships"
        $auMemberList = import-csv $auMemberListFileName
        $auMemberCount = $auMemberList.Length
        $index = 1
        Foreach ($aum in $auMemberList) 
        {
            Write-Output "[$index/$auMemberCount] Removing AU Member id [$($aum.AUMemberObjectId)] of `"$($aum.AUDisplayName)`" [$($aum.AUObjectId)] from directory"
            $removeUrl = 'https://graph.microsoft.com/beta/directory/administrativeUnits/' + $aum.AUObjectId + '/members/' + $aum.AUMemberObjectId +'/$ref'
            $graphRequest = invoke-graphrequest -Method DELETE -Uri $removeUrl
            $index++
        }
    }
}

Function Format-ResultsAndExport($logFilePath) {

    Initialize
    
    $allSchoolAUMemberships = Get-AdministrativeUnitMemberships $logFilePath

    #output to file
    if($skipToken -eq "."){
        write-output $allSchoolAUMemberships | Export-Csv -Path "$csvfilePath" -NoTypeInformation
    }
    else {
        write-output $allSchoolAUMemberships | Export-Csv -Path "$csvfilePath$($skiptoken.Length).csv" -NoTypeInformation
    }


    Out-File $logFilePath -Append -InputObject $global:nextLink
}

# Main
$activityName = "Cleaning up SDS Objects in Directory"

$logFilePath = "$OutFolder\SchoolAuMemberships.log"
$csvFilePath = "$OutFolder\SchoolAuMemberships.csv"



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
 if ((Test-Path $OutFolder) -eq 0)
 {
 	mkdir $OutFolder;
 }


    # Get all Members of all AU's of Edu Object Type School
    Write-Progress -Activity "Reading SDS" -Status "Fetching School Administrative Unit Memberships"

    Write-Host "`nSchool Administrative Units Memberships logged to file $csvFilePath `n" -ForegroundColor Green
    Format-ResultsAndExport $logFilePath

    # Remove School AU Memberships
    Remove-AdministrativeUnitMemberships $csvFilePath


Write-Output "`nDone.`n"

Write-Output "Please run 'disconnect-graph' if you are finished making changes.`n"