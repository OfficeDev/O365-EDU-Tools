# educationODataRef resource type

Files are represented by odata.id strings in the Graph.  A single string will represent the location of a file inside the graph.  Today this string is stored in this object.
Going forward, this representation will be replaced by a real Odata.ref object.  Please note that this will change slightly as this API is moved to Public Preview.


## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|odataid|String|String representation of the file object stored in OneDrive.|

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationODataRef"
}-->

```json
{
  "odataid": "String"
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationODataRef resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->