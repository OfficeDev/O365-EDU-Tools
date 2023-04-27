<#
.SYNOPSIS
This script is designed block use of Azure Active Directory PowerShell for all users except those included in an input csv file.  

.PARAMETER csvFilePath
Location of the csv file with the UPNs of users to be excluded from being blocked from using the Azure Active Directory PowerShell.  The header should be userprincipalname.  See psadmins.csv in the current folder in the GitHub repo for an example.  
#>

Param (
    [Parameter(Mandatory=$true)]
    [string] $csvFilePath
)

# Connect to Azure AD and establish a session
$session = Connect-AzureAD

# Set the 'Azure Active Directory PowerShell' Graph App ID as a variable
$appId = "1b730954-1685-4b74-9bfd-dac224a7b894"

# Ensure the service principal is present in the tenant, and if not add it
$sp = Get-AzureADServicePrincipal -Filter "appId eq '$appId'"
if (-not $sp) {
    $sp = New-AzureADServicePrincipal -AppId $appId
}

# Require user assignment for the Graph app
Set-AzureADServicePrincipal -ObjectId $sp.ObjectId -AppRoleAssignmentRequired $true

# Assign the default permissions to all admins in the CSV file list
$admins = import-csv $csvFilePath
Foreach ($admin in $admins) {
    $user = Get-AzureADUser -objectId $admin.userprincipalname
    New-AzureADServiceAppRoleAssignment -ObjectId $sp.ObjectId -ResourceId $sp.ObjectId -Id ([Guid]::Empty.ToString()) -PrincipalId $user.ObjectId
}

Write-host "Script Complete. PowerShell is now restricted."
