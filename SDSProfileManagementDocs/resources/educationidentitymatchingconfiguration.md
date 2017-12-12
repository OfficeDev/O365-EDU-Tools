## educationIdentityMatchingConfiguration resource type

This resource defines the settings for matching identities. These identities include students and teachers. Based on these settings the users will be updated in the directory.

> **Note:** No users will be created when this resource has been selected

| Property | Type | Description |
|-|-|-|
| **matchingOptions** | [educationidentitymatchingoptions](educationidentitymatchingoptions.md) collection | Mapping between the user account and the options to use to uniquely identify the user to update |

### JSON
<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "#microsoft.graph.educationIdentityMatchingConfiguration"
}-->

```json
"identitySynchronizationConfiguration": {
    "@odata.type": "#microsoft.graph.educationIdentityMatchingConfiguration",
    "matchingOptions": [
        {
            "appliesTo": {"@odata.type": "#microsoft.graph.educationUserRole"},
            "sourcePropertyName": "String",
            "targetPropertyName": "String",
            "targetDomain": "String"
        }
    ]
}
```
