# educationoneRosterApiDataProvider resource

When OneRoster API is used as the input source, this provider type should be used to setup the profile.

Derived from [educationsynchronizationdataprovider](educationsynchronizationdataprovider.md)

### Properties

| Property | Type | Description |
|-|-|-|
| **connectionUrl** | String | The connection URL to the OneRoster instance |
| **clientId** | String |  Client id used to connect to OneRoster provider |
| **clientSecret** | String |  Client secret to authenticate connection to OneRoster instance |
| **customizations** | [educationsynchronizationcustomizations](educationsynchronizationcustomizations.md) | Optional customization to be applied to the synchronization profile.

### JSON
<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "#microsoft.graph.educationoneRosterApiDataProvider"
}-->

```json
"dataProvider": {
    "@odata.type": "#microsoft.graph.educationoneRosterApiDataProvider",
    "connectionUrl": "String",
    "clientId": "String",
    "clientSecret": "String",
    "customizations": { "@odata.type": "microsoft.graph.educationSynchronizationCustomizations" }
}
```
