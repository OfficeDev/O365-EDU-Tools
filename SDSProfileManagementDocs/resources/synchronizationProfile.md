# synchronizationProfile resource type

This resource represents a set of configurations used to synchronize education entities and roster information from a source directory to Azure Active Directory. The resource provides a programmatic representation used in [School Data Sync](https://sds.microsoft.com).

### Methods

| Method | Return Type | Description |
|-|-|-|
| [List synchronization profiles](../api/synchronizationProfile_list.md) | collection of synchronizationProfile | Gets a list of all the synchronization profiles in the tenant |
| [Get synchronization profile](../api/synchronizationProfile_get.md) | synchronizationProfile | Retrieve a specific profile given the profile identifier |
| [Create synchronization profile](../api/synchronizationProfile_create.md) | none | Creates a new synchronization profile |
| [Delete synchronization profile](../api/synchronizationProfile_delete.md) | synchronizationProfile | Retrieve a specific profile given the profile identifier |
| [Pause an ongoing sync](../api/synchronizationProfile_post_pause.md) | none | Pauses an ongoing synchronization |
| [Resume a paused sync](../api/synchronizationProfile_post_resume.md) | none | Resumes a paused synchronization |
| [Reset a sync](../api/synchronizationProfile_post_reset.md) | none | Resets the state of the profile and causes synchronization to restart |
| [Start sync for uploaded files](../api/synchronizationProfile_post_start.md) | collection of [verificationMessage](verificationMessage.md) | Verifies the uploaded source files and starts sync. _Applies only when the dataProvider is [csvDataProvider](csvDataProvider.md)_ |
| [Get an upload URL](../api/synchronizationProfile_get_uploadurl.md) | string | Returns the short-lived URL to upload CSV data files. _Applies only when the dataProvider is [csvDataProvider](csvDataProvider.md)_ |
| [Get status of a sync](../api/synchronizationProfile_get_status.md) | [status](synchronizationProfileStatus.md) | Returns the status of a specific synchronization profile |
| [Get synchronization errors](../api/synchronizationProfile_get_errors.md) | collection of [synchronizationError](synchronizationError.md) | Gets all the errors generated during sync |

### Properties

| Property | Type | Description |
|-|-|-|
| **displayName** | string |  Name of the configuration profile for syncing identities         |
| **dataProvider** | [dataProvider](synchronizationDataProvider.md) |  Data provider used for the profile         |
| **identitySynchronizationConfiguration** | [identitySyncConfiguration](identitySynchronizationConfiguration.md) | Identity [creation](identityCreationConfiguration.md) or [matching](identityMatchingConfiguration.md) configuration         |
| **licensesToAssign** | collection of [synchronizationLicenseAssignment](synchronizationLicenseAssignment.md) |  License setup configuration         |
| **state** | string |  Enumeration provides the state of the profile. Possible values: `provisioning`, `provisioned`, `provisioningFailed`, `deleting`, `deletionFailed`          |

### Relationships

| Property | Type | Description |
|-|-|-|
| **errors** | collection of [synchronizationError](synchronizationError.md) | All errors associated with this synchronization profile |
| **profileStatus** | [synchronizationProfileStatus](synchronizationProfileStatus.md) | Synchronization status |

### JSON representation
Here is a JSON representation of a **synchronizationProfile**.

<!-- { "blockType": "resource", "@odata.type": "#microsoft.graph.synchronizationProfile" } -->

```json
{
    "displayName": "Term 1 Sync",
    "lastSynchronizationTime": "0001-01-01T00:00:00Z",
    "state": "Provisioned",
    "syncStatus": "Paused",
    "errorStatus": "None",
    "id": "19c097a9-ea10-49bb-9242-2cc657549032",
    "dataProvider": { "@odata.type": "#microsoft.graph.csvDataProvider" },
    "identitySynchronizationConfiguration": { "@odata.type": "#microsoft.graph.identityCreationConfiguration",
        "userDomains": [{
            "appliesTo": "Student",
            "name": "school.edu"
        }, {
            "appliesTo": "Teacher",
            "name": "school.edu"
        }]
    },
    "licensesToAssign": [{
        "appliesTo": "Teacher",
        "skuIds": ["6fd2c87f-b296-42f0-b197-1e91e994b900"]
    }, {
        "appliesTo": "Student",
        "skuIds": ["6fd2c87f-b296-42f0-b197-1e91e994b900"]
    }],
    "customizations": {
        "school": { "optionalPropertiesToSync": [], "allowDisplayNameUpdate": false },
        "section": {
            "optionalPropertiesToSync": [],
            "allowDisplayNameUpdate": false
        },
        "student": {
            "optionalPropertiesToSync": [],
            "allowDisplayNameUpdate": false
        },
        "teacher": {
            "optionalPropertiesToSync": [],
            "allowDisplayNameUpdate": false
        },
        "studentEnrollment": {
            "optionalPropertiesToSync": [],
            "synchronizationStartDate": "0001-01-01T00:00:00Z",
            "allowDisplayNameUpdate": false
        },
        "teacherRoster": {
            "optionalPropertiesToSync": [],
            "allowDisplayNameUpdate": false
        }
    }
}
```
