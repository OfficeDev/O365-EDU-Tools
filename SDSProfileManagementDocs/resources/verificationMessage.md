# verificationMessage resource type

This resource represents an error returned to the client in response to [file verification](..\api\synchronizationProfile_post_verifyfiles.md). The resource will contain errors resulting from the verification. This should allow end users to fix the source data before attempting to synchronize with Azure Active Directory.

### Properties

| Property | Type | Description |
|-|-|-|
| **type** | string | Type of the message. Values can be _error_, _warning_, _information_ | 
| **filename** | string | Source file containing the error |
| **description** | string | Detailed information on the message type |