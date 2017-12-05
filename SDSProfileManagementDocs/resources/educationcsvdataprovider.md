# educationcsvdataprovider resource type

When CSV files are the input source, this provider type should be used to setup the profile.  

Derived from [educationsynchronizationdataprovider](educationsynchronizationdataprovider.md)

### Properties

| Property | Type | Description |
|:-|:-|:-|
| customizations | [educationsynchronizationcustomizations](educationsynchronizationcustomizations.md) | Optional customizations to be applied to the synchronization profile.

### JSON

```json
"dataProvider":{
    "@odata.type": "#microsoft.graph.educationcsvdataprovider",
    "customizations": { ... }
    }
}
```