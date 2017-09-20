# educationClass resource type

A class.  Class is a cover on top of a Universal Group.  Students are modeled as regular users while teachers are modeled as admins for the group.  


## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationClass](../api/educationclass_get.md) | [educationClass](educationclass.md) |Read properties and relationships of educationClass object.|
|[Create educationUser](../api/educationclass_post_members.md) |[educationUser](educationuser.md)| Add a new educationUser to the class.|
|[List members](../api/educationclass_list_members.md) |[educationUser](educationuser.md) collection| Get a educationUser object collection.|
|[List schools](../api/educationclass_list_schools.md) |[educationSchool](educationschool.md) collection| Get a educationSchool object collection.|
|[Create educationUser](../api/educationclass_post_teachers.md) |[educationUser](educationuser.md)| Add a new educationUser by posting to the teachers collection.|
|[List teachers](../api/educationclass_list_teachers.md) |[educationUser](educationuser.md) collection| Get a list of teachers for the class.|
|[Create educationAssignment](../../Assignments/api/educationclass_post_assignments.md) |[educationAssignment](../../Assignments/resources/educationassignment.md)| Create a new educationAssignment by posting to the assignments collection.|
|[List assignments](../../Assignments/api/educationclass_list_assignments.md) |[educationAssignment](../../Assignments/resources/educationassignment.md) collection| Get a educationAssignment object collection.|
|[Update](../api/educationclass_update.md) | [educationClass](educationclass.md)	|Update educationClass object. |
|[Delete](../api/educationclass_delete.md) | None |Delete educationClass object. |

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|id| String| GUID for the class|
|description|String| Description of the class|
|displayName|String| Name of the Class|
|mailNickname|String| Mail name for sending email to all users if this is enabled. |
|createdBy|[identitySet](identityset.md)| Entity who created the group |
|classCode|String| Class Code used by the school.|
|externalId|String| ID of the class from the syncing system. |
|externalName|String|Name of the class in the syncing system.|
|externalSource|string| How this class was creaeted.  Possible values are: `sis`, `manual`, `enum_sentinel`.|


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
  "classCode": "String",
  "createdBy": {"@odata.type": "microsoft.graph.identitySet"},
  "description": "String",
  "displayName": "String",
  "externalId": "String",
  "externalName": "String",
  "externalSource": "string",
  "mailNickname": "String"
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