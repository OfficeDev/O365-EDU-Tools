#Connect to Azure AD and establish a session
$session = Connect-AzureAD

#set the ADIbizaUX App ID as a variable
$appId = "74658136-14ec-4630-ad9b-26e160ff0fc6"

#Ensure the service principal is present in the tenant, and if not add it
$sp = Get-AzureADServicePrincipal -Filter "appId eq '$appId'"
if (-not $sp) {
    $sp = New-AzureADServicePrincipal -AppId $appId
}

#Require an App Role Assignment for the Service Principal
Set-AzureADServicePrincipal -ObjectId $sp.ObjectId -AppRoleAssignmentRequired $true

# Assign the app role to the current user
$me = Get-AzureADUser -ObjectId $session.Account.Id
New-AzureADServiceAppRoleAssignment -ObjectId $sp.ObjectId -ResourceId $sp.ObjectId -Id ([Guid]::Empty.ToString()) -PrincipalId $me.ObjectId

Write-host "Script Complete. Azure AD Portal is now restricted."