<#
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

Script Name:
New-DDL_for_Students_by_Grade.ps1

Synopsis:
This script is designed to create a Dynamic Distribution Group for each grade, which includes all students in that grade. These DDL's may be added to students mailboxes who implement the acceptance permissions, to allow a subset of students to email each other. This script assumes the Department attribute for admins contains the string associated to their individual grade (students in 1st grade will have a 1, student in second grade will have a 2, etc.), and uses this attribute to populate and keep each of the grade based DDL's up to date.

Syntax Examples and Options:
.\New-DDL_for_Students_by_Grade.ps1 

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/14/2016 - First Draft

#>

New-DynamicDistributionGroup -Name Grade_1 -IncludedRecipients AllRecipients -ConditionalDepartment 1
New-DynamicDistributionGroup -Name Grade_2 -IncludedRecipients AllRecipients -ConditionalDepartment 2
New-DynamicDistributionGroup -Name Grade_3 -IncludedRecipients AllRecipients -ConditionalDepartment 3
New-DynamicDistributionGroup -Name Grade_4 -IncludedRecipients AllRecipients -ConditionalDepartment 4
New-DynamicDistributionGroup -Name Grade_5 -IncludedRecipients AllRecipients -ConditionalDepartment 5
New-DynamicDistributionGroup -Name Grade_6 -IncludedRecipients AllRecipients -ConditionalDepartment 6
New-DynamicDistributionGroup -Name Grade_7 -IncludedRecipients AllRecipients -ConditionalDepartment 7
New-DynamicDistributionGroup -Name Grade_8 -IncludedRecipients AllRecipients -ConditionalDepartment 8
New-DynamicDistributionGroup -Name Grade_9 -IncludedRecipients AllRecipients -ConditionalDepartment 9
New-DynamicDistributionGroup -Name Grade_10 -IncludedRecipients AllRecipients -ConditionalDepartment 10
New-DynamicDistributionGroup -Name Grade_11 -IncludedRecipients AllRecipients -ConditionalDepartment 11
New-DynamicDistributionGroup -Name Grade_12 -IncludedRecipients AllRecipients -ConditionalDepartment 12
New-DynamicDistributionGroup -Name Grade_K -IncludedRecipients AllRecipients -ConditionalDepartment k
