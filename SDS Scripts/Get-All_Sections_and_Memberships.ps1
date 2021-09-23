<#
Script Name:
Remove-All_Section_Memberships.ps1

Synopsis:
This script is designed to Remove all Section Memberships created by SDS from an O365 tenant. The script sets up the connection to Azure, and then confirm you want to run the script with a "y". Once the script completes, a file will be created in the same directory as the script itself. A folder called "True" will be created and contain the output.

Syntax Examples and Options:
.\Remove-All_Section_Memberships.ps1 -RemoveSectionGroupMemberships $true
.\Remove-All_Section_Memberships.ps1 -RemoveSectionGroups $true
.\Remove-All_Section_Memberships.ps1 -RemoveSchoolAUs $true
.\Remove-All_Section_Memberships.ps1 -RemoveSectionAUs $true

Written By: 
Micrsoft SDS Team, and adapted by Debashis Dwivedi

Change Log:
Version 1.0, 12/12/2016 - First Draft
Version 2.0, 09/22/2021

#>

Param (
    [switch] $PPE = $false,
    [Parameter(Mandatory=$false)]
    [switch] $RemoveSectionGroupMemberships = $false,
    [switch] $RemoveSectionGroups = $false,
    [switch] $RemoveSchoolAUs = $false,
    [switch] $RemoveSectionAUs = $false,    
    [Parameter(Mandatory=$false)]
    [string] $OutFolder = ".",
    [Parameter(Mandatory=$false)]
    [string] $downloadFcns = "y"
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

#checking parameter to download common.ps1 file for required common functions
if ($downloadFcns -ieq "y" -or $downloadFcns -ieq "yes"){
    # Downloading file with latest common functions
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OfficeDev/O365-EDU-Tools/master/SDS%20Scripts/common.ps1" -OutFile ".\common.ps1" -ErrorAction Stop -Verbose
        "Grabbed 'common.ps1' to currrent directory"
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
    
    b. Execute: "connect-graph -scopes GroupMember.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All" to bring up a sign in UI. 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell sesion without error, you are correctly set up

4. Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication -MinimumVersion 0.9.1" isn't working

(END)
========================
"@
}

function Get-AdministrativeUnits($eduObjectType, $refreshToken, $graphscopes, $logFilePath) {
    
    $adminstrativeUnitsUri = "$graphEndPoint/beta/directory/administrativeUnits?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"   
    $administrativeUnits = PageAll-GraphRequest $adminstrativeUnitsUri $refreshToken 'GET' $graphscopes $logFilePath
    Write-Output "[$(get-date -Format G)] Retrieve $($administrativeUnits.Count) groups." | out-file $logFilePath -Append

    $auList = @() #array of objects for AdminstrativeUnits
	$fileName = $eduObjectType + "-AUs.csv"
    $filePath = Join-Path $OutFolder $fileName

    foreach($au in $administrativeUnits)
    {
		if ($au.Id -ne $null) 
		{
			#create object required for export-csv and add to array
			$obj = [pscustomobject]@{"Id"=$au.Id;"DisplayName"=$au.DisplayName;"Source ID"=$au.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId}
			$auList += $obj
		}           
    }    
    
    Write-Output $auList | Export-Csv -Path "$filePath" -NoTypeInformation

    return $filePath
}

function Remove-AdministrativeUnits($auListFileName)
{
    Write-Host "WARNING: You are about to remove Administrative Units and its memberships created from SDS. `nIf you want to skip removing any AUs, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all the AUs logged in $auListFileName (yes/no)?" -ForegroundColor White
    $choice = Read-Host

    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        Write-Progress -Activity $activityName -Status "Deleting Administrative Units"
        $auList = import-csv $auListFileName
		$auCount = $auList.Length
        $index = 1
        Foreach ($au in $auList) 
        {
			Write-Output "[$(get-date -Format G)] [$index/$auCount] Removing AU `"$($au.DisplayName)`" [$($au.Id)] from directory" | out-file $logFilePath -Append			           
            $removeUrl = $graphEndPoint + '/beta/administrativeUnits/' + $au.Id
            PageAll-GraphRequest $removeUrl $refreshToken 'DELETE' $graphscopes $logFilePathno
            $index++
        }
    }
}

function Get-Groups($eduObjectType, $refreshToken, $graphscopes, $logFilePath)
{    
    $groupsUri = "$graphEndPoint/beta/groups?`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'%20and%20extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"
    
    $groups = PageAll-GraphRequest $groupsUri $refreshToken 'GET' $graphscopes $logFilePath
    Write-Output "[$(get-date -Format G)] Retrieve $($groups.Count) groups." | out-file $logFilePath -Append
    
    $groupList = @() #array of objects for groups 
	$fileName = $eduObjectType + "-Groups.csv"
    $filePath = Join-Path $OutFolder $fileName

    #looping through all groups
    foreach($grp in $groups)
    {
		if ($grp.Id -ne $null)
        {
			#create object required for export-csv and add to array
			$obj = [pscustomobject]@{"Id"=$grp.Id;"DisplayName"=$grp.DisplayName;"Mail"=$grp.Mail; "Source ID"=$grp.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId}
			$groupList += $obj
		}			
    }
    
    Write-Output $groupList | Export-Csv -Path "$filePath" -NoTypeInformation
    
    return $filePath
}

function Remove-Groups($groupListFileName)
{
    Write-Host "WARNING: You are about to remove Groups and its memberships created from SDS. `nIf you want to skip removing any Groups, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all the Groups logged in $groupListFileName (yes/no)?" -ForegroundColor White
    $choice = Read-Host

    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        Write-Progress -Activity $activityName -Status "Deleting Groups"
        $groupList = import-csv $groupListFileName
		$groupCount = $groupList.Length
        $index = 1
        Foreach ($group in $groupList) 
        {
			Write-Output "[$(get-date -Format G)] [$index/$groupCount] Removing Group `"$($group.DisplayName)`" [$($group.Id)] from directory" | out-file $logFilePath -Append          
            $removeUrl = $graphEndPoint + '/beta/groups/' + $group.Id
            PageAll-GraphRequest $removeUrl $refreshToken 'DELETE' $graphscopes $logFilePath
			$index++
        }
    }
}

function Remove-GroupMembers($groupListFileName)
{
    Write-Host "WARNING: You are about to remove Groups memberships created from SDS. `nIf you want to skip processing any Groups, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all Group Memberships logged in $groupListFileName (yes/no)?" -ForegroundColor White
    $choice = Read-Host

    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        Write-Progress -Activity $activityName -Status "Getting Group Memberships"
        $groupList = import-csv $groupListFileName
        $groupCount = $groupList.Length
        $index = 1
		$grpMemberSelectClause = "?`$select=id,email,displayName,@data.type,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource"

        Foreach ($group in $groupList) 
        {
			Write-Output "[$(get-date -Format G)] [$index/$groupCount] Processing Memberships for Group `"$($group.DisplayName)`" [$($group.Id)]`n" | out-file $logFilePath -Append			
			$groupMembersUri = $graphEndPoint + '/beta/groups/' + $group.Id + '/members' + $grpMemberSelectClause
            $groupMembers = PageAll-GraphRequest $groupMembersUri $refreshToken 'GET' $graphscopes $logFilePath
            $groupMembersCount = $groupMembers.Count
			Write-Output "[$(get-date -Format G)] Retrieve $($groupMembers.Count) groupMembers." | out-file $logFilePath -Append            
            Write-Progress -Activity $activityName -Status "Removing Group Memberships"
			$memberIndex = 1
            Foreach ($member in $groupMembers)
            {
                $grpMemberType = $member.'@odata.type' #some members are users and some are groups

                if (($member.Id -ne $null) -and ($grpMemberType -eq '#microsoft.graph.user'))
                {
				    Write-Output "[$(get-date -Format G)] [$memberIndex/$groupMembersCount] Removing User `"$($member.DisplayName)`" from Group `"$($group.DisplayName)`"" | out-file $logFilePath -Append                
                    $removeUrl = $graphEndPoint + '/beta/groups/' + $group.Id + '/members/' + $member.Id + '/$ref'
                    PageAll-GraphRequest $removeUrl $refreshToken 'DELETE' $graphscopes $logFilePath
				    $memberIndex++
                }
            }

            $index++
        }
    }
}

# Main function
$graphEndPoint = $GraphEndpointProd

if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
}

$logFilePath = "$OutFolder\SDSSectionMemberships.log"

$activityName = "Cleaning up SDS Objects in Directory"

#scopes used to request access to data
$graphscopes = "GroupMember.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All"

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
 
 $refreshToken = Initialize $graphscopes
 
 if ($RemoveSchoolAUs -eq $true)
{
    # Get all AUs of Edu Object Type School
    Write-Progress -Activity $activityName -Status "Fetching School Administrative Units"
	$OutputFileName = Get-AdministrativeUnits 'School' $refreshToken $graphscopes $logFilePath    
    Write-Host "`nSchool Administrative Units logged to file $OutputFileName `n" -ForegroundColor Green

    # Delete School AUs
    Remove-AdministrativeUnits $OutputFileName
}

if ($RemoveSectionAUs -eq $true)
{
    # Get all AUs of Edu Object Type Section
    Write-Progress -Activity $activityName -Status "Fetching Section Administrative Units"
    $OutputFileName = Get-AdministrativeUnits 'Section' $refreshToken $graphscopes $logFilePath	
    Write-Host "`nSection Administrative Units logged to file $OutputFileName `n" -ForegroundColor Green

    # Delete Section AUs
    Remove-AdministrativeUnits $OutputFileName
}

if ($RemoveSectionGroupMemberships -eq $true -or $RemoveSectionGroups -eq $true)
{
    # Get all Groups of Edu Object Type Section
    Write-Progress -Activity $activityName -Status "Fetching Section Groups"
    $OutputFileName = Get-Groups 'Section' $refreshToken $graphscopes $logFilePath	
    Write-Host "`nSection Groups logged to file $OutputFileName `n" -ForegroundColor Green
    
    if ($RemoveSectionGroupMemberships -eq $true)
    {
        Remove-GroupMembers $OutputFileName
    }

    # Currently hardcoded to "false" to avoid unintended consequences
    if ($RemoveSectionGroups -eq $true)
    {
         Remove-Groups $OutputFileName
    }
}

Write-Output "`nDone.`n"

Write-Output "Please run 'disconnect-graph' if you are finished making changes.`n"