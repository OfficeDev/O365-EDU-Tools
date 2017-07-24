# synchronizationError resource type

This resource represents an error during sync. An unique error will be generated for every entry that fails to synchronize with AAD.

### Methods

| Method | Return Type | Description |
|-|-|-|
| [Get synchronization errors](..\api\synchronizationProfile_get_errors.md) | collection of synchronizationError | Returns the list of synchronization errors observed in a profile |

### Properties

| Property | Type | Description |
|-|-|-|
| **entryType** | string |  represents the sync entity (school, section, student, teacher)         |
| **errorCode** | string |  represents the error code for this error         |
| **errorMessage** | string |  contains a description of the error         |
| **joiningValue** | string |  the unique identifier for the entry         |
| **recordedTime** | DateTimeOffset |  the time of occurrence of this error         |
