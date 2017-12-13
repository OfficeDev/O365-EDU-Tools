# educationSynchronizationProfile resource type

Represents a set of configurations used to synchronize education entities and roster information from a source directory to Azure Active Directory (Azure AD). This resource provides a programmatic representation used in [School Data Sync](https://sds.microsoft.com).

## Methods

| Method | Return Type | Description |
|:-|:-|:-|
| [List synchronization profiles](../api/educationsynchronizationprofile_list.md) | **educationSynchronizationProfile** collection | Get a list of all the synchronization profiles in the tenant. |
| [Get synchronization profile](../api/educationsynchronizationprofile_get.md) | **educationSynchronizationProfile** | Retrieve a specific profile given the profile identifier. |
| [Create synchronization profile](../api/educationsynchronizationprofile_post.md) | None | Create a new synchronization profile. |
| [Delete synchronization profile](../api/educationsynchronizationprofile_delete.md) | **educationSynchronizationProfile** | Delete a specific profile given the profile identifier. |
| [Pause an ongoing sync](../api/educationsynchronizationprofile_pause.md) | None | Pause an ongoing synchronization. |
| [Resume a paused sync](../api/educationsynchronizationprofile_resume.md) | None | Resume a paused synchronization. |
| [Reset a sync](../api/educationsynchronizationprofile_reset.md) | None | Reset the state of the profile and restart synchronization. |
| [Start sync for uploaded files](../api/educationsynchronizationprofile_start.md) | [educationSynchronizationVerificationMessage](verificationMessage.md) collection| Verify the uploaded source files and start synchronization. Applies only when the data provider is [educationCsvDataProvider](educationcsvdataprovider.md). |
| [Get an upload URL](../api/educationsynchronizationprofile_uploadurl.md) | string | Return the short-lived URL to upload CSV data files. Applies only when the data provider is [educationCsvDataProvider](educationcsvdataprovider.md). |
| [Get status of a sync](../api/educationsynchronizationprofilestatus_get.md) | [status](synchronizationprofilestatus.md) | Return the status of a specific synchronization profile. |
| [Get synchronization errors](../api/educationsynchronizationerrors_get.md) | [educationSynchronizationError](educationsynchronizationerror.md) collection| Get all the errors generated during synchronization. |

## Properties

| Property | Type | Description |
|:-|:-|:-|
| **displayName** | string |  Name of the configuration profile for syncing identities.         |
| **dataProvider** | [educationSynchronizationDataProvider](educationsynchronizationdataprovider.md) |  The data provider used for the profile.         |
| **identitysynchronizationconfiguration** | [educationIdentitySynchronizationConfiguration](educationidentitysynchronizationconfiguration.md) | Identity [creation](educationidentitycreationconfiguration.md) or [matching](educationidentitymatchingconfiguration.md) configuration .        |
| **licensesToAssign** | [educationSynchronizationLicenseAssignment](educationsynchronizationlicenseassignment.md) collection|  License setup configuration.        |
| **state** | string |  The state of the profile. Possible values are: `provisioning`, `provisioned`, `provisioningFailed`, `deleting`, `deletionFailed`.          |

## Relationships

| Property | Type | Description |
|:-|:-|:-|
| **errors** | [educationSynchronizationError](educationsynchronizationerror.md) collection| All errors associated with this synchronization profile. |
| **profileStatus** | [educationSynchronizationProfileStatus](educationsynchronizationprofilestatus.md) | The synchronization status. |

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
