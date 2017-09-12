# educationUser resource type




## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationUser](../api/educationuser_get.md) | [educationUser](educationuser.md) |Read properties and relationships of educationUser object.|
|[Create educationClass](../api/educationuser_post_classes.md) |[educationClass](educationclass.md)| Create a new educationClass by posting to the classes collection.|
|[List classes](../api/educationuser_list_classes.md) |[educationClass](educationclass.md) collection| Get a educationClass object collection.|
|[Create educationSchool](../api/educationuser_post_schools.md) |[educationSchool](educationschool.md)| Create a new educationSchool by posting to the schools collection.|
|[List schools](../api/educationuser_list_schools.md) |[educationSchool](educationschool.md) collection| Get a educationSchool object collection.|
|[Update](../api/educationuser_update.md) | [educationUser](educationuser.md)	|Update educationUser object. |
|[Delete](../api/educationuser_delete.md) | None |Delete educationUser object. |

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|createdBy|[identitySet](identityset.md)||
|createdBy.application.displayName|String||
|createdBy.application.id|String||
|createdBy.user.displayName|String||
|createdBy.user.id|String||
|externalSource|string| Possible values are: `sis`, `manual`, `enum_sentinel`.|
|mailingAddress|[physicalAddress](physicaladdress.md)||
|mailingAddress.city|String||
|mailingAddress.countryOrRegion|String||
|mailingAddress.postalCode|String||
|mailingAddress.state|String||
|mailingAddress.street|String||
|middleName|String||
|primaryRole|string| Possible values are: `student`, `teacher`, `enum_sentinel`.|
|residenceAddress|[physicalAddress](physicaladdress.md)||
|residenceAddress.city|String||
|residenceAddress.countryOrRegion|String||
|residenceAddress.postalCode|String||
|residenceAddress.state|String||
|residenceAddress.street|String||
|student|[educationStudent](educationstudent.md)||
|teacher|[educationTeacher](educationteacher.md)||

## Relationships
| Relationship | Type	|Description|
|:---------------|:--------|:----------|
|classes|[educationClass](educationclass.md) collection| Read-only. Nullable.|
|schools|[educationSchool](educationschool.md) collection| Read-only. Nullable.|

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationUser"
}-->

```json
{
  "createdBy": {"@odata.type": "microsoft.graph.identitySet"},
  "createdBy.application.displayName": "String",
  "createdBy.application.id": "String",
  "createdBy.user.displayName": "String",
  "createdBy.user.id": "String",
  "externalSource": "string",
  "mailingAddress": {"@odata.type": "microsoft.graph.physicalAddress"},
  "mailingAddress.city": "String",
  "mailingAddress.countryOrRegion": "String",
  "mailingAddress.postalCode": "String",
  "mailingAddress.state": "String",
  "mailingAddress.street": "String",
  "middleName": "String",
  "primaryRole": "string",
  "residenceAddress": {"@odata.type": "microsoft.graph.physicalAddress"},
  "residenceAddress.city": "String",
  "residenceAddress.countryOrRegion": "String",
  "residenceAddress.postalCode": "String",
  "residenceAddress.state": "String",
  "residenceAddress.street": "String",
  "student": {"@odata.type": "microsoft.graph.educationStudent"},
  "teacher": {"@odata.type": "microsoft.graph.educationTeacher"}
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationUser resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->