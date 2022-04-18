<#
.SYNOPSIS
This script will export all O365 Groups and their respective memberships. The result will be a CSV file, called Get-All_Sections_and_Memberships.csv. To run this script, you will first need to establish a PowerShell connection to Azure AD and Exchange Online.

.PARAMETER outFolder
Path where to put the csv output file.

.EXAMPLE
.\Get-All_Sections_and_Memberships.ps1

.NOTES
***This script may take a while.***

========================
 Required Prerequisites
========================

1. Install Exchange Online Management Module with command 'Install-Module ExchangeOnlineManagement'

2. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session
    
    b. Execute: "Connect-ExchangeOnline" to bring up a sign-in UI. 
    After you complete the login in the web browser, the session in the Powershell window is authenticated via the regular Azure AD authentication flow, and the Exchange Online cmdlets are imported after few seconds.
    
    c. If you are returned to the PowerShell session without error, you are correctly set up.
#>

Param (    
    [Parameter(Mandatory = $false)]
    [string] $outFolder = ".\SDS_Sections_Memberships"
)

function Get-SectionMemberships {
    #Build the Array
    $results = @()

    #Get all Administrative Units
    $groups = Get-UnifiedGroup -ResultSize Unlimited

    $counter = 0

    #Start Foreach Loop against every AU
    Foreach ($group in $groups) {

        #Set Variables for each Group
        $exchGuid = $group.ExchangeGuid
        $guid = $group.Guid
        $name = $group.Name
        $dn = $group.DisplayName
        $addr = $group.PrimarySmtpAddress
        $owner = Get-UnifiedGroupLinks –Identity $name -LinkType Owners

        #Progress Reporting
        Write-Host -ForegroundColor Green "Processing Group $dn"

        #Get Memberships for each Group
        $groupMember = Get-UnifiedGroupLinks $name -LinkType Members
        $total = $groupMember.Count
        $removeNull = $total - 1

        #Loop Through each member and enter each as a line into our export
        For ($i = 0; $i -le $removeNull; $i++) {
            $auObj = New-Object PSObject
            $auObj | Add-Member NoteProperty -Name MemberName -Value $groupMember[$i].Name
            $auObj | Add-Member NoteProperty -Name MemberDisplayName -Value $groupMember[$i].DisplayName
            $auObj | Add-Member NoteProperty -Name MemberSAMAccountName -Value $groupMember[$i].SAMAccountName
            $auObj | Add-Member NoteProperty -Name MemberPrimarySMTPAddress -Value $groupMember[$i].PrimarySMTPAddress
            $auObj | Add-Member NoteProperty -Name GroupDisplayName -Value $dn
            $auObj | Add-Member NoteProperty -Name GroupName -Value $name
            $auObj | Add-Member NoteProperty -Name GroupExchangeGuid -Value $exchGuid
            $auObj | Add-Member NoteProperty -Name GroupGuid -Value $guid
            $auObj | Add-Member NoteProperty -Name GroupOwner -Value $owner
            $auObj | Add-Member NoteProperty -Name GroupAddress -Value $addr
            $results += $auObj
        }

        $counter++
        Write-Progress -Activity "Retrieving section memberships" -Status "Progress ->" -PercentComplete ($counter/$groups.count*100)
    }

    return $results
}

# Create output folder if it does not exist
if ((Test-Path $outFolder) -eq 0) {
    mkdir $outFolder | Out-Null;
}

try {
    Import-Module ExchangeOnlineManagement | Out-Null
}
catch {
    Write-Error "Failed to load Exchange Online Management Module"
    Get-Help -Name .\Get-All_Sections_and_Memberships.ps1 -Full | Out-String | Write-Error
    throw
}

Connect-ExchangeOnline

$sectionMemberships = Get-SectionMemberships

#Export the Results
$sectionMemberships | Export-Csv "$outFolder\Get-All_Sections_and_Memberships.csv" -NoTypeInformation

#Script Complete
Write-Output "`n`nDone.  Please run 'Disconnect-ExchangeOnline' if you are finished`n"