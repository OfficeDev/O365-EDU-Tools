# educationSubmissionResource resource type




## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationSubmissionResource](../api/educationsubmissionresource_get.md) | [educationSubmissionResource](educationsubmissionresource.md) |Read properties and relationships of educationSubmissionResource object.|
|[Update](../api/educationsubmissionresource_update.md) | [educationSubmissionResource](educationsubmissionresource.md)	|Update educationSubmissionResource object. |
|[Delete](../api/educationsubmissionresource_delete.md) | None |Delete educationSubmissionResource object. |

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|assignmentResource|[educationODataRef](educationodataref.md)||
|id|String| Read-only.|
|resource|[educationResource](educationresource.md)||

## Relationships
None


## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationSubmissionResource"
}-->

```json
{
  "assignmentResource": {"@odata.type": "microsoft.graph.educationODataRef"},
  "id": "String (identifier)",
  "resource": {"@odata.type": "microsoft.graph.educationResource"}
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationSubmissionResource resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->