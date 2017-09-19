# educationSchool resource type

A school.  Schools are Administrative Units underneath and can be found as them in the graph.  


## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationSchool](../api/educationschool_get.md) | [educationSchool](educationschool.md) |Read properties and relationships of educationSchool object.|
|[Create educationClass](../api/educationschool_post_classes.md) |[educationClass](educationclass.md)| Create a new educationClass by posting to the classes collection.|
|[List classes](../api/educationschool_list_classes.md) |[educationClass](educationclass.md) collection| Get a educationClass object collection.|
|[Create educationUser](../api/educationschool_post_users.md) |[educationUser](educationuser.md)| Create a new educationUser by posting to the users collection.|
|[List users](../api/educationschool_list_users.md) |[educationUser](educationuser.md) collection| Get a educationUser object collection.|
|[Update](../api/educationschool_update.md) | [educationSchool](educationschool.md)	|Update educationSchool object. |
|[Delete](../api/educationschool_delete.md) | None |Delete educationSchool object. |

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|id|String|GUID of this school.|
|displayName| String| Display name of the school| 
|description| String | Description of the school| 
|status| string| Read-Only.  Possible values are: `inactive`, `active`, `expired`, `deleteable`.|
|externalSource| string| Read-Only.  Possible values are: `sis`, `manual`, `enum_sentinel`.|
|principalEmail| String| Email address of the principal|
|principalName| String | Name of the principal|
|externalPrincipalId| String | Id of principal in syncing system. |
|highestGrade|String| Highest grade taught. |
|lowestGrade|String| Lowest grade taught. |
|schoolNumber|String| School Number.|
|externalId|String| Id of school in syncing system. |
|phone|String| Phone number of school. |
|fax|String| Fax number of school. |
|address|[physicalAddress](physicaladdress.md)| Address of the School.|
|createdBy|[identitySet](identityset.md)|Entity who created the school.|


## Relationships
| Relationship | Type	|Description|
|:---------------|:--------|:----------|
|classes|[educationClass](educationclass.md) collection| Classes taught at the school. Nullable.|
|users|[educationUser](educationuser.md) collection| Users of the school. Nullable.|

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationSchool"
}-->

```json
{
  "id": "String",
  "displayName": "String",
  "description": "String",
  "status": "String",
  "externalSource": "String",
  "principalEmail": "String",
  "principalName": "String",
  "externalPrincipalId": "String",
  "highestGrade": "String",
  "lowestGrade": "String",
  "schoolNumber": "String",
  "address": {"@odata.type": "microsoft.graph.physicalAddress"},
  "createdBy": {"@odata.type": "microsoft.graph.identitySet"},
  "externalId": "String",
  "fax": "String",
  "phone": "String",
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationSchool resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->