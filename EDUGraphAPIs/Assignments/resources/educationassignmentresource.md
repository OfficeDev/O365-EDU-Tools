# educationAssignmentResource resource type




## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationAssignmentResource](../api/educationassignmentresource_get.md) | [educationAssignmentResource](educationassignmentresource.md) |Read properties and relationships of educationAssignmentResource object.|
|[Update](../api/educationassignmentresource_update.md) | [educationAssignmentResource](educationassignmentresource.md)	|Update educationAssignmentResource object. |
|[Delete](../api/educationassignmentresource_delete.md) | None |Delete educationAssignmentResource object. |

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|distributeForStudentWork|Boolean||
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
  "@odata.type": "microsoft.graph.educationAssignmentResource"
}-->

```json
{
  "distributeForStudentWork": true,
  "id": "String (identifier)",
  "resource": {"@odata.type": "microsoft.graph.educationResource"}
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationAssignmentResource resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->