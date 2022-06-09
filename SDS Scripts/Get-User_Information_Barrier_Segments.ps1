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

$outFolder = "C:\temp\"
$csvFilePath = "$outFolder\UserInformationBarrierSegments.csv"

#Create the output array
$outputArray = @()

#Check to see if outFolder exists, and if not create it
if(!(Test-Path $outFolder)) {
    New-Item -ItemType Directory -Force -Path $outFolder
}

#Remove temp csv file
if ((Test-Path $csvFilePath))
{
    Remove-Item $csvFilePath;
}

#Connection to IB info
Connect-IPPSSession

$orgSegments = Get-OrganizationSegment | Select-Object Name, Guid, ExoSegmentId

Disconnect-ExchangeOnline -Confirm:$false | Out-Null

#Connection to fetch user info
Connect-ExchangeOnline 

#Note: Even though Connect-IPPSSession shares the Get-User cmdlet, InformationBarrierSegments is returned when using Connect-ExchangeOnline
$users = Get-User -ResultSize Unlimited -Filter 'InformationBarrierSegments -ne $null' | Select-Object DisplayName, UserPrincipalName, InformationBarrierSegments, Guid 

$userCtr = 0

#Start foreach loop
foreach($user in $users) {

    #Set variables
    $dn = $user.DisplayName
    $upn = $user.UserPrincipalName
    $ibs = $user.InformationBarrierSegments
    $guid = $user.Guid
    $segmentNames = @()

    foreach($segment in $ibs){
        $segmentNames += ($orgSegments | Where-Object{$_.ExoSegmentId -eq $segment}).Name
    }

    #Create the PS Object
    $userObj = New-Object PSObject

    #Add each member attribute to the person's PS Object
    $userObj | Add-Member NoteProperty -Name DisplayName -Value $dn
    $userObj | Add-Member NoteProperty -Name UPN -Value $upn
    $userObj | Add-Member NoteProperty -Name ObjectID -Value $guid
    $userObj | Add-Member NoteProperty -Name InformationBarriers -Value (Join-String -Separator ", " -InputObject $ibs)
    $userObj | Add-Member NoteProperty -Name IBNames -Value (Join-String -Separator ", "  -InputObject $segmentNames)

    #Add this persons PS Object to the output array
    $outputArray += $userObj
    $userCtr++

    #Export the output array to a CSV file in local outFolder directory
    $outputArray | Export-csv $csvFilePath -NoTypeInformation -Append
    Write-Progress -Activity "`nGetting information barrier segments for users" -Status "Progress ->" -PercentComplete ($userCtr/$users.count*100)
}


Write-Host -ForegroundColor Green "`n`nDone.  Please run and 'Disconnect-ExchangeOnline' and disconnect from both sessions if you are finished`n"