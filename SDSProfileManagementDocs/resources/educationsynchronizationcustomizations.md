# educationSynchronizationCustomizations resource type

Contains the list of entities to sync and their [customizations](educationsynchronizationcustomization.md), if any.

> **Note:** Customization of properties to sync does not apply to the **studentEnrollment** and **teacherRoster** entities.

This resource is member of the following data providers:

* [educationCsvDataProvider](educationcsvdataprovider.md)
* [educationPowerSchoolDataProvider](educationpowerschooldataprovider.md)

## Properties

| Property | Type | Description |
|:-|:-|:-|
| **school** | [educationSynchronizationCustomization](educationsynchronizationcustomization.md) |  Customization for a school entity.        |
| **section** | [educationSynchronizationCustomization](educationsynchronizationcustomization.md) |  Customization for a section entity.         |
| **student** | [educationSynchronizationCustomization](educationsynchronizationcustomization.md) |  Customization for a student entity.         |
| **teacher** | [educationSynchronizationCustomization](educationsynchronizationcustomization.md) |  Customization for a teacher entity.         |
| **studentEnrollment** | [educationSynchronizationCustomization](educationsynchronizationcustomization.md) |  Customization for student enrollment.           |
| **teacherRoster** | [educationSynchronizationCustomization](educationsynchronizationcustomization.md) |       Customization for a teacher roster.    |

## JSON representation

```json
"customizations": {
        "school": {
            "optionalPropertiesToSync": []
        },
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
            "synchronizationStartDate": "{UTC Date if delay required. Immediate by default}",
            "isSyncDeferred": false
        },
        "teacherRoster": {
            "optionalPropertiesToSync": []
        }
    }
}
```
