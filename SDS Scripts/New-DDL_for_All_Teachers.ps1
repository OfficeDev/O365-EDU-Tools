<#
Script Name:
New-DDL_for_All_Teachers.ps1

Synopsis:
This script is designed to create a Dynamic Distribution Group which includes all students in the org. This DDL may be added to students mailboxes who implement the acceptance permissions, to allow all students to email each other. This script assumes the Department attribute for students contains the string "Student", and uses this attribute to populate and keep the DDL up to date.

Syntax Examples and Options:
.\New-DDL_for_All_Teachers.ps1 

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/14/2016 - First Draft

#>

New-DynamicDistributionGroup -Name All_Teachers -IncludedRecipients AllRecipients -ConditionalDepartment Teacher
