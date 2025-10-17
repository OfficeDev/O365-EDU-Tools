<#
.SYNOPSIS
This script is designed block use of Microsoft Graph PowerShell for all users except those included in an input csv file.  

.PARAMETER csvFilePath
Location of the csv file with the UPNs of users to be excluded from being blocked from using the Microsoft Graph PowerShell.  The header should be userprincipalname.  See psadmins.csv in the current folder in the GitHub repo for an example.  
#>

Param (
    [Parameter(Mandatory=$true)]
    [string] $csvFilePath
)

# Connect to Azure AD and establish a session
$session = Connect-AzureAD

# Set the 'Microsoft Graph PowerShell' Graph App ID as a variable
$appId = "14d82eec-204b-4c2f-b7e8-296a70dab67e"

# Ensure the service principal is present in the tenant, and if not add it
$sp = Get-AzureADServicePrincipal -Filter "appId eq '$appId'"
if (-not $sp) {
    $sp = New-AzureADServicePrincipal -AppId $appId
}

# Require user assignment for the Graph app
Set-AzureADServicePrincipal -ObjectId $sp.ObjectId -AppRoleAssignmentRequired $true

# Assign the default permissions to all admins in the CSV file list
$admins = Import-Csv $csvFilePath
Foreach ($admin in $admins) {
    $user = Get-AzureADUser -objectId $admin.userprincipalname
    New-AzureADServiceAppRoleAssignment -ObjectId $sp.ObjectId -ResourceId $sp.ObjectId -Id ([Guid]::Empty.ToString()) -PrincipalId $user.ObjectId
}

Write-host "Script Complete. PowerShell is now restricted."
