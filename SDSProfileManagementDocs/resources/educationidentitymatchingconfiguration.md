## educationIdentityMatchingConfiguration resource type

Defines the settings for matching school data profile identities. These identities include students and teachers. Based on these settings, the users will be updated in the directory.

> **Note:** No users are created when this resource is selected.

## Properties

| Property | Type | Description |
|:-|:-|:-|
| **matchingOptions** | [educationIdentityMatchingOptions](educationidentitymatchingoptions.md) collection | Mapping between the user account and the options to use to uniquely identify the user to update. |

## JSON representation

```json
"identitySynchronizationConfiguration": {
    "@odata.type": "#microsoft.graph.educationidentitymatchingconfiguration",
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
