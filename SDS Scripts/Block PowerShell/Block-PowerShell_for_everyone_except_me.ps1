<#
.SYNOPSIS
This script is designed block use of Azure Active Directory PowerShell for all users except who is running the script.  
#>

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

# Assign the default app role (0-Guid) to the current user
$me = Get-AzureADUser -ObjectId $session.Account.Id
New-AzureADServiceAppRoleAssignment -ObjectId $sp.ObjectId -ResourceId $sp.ObjectId -Id ([Guid]::Empty.ToString()) -PrincipalId $me.ObjectId

Write-host "Script Complete. PowerShell is now restricted."
