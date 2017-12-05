# educationsynchronizationprofilestatus resource type

Represents the synchronization status of a [synchronization profile](educationsynchronizationprofile.md). 

> **Note:** Updates to the educationsynchronizationprofilestatus might be delayed due to the asynchronous nature of background sync processing.

### Methods

| Method | Return Type | Description |
|-|-|-|
| [Get status of a sync](../api/educationsynchronizationprofilestatus_get.md) | educationsynchronizationprofilestatus | Returns the status of a specific synchronization profile |

### Properties

| Property | Type | Description |
|-|-|-|
| **status** | string | Enumeration representing the status of a sync. Possible values are: `paused`, `inProgress`, `success`, `error`, `quarantined`, `validationError` |
| **lastSynchronizationDateTime** | DateTimeOffset | Represents the time when most recent changes have been observed in the directory.  |

### JSON

```json
{
    "@odata.context": "https://graph.microsoft.com/beta/$metadata#education/synchronizationProfiles('{id}')/profileStatus/$entity",
    "status": "inProgress",
    "lastSynchronizationDateTime": "2017-07-04T22:06:37.6472621Z"
}
```