# educationpowerschooldataprovider resource

Used to set up the school data synchronization profile when [PowerSchool](https://www.powerschool.com/solutions/student-information-system-sis/) is used as the input source.

Derived from [educationsynchronizationdataprovider](educationsynchronizationdataprovider.md).

## Properties

| Property | Type | Description |
|:-|:-|:-|
| **connectionUrl** | String | The connection URL to the PowerSchool instance. |
| **clientId** | String |  The client ID used to connect to PowerSchool. |
| **clientSecret** | String |  The client secret to authenticate the connection to the PowerSchool instance. |
| **schoolsIds** | String collection |  The list of schools to sync. |
| **schoolYear** | String |  The school year to sync. |
| **allowTeachersInMultipleSchools** | Boolean |  Indicates whether the source has multiple identifiers for a single student or teacher. |
| **customizations** | [educationsynchronizationcustomizations](educationsynchronizationcustomizations.md) | Optional customization to be applied to the synchronization profile.|

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
