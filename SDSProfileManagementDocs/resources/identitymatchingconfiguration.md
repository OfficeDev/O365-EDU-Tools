## identityMatchingConfiguration resource type

This resource defines the settings for matching identities. These identities include students and teachers. Based on these settings the users will be updated in the directory.

> **Note:** No users will be created when this resource has been selected

| Property | Type | Description |
|-|-|-|
| **matchingOptions** | [identityMatchingOptions](identitymatchingoptions.md) collection | Mapping between the user account and the options to use to uniquely identify the user to update |

### JSON

```json
"identitySynchronizationConfiguration": {
    "@odata.type": "#microsoft.graph.identityMatchingConfiguration",
    "matchingOptions": [
        {
            "appliesTo": "student",
            "sourcePropertyName": "Username",
            "targetPropertyName": "userPrincipalName",
            "targetDomain": "{domain}"
        },
        {
            "appliesTo": "teacher",
            "sourcePropertyName": "Username",
            "targetPropertyName": "userPrincipalName",
            "targetDomain": "{domain}"
        }
    ]
}
```
