## educationidentitycreationconfiguration resource type

This resource defines the settings on creation of identities. These identities include students and teachers. Based on these settings the users will be created in the directory.

> **Note:** If you have directory sync turned on to sync between on-premise AD and AAD, then this resource type should not be used. Instead developers should use [educationidentitymatchingconfiguration](educationidentitymatchingconfiguration.md)

Derived from [identitySyncConfiguration](identitySyncConfiguration.md)

### Properties

| Property | Type | Description |
|-|-|-|
| **userDomains** | [educationidentitydomain](educationidentitydomain.md) collection |  Sets the list of domains to use per user type  |

### JSON

```json
"identitySynchronizationConfiguration": {
    "@odata.type": "#microsoft.graph.educationidentitycreationconfiguration",
    "userDomains": [
        {
            "appliesTo": "student",
            "name": "testschool.edu"
        },
        {
            "appliesTo": "teacher",
            "name": "testschool.edu"
        }
    ]
}
```