<#
.Synopsis
This script is designed to get all users who have Intune for Education licenses currently, and removes them.

.Description
The script will interact with Microsoft online resources using the Graph module.  Once connected, the script will pull the users' license information. A folder will be created in the same directory as the script itself containing log file and a csv file with the data previously mentioned.  Once the data is pulled, you are prompted to confirm that you want to update users' licenses contained in the csv.

.Example
.\Remove-Intune_Licenses.ps1

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

    d. If you are returned to the PowerShell session without error, you are correctly set up

3.  Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication" isn't working.
#>

$outFolder = ".\RemoveIntuneLicenses"
$logFilePath = "$outFolder\removeIntuneLicenses.log"
$csvFilePath = "$outFolder\intuneUsers.csv"

function Get-IntuneUsers {

    # Removes csv file
    if ((Test-Path $csvFilePath))
    {
        Remove-Item $csvFilePath;
    }

    # Get all users
    Write-Progress -Activity "Reading AAD" -Status "Fetching users"
    $users = Get-MgUser -All | Select-Object id, userPrincipalName
    $intuneUsers = @() # Array of objects for user
    $userCnt = 0 # Counter for license retrieval progress

    Foreach ($user in $users) {
        # Check if user has Intune License
        $userLicenseSkuId = (Get-MgUserLicenseDetail -UserId $user.id | ? {$_.SkuPartNumber -match "INTUNE_EDU"}).skuId
        
        if ($userLicenseSkuId -eq $intuneSkuId) {
            # Create object required for export-csv and add to array
            $intuneUsers += [pscustomobject]@{"UserId"=$user.id;"UserPrincipalName"=$user.userPrincipalName}
        }
        $userCnt++
        Write-Progress -Activity "Retrieving user license info..." -Status "Progress ->" -PercentComplete ($userCnt/$users.count*100)
    }
    $intuneUsers | Export-Csv -Path "$csvfilePath" -Append -NoTypeInformation
}

function Remove-IntuneLicenses {

    $intuneUsers = Import-Csv $csvfilePath
    $userCnt = 0 # Counter for users

    # Remove the Intune License for any users that currently have it
    Foreach ($user in $intuneUsers) {
        Write-Output "[$(Get-Date -Format G)] Adding the Intune EDU license to  $($user.userPrincipalName) from school AUs." | Out-File $logFilePath -Append
        try {
            Set-MgUserLicense -UserId $user.userId -AddLicenses @{} -RemoveLicenses @($intuneSkuId) -ErrorAction Stop | Out-Null
        }
        catch {
            $errorMessage = $_.ToString()
            "[$(Get-Date -Format G)] Error removing the Intune EDU license from $($user.userPrincipalName)`n$errorMessage" | Tee-Object -FilePath $logFilePath -Append | Write-Host -ForegroundColor Red
        }
        $userCnt++
        Write-Progress -Activity "Removing the Intune EDU license from users" -Status "Progress ->" -PercentComplete ($userCnt/$intuneUsers.count*100)
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
    Get-Help -Name .\Remove-Intune_Licenses.ps1 -Full | Out-String | Write-Error
    throw
}

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0)
{
	mkdir $outFolder;
}

Connect-MgGraph -scopes Organization.Read.All, Directory.Read.All, Organization.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All

# Get the Intune sku and set a string variable
$intuneSkuId = (Get-MgSubscribedSku | ? {$_.SkuPartNumber -match "INTUNE_EDU"}).skuId

Write-Host "`nActivity logged to file $logFilePath `n" -ForegroundColor Green

Get-IntuneUsers

Write-Host "`nYou are about to remove Intune Licenses from users logged in $csvFilePath.`nIf you want to skip any users, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
Write-Host "Proceed with removing Intune Licenses for users logged in $csvFilePath (yes/no)?" -ForegroundColor Yellow
$choiceAddIntune = Read-Host

if ($choiceAddIntune -ieq "y" -or $choiceAddIntune -ieq "yes") {
    Remove-IntuneLicenses
}

Write-Output "`n`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"
