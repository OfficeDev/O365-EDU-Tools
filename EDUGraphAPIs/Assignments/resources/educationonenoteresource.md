# educationOneNoteResource resource type


Subclass of [educationResource](educationresource.md).  This represents the location of the **OneNote** page.  

>**Important:** This API currently an incorrect syntax.  This will be 
replaced by the representation (single property) like the rest of graph.  Use this knowing it will change!!

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|notebookId|String|Notebook ID of the OneNote for this resource.|
|pageId|String|Page Id of the OneNote.|
|sectionName|String|Section Name of the OneNote.|

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationOneNoteResource"
}-->

```json
{
  "notebookId": "String",
  "pageId": "String",
  "sectionName": "String"
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationOneNoteResource resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->