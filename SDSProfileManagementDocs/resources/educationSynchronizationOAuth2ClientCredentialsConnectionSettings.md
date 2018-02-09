# educationSynchronizationOAuth2ClientCredentialsConnectionSettings resource

When [OAuth2 Client Credentials Grant](https://tools.ietf.org/html/rfc6749#section-4.4) is to be used to connect to the data provider, this connection settings type should be used to setup the profile.

Derived from [educationSynchronizationConnectionSettings](educationSynchronizationConnectionSettings.md)

## Properties

| Property | Type | Description |
|:-|:-|:-|
| **tokenUrl** | String | The URL to get access tokens for the data provider |
| **scope** | String | [The scope of the access request](https://tools.ietf.org/html/rfc6749#section-3.3) |

## JSON

```json
"connectionSettings": {
    "@odata.type": "#microsoft.graph.educationSynchronizationOAuth2ClientCredentialsConnectionSettings",
    "clientId": "String",
    "clientSecret": "String",
    "tokenUrl": "String",
    "scope": "String"
}
```
