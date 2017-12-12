# educationCsvDataProvider resource type

When CSV files are the input source, this provider type should be used to setup the profile.  

Derived from [educationsynchronizationdataprovider](educationsynchronizationdataprovider.md)

### Properties

| Property | Type | Description |
|:-|:-|:-|
| customizations | [educationsynchronizationcustomizations](educationsynchronizationcustomizations.md) | Optional customizations to be applied to the synchronization profile.

### JSON
<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "#microsoft.graph.educationCsvDataProvider"
}-->

```json
"dataProvider":{
    "@odata.type": "#microsoft.graph.educationCsvDataProvider",
    "customizations": { "@odata.type": "microsoft.graph.educationSynchronizationCustomizations" }
    }
}
```