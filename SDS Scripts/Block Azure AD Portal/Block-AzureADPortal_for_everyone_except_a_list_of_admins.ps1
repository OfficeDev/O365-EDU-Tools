#Connect to Azure AD and establish a session
$session = Connect-AzureAD

#set the ADIbizaUX App ID as a variable
$appId = "74658136-14ec-4630-ad9b-26e160ff0fc6"

#Ensure the service principal is present in the tenant, and if not add it
$sp = Get-AzureADServicePrincipal -Filter "appId eq '$appId'"
if (-not $sp) {
    $sp = New-AzureADServicePrincipal -AppId $appId
}

#Require user assignment for the PowerShell app
Set-AzureADServicePrincipal -ObjectId $sp.ObjectId -AppRoleAssignmentRequired $true

# Assign the default app role to each of the users in the CSV
$admins = import-csv c:\temp\IntuneforEducationAdmins.csv
Foreach ($admin in $admins) {
$user = Get-AzureADUser -objectId $admin.userprincipalname
New-AzureADServiceAppRoleAssignment -ObjectId $sp.ObjectId -ResourceId $sp.ObjectId -Id ([Guid]::Empty.ToString()) -PrincipalId $user.ObjectId
}


Write-host "Script Complete. Azure AD portal is now restricted."