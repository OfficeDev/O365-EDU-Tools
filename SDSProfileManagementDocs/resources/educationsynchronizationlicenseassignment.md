# educationSynchronizationLicenseAssignment resource type

This resource represents the license information to assign to user accounts. The resource will be used to setup license assignments when creating new user accounts.

### Properties

| Property | Type | Description |
|-|-|-|
| **appliesTo** | string |  Enumeration user role type to assign to license. Possible values: `student`, `teacher`         |
| **skuIds** | collection of strings |  Collection of strings representing the SKU identifiers of the licenses to assign         |

### JSON
<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "#microsoft.graph.educationSynchronizationLicenseAssignment"
}-->

```json
{
    "appliesTo": {"@odata.type": "#microsoft.graph.educationUserRole"},
    "skuIds": ["String"]
}
```
