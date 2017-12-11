# educationfilesynchronizationverificationmessage resource type

Represents an error returned to the client in response to a request to [start synchronization](../api/educationsynchronizationprofile_start.md) for CSV-based profiles. The resource will contain errors that result from the verification. Users must fix the source data before you restart the request to synchronize with Azure Active Directory (Azure AD).

### Properties

| Property | Type | Description |
|-|-|-|
| **type** | string | Type of the message. Possible values `error`, `warning`, `information`. | 
| **filename** | string | Source file that contains the error. |
| **description** | string | Detailed information about the message type. |

### JSON

```json
{
    "type": "Error",
    "fileName": "section.csv",
    "description": "5 row(s) have missing data for the field - SIS ID"
}
```