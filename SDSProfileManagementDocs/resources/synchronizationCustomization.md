# synchronizationCustomization resource type

This resource provides settings for customizing the synchronization of the resource entities. The customization can be applied to all the entities being synchronized. 

> **Note:** The **synchronizationStartDate** property only applies to _StudentEnrollment_ entity.

### Properties

| Property | Type | Description |
|-|-|-|
| **optionalPropertiesToSync** | collection of string |  Collection of property names to sync. If set to null, all properties will be synchronized       |
| **synchronizationStartDate** | DateTime |  Date that the synchronization should be deferred to. Should be set to a future value. If set to null, the resource will be synchronized when the profile setup completes. _This only applies to StudentEnrollment_      |
| **allowDisplayNameUpdate** | boolean |  Value indicating whether the display name of the resource can be overwritten by sync         |
