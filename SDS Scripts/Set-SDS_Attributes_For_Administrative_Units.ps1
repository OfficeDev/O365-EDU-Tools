<#
Script Name:

Synopsis:

Syntax Examples and Options:

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
    
    b. Execute: "Connect-MgGraph" to bring up a sign-in UI. 
    
    c. Sign in with any tenant administrator credentials.
    
    d. If you are returned to the PowerShell session without error, you are correctly set up

3.  Ensure that you have application setup correctly in Azure Active Directory with the following permission scopes:

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
    $pageCnt = 1 # Counts the number of pages of users retrieved
    $lastRefreshed = $null # Used for refreshing connection

    # Get all AU's of Edu Object Type School
    Write-Progress -Activity "Reading AAD" -Status "Fetching users"

    do {
        # Check if need to renew connection
        $currentDT = Get-Date
        if ($lastRefreshed -eq $null -or (New-TimeSpan -Start $currentDT -End $lastRefreshed).Minutes -gt 10) {
            Connect-Graph | Out-Null
            $lastRefreshed = Get-Date
        }

        $auUri = "$graphEndPoint/$graphVersion/directory/administrativeUnits?`$select=id,displayName"

        if ($skipToken -ne "." ) {
            $auUri = $skipToken
        }

        $auResponse = Invoke-Graphrequest -Uri $auUri -Method GET
        $aus = $auResponse.value
        
        $auCtr = 1 # Counter for AUs retrieved
        
        foreach ($au in $aus){
            $obj = [pscustomobject]@{"AUObjectId"=$au.Id;"AUDisplayName"=$au.DisplayName;}
            $auList += $obj
            $auCtr++
        }

        Write-Progress -Activity "Retrieving AUs..." -Status "Retrieved $auCtr AUs from $pageCnt pages"
        
        # Write nextLink to log if need to restart from previous page
        Write-Output "[$(Get-Date -Format G)] Retrieved $pageCnt AU pages. nextLink: $($graphResponse.'@odata.nextLink')" | Out-File $logFilePath -Append
        $pageCnt++

    } while ($auResponse.'@odata.nextLink')  

    $auList | Export-Csv $csvFilePath -Append -NotypeInformation

} 

function Set-SDS_Attributes_For_AUs {
    Param
    (
        $auListFileName
    ) 

    Write-Host "`nWARNING: You are about to modify existing administrative units with SDS school extension attributes. `nIf you want to skip modifying any administrative units, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with modifying all the administrative units logged in $auListFileName (yes/no)?" -ForegroundColor Yellow
    
    $choice = Read-Host
    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        $auList = Import-Csv $auListFileName | Sort-Object * -Unique # Import AUs retrieved and remove dupes if occured from skipToken retry.
        $auCount = (gc $auListFileName | measure-object).count - 1
        $auCtr = 1 # Counter for 

        Foreach ($au in $auList) 
        {
            Write-Output "[$(get-date -Format G)] [$auCtr/$auCount] Removing user $($au.AUObjectId)" | Out-File $logFilePath -Append
            
            $uri = "https://graph.microsoft.com/beta/administrativeUnits/$AUObjectId"
            $requestBody = '{
                "extension_fe2174665583431c953114ff7268b7b3_Education_AnchorId": "School_' + $AUObjectId + '",
                "extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource_SchoolId": "' + $ + '",
                "extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType": "' + $ + '",
                "extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource": "SIS"
            }'
        
            $result = Invoke-GraphRequest -Method Patch -Uri $uri -body $requestBody -ContentType "application/json" -SkipHttpErrorCheck

            Write-Progress -Activity "Removing users." -Status "Progress ->" -PercentComplete ($au/$auCount.count*100)
            $index++
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

try 
{
    Import-Module ExchangeOnlineManagement | Out-Null
}
catch
{
    Write-Error "Failed to load Exchange Online Management Module for creating Information Barriers"
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
Connect-Graph

Get-AdministrativeUnits
Set-SDS_Attributes_For_AUs $csvFilePath

Write-Output "`n`nDone.  Please run 'Disconnect-Graph' if you are finished.`n"