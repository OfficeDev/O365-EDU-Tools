<#
.Synopsis
This script is designed to get all users who do not have Intune for Education licenses currently, and adds them.

.Description
The script will interact with Microsoft online resources using the Graph module.  Once connected, the script will pull the users' license information. A folder will be created in the same directory as the script itself containing log file and a csv file with the data previously mentioned.  Once the data is pulled, you are prompted to confirm that you want to update users' licenses contained in the csv.

.Example
.\Add-Intune_Licenses.ps1

.Notes
***This script may take a while.***

========================
 Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module with the command 'Install-Module Microsoft.Graph'

2. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session

    b. Execute: "Connect-MgGraph -scopes Organization.Read.All, Directory.Read.All, Organization.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All" to bring up a sign-in UI. 

    c. Sign in with any tenant administrator credentials.

    d. If you are returned to the PowerShell session without error, you are correctly set up.

3.  Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication" isn't working.

4.  Please visit the following link if a message is received that the license cannot be assigned.
    https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-groups-resolve-problems
#>

$outFolder = ".\AddIntuneLicenses"
$logFilePath = "$outFolder\addIntuneLicenses.log"
$csvFilePath = "$outFolder\nonIntuneUsers.csv"

function Get-NonIntuneUsers {

    # Removes csv file
    if ((Test-Path $csvFilePath))
    {
        Remove-Item $csvFilePath;
    }

    # Get all users
    Write-Progress -Activity "Reading AAD" -Status "Fetching users"
    $users = Get-MgUser -All | Select-Object id, userPrincipalName
    $nonIntuneUsers = @() # Array of objects for user
    $userCnt = 0 # Counter for license retrieval progress

    Foreach ($user in $users) {
        # Check if user is without Intune License
        $userLicenseSkus = (Get-MgUserLicenseDetail -UserId $user.id).SkuPartNumber
        $userLicenseSkuList = $userLicenseSkus -join ","

        if ($userLicenseSkuList -notlike "*INTUNE_EDU*") {
            # Create object required for export-csv and add to array
            $nonIntuneUsers += [pscustomobject]@{"UserId"=$user.id;"UserPrincipalName"=$user.userPrincipalName;"LicenseSkus"=$userLicenseSkuList}
        }
        $userCnt++
        Write-Progress -Activity "Retrieving user license info..." -Status "Progress ->" -PercentComplete ($userCnt/$users.count*100)
    }
    $nonIntuneUsers | Export-Csv -Path "$csvfilePath" -Append -NoTypeInformation
}

function Add-IntuneLicenses {

    $nonIntuneUsers = Import-Csv $csvfilePath
    $userCnt = 0 # Counter for users

    if ($intuneLicenseFree -gt $nonIntuneUsers.count) {
        # Add the Intune License for any users that do not currently have it
        Foreach ($user in $nonIntuneUsers) {
            Write-Output "[$(Get-Date -Format G)] Adding the Intune EDU license to $($user.userPrincipalName) from school AUs." | Out-File $logFilePath -Append
            try {
                Set-MgUserLicense -UserId $user.userId -AddLicenses @{SkuId = $intuneSkuId} -RemoveLicenses @() -ErrorAction Stop | Out-Null
            }
            catch {
                $errorMessage = $_.ToString()
                "[$(Get-Date -Format G)] Error adding the Intune EDU license to $($user.userPrincipalName)`n$errorMessage" | Tee-Object -FilePath $logFilePath -Append | Write-Host -ForegroundColor Red
            }
            $userCnt++
            Write-Progress -Activity "Adding the Intune EDU license to users" -Status "Progress ->" -PercentComplete ($userCnt/$nonIntuneUsers.count*100)
        }
    }
    else {
        Write-Error "`nCannot apply licenses.  Total: $intuneLicenseTotal `t Consumed: $intuneLicenseConsumed"
    }
}

# Main

try
{
    Import-Module Microsoft.Graph.Authentication | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-Help -Name .\Add-Intune_Licenses.ps1 -Full | Out-String | Write-Error
    throw
}

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0)
{
	mkdir $outFolder;
}

Connect-MgGraph -scopes Organization.Read.All, Directory.Read.All, Organization.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All

# Get the Intune sku and counts
$intuneLicense = Get-MgSubscribedSku | ? {$_.SkuPartNumber -match "INTUNE_EDU"}
$intuneSkuId = $intuneLicense.SkuId
$intuneLicenseTotal = $intuneLicense.PrepaidUnits.Enabled
$intuneLicenseConsumed = $intuneLicense.ConsumedUnits
$intuneLicenseFree = $intuneLicenseTotal - $intuneLicenseConsumed

Write-Host "`nActivity logged to file $logFilePath `n" -ForegroundColor Green

Get-NonIntuneUsers

Write-Host "`nYou are about to add Intune Licenses to users logged in $csvFilePath.`nIf you want to skip any users, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
Write-Host "Proceed with adding Intune Licenses for users logged in $csvFilePath (yes/no)?" -ForegroundColor Yellow
$choiceAddIntune = Read-Host

if ($choiceAddIntune -ieq "y" -or $choiceAddIntune -ieq "yes") {
    Add-IntuneLicenses
}

Write-Output "`n`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"