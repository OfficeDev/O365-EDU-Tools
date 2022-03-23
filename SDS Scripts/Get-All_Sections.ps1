<#
.SYNOPSIS
This script is designed to get all SDS sections, and export the default Azure AD attributes to a CSV files called Get-All_Sections.csv, into the c:\temp directory. No other object types are exported with this script.

.EXAMPLE
.\Get-All_Sections.ps1

.NOTES
========================
 Required Prerequisites
========================

1. Install AzureAD Powershell Module with the command 'Install-Module AzureAD' (Recommend Windows PowerShell 5.x Module to be used for Azure AD powershell operations)

2. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "Connect-AzureAD to bring up a sign-in UI.
    
    c. Sign in with any tenant administrator credentials
    
    d. If you are returned to the PowerShell session without error, you are correctly set up.

3. Retry this script.  If you still get an error about failing to load the AzureAD module, troubleshoot why "Import-Module AzureAD" isn't working.
#>

Param(
	[string] $outFolder = ".\SDSSectionsExport"
)

try 
{
    Import-Module AzureAD | Out-Null
}
catch
{
    Write-Error "Failed to load AzureAD"
    Get-Help -Name .\Get-All_Sections.ps1 -Full | Out-String | Write-Error
    throw
}

Connect-AzureAD | Out-Null

$fileName = "Get-All_Sections.csv"
$csvFilePath = Join-Path $outFolder $fileName

#Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0)
{
	mkdir $outFolder | Out-Null;
}

Remove-Item -Path $csvFilePath -Force -ErrorAction Ignore

$output = @()

Write-Progress -Activity "Reading AAD" -Status "Fetching SDS section groups"

$groups = Get-AzureADGroup -All:$true | Select-Object -Property DisplayName, Mail, ObjectId, ProvisioningErrors | Where-Object {$_.Mail -like "Section_*"}

$grpCtr = 0

Foreach ($group in $groups) {

	#Grabbing error collection and joining into single column
	$grpErrs = $group | Select-Object -ExpandProperty ProvisioningErrors
	$grpErrJoin = $grpErrs -join ","
	
	#Create the PS Object
    $groupObj = New-Object PSObject

	#Add Members for Group Attributes
    $groupObj | Add-Member NoteProperty -Name DisplayName -Value $group.DisplayName
    $groupObj | Add-Member NoteProperty -Name EmailAddress -Value $group.Mail
	$groupObj | Add-Member NoteProperty -Name ObjectID -Value $group.ObjectId
	$groupObj | Add-Member NoteProperty -Name Errors -Value $grpErrJoin

	#Add All Member Attributes to PS Object
	$output += $groupObj

	$grpCtr++
	Write-Progress -Activity "`nReading SDS section groups properties.." -Status "Progress ->" -PercentComplete ($grpCtr/$groups.count*100)
}

#Export the output array to CSV
$output | Export-Csv $csvFilePath -NoTypeInformation

Disconnect-AzureAD

Write-host -ForegroundColor Green "Exported data to $csvFilePath.  `nScript Complete."
