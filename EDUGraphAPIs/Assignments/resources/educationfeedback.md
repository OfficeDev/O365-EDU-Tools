# educationFeedback resource type

Feedback from a teacher to a student. This property represents both the text part of the feedback along with the who.

<!-- Verify that this has been fixed, and delete this note.
>**Note:** Due to a bug, Microsoft Graph will return **educationItemBody** for the text property. This is a duplicate of the itemBody that 
is already found on the Microsoft Graph API. When the code moves to production, this behavior will be updated. For clients who use the JSON that's
sent back and forth to Microsoft Graph, there should be no work necessary to handle this change.
-->

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|feedbackBy|[identitySet](identityset.md)|User who created the feedback.|
|feedbackDateTime|DateTimeOffset|Moment in time when the feedback was given. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 would look like this: `'2014-01-01T00:00:00Z'`|
|text|[itemBody](itembody.md)|Feedback.|

## JSON representation

The following is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationFeedback"
}-->

```json
{
  "feedbackBy": {"@odata.type": "microsoft.graph.identitySet"},
  "feedbackDateTime": "String (timestamp)",
  "text": {"@odata.type": "microsoft.graph.itemBody"}
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationFeedback resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->