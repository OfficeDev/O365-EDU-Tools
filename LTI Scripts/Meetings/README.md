# Find Microsoft 365 LTI Meetings

[`Get-LTIMeetings.ps1`](./Get-LTIMeetings.ps1) finds Outlook calendar events created through Microsoft 365 LTI for one LTI context ID and exports the results to CSV.

The script uses Microsoft Graph app-only authentication. It can scan:

- One mailbox specified by user principal name (UPN).
- Members and owners of Microsoft 365 groups tagged with the LTI context ID.
- All licensed users in the tenant.

The script only reads Microsoft Graph data. It does not modify users, groups, calendars, or meetings.

## How Meeting Discovery Works

Microsoft 365 LTI stamps calendar events with this single-value extended property:

```text
String {00020329-0000-0000-C000-000000000046} Name OfficeLtiMeetingsContextId
```

The property value is the LTI context ID. `Get-LTIMeetings.ps1` requires `-LTIContextId` and searches for an exact value match. It searches one context ID per run.

By default, the script keeps only events where the scanned mailbox is the organizer. This avoids counting attendee calendar copies as separate created meetings.

## Prerequisites

- PowerShell 7 or later. Check with `pwsh --version`.
- A Microsoft 365 tenant with Microsoft 365 LTI meetings.
- A Microsoft Entra account that can create an app registration.
- An administrator who can grant tenant-wide admin consent for Microsoft Graph application permissions.
- The LTI context ID to search for.

The script calls Microsoft Graph REST endpoints directly. No Microsoft Graph PowerShell modules are required.

## 1. Create the Microsoft Entra App

These steps should be completed in the tenant that contains the mailboxes to scan.

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com/).
2. Go to **Identity** > **Applications** > **App registrations**.
3. Select **New registration**.
4. Enter a descriptive name such as `Microsoft 365 LTI Meeting Discovery`.
5. For **Supported account types**, select **Accounts in this organizational directory only (Single tenant)**.
6. Leave **Redirect URI** empty.
7. Select **Register**.
8. On the app's **Overview** page, record:
   - **Application (client) ID**. Use this as `-AppId`.
   - **Directory (tenant) ID**. Use this as `-TenantId`.

## 2. Add Microsoft Graph Permissions

In the app registration, go to **API permissions** > **Add a permission** > **Microsoft Graph** > **Application permissions**.

Add permissions according to the scan modes you will use:

| Permission | Required for | Why it is needed |
| --- | --- | --- |
| `Calendars.Read` | Every mode | Reads events and the LTI extended property from target mailboxes. |
| `User.Read.All` | Tenant-wide scan | Enumerates users and reads `assignedLicenses` so the script can select licensed users. |
| `GroupMember.Read.All` | `-ScanGroupMembers` | Searches basic group properties and reads group members and owners. |

For an app that must support every mode, add all three permissions. Select **Application permissions**, not **Delegated permissions**.

After adding the permissions:

1. Select **Grant admin consent for _your tenant_**.
2. Confirm the prompt.
3. Verify that each permission shows **Granted for _your tenant_**.

Application permissions run without a signed-in user and require administrator consent. `Calendars.Read` can read calendars in all mailboxes by default. If access must be limited, work with an Exchange Online administrator to configure [Role Based Access Control for Applications](https://learn.microsoft.com/exchange/permissions-exo/application-rbac). Avoid leaving an overlapping tenant-wide Entra permission because Entra grants and Exchange application RBAC grants are additive.

## 3. Create a Client Secret

1. In the app registration, go to **Certificates & secrets** > **Client secrets**.
2. Select **New client secret**.
3. Enter a description and choose the shortest practical expiration period.
4. Select **Add**.
5. Immediately copy the secret's **Value**. Do not copy the Secret ID. The value is shown only once.
6. Store the value in an approved secret manager and track its expiration date.

Client secrets are convenient for local execution but are less secure than certificates or federated credentials. Do not save the secret in this repository, a script, a CSV file, or shell history. For production automation, use a certificate or federated credential and update the script's authentication method.

## 4. Open PowerShell and Prompt for the Secret

From the workspace root, prompt for the secret and convert it to the plain-text string expected by the script:

```powershell
$secret = Read-Host "Client secret" -AsSecureString | ConvertFrom-SecureString -AsPlainText
```

The value is held in the current PowerShell process and is not written into command history. Close the terminal when finished to discard the variable.

## 5. Run the Script

`-UserUpn` and `-ScanGroupMembers` are mutually exclusive. If neither is supplied, the script scans all licensed users.

### Scan One Mailbox

This is the narrowest and fastest mode. It requires `Calendars.Read`.

```powershell
./scripts/Get-LTIMeetings.ps1 -TenantId "TENANT_ID" -AppId "APP_ID" -Secret $secret -LTIContextId "CONTEXT_ID" -UserUpn "teacher@contoso.com"
```

### Scan Members and Owners of Matching Groups

The script searches for groups whose description contains `contextId: CONTEXT_ID`, verifies the context ID in the returned descriptions, deduplicates user members and owners, and scans their mailboxes. This mode requires `Calendars.Read` and `GroupMember.Read.All`.

```powershell
./scripts/Get-LTIMeetings.ps1 -TenantId "TENANT_ID" -AppId "APP_ID" -Secret $secret -LTIContextId "CONTEXT_ID" -ScanGroupMembers
```

### Scan All Licensed Users

This mode enumerates all users, keeps accounts with at least one assigned license, and scans each mailbox. It requires `Calendars.Read` and `User.Read.All` and can take significantly longer in a large tenant.

```powershell
./scripts/Get-LTIMeetings.ps1 -TenantId "TENANT_ID" -AppId "APP_ID" -Secret $secret -LTIContextId "CONTEXT_ID"
```

### Include Attendee Calendar Copies

The default is `-OrganizerOnly:$true`. Set it to false to include meetings where the scanned mailbox is an attendee rather than the organizer.

```powershell
./scripts/Get-LTIMeetings.ps1 -TenantId "TENANT_ID" -AppId "APP_ID" -Secret $secret -LTIContextId "CONTEXT_ID" -UserUpn "teacher@contoso.com" -OrganizerOnly:$false
```

### Choose the Output File

Use `-CsvPath` to override the timestamped default output path.

```powershell
./scripts/Get-LTIMeetings.ps1 -TenantId "TENANT_ID" -AppId "APP_ID" -Secret $secret -LTIContextId "CONTEXT_ID" -UserUpn "teacher@contoso.com" -CsvPath "C:\temp\LTI-meetings.csv"
```

## Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| `TenantId` | Yes | Microsoft Entra directory tenant ID or verified tenant domain. |
| `AppId` | Yes | Application (client) ID of the app registration. |
| `Secret` | Yes | Client secret value. Use the secret value, not its ID. |
| `LTIContextId` | Yes | Exact LTI context ID to find. |
| `UserUpn` | No | Scans one mailbox. Cannot be combined with `ScanGroupMembers`. |
| `ScanGroupMembers` | No | Scans unique user members and owners of groups tagged with the context ID. Cannot be combined with `UserUpn`. |
| `OrganizerOnly` | No | Defaults to `$true`; use `$false` to include attendee copies. |
| `CsvPath` | No | Full output CSV path. Defaults to `scripts/LTI_Meetings_yyyyMMdd_HHmmss.csv`. |

## CSV Output

When meetings are found, the CSV contains:

| Column | Description |
| --- | --- |
| `Mailbox` | UPN or object ID of the mailbox scanned. |
| `Subject` | Meeting subject. |
| `StartDateTime` | Event start date and time returned by Microsoft Graph. |
| `EndDateTime` | Event end date and time returned by Microsoft Graph. |
| `Organizer` | Organizer email address. |
| `IsOnlineMeeting` | Whether Microsoft Graph identifies the event as an online meeting. |
| `LTIContextId` | Context ID supplied to the script. |
| `EventId` | Microsoft Graph event ID. |

If no matching meetings are found, the script prints `No LTI meetings found.` and does not create an empty CSV.

## Troubleshooting

### Authentication Fails

- Confirm that `TenantId`, `AppId`, and the client secret **Value** belong to the same app registration and tenant.
- Check whether the secret expired.
- Create a replacement secret if its value was not copied when it was created.

### Access Is Denied or Mailboxes Are Skipped

- Confirm that the required permissions were added as **Application permissions**.
- Confirm that admin consent shows as granted.
- Check any Exchange Online application RBAC scope that may exclude the mailbox.
- Confirm that the target user has an Exchange Online mailbox.

### No Meetings Are Found

- Confirm the exact `LTIContextId`; the script searches one exact context value per run.
- Try `-OrganizerOnly:$false` to determine whether the mailbox only has an attendee copy.
- For `-ScanGroupMembers`, verify that the group description contains `contextId: CONTEXT_ID`.
- Confirm that the event uses the current `OfficeLtiMeetingsContextId` property. Classic OneDrive LTI events stamped only with the legacy `ContextId` property are not returned by this script.

### Both Mailbox Selectors Were Supplied

`-UserUpn` and `-ScanGroupMembers` select different scan modes and cannot be used together. Remove one of them.

## Security and Cleanup

- Grant only the permissions needed for the scan modes you use.
- Remove unused permissions and credentials after discovery work is complete.
- Rotate secrets before expiration and immediately after suspected exposure.
- Treat the CSV as potentially sensitive because it contains mailbox addresses, meeting subjects, times, and event IDs.
- Do not commit secrets or generated CSV output to source control.

## References

- [Identify Microsoft 365 LTI meetings](../IdentifyingMicrosoft365LTIMeetings.md)
- [Microsoft Graph: List events](https://learn.microsoft.com/graph/api/user-list-events)
- [Microsoft Graph: List users](https://learn.microsoft.com/graph/api/user-list)
- [Microsoft Graph: List group members](https://learn.microsoft.com/graph/api/group-list-members)
- [Microsoft Graph: List group owners](https://learn.microsoft.com/graph/api/group-list-owners)
- [Register an app for app-only Microsoft Graph access](https://learn.microsoft.com/graph/tutorials/dotnet-app-only#register-application-for-app-only-authentication)
- [Register an application with the Microsoft identity platform](https://learn.microsoft.com/graph/auth-register-app-v2)
- [Exchange Online RBAC for Applications](https://learn.microsoft.com/exchange/permissions-exo/application-rbac)
- [OfficeDev O365-EDU-Tools object discovery guide](https://github.com/OfficeDev/O365-EDU-Tools/blob/master/LTI%20Scripts/M365%20Object%20Discovery/readme.md)
