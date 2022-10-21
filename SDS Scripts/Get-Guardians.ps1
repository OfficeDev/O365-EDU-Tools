<#
-----------------------------------------------------------------------
 <copyright file="Get-Guardians.ps1" company="Microsoft">
 Â© Microsoft. All rights reserved.
 </copyright>
-----------------------------------------------------------------------
.Synopsis
    Gets all guardians associated with a singe student synced from SDS.
.Description
    This script will query for a single SDS synced student and export the guardians associated with them to a CSV file.
.Parameter OutFolder
    The script will output log file here.
.Parameter clientId
    The application Id that has EduRoster.Read.All and EduRoster.ReadWrite.All permission
.Parameter tenantId
    The Id of the tenant.
.Parameter certificateThumbprint
    The certificate thumbprint for the application.
.Parameter studentAadObjectId
    The AAD object Id of the student for whom the guardians needs to be retrieved. 
.Example
    Get guardian for one student: .\Get-Guardians.ps1 -OutFolder . -clientId "743f3d66-95aa-41d9-237d-45e961251889" -clientSecret "8bK]-[p19402Ac;Y+7<b>5b" -tenantDomain "contoso.onmicrosoft.com" -tenantId 8a572b06-4f46-432f-9185-258f6a8d67e6 -certificateThumbprint <CertificateThumbprint> -studentAadObjectId "ab043123-00aa-60d9-2ab4-12e961702abc"
.Notes
========================
 Required Prerequisites
========================
1. App must be created in customer's Azure account with appropriate app permissions and scopes (EduRoster.Read.All,EduRoster.ReadWrite.All)
2. App must contain a certificate and clientSecret https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-configure-app-access-web-apis
3. Install Microsoft Graph Powershell Module with command 'Install-Module Microsoft.Graph'
4. Connect-MgGraph -ClientID 743f3d66-95aa-41d9-237d-45e961251889 -TenantId 8a572b06-4f46-432f-9185-258f6a8d67e6 -CertificateThumbprint <CertificateThumbprint>
5. Import-Module Microsoft.Graph.Education
6. Related Contacts must exist in the uploaded customer CSV files.
========================
#>

Param (
    [Parameter(Mandatory = $false)]
    [string] $OutFolder = ".",

    [Parameter(Mandatory = $true)]
    [string] $clientId,

    [Parameter(Mandatory = $true)]
    [string] $tenantId,

    [Parameter(Mandatory = $true)]
    [string] $certificateThumbprint,

    [Parameter(Mandatory = $true)]
    [string] $studentAadObjectId
)

Connect-MgGraph -ClientID $clientId -TenantId $tenantId -CertificateThumbprint $certificateThumbprint

function Get-GuardiansForUser($userId) {
    Write-Progress -Activity "Getting guardians for user $userId"

    $user = Invoke-graphrequest -method GET -uri "https://graph.microsoft.com/beta/education/users/$($userid)?`$select=relatedContacts,id,displayName"

    $allContacts = $user.relatedContacts

    $data = @()
    
    foreach($contact in $allContacts)
    {
        $data += [pscustomobject]@{
            "Mobile Phone" = $contact.mobilePhone
            "Relationship" = $contact.relationship
            "Email Address" = $contact.emailAddress
            "DisplayName" = $contact.displayName
            "Access Consent" = $contact.accessConsent
        }
    }

    #Create CSV file
    $fileName = $user.displayName + "-Guardians.csv"
    $filePath = Join-Path $outFolder $fileName
    Remove-Item -Path $filePath -Force -ErrorAction Ignore

    $cnt = ($data | Measure-Object).Count
    if ($cnt -gt 0)
    {
        Write-Host "Exporting $cnt Guardians ..."
        $data | Export-Csv $filePath -Force -NoTypeInformation
        Write-Host "`nGuardians exported to file $filePath `n" -ForegroundColor Green
        return $filePath
    }
    else
    {
        Write-Host "No Guardians found to export."
        return $null
    }
}

if ($studentAadObjectId -ne "") {
    $studentAadObjectIdArr = $studentAadObjectId.split(',')
    foreach($studentAadObjectId in $studentAadObjectIdArr) {
        Write-Host "Getting guardians for student object Id $studentAadObjectId"
        Get-GuardiansForUser -userId $studentAadObjectId
    }    
} 

Write-Output "Please run 'Disconnect-Graph' if you are finished.`n"