<#
Script Name:
New-Transport_Rule_Outbound.ps1

Synopsis:
This script is designed to create an outbound transport rule, to restrict a set of students ability to send email outside of their respective O365 tenant.

Syntax Examples and Options:
.\New-Transport_Rule_Outbound.ps1 

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/14/2016 - First Draft

#>

New-TransportRule -Name "Outbount Student Restrictions" -Enabled $true -FromMemberOF All_Students -SentToScope NotInOrganization -RejectMessageReasonText "Students are not allowed to send messages to recipients outside of the organization."
