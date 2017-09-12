# educationAssignment resource type




## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationAssignment](../api/educationassignment_get.md) | [educationAssignment](educationassignment.md) |Read properties and relationships of educationAssignment object.|
|[Create educationAssignmentResource](../api/educationassignment_post_resources.md) |[educationAssignmentResource](educationassignmentresource.md)| Create a new educationAssignmentResource by posting to the resources collection.|
|[List resources](../api/educationassignment_list_resources.md) |[educationAssignmentResource](educationassignmentresource.md) collection| Get a educationAssignmentResource object collection.|
|[Create educationSubmission](../api/educationassignment_post_submissions.md) |[educationSubmission](educationsubmission.md)| Create a new educationSubmission by posting to the submissions collection.|
|[List submissions](../api/educationassignment_list_submissions.md) |[educationSubmission](educationsubmission.md) collection| Get a educationSubmission object collection.|
|[Update](../api/educationassignment_update.md) | [educationAssignment](educationassignment.md)	|Update educationAssignment object. |
|[Delete](../api/educationassignment_delete.md) | None |Delete educationAssignment object. |
|[Publish](../api/educationassignment_publish.md)|[educationAssignment](educationassignment.md)||

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|allowLateSubmissions|Boolean||
|allowStudentsToAddResourcesToSubmission|Boolean||
|assignDateTime|DateTimeOffset|The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|
|assignTo|[educationAssignmentRecipient](educationassignmentrecipient.md)||
|assignedDateTime|DateTimeOffset|The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|
|classId|String||
|createdBy|[identitySet](identityset.md)||
|createdDateTime|DateTimeOffset|The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|
|displayName|String||
|dueDateTime|DateTimeOffset|The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|
|grading|[educationAssignmentGradeType](educationassignmentgradetype.md)||
|id|String| Read-only.|
|instructions|[itemBody](itembody.md)||
|lastModifiedBy|[identitySet](identityset.md)||
|lastModifiedDateTime|DateTimeOffset|The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|
|resourcesFolder|[educationODataRef](educationodataref.md)||
|status|string| Possible values are: `draft`, `published`, `assigned`.|

## Relationships
| Relationship | Type	|Description|
|:---------------|:--------|:----------|
|resources|[educationAssignmentResource](educationassignmentresource.md) collection| Read-only. Nullable.|
|submissions|[educationSubmission](educationsubmission.md) collection| Read-only. Nullable.|

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
  "id": "String (identifier)",
  "instructions": {"@odata.type": "microsoft.graph.itemBody"},
  "lastModifiedBy": {"@odata.type": "microsoft.graph.identitySet"},
  "lastModifiedDateTime": "String (timestamp)",
  "resourcesFolder": {"@odata.type": "microsoft.graph.educationODataRef"},
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