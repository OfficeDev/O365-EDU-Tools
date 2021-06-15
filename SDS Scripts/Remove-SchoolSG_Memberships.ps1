<#
Script Name:
Remove-All_SchoolSG_Memberships.ps1

Synopsis:
This script is designed to remove all School SG Membershipss created by SDS from an O365 tenant. The script sets up the connection to Azure, and then confirm you want to run the script with a "y". 
Once the script completes, a file will be created in the same directory as the script itself, and contain an output file which details the school SG memberships removed.

Syntax Examples and Options:
.\Remove-SchoolSG_Memberships.ps1

Written By: 
SDS Team, and adapted by Ayron Johnson

Change Log:
Version 1, 4/6/21 - First Draft

#>

Param (
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory=$false)]
    [string] $OutFolder = ".\SDSSchoolSGMemberships"
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
    Write-Output "If prompted, please use a tenant admin-account to grant access to GroupMember.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All privileges"
    Refresh-Token
}

$lastRefreshed = $null
function Refresh-Token() {
    if ($lastRefreshed -eq $null -or (get-date - $lastRefreshed).Minutes -gt 10) {
        connect-graph -scopes GroupMember.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All
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

function Get-SecurityGroupMemberships($logFilePath) {

    #preparing uri string
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

    $initialSDSSchoolSGsUri = "https://graph.microsoft.com/beta/groups$grpSelectClause"
    
    #getting SGs for all schools
    $checkedSDSSchoolSGsUri = TokenSkipCheck $initialSDSSchoolSGsUri $logFilePath
    $schoolSGs = PageAll-GraphRequest $checkedSDSSchoolSGsUri $logFilePath

    #write to school SG count to log
    write-output "Retrieve $($schoolSGs.Count) school SGs." | out-file $logFilePath -Append
    
    $schoolSGMemberships = @() #array of objects for memberships

    $i = 0 #counter for progress

    #looping through all school SGs
    foreach($grp in $schoolSGs)
    {
        if ($grp.id -ne $null)
        {

            #getting members of each school SG
            $grpMembershipUri = 'https://graph.microsoft.com/beta/groups/' + $grp.id + '/members' + "$grpMemberSelectClause"
            $checkedSGMembershipUri = TokenSkipCheck $grpMembershipUri $logFilePath
            $schoolSGMembers = PageAll-GraphRequest $checkedSGMembershipUri $logFilePath
            #$schoolSGMembers = invoke-graphrequest -Method GET -Uri $grpMembershipUri -ContentType "application/json"

            #write member count to log
            #write-output "Retrieve $($schoolSGMembers.Count) school SG memberships." | out-file $logFilePath -Append

            #getting info for each SG member
            foreach ($grpMember in $schoolSGMembers)
            {
                $grpMemberType = $grpMember.'@odata.type' #some members are users and some are groups
                
                if ($grpMemberType -eq '#microsoft.graph.user')
                {

                    #$userUri = "https://graph.microsoft.com/beta/users/" + $grpMember.Id + "?$grpMemberSelectClause"
                    #$user = invoke-graphrequest -Method GET -Uri $userUri -ContentType "application/json"

                    #users created by sds have this extension
                    if ($grpMember.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource -ne $null)
                    {
                        #write to log
                        #$grpm = $grp.Id + "," + $grp.DisplayName + "," + $grpMember.Id | Out-File $logFilePath -Append

                        #create object required for export-csv and add to array
                        $obj = [pscustomobject]@{"SGObjectId"=$grp.id;"SGDisplayName"=$grp.displayName;"SGMemberObjectId"=$grpMember.id; "SGMemberDisplayName"=$grpMember.displayName}
                        $schoolSGMemberships += $obj
                    }
                }
            }
        }
        $i++
        Write-Progress -Activity "Retrieving school SG memberships" -Status "Progress ->" -PercentComplete ($i/$schoolSGs.count*100)
    }

    $results = $schoolSGMemberships -ne "Welcome To Microsoft Graph!"
    return $results
}

function Remove-AdministrativeUnitMemberships
{
    Param
    (
        $grpMemberListFileName
    )

    Write-Host "WARNING: You are about to remove Administrative Unit memberships created from SDS. `nIf you want to skip removing any SG members, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all the SG memberships logged in $grpMemberListFileName (yes/no)?" -ForegroundColor White
    $choice = Read-Host
    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        Write-Progress -Activity $activityName -Status "Deleting Administrative Unit Memberships"
        $grpMemberList = import-csv $grpMemberListFileName
        $grpMemberCount = $grpMemberList.Length
        $index = 1
        Foreach ($grpm in $grpMemberList) 
        {
            Write-Output "[$index/$grpMemberCount] Removing SG Member id [$($grpm.SGMemberObjectId)] of `"$($grpm.SGDisplayName)`" [$($grpm.SGObjectId)] from directory"
            $removeUrl = 'https://graph.microsoft.com/beta/groups/' + $grpm.SGObjectId + '/members/' + $grpm.SGMemberObjectId +'/$ref'
            $graphRequest = invoke-graphrequest -Method DELETE -Uri $removeUrl
            $index++
        }
    }
}

Function Format-ResultsAndExport($logFilePath) {

    Initialize
    
    $allSchoolSGMemberships = Get-SecurityGroupMemberships $logFilePath

    #output to file
    if($skipToken -eq "."){
        write-output $allSchoolSGMemberships | Export-Csv -Path "$csvfilePath" -NoTypeInformation
    }
    else {
        write-output $allSchoolSGMemberships | Export-Csv -Path "$csvfilePath$($skiptoken.Length).csv" -NoTypeInformation
    }


    Out-File $logFilePath -Append -InputObject $global:nextLink
}

# Main

$activityName = "Cleaning up SDS Objects in Directory"

$logFilePath = "$OutFolder\SchoolSGMemberships.log"
$csvFilePath = "$OutFolder\SchoolSGMemberships.csv"

$activityName = "Cleaning up SDS Objects in Directory"

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


    # Get all Members of all SG's of Edu Object Type School
    Write-Progress -Activity $activityName -Status "Fetching School Security Group Memberships"
    Format-ResultsAndExport $logFilePath
    Write-Host "`nSchool Security Group Memberships logged to file $csvFilePath `n" -ForegroundColor Green
    

    # Remove School SG Memberships
    Remove-AdministrativeUnitMemberships $csvFilePath


Write-Output "`nDone.`n"

Write-Output "Please run 'disconnect-graph' if you are finished making changes.`n"