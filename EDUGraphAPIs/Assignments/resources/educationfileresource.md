# educationFileResource resource type

Subclass of [educationResource](educationresource.md).  Represents a file object that is associated with the assignment or submission.  In this case the file is not one of the special
files (word, excel, etc.) but is a file that does not have special handling within the system.  The file resource must be stored in the resourceFolder that is associated with the assignment or submission this resource is attached to.



## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|file|[educationODataRef](educationodataref.md)|Location on disk of the file resource.|

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationFileResource"
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
  "description": "educationFileResource resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->