# synchronizationCustomizations resource type

This resource contains the list of entities to sync and their [customizations](synchronizationcustomization.md) if any.

> **Note:** For studentEnrollment and teacherRoster customization of properties to sync doesn't apply.

This resource is member of the following data providers

* [csvDataProvider](csvdataprovider.md)
* [powerSchoolDataProvider](powerschooldataprovider.md)

### Properties

| Property | Type | Description |
|-|-|-|
| **school** | [synchronizationCustomization](synchronizationcustomization.md) |  Customization for a school entity         |
| **section** | [synchronizationCustomization](synchronizationcustomization.md) |  Customization for a section entity         |
| **student** | [synchronizationCustomization](synchronizationcustomization.md) |  Customization for a student entity         |
| **teacher** | [synchronizationCustomization](synchronizationcustomization.md) |  Customization for a teacher entity         |
| **studentEnrollment** | [synchronizationCustomization](synchronizationcustomization.md) |  Customization for student enrollment.           |
| **teacherRoster** | [synchronizationCustomization](synchronizationcustomization.md) |       Customization for teacher roster.    |

### JSON

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
