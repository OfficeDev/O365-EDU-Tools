# educationAssignmentPointsGradeType resource type

Used with assignmnets.grading property.  This is a subclass of  [educationAssignmentGradeType](educationassignmentgradetype.md)

This tells the assignment that it will be graded and stores the maximum number of points each student can achieve on this work item.  When this is set on an assignment, each submission will get
a [educationAssignmentPointsGrade](educationassignmentpointsgrade.md) property associated with it for the storage of each students points.

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|maxPoints|Single| Max points possible for this assignment.  |

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationAssignmentPointsGradeType"
}-->

```json
{
  "maxPoints": "Single"
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationAssignmentPointsGradeType resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->