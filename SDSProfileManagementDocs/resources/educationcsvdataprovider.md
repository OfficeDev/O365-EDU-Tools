# educationCsvDataProvider resource type

Used to set up the school data synchronization profile when CSV files are the input source.  

Derived from [educationSynchronizationDataProvider](educationsynchronizationdataprovider.md).

## Properties

| Property | Type | Description |
|:-|:-|:-|
| customizations | [educationSynchronizationCustomizations](educationsynchronizationcustomizations.md) | Optional customizations to be applied to the synchronization profile.|

## JSON representation

```json
"dataProvider":{
    "@odata.type": "#microsoft.graph.educationcsvdataprovider",
    "customizations": { ... }
    }
}
```