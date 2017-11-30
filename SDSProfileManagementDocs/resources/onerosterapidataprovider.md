# oneRosterApiDataProvider resource

When OneRoster API is used as the input source, this provider type should be used to setup the profile.

Derived from [synchronizationDataProvider](synchronizationdataprovider.md)

### Properties

| Property | Type | Description |
|-|-|-|
| **connectionUrl** | String | The connection URL to the OneRoster instance |
| **clientId** | String |  Client id used to connect to OneRoster provider |
| **clientSecret** | String |  Client secret to authenticate connection to OneRoster instance |
| **customizations** | [synchronizationCustomizations](synchronizationcustomizations.md) | Optional customization to be applied to the synchronization profile.

### JSON

```json
"dataProvider": {
    "@odata.type": "#microsoft.graph.oneRosterApiDataProvider",
    "connectionUrl": "{OneRoster Url}",
    "clientId": "{ClientId}",
    "clientSecret": "{ClientSecret}",
    "customizations": { ... }
}
```
