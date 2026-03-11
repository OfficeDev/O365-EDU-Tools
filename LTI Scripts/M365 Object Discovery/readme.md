## Find M365 objects created by Microsoft LTI tools
This script will find all of the Groups, Sites, Drives, and Drive Items (folders and files) created by the classic Microsoft OneDrive LTI and/or Microsoft 365 LTI tools supporting your LMS courses.

To identify groups created via Microsoft LTI tools, we will look for M365 groups with specific metatdata written in the title/description, including the issuerName tag matching the LMS (when available).  

The script produces a CSV format file that contains details of the folders and files connected to either the classic Microsoft OneDrive LTI or Microsoft 365 LTI links in the LMS. The script curronly only reads data - however, it could extented to tale actions on groups, Sites, Drives or Files (ex: Archive the Group, Delete the Site or File, or move file(s) selectivley) - Please reference [Microsoft Graph documentation](https://learn.microsoft.com/en-us/graph/) for how to take additional actions on objects returned in this script.  

Features:
- If you have multiple LMSs, you can choose to search for M365 objects created by any LMS, or by a specific LMS (when available - see note below)
- If you have both the classic OneDrive LTI and Microsoft 365 LTI, you can choose to search for M365 objects created by one or both of the Microsoft LTI tools

>[!NOTE]
>In the classic OneDrive LTI, we only recognized Canvas, Blackboard and Schoology as unique Issuer LMSs ... other LMSs will be labeled as 'Generic" (Other). 

**How to run the script in your M365 tenant**:
This script requires Microsoft Graph App-only scopes in order to read all of the Groups, Sites, Drives, and DriveItems in your M365 Tenant. You will need to create an app registration and provide Admin Consent (as a Global Administrator) to allow the app to use these scopes.

The following steps must be completed by an M365/Entra Global Administrator.

**Finding your Entra tenant ID**
1) Browse to https://entra.microsoft.com/ using an acount that has Global Administrator role
2) Click Overview on the left side menu
3) Copy the Tenant ID value displayed - you will need to provide this as an input to run the script

**Creating the App registration:**
1) Log into the Microsoft Entra admin center at https://entra.microsoft.com/ using an account that has Global Administrator role
2) Click App registrations on the left side menu
3) Click the + New registration button in the header toolbar
4) Choose a name for your application like “Microsoft LTI Object Discovery Script”
5) For Supported Account Types, choose the “Single tenant only – *“ option that references your primary tenant domain
6) Click the Register button at the bottom of the page to save your new app registration
7) On the App registration Overview page, cop the Application (client) ID value  - you will need to provide this as an input to run the script

**Adding permissions and providing consent to the app to call Graph APIs:**
1) From the left side menu of your new app registration, choose API permissions
2) Choose + Add permission from the header toolbar
3) From the left side menu of your new app registration, choose API permissions
4) Choose + Add permission button in the header toolbar
5) From the Request API permissions pane on the right, click the Microsoft Graph tile at the top
6) Select Application permissions.  Search for and select the following permissions:

        Group.Read.All
        Member.Read.Hidden
        Sites.Read.All
        Files.Read.All
        Team.ReadBasic.All
        User.Read.All
   
8) After selecting the permissions, click the Add permission button
9) Choose the “Grant admin consent for …”  in the header toolbar, and click Yes in the confirmation popup

**Creating a secret for the app to use to authenticate and obtain priviledeges:**
1) From the left side menu of the app registration, choose Certificates & secrets
2) Click the + New Client Secret button in the header toolbar
3) In the Add a client secret right side panel, enter a description like "OneDriveLTIDiscoverySecret" and set an expiration date (you will need to create a new secret after this date and update the value in your app to continue to access the APIs)
4) Clck Add to create secret
5) Copy the Value from the new Client secret and save it (securely) - you will need to provide this as an input to run the script

**Executing the PowerShell Script**
```
Get-MicrosoftLTIObjects.ps1 -TenantId "your-domain.edu" -AppId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -ClientSecret "your-secret" -LMS "Canvas"
```
