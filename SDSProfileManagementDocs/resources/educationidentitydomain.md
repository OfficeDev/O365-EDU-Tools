# educationidentitydomain resource type

Represents the mapping between an education user type and the domain the user's account belongs to. The domain resource is part of the [identity creation configuration](educationidentitycreationconfiguration.md). 

## Properties

| Property | Type | Description |
|:-|:-|:-|
| **appliesTo** | string |  The user role type to assign to license. Possible values are `student`, `teacher`.      |
| **name** | string |  Represents the domain for the user account.         |

## JSON representation

```json
{
    "appliesTo": "student",
    "name": "testschool.edu"
}
```
