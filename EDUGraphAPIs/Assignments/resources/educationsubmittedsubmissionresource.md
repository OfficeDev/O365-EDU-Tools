# educationSubmittedSubmissionResource resource type




## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationSubmittedSubmissionResource](../api/educationsubmittedsubmissionresource_get.md) | [educationSubmittedSubmissionResource](educationsubmittedsubmissionresource.md) |Read properties and relationships of educationSubmittedSubmissionResource object.|
|[Update](../api/educationsubmittedsubmissionresource_update.md) | [educationSubmittedSubmissionResource](educationsubmittedsubmissionresource.md)	|Update educationSubmittedSubmissionResource object. |
|[Delete](../api/educationsubmittedsubmissionresource_delete.md) | None |Delete educationSubmittedSubmissionResource object. |

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
  "@odata.type": "microsoft.graph.educationSubmittedSubmissionResource"
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
  "description": "educationSubmittedSubmissionResource resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->