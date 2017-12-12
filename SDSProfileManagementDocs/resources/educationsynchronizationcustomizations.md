# educationsynchronizationcustomizations resource type

This resource contains the list of entities to sync and their [customizations](educationsynchronizationcustomization.md) if any.

> **Note:** For studentEnrollment and teacherRoster customization of properties to sync doesn't apply.

This resource is member of the following data providers

* [educationcsvdataprovider](educationcsvdataprovider.md)
* [educationpowerschooldataprovider](educationpowerschooldataprovider.md)

## Properties

| Property | Type | Description |
|-|-|-|
| **school** | [educationsynchronizationcustomization](educationsynchronizationcustomization.md) |  Customization for a school entity         |
| **section** | [educationsynchronizationcustomization](educationsynchronizationcustomization.md) |  Customization for a section entity         |
| **student** | [educationsynchronizationcustomization](educationsynchronizationcustomization.md) |  Customization for a student entity         |
| **teacher** | [educationsynchronizationcustomization](educationsynchronizationcustomization.md) |  Customization for a teacher entity         |
| **studentEnrollment** | [educationsynchronizationcustomization](educationsynchronizationcustomization.md) |  Customization for student enrollment.           |
| **teacherRoster** | [educationsynchronizationcustomization](educationsynchronizationcustomization.md) |       Customization for teacher roster.    |

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
