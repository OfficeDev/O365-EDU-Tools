# educationonerosterapidataprovider resource

Used to set up the school data synchronization profile when the [OneRoster API](https://www.imsglobal.org/activity/onerosterlis) is used as the input source.

Derived from [educationsynchronizationdataprovider](educationsynchronizationdataprovider.md).

## Properties

| Property | Type | Description |
|:-|:-|:-|
| **connectionUrl** | String | The connection URL to the OneRoster instance. |
| **clientId** | String |  The client ID used to connect to the OneRoster provider. |
| **clientSecret** | String |  The client secret to authenticate the connection to the OneRoster instance. |
| **customizations** | [educationsynchronizationcustomizations](educationsynchronizationcustomizations.md) | Optional customization to be applied to the synchronization profile.|

## JSON representation

```json
"dataProvider": {
    "@odata.type": "#microsoft.graph.educationonerosterapidataprovider",
    "connectionUrl": "{OneRoster Url}",
    "clientId": "{ClientId}",
    "clientSecret": "{ClientSecret}",
    "customizations": { ... }
}
```
