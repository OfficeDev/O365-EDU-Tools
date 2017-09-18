# educationPowerPointResource resource type

Subclass of [educationResource](educationresource.md).  This is a powerpoint resource.  The powerpoint file must be uploaded in the fileResource directory associated with the 
assignment or submission.


## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|file|[educationODataRef](educationodataref.md)|Location of the file on disk.|

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationPowerPointResource"
}-->

```json
{
  "file": {"@odata.type": "microsoft.graph.educationODataRef"}
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationPowerPointResource resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->