# educationSynchronizationError resource type

Represents an error during school data profile sync. An unique error will be generated for every entry that fails to synchronize with Azure Active Directory (Azure AD).

## Methods

| Method | Return Type | Description |
|:-|:-|:-|
| [Get synchronization errors](../api/educationsynchronizationerrors_get.md) | Collection of **educationSynchronizationError** | Returns the list of synchronization errors observed in a profile |

## Properties

| Property | Type | Description |
|:-|:-|:-|
| **entryType** | string |  represents the sync entity (school, section, student, teacher)         |
| **errorCode** | string |  represents the error code for this error         |
| **errorMessage** | string |  contains a description of the error         |
| **joiningValue** | string |  the unique identifier for the entry         |
| **recordedDateTime** | DateTimeOffset |  the time of occurrence of this error         |

## JSON representation

```json
{
    "entryType": "Student",
    "errorCode": "UnsynchronizableChange",
    "errorMessage": "Student cannot be updated as no matching entry in Active Directory was found for Student.  Verify the identity matching criteria for the profile.",
    "joiningValue": "test@testschool.edu",
    "recordedDateTime": "2017-07-05T00:52:45Z",
    "reportableIdentifier": "test"
}
```
