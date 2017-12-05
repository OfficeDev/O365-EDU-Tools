# csvDataProvider resource type

When CSV files are the input source, this provider type should be used to setup the profile.  

Derived from [synchronizationDataProvider](synchronizationdataprovider.md)

### Properties

| Property | Type | Description |
|:-|:-|:-|
| customizations | [synchronizationCustomizations](synchronizationcustomizations.md) | Optional customizations to be applied to the synchronization profile.

### JSON

```json
"dataProvider":{
    "@odata.type": "#microsoft.graph.csvDataProvider",
    "customizations": { ... }
    }
}
```