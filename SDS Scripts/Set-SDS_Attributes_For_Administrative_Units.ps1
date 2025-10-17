<#
Script Name:
Set-SDS_Attributes_For_Administrative_Units.ps1

Synopsis:
This script is designed to add the minimum number of SDS extension attributes to administrative units not created by SDS.  It will use the Graph to pull the administrative units and output them to a csv.  Afterwards, you are prompted to confirm that you want to modify the administrative units.  A folder will be created in the same directory as the script itself and contains a log file and the csv.  Nextlink in the log can be used for the skipToken script parameter to continue where the script left off in case it does not finish.  

Syntax Examples and Options:
.\Set-SDS_Attributes_For_Administrative_Units.ps1

#>

Param (
    [string] $skipToken = ".",
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\AdministrativeUnits",
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    [Parameter(Mandatory=$false)]
    [switch] $PPE = $false
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

$logFilePath = "$outFolder\AdministrativeUnits.log"
$csvFilePath = "$outFolder\AdministrativeUnits.csv"

function Get-PrerequisiteHelp
{
    Write-Output @"
========================
 Required Prerequisites
========================

1. Install Microsoft Graph Powershell Module with the command 'Install-Module Microsoft.Graph'

2. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "Connect-Graph" to bring up a sign-in UI. 
    
    c. Sign in with any tenant administrator credentials.
    
    d. If you are returned to the PowerShell session without error, you are correctly set up.

3.  Ensure that you have application setup correctly in Azure Active Directory with the following permission scopes: AdministrativeUnit.Read.All, Directory.Read.All, AdministrativeUnit.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All

4.  Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication" isn't working.

(END)
========================
"@
}

function Get-AdministrativeUnits {

    # Removes csv file unless link is provided to resume
    if ((Test-Path $csvFilePath) -and ($skipToken -eq "."))
    {
 	    Remove-Item $csvFilePath;
    }

    $auList = @() # Array of objects for AUs
    $pageCnt = 1 # Counts the number of pages of AUs retrieved
    $lastRefreshed = $null # Used for refreshing connection

    # Get all AU's of Edu Object Type School
    Write-Progress -Activity "Reading AAD" -Status "Fetching AU's"

    do {
        # Check if need to renew connection
        $currentDT = Get-Date
        if ($lastRefreshed -eq $null -or (New-TimeSpan -Start $currentDT -End $lastRefreshed).Minutes -gt 10) {
            Connect-Graph -scopes "AdministrativeUnit.Read.All, Directory.Read.All, AdministrativeUnit.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All" | Out-Null
            $lastRefreshed = Get-Date
        }

        $auUri = "$graphEndPoint/$graphVersion/directory/administrativeUnits?`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource"

        if ($skipToken -ne "." ) {
            $auUri = $skipToken
        }

        $auResponse = Invoke-Graphrequest -Uri $auUri -Method GET
        $aus = $auResponse.value
        
        $auCtr = 1 # Counter for AUs retrieved
        
        foreach ($au in $aus){
            if ( !($au.extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource) ) { # Filtering out AU already with SDS attribute
                $obj = [pscustomobject]@{"AUObjectId"=$au.Id;"AUDisplayName"=$au.DisplayName;}
                $auList += $obj
                $auCtr++
            }
        }

        Write-Progress -Activity "Retrieving AUs..." -Status "Retrieved $auCtr AUs from $pageCnt pages"
        
        # Write nextLink to log if need to restart from previous page
        Write-Output "[$(Get-Date -Format G)] Retrieved $pageCnt AU pages. nextLink: $($graphResponse.'@odata.nextLink')" | Out-File $logFilePath -Append
        $pageCnt++

    } while ($auResponse.'@odata.nextLink')  

    $auList | Export-Csv $csvFilePath -Append -NotypeInformation

} 

function Set-SDS_Attributes_For_AUs {

    Write-Host "`nWARNING: You are about to modify existing administrative units with SDS school extension attributes. `nIf you want to skip modifying any administrative units, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with modifying all the administrative units logged in $csvFilePath (yes/no)?" -ForegroundColor Yellow
    
    $choice = Read-Host
    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        $auList = Import-Csv $csvFilePath | Sort-Object * -Unique # Import AUs retrieved and remove dupes if occured from skipToken retry.
        $auCount = (gc $csvFilePath | measure-object).count - 1
        $auCtr = 1 # Counter for progress

        Foreach ($au in $auList) 
        {
            Write-Output "[$(get-date -Format G)] [$auCtr/$auCount] Removing user $($au.AUObjectId)" | Out-File $logFilePath -Append
            
            $uri = "$graphEndPoint/$graphVersion/administrativeUnits/" + $au.AUObjectId
            $requestBody = '{
                "extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType": "School",
                "extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource": "Manual"
            }'
        
            $result = Invoke-GraphRequest -Method Patch -Uri $uri -body $requestBody -ContentType "application/json" -SkipHttpErrorCheck

            Write-Progress -Activity "Adding SDS attributes to administrative units" -Status "Progress ->" -PercentComplete ($auCtr/$auCount.count*100)
        }
    }
}

# Main

$graphEndPoint = $GraphEndpointProd

if ($PPE)
{
    $graphEndPoint = $GraphEndpointPPE
}

try
{
    Import-Module Microsoft.Graph.Authentication | Out-Null
}
catch
{
    Write-Error "Failed to load Microsoft Graph PowerShell Module."
    Get-PrerequisiteHelp | Out-String | Write-Error
    throw
}

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0)
{
	mkdir $outFolder;
}

Write-Host "`nActivity logged to file $logFilePath `n" -ForegroundColor Green

# Connecting to resources
Connect-Graph -scopes "AdministrativeUnit.Read.All, Directory.Read.All, AdministrativeUnit.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All"

Get-AdministrativeUnits
Set-SDS_Attributes_For_AUs

Write-Output "`n`nDone.  Logs can be reviewed at $logFilePath`n"

Write-Output "Please run 'Disconnect-Graph' if you are finished making changes.`n"