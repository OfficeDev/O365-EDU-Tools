<#
Script Name:
Remove-All_Section_Memberships.ps1

Synopsis:
This script is designed to Remove all Section Memberships created by SDS from an O365 tenant. You will be prompted twice to enter credentials, and once the script completes, the output will be in the same directory as the script itself. A folder called “true” will be created and contain the output.

Syntax Examples and Options:
.\Remove-All_Section_Memberships.ps1 -RemoveSectionGroupMemberships $true

Written By: 
Micrsoft SDS Team, and adapted by Bill Sluss

Change Log:
Version 1.0, 12/12/2016 - First Draft

#>


Param (
    #[switch] $RemoveSchoolAUs = $false,
    [switch] $RemoveSectionGroupMemberships = $false,
    #[switch] $RemoveSectionGroups = $false,
    #[switch] $RemoveSchoolAUMemberships = $false,
    [string] $OutFolder = ".",
    [switch] $PPE = $false
)

$RemoveSectionGroups = $false

$GraphEndpointProd = "https://graph.windows.net"
$AuthEndpointProd = "https://login.windows.net"

$GraphEndpointPPE = "https://graph.ppe.windows.net"
$AuthEndpointPPE = "https://login.windows-ppe.net"

$NugetClientLatest = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

function Get-PrerequisiteHelp
{
    Write-Output @"
========================
 Required Prerequisites
========================

1. Install Microsoft Online Services Sign-In Assistant v7.0 from http://www.microsoft.com/en-us/download/details.aspx?id=39267

2. Install the AAD PowerShell Module from http://msdn.microsoft.com/en-us/library/azure/jj151815.aspx#bkmk_installmodule

3. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "Connect-MsolService" to bring up a sign in UI 
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell sesion without error, you are correctly set up

5. Retry this script.  If you still get an error about failing to load the MSOnline module, troubleshoot why "Import-Module MSOnline" isn't working

(END)
========================
"@
}

. .\CommonFunctions.ps1

function Get-AdministrativeUnits
{
    Param
    (
        $eduObjectType
    )

    $fileName = $eduObjectType + "-AUs-" + $authToken.TenantId +".csv"
	$filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore
    
    $firstPage = $true
    Do
    {
        if ($firstPage)
        {
            $uri = $graphEndPoint + "/" + $authToken.TenantId + "/administrativeUnits?api-version=beta&`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"
            "ObjectId, DisplayName" | Out-File $filePath -Append
            $firstPage = $false
        }
        else
        {
            $uri = $graphEndPoint + "/" + $authToken.TenantId + "/" + $responseObject.odatanextLink + "&api-version=beta"
        }
        # Write-Host "GET: $uri"

        $response = Send-WebRequest "Get" $uri
        $responseString = $response.Content.Replace("odata.", "odata")
        $responseObject = $responseString | ConvertFrom-Json
        foreach ($au in $responseObject.value)
        {
            $au.ObjectId + ", " + $au.DisplayName | Out-File $filePath -Append
        }
    }
    While ($responseObject.odatanextLink -ne $null)

    return $filePath
}

function Remove-AdministrativeUnits
{
    Param
    (
        $auListFileName
    )

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
            Write-Output "[$index/$auCount] Removing AU `"$($au.DisplayName)`" [$($au.ObjectId)] from directory"
            Remove-MsolAdministrativeUnit -ObjectId $au.ObjectId -Force
            $index++
        }
    }
}

function Get-Groups
{
    Param
    (
        $eduObjectType
    )

    $fileName = $eduObjectType + "-Groups-" + $authToken.TenantId +".csv"
	$filePath = Join-Path $OutFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore
    
    $firstPage = $true
    Do
    {
        if ($firstPage)
        {
            $uri = $graphEndPoint + "/" + $authToken.TenantId + "/groups?api-version=1.6&`$filter=extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource%20eq%20'SIS'%20and%20extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType%20eq%20'$eduObjectType'"
            "ObjectId, DisplayName, Mail, Source ID" | Out-File $filePath -Append
            $firstPage = $false
        }
        else
        {
            $uri = $graphEndPoint + "/" + $authToken.TenantId + "/" + $responseObject.odatanextLink + "&api-version=1.6"
        }
        # Write-Host "GET: $uri"

        $response = Send-WebRequest "Get" $uri
        $responseString = $response.Content.Replace("odata.", "odata")
        $responseObject = $responseString | ConvertFrom-Json
        foreach ($group in $responseObject.value)
        {
            $group.ObjectId + ", " + $group.DisplayName + ", " + $group.Mail + ", " + $group.extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId | Out-File $filePath -Append
        }
    }
    While ($responseObject.odatanextLink -ne $null)

    return $filePath
}

function Remove-GroupMembers
{
    Param
    (
        $groupListFileName
    )

    Write-Host "WARNING: You are about to remove Groups memberships created from SDS. `nIf you want to skip processing any Groups, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all Group Memberships logged in $groupListFileName (yes/no)?" -ForegroundColor White
    
    $choice = Read-Host
    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        $fileName = "GroupsMembers-" + $authToken.TenantId +".txt"
	    $filePath = Join-Path $OutFolder $fileName
        Remove-Item -Path $filePath -Force -ErrorAction Ignore

        Write-Progress -Activity $activityName -Status "Getting Group Memberships"
        $groupList = import-csv $groupListFileName
        $groupCount = $groupList.Length
        $index = 1
        Foreach ($group in $groupList) 
        {
            Write-Host "`n[$index/$groupCount] Processing Memberships for Group `"$($group.DisplayName)`" [$($group.ObjectId)]`n" -ForegroundColor White
            "`nGroup: $group `n" >>$filePath
            $groupMembers = Get-MsolGroupMember -GroupObjectId $group.ObjectId -All
            $groupMembers | select ObjectId, EmailAddress, DisplayName >>$filePath
            Write-Progress -Activity $activityName -Status "Removing Group Memberships"

            Foreach ($member in $groupMembers)
            {
                Write-Host "Removing User `"$($member.DisplayName)`" from Group `"$($group.DisplayName)`"" -ForegroundColor Gray
                $removeUrl = $graphEndPoint + "/" + $authToken.TenantId + "/groups/" + $group.ObjectId + '/$links/members/' + $member.ObjectId + "?api-version=1.6"
                # Write-Host "DELETE: $removeUrl"

                $response = Send-WebRequest "Delete" $removeUrl
            }

            $index++
        }
    }
}

function Remove-Groups
{
    Param
    (
        $groupListFileName
    )

    Write-Host "WARNING: You are about to remove Groups and its memberships created from SDS. `nIf you want to skip removing any Groups, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with deleting all the Groups logged in $groupListFileName (yes/no)?" -ForegroundColor White
    $choice = Read-Host
    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        Write-Progress -Activity $activityName -Status "Deleting Groups"
        $groupList = import-csv $groupListFileName
        Foreach ($group in $groupList) 
        {
            Write-Output "Removing Group `"$($group.DisplayName)`" [$($group.ObjectId)] from directory"
            Remove-MsolGroup -ObjectId $group.ObjectId -Force
        }
    }
}


# Main
$graphEndPoint = $GraphEndpointProd
$authEndPoint = $AuthEndpointProd
if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
    $authEndPoint = $AuthEndpointPPE
}

$activityName = "Cleaning up SDS Objects in Directory"

try
{
    Import-Module MSOnline | Out-Null
}
catch
{
    Write-Error "Failed to load MSOnline PowerShell Module."
    Get-PrerequisiteHelp | Out-String | Write-Error
    throw
}

# Connect to the tenant
Write-Progress -Activity $activityName -Status "Connecting to tenant"
Connect-MsolService -ErrorAction Stop

$adalLoaded = Load-ActiveDirectoryAuthenticationLibrary
if ($adalLoaded)
{
    $authToken = Get-AuthenticationResult
}
else
{
    Write-Error "Could not load dependent libraries required by the script."
    Get-PrerequisiteHelp | Out-String | Write-Error
    Exit
}

Write-Progress -Activity $activityName -Status "Connected. Discovering tenant information"
$tenantInfo = Get-MsolCompanyInformation
$tenantId =  $tenantInfo.ObjectId
$tenantDisplayName = $tenantInfo.DisplayName

# Create output folder if it does not exist
if ((Test-Path $OutFolder) -eq 0)
{
	mkdir $OutFolder;
}

if ($RemoveSchoolAUs -eq $true)
{
    # Get all AUs of Edu Object Type School
    Write-Progress -Activity $activityName -Status "Fetching School Administrative Units"
    $OutputFileName = Get-AdministrativeUnits "School"
    Write-Host "`nSchool Administrative Units logged to file $OutputFileName `n" -ForegroundColor Green

    # Delete School AUs
    Remove-AdministrativeUnits $OutputFileName
}

if ($RemoveSectionAUs -eq $true)
{
    # Get all AUs of Edu Object Type Section
    Write-Progress -Activity $activityName -Status "Fetching Section Administrative Units"
    $OutputFileName = Get-AdministrativeUnits "Section"
    Write-Host "`nSection Administrative Units logged to file $OutputFileName `n" -ForegroundColor Green

    # Delete Section AUs
    Remove-AdministrativeUnits $OutputFileName
}

if ($RemoveSectionGroupMemberships -eq $true -or $RemoveSectionGroups -eq $true)
{
    # Get all Groups of Edu Object Type Section
    Write-Progress -Activity $activityName -Status "Fetching Section Groups"
    $OutputFileName = Get-Groups "Section"
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
