# educationClass resource type

Represents a class within a school.  educationClass corresponds one-to-one with Office Group and shares the same id.
Students are modeled as regular members of the class, while teachers are modeled as owners and have appropriate rights.  
For correct operation of Office experiences, teachers must be members of both the teachers and members collections.  


## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationClass](../api/educationclass_get.md) | [educationClass](educationclass.md) |Read properties and relationships of educationClass object.|
|[Add member](../api/educationclass_post_members.md) |[educationUser](educationuser.md)| Add a new educationUser for the class by posting to the members navigation property.|
|[List members](../api/educationclass_list_members.md) |[educationUser](educationuser.md) collection| Get a educationUser object collection.|
|[Remove member](../api/educationclass_delete_members.md) |[educationUser](educationuser.md)| Remove an educationUser from the class through the members navigation property.|
|[List schools](../api/educationclass_list_schools.md) |[educationSchool](educationschool.md) collection| Get a educationSchool object collection.|
|[Add teacher](../api/educationclass_post_teachers.md) |[educationUser](educationuser.md)| Add a new educationUser for the class by posting to the teachers navigation property.|
|[List teachers](../api/educationclass_list_teachers.md) |[educationUser](educationuser.md) collection| Get a list of teachers for the class.|
|[Remove teacher](../api/educationclass_delete_teachers.md) |[educationUser](educationuser.md)| Remove an educationUser from the class through the teachers navigation property.|
|[Create educationAssignment](../../Assignments/api/educationclass_post_assignments.md) |[educationAssignment](../../Assignments/resources/educationassignment.md)| Create a new educationAssignment by posting to the assignments collection.|
|[List assignments](../../Assignments/api/educationclass_list_assignments.md) |[educationAssignment](../../Assignments/resources/educationassignment.md) collection| Get a educationAssignment object collection.|
|[Update](../api/educationclass_update.md) | [educationClass](educationclass.md)	|Update educationClass object. |
|[Delete](../api/educationclass_delete.md) | None |Delete educationClass object. |

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|id| String| Unique identifier for the class|
|description|String| Description of the class|
|displayName|String| Name of the class|
|mailNickname|String| Mail name for sending email to all members, if this is enabled. |
|createdBy|[identitySet](identityset.md)| Entity who created the class |
|classCode|String| Class Code used by the school to identify the class.|
|externalId|String| ID of the class from the syncing system. |
|externalName|String|Name of the class in the syncing system.|
|externalSource|string| How this class was created.  Possible values are: `sis`, `manual`, `unknownFutureValue`.|
|term|[educationTerm](educationterm.md)|Term for this class.|


## Relationships
| Relationship | Type	|Description|
|:---------------|:--------|:----------|
|members|[educationUser](educationuser.md) collection| All users in the class. Nullable.|
|schools|[educationSchool](educationschool.md) collection| All schools this class is associated with. Nullable.|
|teachers|[educationUser](educationuser.md) collection|  All teachers in the class.  Nullable.|
|assignments|[educationAssignment](../../Assignments/resources/educationassignment.md) collection| All assignments associated with this class. Nullable.|

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationClass"
}-->

```json
{
  "id": "String",
  "description": "String",
  "classCode": "String",
  "createdBy": {"@odata.type": "microsoft.graph.identitySet"},
  "displayName": "String",
  "externalId": "String",
  "externalName": "String",
  "externalSource": "string",
  "mailNickname": "String",
  "term": {"@odata.type": "microsoft.graph.education.term"}
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationClass resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->