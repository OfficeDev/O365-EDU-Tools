<#
Script Name:
Set-SDS_Attributes_For_Security_Groups.ps1

.Synopsis
This script is designed to add the minimum SDS extension attributes to security groups not created by SDS.

.Description
This script will use the Graph to pull the security groups and output them to a csv.  Afterwards, you are prompted to confirm that you want to modify the security groups.  A folder will be created in the same directory as the script itself and contains a log file and the csv.  The rows of the csv file can be reduced to only modify specific security groups.  Nextlink in the log can be used for the skipToken script parameter to continue where the script left off in case it does not finish.  

.Example
.\Set-SDS_Attributes_For_Security_Groups.ps1
#>

Param (
    [string] $skipToken = ".",
    [Parameter(Mandatory=$false)]
    [string] $outFolder = ".\SecurityGroups",
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    [Parameter(Mandatory=$false)]
    [switch] $PPE = $false
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

$logFilePath = "$outFolder\SecurityGroups.log"
$csvFilePath = "$outFolder\SecurityGroups.csv"

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

3.  Ensure that you have access to the following permission scopes: Group.ReadWrite.All

4.  Retry this script.  If you still get an error about failing to load the Microsoft Graph module, troubleshoot why "Import-Module Microsoft.Graph.Authentication" isn't working.

(END)
========================
"@
}

function Get-SecurityGroups {

    # Removes csv file unless link is provided to resume
    if ((Test-Path $csvFilePath) -and ($skipToken -eq "."))
    {
 	    Remove-Item $csvFilePath;
    }

 
    $pageCnt = 1 # Counts the number of pages of SGs retrieved
    $lastRefreshed = $null # Used for refreshing connection

    # Get all SG's
    Write-Progress -Activity "Reading AAD" -Status "Fetching security groups"

    do {
        $grpList = @() # Array of objects for SGs
        
        # Check if need to renew connection
        $currentDT = Get-Date
        if ($lastRefreshed -eq $null -or (New-TimeSpan -Start $currentDT -End $lastRefreshed).Minutes -gt 10) {
            Connect-Graph -scope "Group.ReadWrite.All" | Out-Null
            $lastRefreshed = Get-Date
        }

        #preparing uri string
        $grpSelectClause = "`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"
        $grpUri = "$graphEndPoint/$graphVersion/groups?`$filter=securityEnabled%20eq%20true&$grpSelectClause"

        if ($skipToken -ne "." ) {
            $grpUri = $skipToken
        }

        $grpResponse = Invoke-Graphrequest -Uri $grpUri -Method GET
        $grps = $grpResponse.value
        
        $grpCtr = 1 # Counter for security groups retrieved
        
        foreach ($grp in $grps){
            if ( !($grp.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType) ) { # Filtering out security groups already with SDS attribute
                $grpList += [pscustomobject]@{"GroupObjectId"=$grp.Id;"GroupDisplayName"=$grp.DisplayName}
                $grpCtr++
            }
        }

        Write-Progress -Activity "Retrieving security groups..." -Status "Retrieved $grpCtr security groups from $pageCnt pages"
        
        # Write nextLink to log if need to restart from previous page
        Write-Output "[$(Get-Date -Format G)] Retrieved $pageCnt security group pages. nextLink: $($grpResponse.'@odata.nextLink')" | Out-File $logFilePath -Append
        $pageCnt++

    } while ($grpResponse.'@odata.nextLink')  

    $grpList | Export-Csv $csvFilePath -Append -NotypeInformation

} 

function Set-SDS_Attributes_For_SGs {

    Write-Host "`nWARNING: You are about to modify existing security groups with SDS school extension attributes. `nIf you want to skip modifying any security groups, edit the file now and remove the corresponding lines before proceeding. `n" -ForegroundColor Yellow
    Write-Host "Proceed with modifying all the security groups logged in $csvFilePath (yes/no)?" -ForegroundColor Yellow
    
    $choice = Read-Host
    if ($choice -ieq "y" -or $choice -ieq "yes")
    {
        $grpList = Import-Csv $csvFilePath | Sort-Object * -Unique # Import SGs retrieved and remove dupes if occurred from skipToken retry.
        $grpCount = (gc $csvFilePath | measure-object).count - 1
        $grpCtr = 1 # Counter for progress

        Foreach ($grp in $grpList) 
        {
            Write-Output "[$(get-date -Format G)] [$grpCtr/$grpCount] Removing user $($grp.GroupObjectId)" | Out-File $logFilePath -Append
            
            $uri = "$graphEndPoint/$graphVersion/groups/" + $grp.GroupObjectId
            $requestBody = '{
                "extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType": ""
            }'
        
            $result = Invoke-GraphRequest -Method Patch -Uri $uri -body $requestBody -ContentType "application/json" -SkipHttpErrorCheck

            Write-Progress -Activity "Adding SDS attributes to security groups" -Status "Progress ->" -PercentComplete ($grpCtr/$grpCount.count*100)
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
Connect-Graph -scope "Group.ReadWrite.All" | Out-Null

Get-SecurityGroups
Set-SDS_Attributes_For_SGs

Write-Output "`n`nDone.  Please run 'Disconnect-Graph' if you are finished.`n"
