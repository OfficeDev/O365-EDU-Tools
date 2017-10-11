## identityCreationConfiguration resource type

This resource defines the settings on creation of identities. These identities include students and teachers. Based on these settings the users will be created in the directory.

> **Note:** If you have directory sync turned on to sync between on-premise AD and AAD, then this resource type should not be used. Instead developers should use [IdentityMatchingConfiguration](IdentityMatchingConfiguration.md)

Derived from [identitySyncConfiguration](identitySyncConfiguration.md)

### Properties

| Property | Type | Description |
|-|-|-|
| **userDomains** | [identityDomain](identityDomain.md) collection |  Sets the list of domains to use per user type  |
