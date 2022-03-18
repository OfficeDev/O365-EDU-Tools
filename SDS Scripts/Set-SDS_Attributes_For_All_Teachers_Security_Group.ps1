<#
Script Name:
Set-SDS_Attributes_For_All_Teachers_Security_Group.ps1

.Synopsis
This script is designed to add the AllTeachersSecurityGroup SDS extension attributes to a group not created by SDS.

.Description
This script will use Graph to check the group then update it with the SDS extension attribute for the 'All Teachers' security group.

.Example
.\Set-SDS_Attributes_For_AllTeachersSecurityGroup.ps1 -groupId <AAD guid for the group>

.Notes
This script is only supposed to be used for a group that contains all teachers.
#>

Param (
    [Parameter(Mandatory=$true)]
    [string] $groupId,
    [Parameter(Mandatory=$false)]
    [string] $graphVersion = "beta",
    [Parameter(Mandatory=$false)]
    [switch] $PPE = $false
)

$GraphEndpointProd = "https://graph.microsoft.com"
$GraphEndpointPPE = "https://graph.microsoft-ppe.com"

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

# Connecting to resources
Connect-Graph -scope "Group.ReadWrite.All" | Out-Null

#preparing uri string
$grpSelectClause = "?`$select=id,displayName,extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType"
$grpUri = "$graphEndPoint/$graphVersion/groups/$groupId/$grpSelectClause"

try {
    $graphResponse = Invoke-GraphRequest -Method GET -Uri $grpUri -ContentType "application/json"
    $grp = $graphResponse
}
catch{
    throw "Could not retrieve group."
}

if ( !($grp.extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType) ) { # Filtering out group already with SDS attribute
    $uri = "$graphEndPoint/$graphVersion/groups/" + $groupId
    $requestBody = '{
        "extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType": "AllTeachersSecurityGroup",
        "extension_fe2174665583431c953114ff7268b7b3_Education_SyncSource": "Manual"
    }'

    $result = Invoke-GraphRequest -Method Patch -Uri $uri -body $requestBody -ContentType "application/json" -SkipHttpErrorCheck
}
else {
    Write-Host "`nCannot update this group because it already has SDS attributes." -ForegroundColor Yellow
    $grp
}

Write-Output "`n`nDone.  Please run 'Disconnect-Graph' if you are finished.`n"
