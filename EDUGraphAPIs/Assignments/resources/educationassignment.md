# educationAssignment resource type

Assignment is the core object of the Assignments API.  Assignments are owned by a class and thus
most of the APIs are done within the class namespace.  Only a teacher in a class can create an assignment.
Assignment starts in the "Draft" state when created.  In draft, students will not see the assignment and submissions will not be created.
The status on an assignment cannot be changed via PATCH, the status is changed by using the action.  



## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationAssignment](../api/educationassignment_get.md) | [educationAssignment](educationassignment.md) |Read properties and relationships of educationAssignment object.|
|[Create educationAssignmentResource](../api/educationassignment_post_resources.md) |[educationAssignmentResource](educationassignmentresource.md)| Create a new educationAssignmentResource by posting to the resources collection.|
|[List resources](../api/educationassignment_list_resources.md) |[educationAssignmentResource](educationassignmentresource.md) collection| Get a educationAssignmentResource object collection.|
|[List submissions](../api/educationassignment_list_submissions.md) |[educationSubmission](educationsubmission.md) collection| Get a educationSubmission object collection.|
|[Update](../api/educationassignment_update.md) | [educationAssignment](educationassignment.md)	|Update educationAssignment object. |
|[Delete](../api/educationassignment_delete.md) | None |Delete educationAssignment object. |
|[Publish](../api/educationassignment_publish.md)|[educationAssignment](educationassignment.md)||

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|id|String| Read-only.|
|allowLateSubmissions|Boolean| Identifies whether students can submit after the due date. |
|allowStudentsToAddResourcesToSubmission|Boolean| Identifies whether students can add their own resources to a submission or if they can only modify resources added by the teacher. |
|assignDateTime|DateTimeOffset|The date when the assignment should become active.  If in the future, the assignment is not shown to the student until this date.  The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|
|assignTo|[educationAssignmentRecipient](educationassignmentrecipient.md)| Which users, or whole class should receive a submission object once the assignment is published. |
|assignedDateTime|DateTimeOffset|The moment that the assignment was published to students and the assignment shows up on the students timeline.  The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|
|classId|String| Class which this assignment belongs. |
|createdBy|[identitySet](identityset.md)| Who created the assignment. |
|createdDateTime|DateTimeOffset|Moment when the assignment was created.  The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|
|displayName|String|Name of the assignment.|
|dueDateTime|DateTimeOffset|Date when the students assignment is due.  The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|
|grading|[educationAssignmentGradeType](educationassignmentgradetype.md)|How the assignment will be graded. |
|instructions|[itemBody](itembody.md)| Instructions for the assignment.  This along with the display name tell the student what to do. |
|lastModifiedBy|[identitySet](identityset.md)| Who last modified the assignment. |
|lastModifiedDateTime|DateTimeOffset|Moment when the assignment was last modified.  The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|
|resourcesFolderUrl|String| Folder into which file based resource should be put to be part of a assignmnet resource.  Files must live in this folder to be added as a resource.|
|status|string| Status of the Asssignment.  You can not PATCH this value.  Possible values are: `draft`, `published`, `assigned`.|

## Relationships
| Relationship | Type	|Description|
|:---------------|:--------|:----------|
|resources|[educationAssignmentResource](educationassignmentresource.md) collection| Learning objects that are associated with this assignment.  Only teachers can modify this list. Nullable.|
|submissions|[educationSubmission](educationsubmission.md) collection| Once published, there is a submission object for each student representing their work and grade.  Read-only. Nullable.|

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationAssignment"
}-->

```json
{
  "id": "String (identifier)",
  "allowLateSubmissions": true,
  "allowStudentsToAddResourcesToSubmission": true,
  "assignDateTime": "String (timestamp)",
  "assignTo": {"@odata.type": "microsoft.graph.educationAssignmentRecipient"},
  "assignedDateTime": "String (timestamp)",
  "classId": "String",
  "createdBy": {"@odata.type": "microsoft.graph.identitySet"},
  "createdDateTime": "String (timestamp)",
  "displayName": "String",
  "dueDateTime": "String (timestamp)",
  "grading": {"@odata.type": "microsoft.graph.educationAssignmentGradeType"},
  "instructions": {"@odata.type": "microsoft.graph.itemBody"},
  "lastModifiedBy": {"@odata.type": "microsoft.graph.identitySet"},
  "lastModifiedDateTime": "String (timestamp)",
  "resourcesFolderUrl": "String",
  "status": "string"
}
```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationAssignment resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->