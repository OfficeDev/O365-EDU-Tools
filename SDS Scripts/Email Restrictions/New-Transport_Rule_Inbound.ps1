<#
Script Name:
New-Transport_Rule_Inbound.ps1

Synopsis:
This script is designed to create an inbound transport rule, to restrict all inbound email for a group or students from any sender outside of the O365 tenant.

Syntax Examples and Options:
.\New-Transport_Rule_Inbound.ps1 

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/14/2016 - First Draft

#>

New-TransportRule -Name "Inbound Student Restrictions" -Enabled $true -FromScope NotInOrganization AnyOfToCcHeaderMemberOf All_Students -RejectMessageReasonText "Students are not allowed to receive messages from senders outside of the school district."
