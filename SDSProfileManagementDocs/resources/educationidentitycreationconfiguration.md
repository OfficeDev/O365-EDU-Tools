## educationidentitycreationconfiguration resource type

Defines the settings on creation of school data profile identities. These identities include students and teachers. Based on these settings, the users will be created in the directory.

> **Note:** If you have directory sync turned on to sync between on-premises Active Directory and Azure Active Directory (Azure AD), use the [educationidentitymatchingconfiguration](educationidentitymatchingconfiguration.md) resource instead.

Derived from [identitySyncConfiguration](identitySyncConfiguration.md).

## Properties

| Property | Type | Description |
|:-|:-|:-|
| **userDomains** | [educationidentitydomain](educationidentitydomain.md) collection |  Sets the list of domains to use per user type.  |

## JSON representation

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