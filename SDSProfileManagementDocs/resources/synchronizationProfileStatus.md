# synchronizationStatus resource type

Represents the synchronization status of a [synchronization profile](synchronizationProfile.md). 

> **Note:** Updates to the synchronizationProfileStatus might be delayed due to the asynchronous nature of background sync processing.

### Methods

| Method | Return Type | Description |
|-|-|-|
| [Get status of a sync](../api/synchronizationProfile_get_status.md) | synchronizationProfileStatus | Returns the status of a specific synchronization profile |

### Properties

| Property | Type | Description |
|-|-|-|
| **status** | string | Enumeration representing the status of a sync. Possible values are: `paused`, `inProgress`, `success`, `error`, `quarantined`, `validationError` |
| **lastSynchronizationDateTime** | DateTimeOffset | Represents the time when most recent changes have been observed in the directory.  |