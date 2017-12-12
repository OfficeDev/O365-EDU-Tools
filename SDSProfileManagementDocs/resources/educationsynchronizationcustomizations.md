# educationSynchronizationCustomizations resource type

This resource contains the list of entities to sync and their [customizations](educationsynchronizationcustomization.md) if any.

> **Note:** For studentEnrollment and teacherRoster customization of properties to sync doesn't apply.

This resource is member of the following data providers

* [educationcsvdataprovider](educationcsvdataprovider.md)
* [educationpowerschooldataprovider](educationpowerschooldataprovider.md)

### Properties

| Property | Type | Description |
|-|-|-|
| **school** | [educationSynchronizationCustomizations](educationsynchronizationcustomization.md) |  Customization for a school entity         |
| **section** | [educationSynchronizationCustomizations](educationsynchronizationcustomization.md) |  Customization for a section entity         |
| **student** | [educationSynchronizationCustomizations](educationsynchronizationcustomization.md) |  Customization for a student entity         |
| **teacher** | [educationSynchronizationCustomizations](educationsynchronizationcustomization.md) |  Customization for a teacher entity         |
| **studentEnrollment** | [educationSynchronizationCustomizations](educationsynchronizationcustomization.md) |  Customization for student enrollment.           |
| **teacherRoster** | [educationSynchronizationCustomizations](educationsynchronizationcustomization.md) |       Customization for teacher roster.    |

### JSON
<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "#microsoft.graph.educationSynchronizationCustomizations"
}-->

```json
"customizations": {
        "school": {"@odata.type": "microsoft.graph.educationSynchronizationCustomization"},
        "section": {"@odata.type": "microsoft.graph.educationSynchronizationCustomization"},
        "student": {"@odata.type": "microsoft.graph.educationSynchronizationCustomization"},
        "teacher": {"@odata.type": "microsoft.graph.educationSynchronizationCustomization"},
        "studentEnrollment": {"@odata.type": "microsoft.graph.educationSynchronizationCustomization"},
        "teacherRoster": {"@odata.type": "microsoft.graph.educationSynchronizationCustomization"}
    }
}
```
