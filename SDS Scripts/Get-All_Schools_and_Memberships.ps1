<#
Script Name:
Get-All_Schools_and_Memberships.ps1

Written By: 
Bill Sluss, and adapted by Prajitha Chalil Veedu

Change Log:
Version 1.0, 12/05/2016 - First Draft
Version 2.0, 3/23/2022 - Updated script to use Graph API instead of ADAL
#>

<#
.SYNOPSIS
    This script is designed to export all Schools and their respective members. The result of this script is a single CSV export, called Get-All_Schools_and_Memberships.csv. 
.EXAMPLE    
    .\Get-All_Schools_and_Memberships.ps1
#>

Param (
    [switch] $PPE = $false,
    [Parameter(Mandatory=$false)]
    [string] $skipToken= ".",
    [Parameter(Mandatory=$false)]
    [string] $OutFolder = ".",
    # Parameter to specify whether to download the script with common functions or not
    [switch] $skipDownloadCommonFunctions
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

if ($skipDownloadCommonFunctions -eq $false) {
    # Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose
        "Grabbed 'common.ps1' to the directory alongside the executing script"
        Write-Output "[$(get-date -Format G)] Grabbed 'common.ps1' to the directory alongside the executing script. common.ps1 script contains common functions, which can be used by other SDS scripts" | out-file $logFilePath -Append

    } 
    catch {
        throw "Unable to download common.ps1"
    }
}
    
#import file with common functions
. .\common.ps1 

function Get-PrerequisiteHelp
{
    Write-Output @"
========================
 Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'

2.  Make sure to download common.ps1 to the same folder of the script which has common functions needed.  https://github.com/OfficeDev/O365-EDU-Tools/blob/master/SDS%20Scripts/common.ps1

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "connect-graph -scopes AdministrativeUnit.ReadWrite.All, User.Read.All" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell sesion without error, you are correctly set up

5. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working

(END)
========================
"@
}

function Get-AdministrativeUnitMemberships($refreshToken, $graphscopes, $logFilePath) {

    #preparing uri string
    $auSelectClause = "`$select=id,displayName,description"
    $auMemberAllSelectClause = "`$select=id,displayName,mail,@data.type,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId"
    $auMemberStudentSelectClause = "`$select=id,displayName,mail,@data.type,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_StudentId"

    $initialSDSSchoolAUsUri = "$graphEndPoint/beta/directory/administrativeUnits?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'School'&$auSelectClause"
    
    #getting AUs for all schools
    $checkedSDSSchoolAUsUri = TokenSkipCheck $initialSDSSchoolAUsUri $logFilePath
    $allSchoolAUs = PageAll-GraphRequest $checkedSDSSchoolAUsUri $refreshToken 'GET' $graphscopes $logFilePath

    #write to school AU count to log
    write-output "[$(get-date -Format G)] Retrieve $($allSchoolAUs.Count) school AUs." | out-file $logFilePath -Append
    
    $schoolAUMemberships = @() #array of objects for memberships

    $choice = Write-Host "`nTarget both students and teachers in SDS school created AUs (yes/no)?.  Default: students only" -ForegroundColor White
    $choice = Read-Host
    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        $auMemberSelectClause = $auMemberAllSelectClause
    }
    else
    {
        $auMemberSelectClause = $auMemberStudentSelectClause
    }

    $i = 0 #counter for progress
    
    #looping through all school Aus
    foreach($au in $allSchoolAUs)
    {
        if ($au.id -ne $null)
        {
            #getting members of each school au
            $auMembershipUri = $graphEndPoint + '/beta/directory/administrativeUnits/' + $au.id + '/members'
            $checkedAUMembershipUri = TokenSkipCheck $auMembershipUri $logFilePath
            $schoolAUMembers = PageAll-GraphRequest $checkedAUMembershipUri $refreshToken 'GET' $graphscopes $logFilePath

            #getting info for each au member
            foreach ($auMember in $schoolAUMembers)
            {
                $auMemberType = $auMember.'@odata.type' #some members are users and some are groups
                
                if ($auMemberType -eq '#microsoft.graph.user')
                {
                    $userUri = $graphEndPoint + "/beta/users/" + $auMember.Id + "?$auMemberSelectClause"
                    $user = invoke-graphrequest -Method GET -Uri $userUri -ContentType "application/json"

                    #users created by sds have this extension
                    if ($user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId -ne $null)
                    {   
                        #checking if retuning students only
                        if(($choice -ieq "y" -or $choice -ieq "yes") -or ($user.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_StudentId -ne $null))
                        {
                            #create object required for export-csv and add to array
                            $obj = [pscustomobject]@{"DisplayName"=$au.displayName;"Description"=$au.description;"AUObjectID"=$au.id;"MemberEmailAddress"=$user.mail;"MemberObjectID"=$user.id;}
                            $schoolAUMemberships += $obj
                        }
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

Function Format-ResultsAndExport($graphscopes, $logFilePath) {

    $refreshToken = Initialize $graphscopes
    
    $allSchoolAUMemberships = Get-AdministrativeUnitMemberships $refreshToken $graphscopes $logFilePath

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
$graphEndPoint = $GraphEndpointProd

if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
}

$logFilePath = "$OutFolder\Get-All_Schools_and_Memberships.log"
$csvFilePath = "$OutFolder\Get-All_Schools_and_Memberships.csv"

#list used to request access to data
$graphscopes = "AdministrativeUnit.ReadWrite.All, User.Read.All"

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

Format-ResultsAndExport $graphscopes $logFilePath

Write-Output "`nDone.`n"

Write-Output "Please run 'disconnect-graph' if you are finished making changes.`n"