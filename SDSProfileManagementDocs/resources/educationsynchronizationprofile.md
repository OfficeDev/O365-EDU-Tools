# educationSynchronizationProfile resource type

Represents a set of configurations used to synchronize education entities and roster information from a source directory to Azure Active Directory (Azure AD). The resource provides a programmatic representation used in [School Data Sync](https://sds.microsoft.com).

## Methods

| Method | Return Type | Description |
|:-|:-|:-|
| [List synchronization profiles](../api/synchronizationprofile_list.md) | **educationSynchronizationProfile** collection | Gets a list of all the synchronization profiles in the tenant |
| [Get synchronization profile](../api/synchronizationprofile_get.md) | **educationSynchronizationProfile** | Retrieve a specific profile given the profile identifier |
| [Create synchronization profile](../api/synchronizationprofile_post.md) | None | Creates a new synchronization profile |
| [Delete synchronization profile](../api/synchronizationprofile_delete.md) | **educationSynchronizationProfile** | Retrieve a specific profile given the profile identifier |
| [Pause an ongoing sync](../api/synchronizationprofile_pause.md) | None | Pauses an ongoing synchronization |
| [Resume a paused sync](../api/synchronizationprofile_resume.md) | None | Resumes a paused synchronization |
| [Reset a sync](../api/synchronizationprofile_reset.md) | None | Resets the state of the profile and causes synchronization to restart |
| [Start sync for uploaded files](../api/synchronizationprofile_start.md) | [educationSynchronizationVerificationMessage](verificationMessage.md) collection| Verifies the uploaded source files and starts sync. _Applies only when the dataProvider is [educationcsvdataprovider](educationcsvdataprovider.md)_ |
| [Get an upload URL](../api/synchronizationProfile_get_uploadurl.md) | string | Returns the short-lived URL to upload CSV data files. _Applies only when the dataProvider is [educationcsvdataprovider](educationcsvdataprovider.md)_ |
| [Get status of a sync](../api/synchronizationprofilestatus_get.md) | [status](synchronizationprofilestatus.md) | Returns the status of a specific synchronization profile |
| [Get synchronization errors](../api/synchronizationerrors_get.md) | [educationSynchronizationError](educationsynchronizationerror.md) collection| Gets all the errors generated during sync. |

## Properties

| Property | Type | Description |
|:-|:-|:-|
| **displayName** | string |  Name of the configuration profile for syncing identities         |
| **dataProvider** | [dataProvider](educationsynchronizationdataprovider.md) |  Data provider used for the profile         |
| **identitysynchronizationconfiguration** | [educationidentitysynchronizationconfiguration](educationidentitysynchronizationconfiguration.md) | Identity [creation](educationidentitycreationconfiguration.md) or [matching](educationidentitymatchingconfiguration.md) configuration         |
| **licensesToAssign** | collection of [educationsynchronizationlicenseassignment](educationsynchronizationlicenseassignment.md) |  License setup configuration         |
| **state** | string |  Enumeration provides the state of the profile. Possible values: `provisioning`, `provisioned`, `provisioningFailed`, `deleting`, `deletionFailed`          |

## Relationships

| Property | Type | Description |
|:-|:-|:-|
| **errors** | collection of [educationsynchronizationerror](educationsynchronizationerror.md) | All errors associated with this synchronization profile |
| **profileStatus** | [educationsynchronizationprofilestatus](educationsynchronizationprofilestatus.md) | Synchronization status |

## JSON representation
The following is a JSON representation of a **synchronizationProfile**.

<!-- { "blockType": "resource", "@odata.type": "#microsoft.graph.synchronizationProfile" } -->

```json
{
    "displayName": "Term 1 Sync",
    "lastSynchronizationTime": "0001-01-01T00:00:00Z",
    "state": "Provisioned",
    "syncStatus": "Paused",
    "errorStatus": "None",
    "id": "19c097a9-ea10-49bb-9242-2cc657549032",
    "dataProvider": { "@odata.type": "#microsoft.graph.educationcsvdataprovider" },
    "identitySynchronizationConfiguration": { "@odata.type": "#microsoft.graph.educationidentitycreationconfiguration",
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
