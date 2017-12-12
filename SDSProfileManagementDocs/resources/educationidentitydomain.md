# educationIdentityDomain resource type

This resource represents mapping between an education user type and the domain the user's account belongs to. The domain resource is part of the [identity creation option](educationidentitycreationconfiguration.md). 

### Properties

| Property | Type | Description |
|-|-|-|
| **appliesTo** | string |  Enumeration user role type to assign to license. Possible values: `student`, `teacher`       |
| **name** | string |  Represents the domain for the user account         |

### JSON
<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "#microsoft.graph.educationIdentityDomain"
}-->

```json
{
    "appliesTo": {"@odata.type": "#microsoft.graph.educationUserRole"},
    "name": "String"
}
```
