<#
.SYNOPSIS

Creates a csv with information barriers and organization segments for users in the tenant.

.DESCRIPTION

The script will connect to Exchange Online using Connect-IPPSSession and Connect-ExchangeOnline to get retrieve information barriers and corresponding organization segments for all users of the tenant.

.INPUTS

Folder location for csv output. $outFolder

.OUTPUTS

A folder location defined as an input will include a csv files of all outputs. 

.EXAMPLE

PS> .\Get-User_Information_Barrier_Segments.ps1

.NOTES

The sequence of loading both modules is significant. Load the IPPSSession before ExchangeOnline modules

========================
 Required Prerequisites
========================

1. Install current PowerShell version.

2. Install the Exchange Online Management Module with command 'Install-Module ExchangeOnlineManagement'

2. Check that you can connect to your tenant directory from the PowerShell module to make sure everything is set up correctly.

    a. Open a separate PowerShell session

    c. Type "Connect-IPPSSession"; "Connect-ExchangeOnline"

    d. Sign in with any tenant administrator credentials.

    d. If you are returned to the PowerShell session without error, you are correctly set up

3.  Retry this script.  If you still get an error about failing to load the Exchange Online Management module, troubleshoot why 'Install-Module ExchangeOnlineManagement' isn't working.
#>

Connect-IPPSSession
Connect-ExchangeOnline

$outFolder = "C:\temp\"
$csvFilePath = "$outFolder\UserInformationBarrierSegments.csv"

#Create the output array
$outputArray = @()

#Check to see if outFolder exists, and if not create it
if(!(Test-Path $outFolder)) {
    New-Item -ItemType Directory -Force -Path $outFolder
}

#Get all exchange recipients with mailboxes
$recipients = Get-Recipient -RecipientType UserMailbox -ResultSize Unlimited
$rCtr = 0

#Start foreach loop
foreach($recipient in $recipients) {

    #Set variables
    $dn = $recipient.DisplayName
    $smtp = $recipient.PrimarySMTPAddress
    $ibs = $recipient.InformationBarrierSegments
    $guid = $recipient.Guid
    $segmentNames = @()

    foreach($segment in $ibs){
        $segmentNames += (Get-OrganizationSegment | Where-Object{$_.ExoSegmentId -eq $segment}).Name
    }

    #Create the PS Object
    $userObj = New-Object PSObject

    #Add each member attribute to the person's PS Object
    $userObj | Add-Member NoteProperty -Name DisplayName -Value $dn
    $userObj | Add-Member NoteProperty -Name EmailAddress -Value $smtp
    $userObj | Add-Member NoteProperty -Name ObjectID -Value $guid
    $userObj | Add-Member NoteProperty -Name InformationBarriers -Value (Join-String -Separator ", " -InputObject $ibs)
    $userObj | Add-Member NoteProperty -Name IBNames -Value (Join-String -Separator ", "  -InputObject $segmentNames)

    #Add this persons PS Object to the output array
    $outputArray += $userObj
    $rCtr++
    Write-Progress -Activity "`nGetting information barrier segments for users" -Status "Progress ->" -PercentComplete ($rCtr/$recipients.count*100)
}

#Export the output array to a CSV file in local outFolder directory
$outputArray | Export-csv $csvFilePath -NoTypeInformation

Write-Host -ForegroundColor Green "`n`nDone.  Please run and 'Disconnect-ExchangeOnline' and disconnect from both sessions if you are finished`n"