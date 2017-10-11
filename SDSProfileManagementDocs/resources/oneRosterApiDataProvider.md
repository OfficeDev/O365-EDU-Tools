# powerSchoolDataProvider resource

When OneRoster API is used as the input source, this provider type should be used to setup the profile.

Derived from [synchronizationDataProvider](synchronizationDataProvider.md)

### JSON representation

### Properties

| Property | Type | Description |
|-|-|-|
| **connectionUrl** | String | The connection URL to the PowerSchool instance |
| **clientId** | String |  Client id used to connect to PowerSchool |
| **clientSecret** | String |  Client secret to authenticate connection to PowerSchool instance |
| **customizations** | [synchronizationCustomizations](synchronizationCustomizations.md) | Optional customization to be applied to the synchronization profile. 
