# educationidentitymatchingoptions resource type

Provides a mapping between a source property and a target property for matching user accounts. The source property should exist in the source data. The target property should be a valid property in Azure Active Directory (Azure AD).

## Properties

| Property | Type | Description |
|-|-|-|
| **appliesTo** | string |  The user role type to assign to license. Possible values are `student`, `teacher`.      |
| **sourcePropertyName** | string |  Name of the source property, should be a field name in source data. This property is case-sensitive.        |
| **targetPropertyName** | string |  Name of the target property, should be a valid property in AAD. This property is case-sensitive.     |
| **targetDomain** | string |  Domain to suffix with the source property to match on the target. If provided as null, then the source property will be used to match with the target property         |

## JSON representation

```json
{
    "appliesTo": "student",
    "sourcePropertyName": "Username",
    "targetPropertyName": "userPrincipalName",
    "targetDomain": "{domain}"
}
```
