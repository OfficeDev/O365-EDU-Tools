<# 
Script Name: 
Remove-Intune_Licenses.ps1 
  
Synopsis: 
This script is designed to get all users who have Intune for Education licenses currently, and remove them. No parameters are needed with this script, and you will see an output displayed on the screen for each user where the removal is being attempted and subsequently processed. 
  
Syntax Examples and Options: 
.\Remove-Intune_Licenses.ps1 
  
Written By:  
Bill Sluss 
  
Change Log: 
Version 1.0, 05/05/2017 - First Draft 
  
#> 

#Get the Intnue Sku and set a variable
$sku = (get-msolaccountsku | ? {$_.accountskuid -match "INTUNE_EDU"}).accountskuid
$sku2 = $sku.tostring()

#Get all users that have the INTUNE_EDU sku applied
$Users = Get-MsolUser -All | ? {$_.Licenses.AccountSkuId -match  "INTUNE_EDU"}

#Remove all Intune licenses from users that have them currently
Foreach ($User in $Users) {
$upn = $User.UserPrincipalName
Write-host -foregroundcolor green "Removing the Intune EDU license from $upn"
Set-MsolUserLicense -UserPrincipalName $upn -RemoveLicenses $sku2
}

write-host -foregroundcolor green "script complete"
