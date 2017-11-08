# educationRoot resource type


The `/education` namespace exposes special functionality specific to the education sector. 
Some of these objects can be found in other parts of the Graph (users for instance),
but the education namespace will provide education-specific properties and features on these objects.

## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Create educationClass](../api/educationroot_post_classes.md) |[educationClass](educationclass.md)| Create a new educationClass by posting to the classes collection.|
|[List classes](../api/educationroot_list_classes.md) |[educationClass](educationclass.md) collection| Get a educationClass object collection.|
|[Create educationSchool](../api/educationroot_post_schools.md) |[educationSchool](educationschool.md)| Create a new educationSchool by posting to the schools collection.|
|[List schools](../api/educationroot_list_schools.md) |[educationSchool](educationschool.md) collection| Get a educationSchool object collection.|
|[Create educationUser](../api/educationroot_post_users.md) |[educationUser](educationuser.md)| Create a new educationUser by posting to the users collection.|
|[List users](../api/educationroot_list_users.md) |[educationUser](educationuser.md) collection| Get a educationUser object collection.|

## Properties
None

## Relationships
| Relationship | Type	|Description|
|:---------------|:--------|:----------|
|classes|[educationClass](educationclass.md) collection| Read-only. Nullable.|
|me|[educationUser](educationuser.md)| Read-only. Nullable.|
|schools|[educationSchool](educationschool.md) collection| Read-only. Nullable.|
|users|[educationUser](educationuser.md) collection| Read-only. Nullable.|

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationRoot resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->