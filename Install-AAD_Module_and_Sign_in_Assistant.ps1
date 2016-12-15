<#
Disclaimer: 
This sample script is not supported under any Microsoft standard support program or service. The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages

Script Name:
Install-AAD_Module_and_Sign_in_Assistant.ps1

Synopsis:
This script is designed to download and Install the Azure AD Module for PowerShell and the Microsoft Online Services Sign-in Assistant. The download will place the install files into your c:\temp directory, and then run the install from this location. To confirm the install completed successfully, run the Connect-Azure_AD_and_Exchange_Online.ps1 from this script repository. This will establish your connection to Azure Ad and Exchange Online.

Syntax Examples:
.\Install-AAD_Module_and_Sign_in_Assistant.ps1

Written By: 
Bill Sluss

Change Log:
Version 1.0, 12/09/2016 - First Draft

#>


#Import AAD Module, and Download and Install if not present

Import-Module MSOnline -erroraction silentlycontinue

If (get-module msonline) {

write-host -foregroundcolor green "The Azure AD PowerShell Module is loaded"

}

else {

write-host -foregroundcolor red "The Azure AD PowerShell Module is not present. We will download and install the required components. This will take about 60 seconds to complete."

#Import BITS module
Import-Module BitsTransfer

#Download Online Services Sign-In Assistant (64 Bit) 
#Reference Link = http://technet.microsoft.com/en-us/library/jj151815.aspx
$job = Start-BitsTransfer -Source 'https://download.microsoft.com/download/5/0/1/5017D39B-8E29-48C8-91A8-8D0E4968E6D4/en/msoidcli_64.msi' -Destination c:\temp\msoidcli_64.msi -Asynchronous
Write-Host "Downloading Online Services Sign-In Assistant"
while( ($job.JobState.ToString() -eq 'Transferring') -or ($job.JobState.ToString() -eq 'Connecting') )
{
    Write-Host $job.JobState.ToString()
    $Pro = [Math]::Round( ($job.BytesTransferred/$job.BytesTotal),2)*100
    #Write-Host $Pro "%"

    Sleep 2
}
if ($job.InternalErrorCode -ne 0) {
    ("Error downloading Sign-In Assistant" -f $job.InternalErrorCode) | Out-File c:\temp\SignIn_Assistant_DownloadError.log}
else {
    Complete-BitsTransfer -BitsJob $job
    Write-Host -foregroundcolor green "The Online Services Sign-In Assistant Download Completed Successfully"}

#Install Online Services Sign-in Assistant 
Write-Host "Installing Microsoft Online Services Sign-In Assistant"
$msi = @("c:\temp\msoidcli_64.msi")
foreach($_ in $msi)
    {Start-Process -FilePath msiexec -ArgumentList /i, $_, /qn -Wait}
foreach($_ in $msi)
    {msiexec /i $_ /qn | out-null}
Write-Host -foregroundcolor green "The Online Services Sign-In Assistant Install Completed Successfully"

sleep 20

#Download Windows Azure AD Module (64 Bit) 
#Reference Link = http://technet.microsoft.com/en-us/library/jj151815.aspx
$job = Start-BitsTransfer -Source 'http://go.microsoft.com/fwlink/p/?linkid=236297' -Destination c:\temp\AdministrationConfig-en.msi -Asynchronous
Write-Host "Downloading the Azure Active Directory Module for windows PowerShell"
while( ($job.JobState.ToString() -eq 'Transferring') -or ($job.JobState.ToString() -eq 'Connecting') )
{
    Write-Host $job.JobState.ToString()
    $Pro = [Math]::Round( ($job.BytesTransferred/$job.BytesTotal),2)*100
    #Write-Host $Pro "%"

    Sleep 2
}
if ($job.InternalErrorCode -ne 0) {
    ("Error downloading AdministrationConfig-en.msi" -f $job.InternalErrorCode) | Out-File c:\temp\WindowsAzureADModuleDownloadError.log}
else {
    Complete-BitsTransfer -BitsJob $job
    Write-Host -foregroundcolor green "The Azure Active Directory Module for Windows PowerShell Download Completed Successfully"}


sleep 20

#Install Windows Azure AD Module for PowerShell 
Write-Host "Installing the Azure Active Directory Module for Windows PowerShell"
$msi = @("c:\temp\AdministrationConfig-en.msi")
foreach($_ in $msi)
    {Start-Process -FilePath msiexec -ArgumentList /i, $_, /qn -Wait}
foreach($_ in $msi)
    {msiexec /i $_ /qn | out-null}
Write-Host -foregroundcolor green "The Azure Active Directory Module for Windows PowerShell Install Completed Successfully"

sleep 20


Import-Module MSOnline
}


