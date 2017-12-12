# educationpowerschooldataprovider resource

When PowerSchool is used as the input source, this provider type should be used to setup the profile.

Derived from [educationsynchronizationdataprovider](educationsynchronizationdataprovider.md)

## Properties

| Property | Type | Description |
|-|-|-|
| **connectionUrl** | String | The connection URL to the PowerSchool instance |
| **clientId** | String |  Client id used to connect to PowerSchool |
| **clientSecret** | String |  Client secret to authenticate connection to PowerSchool instance |
| **schoolsIds** | String collection |  The list of schools to sync |
| **schoolYear** | String |  The school year to sync |
| **allowTeachersInMultipleSchools** | Boolean |  Indicates whether source has multiple identifiers for a single student or teacher |
| **customizations** | [educationsynchronizationcustomizations](educationsynchronizationcustomizations.md) | Optional customization to be applied to the synchronization profile.

## JSON representation

```json
"dataProvider": {
    "@odata.type": "#microsoft.graph.educationpowerschooldataprovider",
    "connectionUrl": "{PowerSchool Server Url}",
    "clientId": "{ClientId}",
    "clientSecret": "{ClientSecret}",
    "customizations": { ... }
}
```
