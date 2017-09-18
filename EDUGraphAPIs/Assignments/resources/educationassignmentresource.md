# educationAssignmentResource resource type

Wrapper object which stores the resources associated with an assignment.  The wrapper adds the distributeForStudentWork property which represents whether this resource is meant to
be copied to the student submission.  If the object is not copied, then each student will simply see a link to the resource on the assignment.  There will be no ability for the student
to update the resource.  This should be thought of as a hand-out from the teacher to the student with nothing needed to be returned.  If the resource is distributed, each student 
will recieve a copy of this resource in the resource list of their assignment.  Each student will be able to modify their copy and submit it for grading.


## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationAssignmentResource](../api/educationassignmentresource_get.md) | [educationAssignmentResource](educationassignmentresource.md) |Read properties and relationships of educationAssignmentResource object.|
|[Update](../api/educationassignmentresource_update.md) | [educationAssignmentResource](educationassignmentresource.md)	|Update educationAssignmentResource object. |
|[Delete](../api/educationassignmentresource_delete.md) | None |Delete educationAssignmentResource object. |

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|distributeForStudentWork|Boolean|Indicates whether this resource should be copied to each student submission for modification and submission.|
|id|String| ID of this resource.  Read-only.|
|resource|[educationResource](educationresource.md)|Resource object that has been assoicated with this assignment.|

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