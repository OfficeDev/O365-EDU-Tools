<#
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

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