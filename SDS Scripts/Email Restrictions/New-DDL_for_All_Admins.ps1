<#
Script Name:
New-DDL_for_All_Admins.ps1

Synopsis:
This script is designed to create a Dynamic Distribution Group which includes all admins in the org. This DDL may be added to students mailboxes who implement the acceptance permissions, to allow these admins to email each of the respective students. This script assumes the Department attribute for admins contains the string "admin", and uses this attribute to populate and keep the DDL up to date.

Syntax Examples and Options:
.\New-DDL_for_All_Admins.ps1 

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/14/2016 - First Draft

#>

New-DynamicDistributionGroup -Name All_Admins -IncludedRecipients AllRecipients -ConditionalDepartment Admin
