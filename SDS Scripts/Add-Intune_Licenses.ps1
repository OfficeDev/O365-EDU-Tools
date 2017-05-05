
<# 
Script Name: 
Add-Intune_Licenses.ps1 
  
Synopsis: 
This script is designed to get all users who don't have Intune for Education licenses currently, and adds them. No parameters are needed with this script, and you will see an output displayed on the screen for each user where the add is being attempted and subsequently processed. 
  
Syntax Examples and Options: 
.\Add-Intune_Licenses.ps1 
  
Written By:  
Bill Sluss 
  
Change Log: 
Version 1.0, 05/05/2017 - First Draft 
  
#> 

#Get the Intnue sku and set a string variable
$sku = (get-msolaccountsku | ? {$_.accountskuid -match "INTUNE_EDU"}).accountskuid
$sku2 = $sku.tostring()

#Get all users that have the INTUNE_EDU sku applied
$Users = Get-MsolUser -All | ? {$_.Licenses.AccountSkuId -notmatch "INTUNE_EDU"}

#Add the Intune License for any users that dont currently have it
Foreach ($User in $Users) {
$upn = $User.UserPrincipalName
Write-host -foregroundcolor green "Adding the Intune EDU license to $upn"
Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses $sku2
}

write-host -foregroundcolor green "script complete"