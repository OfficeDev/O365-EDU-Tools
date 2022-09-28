<#
.SYNOPSIS
This script is designed to export all Schools and their respective members. The result of this script is a single CSV export, called Get-All_Schools_and_Memberships.csv.

.PARAMETER skipToken
Used to start where the script left off fetching the users in case of interruption.  The value used is nextLink in the log file, otherwise use default value of "" to start from the beginning.

.PARAMETER outFolder
Path where to put the log and csv file with the fetched users.

.PARAMETER graphVersion
The version of the Graph API. 

.EXAMPLE    
.\Get-All_Schools_and_Memberships.ps1

.NOTES
***This script may take a while.***

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

(END)
========================
#>

Param (
    [switch] $PPE = $false,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\SDS_Schools_Memberships",
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    #Parameter to specify whether to download the script with common functions or not
    [switch] $skipDownloadCommonFunctions
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

$logFilePath = "$outFolder\Get-All_Schools_and_Memberships.log"
$csvFilePath = "$outFolder\Get-All_Schools_and_Memberships.csv"

#Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0)
{
    mkdir $outFolder | Out-Null;
}

if ($skipDownloadCommonFunctions -eq $false) {
    #Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose
        "Grabbed 'common.ps1' to the directory alongside the executing script"
        Write-Output "[$(get-date -Format G)] Grabbed 'common.ps1' to the directory alongside the executing script. common.ps1 script contains common functions, which can be used by other SDS scripts" | out-file $logFilePath -Append
    } 
    catch {
        throw "Unable to download common.ps1"
    }
}
    
#Import file with common functions
. .\common.ps1

function Get-AdministrativeUnitMemberships($refreshToken, $graphscopes, $logFilePath) {

    #Preparing uri string
    $auSelectClause = "`$select=id,displayName,description"
    $auMemberSelectClause = "`$select=id,displayName,mail,@data.type,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId"

    $initialSDSSchoolAUsUri = "$graphEndPoint/$graphVersion/directory/administrativeUnits?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'School'&$auSelectClause"
    
    #Getting AUs for all schools
    $checkedSDSSchoolAUsUri = TokenSkipCheck $initialSDSSchoolAUsUri $logFilePath
    $allSchoolAUs = PageAll-GraphRequest $checkedSDSSchoolAUsUri $refreshToken 'GET' $graphscopes $logFilePath

    #Write to school AU count to log
    Write-Output "[$(get-date -Format G)] Retrieve school AUs." | out-file $logFilePath -Append

    $schoolAUMemberships = @() #Array of objects for memberships

    $i = 0 #Counter for progress
    
    #Looping through all school Aus
    foreach($au in $allSchoolAUs)
    {
        if ($au.id -ne $null)
        {
            Write-Output "[$(get-date -Format G)] Getting members of School AU $($au.id)" | out-file $logFilePath -Append
            #Getting members of each school au
            $auMembershipUri = $graphEndPoint + '/' + $graphVersion + '/directory/administrativeUnits/' + $au.id + '/members'
            $checkedAUMembershipUri = TokenSkipCheck $auMembershipUri $logFilePath
            $schoolAUMembers = PageAll-GraphRequest $checkedAUMembershipUri $refreshToken 'GET' $graphscopes $logFilePath

            #Getting info for each au member
            foreach ($auMember in $schoolAUMembers)
            {
                $auMemberType = $auMember.'@odata.type' #Some members are users and some are groups
                
                if ($auMemberType -eq '#microsoft.graph.user')
                {
                    $userUri = $graphEndPoint + "/$graphVersion/users/" + $auMember.Id + "?$auMemberSelectClause"
                    $user = invoke-graphrequest -Method GET -Uri $userUri -ContentType "application/json"

                    #Users created by sds have this extension
                    if ($user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId -ne $null)
                    {                        
                        #Create object required for export-csv and add to array
                        $obj = [pscustomobject]@{"DisplayName"=$au.displayName;"Description"=$au.description;"AUObjectID"=$au.id;"MemberEmailAddress"=$user.mail;"MemberObjectID"=$user.id;}
                        $schoolAUMemberships += $obj
                    }
                }
            }
        }
        $i++
        Write-Progress -Activity "Retrieving school AU memberships" -Status "Progress ->" -PercentComplete ($i/$allSchoolAUs.count*100)
    }

    return $schoolAUMemberships
}

Function Format-ResultsAndExport($graphscopes, $logFilePath) {

    $refreshToken = Initialize $graphscopes
    
    $allSchoolAUMemberships = Get-AdministrativeUnitMemberships $refreshToken $graphscopes $logFilePath

    if($allSchoolAUMemberships.Count -gt 0) {
        #Output to file
        if($skipToken -eq ".") {
            Write-Output $allSchoolAUMemberships | Export-Csv -Path "$csvfilePath" -NoTypeInformation
        }
        else {
            Write-Output $allSchoolAUMemberships | Export-Csv -Path "$csvfilePath$($skiptoken.Length).csv" -NoTypeInformation
        }
    }
    else {
        Write-Output "[$(get-date -Format G)] There are no AU memberships available." | out-file $logFilePath -Append
    }
}

#Main
$graphEndPoint = $GraphEndpointProd

if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
}

#List used to request access to data
$graphscopes = "AdministrativeUnit.ReadWrite.All, User.Read.All"

try
{
    Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1 | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-Help -Name .\Get-All_Schools_and_Memberships.ps1 -Full | Out-String | Write-Error
    throw
}

Format-ResultsAndExport $graphscopes $logFilePath

Write-Output "`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"