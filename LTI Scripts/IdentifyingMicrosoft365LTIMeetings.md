# Identifying Microsoft 365 LTI Meetings via Graph API

Every meeting created by the **Microsoft 365 LTI** is an Outlook calendar event stamped with a custom extended property. Its value is the **LTI context id** (the class identifier), which is what you filter on.

**Extended property identifier:**

```
String {00020329-0000-0000-C000-000000000046} Name OfficeLtiMeetingsContextId
```

---

## Find All LTI Meetings in a Mailbox

Use this request with delegated authentication to retrieve events from the signed-in user's default calendar and expand only the LTI extended property:

```http
GET https://graph.microsoft.com/v1.0/me/events
  ?$select=id,subject,start,end,organizer,type,seriesMasterId
  &$expand=singleValueExtendedProperties($filter=id eq 'String {00020329-0000-0000-C000-000000000046} Name OfficeLtiMeetingsContextId')
```

To query another user's mailbox with application permissions, replace `/me/events` with:

```http
GET https://graph.microsoft.com/v1.0/users/{user-id-or-upn}/events
  ?$select=id,subject,start,end,organizer,type,seriesMasterId
  &$expand=singleValueExtendedProperties($filter=id eq 'String {00020329-0000-0000-C000-000000000046} Name OfficeLtiMeetingsContextId')
```

Filter the response client-side. Keep an event when `singleValueExtendedProperties` contains an item whose `id` is the identifier above. The item's `value` is the LTI context id. A matching event has this shape:

```json
{
  "subject": "Biology class meeting",
  "singleValueExtendedProperties": [
    {
      "id": "String {00020329-0000-0000-C000-000000000046} Name OfficeLtiMeetingsContextId",
      "value": "the-lti-context-id"
    }
  ]
}
```

Follow every `@odata.nextLink` in the response until it is no longer returned. Each next-link URL is already encoded; send it unchanged rather than rebuilding its query parameters.

---

## PowerShell Discovery Script

Use [`Get-LTIMeetings.ps1`](./scripts/Get-LTIMeetings.ps1) to find meetings for one exact LTI context ID. It requires PowerShell 7 or later, uses Microsoft Graph REST directly, and does not require Microsoft Graph PowerShell modules.

Prompt for the client secret so it is not stored in shell history:

```powershell
$secret = Read-Host "Client secret" -AsSecureString | ConvertFrom-SecureString -AsPlainText
```

Scan one mailbox:

```powershell
./scripts/Get-LTIMeetings.ps1 -TenantId "TENANT_ID" -AppId "APP_ID" -Secret $secret -LTIContextId "CONTEXT_ID" -UserUpn "teacher@contoso.com"
```

Scan the unique user members and owners of Microsoft 365 groups whose description is tagged with the context ID:

```powershell
./scripts/Get-LTIMeetings.ps1 -TenantId "TENANT_ID" -AppId "APP_ID" -Secret $secret -LTIContextId "CONTEXT_ID" -ScanGroupMembers
```

Scan every licensed user in the tenant:

```powershell
./scripts/Get-LTIMeetings.ps1 -TenantId "TENANT_ID" -AppId "APP_ID" -Secret $secret -LTIContextId "CONTEXT_ID"
```

`-UserUpn` and `-ScanGroupMembers` are mutually exclusive. If neither is supplied, the script scans all licensed users. By default, it returns only events organized by the mailbox being scanned; add `-OrganizerOnly:$false` to include attendee calendar copies. Results are written to a timestamped CSV in the `scripts` directory unless `-CsvPath` is supplied.

Because the script uses app-only authentication, it calls `/users/{id-or-upn}/events`; app-only authentication cannot call `/me/events`. For unattended or production automation, use a certificate or federated credential rather than a client secret and adapt the script's authentication method accordingly.

---

## Find Meetings for a Specific Class

Use this request to filter server-side by a known LTI context id. Replace `CONTEXT_ID` with the exact context id value for the class.

```
GET https://graph.microsoft.com/v1.0/me/events
  ?$filter=singleValueExtendedProperties/any(ep: ep/id eq 'String {00020329-0000-0000-C000-000000000046} Name OfficeLtiMeetingsContextId' and ep/value eq 'CONTEXT_ID')
  &$select=id,subject,start,end,organizer
```

Value equality matching is exact but **case-insensitive**. The property name in the extended-property `id` is case-sensitive.

---

## Graph API Requirements

| Item | Value |
|------|-------|
| Endpoint version | `v1.0` |
| Permission (delegated) | `Calendars.Read` |
| Permission (application) | `Calendars.Read` |
| User/app context | Per-mailbox — no tenant-wide events endpoint exists |

The script uses Microsoft Graph **application permissions**. `Calendars.Read` is required in every mode. Add `User.Read.All` when scanning all licensed users and `GroupMember.Read.All` when using `-ScanGroupMembers`. All of these application permissions require administrator consent.

---

## Important Notes

- **Attendee copies inflate counts.** The extended property stamp is also written to attendees' calendar copies. To count *created* meetings only, deduplicate to events where `organizer.emailAddress.address` matches the mailbox you are querying.

- **The script searches one context at a time.** `-LTIContextId` is required and matching is exact. Run the script again for each additional context ID.

- **Tenant-wide sweep requires enumeration.** There is no single endpoint to query all calendar events across a tenant. The script enumerates licensed users and issues a `/users/{userId}/events` request for each.

- **Group-scoped discovery depends on the description tag.** `-ScanGroupMembers` searches group descriptions for `contextId: CONTEXT_ID`, then scans unique user members and owners of matching groups.

- **Application calendar access is broad by default.** The `Calendars.Read` application permission can read calendars in all mailboxes unless Exchange Online access is scoped. For new scoped deployments, use [Role Based Access Control for Applications in Exchange Online](https://learn.microsoft.com/exchange/permissions-exo/application-rbac).

- **Classic LTI compatibility.** Older "classic" LTI meetings use a legacy variant of the property named `ContextId` (same property set GUID, different name). If you need to include those, add a parallel filter for:
  ```
  String {00020329-0000-0000-C000-000000000046} Name ContextId
  ```

---

## Additional Links

- [Microsoft Graph API — List Events](https://learn.microsoft.com/en-us/graph/api/user-list-events)
- [Microsoft Graph API — List Users](https://learn.microsoft.com/en-us/graph/api/user-list)
- [Microsoft Graph API — List Group Owners](https://learn.microsoft.com/en-us/graph/api/group-list-owners)
- [Microsoft Graph API — Extended Properties](https://learn.microsoft.com/en-us/graph/api/resources/singlevaluelegacyextendedproperty)
- [Register an app for app-only Microsoft Graph access](https://learn.microsoft.com/en-us/graph/tutorials/dotnet-app-only#register-application-for-app-only-authentication)
- [Exchange Online RBAC for Applications](https://learn.microsoft.com/exchange/permissions-exo/application-rbac)
- [Microsoft 365 LTI Overview](https://learn.microsoft.com/en-us/microsoft-365/lti/)
- [O365-EDU-Tools object discovery reference](https://github.com/OfficeDev/O365-EDU-Tools/blob/master/LTI%20Scripts/M365%20Object%20Discovery/readme.md)
