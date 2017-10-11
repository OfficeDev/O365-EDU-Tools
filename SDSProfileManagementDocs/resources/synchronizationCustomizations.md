# synchronizationCustomizations resource type

This resource contains the list of entities to sync and their [customizations](synchronizationCustomization.md) if any.

> **Note:** For studentEnrollment and teacherRoster customization of properties to sync doesn't apply.

This resource is member of the following data providers

* [csvDataProvider](csvDataProvider.md)
* [powerSchoolDataProvider](powerSchoolDataProvider.md)

### Properties

| Property | Type | Description |
|-|-|-|
| **school** | [synchronizationCustomization](synchronizationCustomization.md) |  Customization for a school entity         |
| **section** | [synchronizationCustomization](synchronizationCustomization.md) |  Customization for a section entity         |
| **student** | [synchronizationCustomization](synchronizationCustomization.md) |  Customization for a student entity         |
| **teacher** | [synchronizationCustomization](synchronizationCustomization.md) |  Customization for a teacher entity         |
| **studentEnrollment** | [synchronizationCustomization](synchronizationCustomization.md) |  Customization for student enrollment.           |
| **teacherRoster** | [synchronizationCustomization](synchronizationCustomization.md) |       Customization for teacher roster.    |
