<#
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

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