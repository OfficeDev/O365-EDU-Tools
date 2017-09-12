# educationClass resource type




## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationClass](../api/educationclass_get.md) | [educationClass](educationclass.md) |Read properties and relationships of educationClass object.|
|[Create educationUser](../api/educationclass_post_members.md) |[educationUser](educationuser.md)| Create a new educationUser by posting to the members collection.|
|[List members](../api/educationclass_list_members.md) |[educationUser](educationuser.md) collection| Get a educationUser object collection.|
|[Create educationSchool](../api/educationclass_post_schools.md) |[educationSchool](educationschool.md)| Create a new educationSchool by posting to the schools collection.|
|[List schools](../api/educationclass_list_schools.md) |[educationSchool](educationschool.md) collection| Get a educationSchool object collection.|
|[Create educationUser](../api/educationclass_post_teachers.md) |[educationUser](educationuser.md)| Create a new educationUser by posting to the teachers collection.|
|[List teachers](../api/educationclass_list_teachers.md) |[educationUser](educationuser.md) collection| Get a educationUser object collection.|
|[Update](../api/educationclass_update.md) | [educationClass](educationclass.md)	|Update educationClass object. |
|[Delete](../api/educationclass_delete.md) | None |Delete educationClass object. |

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|classNumber|String||
|createdBy|[identitySet](identityset.md)||
|createdBy.application.displayName|String||
|createdBy.application.id|String||
|createdBy.user.displayName|String||
|createdBy.user.id|String||
|description|String||
|displayName|String||
|externalId|String||
|externalName|String||
|externalSource|string| Possible values are: `sis`, `manual`, `enum_sentinel`.|
|mailNickname|String||
|period|String||

## Relationships
| Relationship | Type	|Description|
|:---------------|:--------|:----------|
|members|[educationUser](educationuser.md) collection| Read-only. Nullable.|
|schools|[educationSchool](educationschool.md) collection| Read-only. Nullable.|
|teachers|[educationUser](educationuser.md) collection| Read-only. Nullable.|

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
  "classNumber": "String",
  "createdBy": {"@odata.type": "microsoft.graph.identitySet"},
  "createdBy.application.displayName": "String",
  "createdBy.application.id": "String",
  "createdBy.user.displayName": "String",
  "createdBy.user.id": "String",
  "description": "String",
  "displayName": "String",
  "externalId": "String",
  "externalName": "String",
  "externalSource": "string",
  "mailNickname": "String",
  "period": "String"
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