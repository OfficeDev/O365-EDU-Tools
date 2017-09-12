# educationSubmission resource type




## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationSubmission](../api/educationsubmission_get.md) | [educationSubmission](educationsubmission.md) |Read properties and relationships of educationSubmission object.|
|[Create educationSubmissionResource](../api/educationsubmission_post_resources.md) |[educationSubmissionResource](educationsubmissionresource.md)| Create a new educationSubmissionResource by posting to the resources collection.|
|[List resources](../api/educationsubmission_list_resources.md) |[educationSubmissionResource](educationsubmissionresource.md) collection| Get a educationSubmissionResource object collection.|
|[Create educationSubmittedSubmissionResource](../api/educationsubmission_post_submittedresources.md) |[educationSubmittedSubmissionResource](educationsubmittedsubmissionresource.md)| Create a new educationSubmittedSubmissionResource by posting to the submittedResources collection.|
|[List submittedResources](../api/educationsubmission_list_submittedresources.md) |[educationSubmittedSubmissionResource](educationsubmittedsubmissionresource.md) collection| Get a educationSubmittedSubmissionResource object collection.|
|[Update](../api/educationsubmission_update.md) | [educationSubmission](educationsubmission.md)	|Update educationSubmission object. |
|[Delete](../api/educationsubmission_delete.md) | None |Delete educationSubmission object. |
|[Recall](../api/educationsubmission_recall.md)|[educationSubmission](educationsubmission.md)||
|[Release](../api/educationsubmission_release.md)|[educationSubmission](educationsubmission.md)||
|[Submit](../api/educationsubmission_submit.md)|[educationSubmission](educationsubmission.md)||

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|feedback|[educationFeedback](educationfeedback.md)||
|grade|[educationAssignmentGrade](educationassignmentgrade.md)||
|id|String| Read-only.|
|recipient|[educationSubmissionRecipient](educationsubmissionrecipient.md)||
|releasedBy|[identitySet](identityset.md)||
|releasedDateTime|DateTimeOffset|The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|
|resourcesFolder|[educationODataRef](educationodataref.md)||
|status|string| Possible values are: `working`, `submitted`, `completed`.|
|submittedBy|[identitySet](identityset.md)||
|submittedDateTime|DateTimeOffset|The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|

## Relationships
| Relationship | Type	|Description|
|:---------------|:--------|:----------|
|resources|[educationSubmissionResource](educationsubmissionresource.md) collection| Read-only. Nullable.|
|submittedResources|[educationSubmittedSubmissionResource](educationsubmittedsubmissionresource.md) collection| Read-only. Nullable.|

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationSubmission"
}-->

```json
{
  "feedback": {"@odata.type": "microsoft.graph.educationFeedback"},
  "grade": {"@odata.type": "microsoft.graph.educationAssignmentGrade"},
  "id": "String (identifier)",
  "recipient": {"@odata.type": "microsoft.graph.educationSubmissionRecipient"},
  "releasedBy": {"@odata.type": "microsoft.graph.identitySet"},
  "releasedDateTime": "String (timestamp)",
  "resourcesFolder": {"@odata.type": "microsoft.graph.educationODataRef"},
  "status": "string",
  "submittedBy": {"@odata.type": "microsoft.graph.identitySet"},
  "submittedDateTime": "String (timestamp)"
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationSubmission resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->