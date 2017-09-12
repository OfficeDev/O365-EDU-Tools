# educationSchool resource type




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
|address|[physicalAddress](physicaladdress.md)||
|address.city|String||
|address.countryOrRegion|String||
|address.postalCode|String||
|address.state|String||
|address.street|String||
|createdBy|[identitySet](identityset.md)||
|createdBy.application.displayName|String||
|createdBy.application.id|String||
|createdBy.user.displayName|String||
|createdBy.user.id|String||
|externalId|String||
|externalSchoolPrincipalId|String||
|fax|String||
|highestGrade|String||
|lowestGrade|String||
|phone|String||
|schoolNumber|String||
|schoolPrincipalEmail|String||
|schoolPrincipalName|String||
|schoolZone|String||

## Relationships
| Relationship | Type	|Description|
|:---------------|:--------|:----------|
|classes|[educationClass](educationclass.md) collection| Read-only. Nullable.|
|users|[educationUser](educationuser.md) collection| Read-only. Nullable.|

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
  "address": {"@odata.type": "microsoft.graph.physicalAddress"},
  "address.city": "String",
  "address.countryOrRegion": "String",
  "address.postalCode": "String",
  "address.state": "String",
  "address.street": "String",
  "createdBy": {"@odata.type": "microsoft.graph.identitySet"},
  "createdBy.application.displayName": "String",
  "createdBy.application.id": "String",
  "createdBy.user.displayName": "String",
  "createdBy.user.id": "String",
  "externalId": "String",
  "externalSchoolPrincipalId": "String",
  "fax": "String",
  "highestGrade": "String",
  "lowestGrade": "String",
  "phone": "String",
  "schoolNumber": "String",
  "schoolPrincipalEmail": "String",
  "schoolPrincipalName": "String",
  "schoolZone": "String"
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