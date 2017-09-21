# educationOrganization resource type


Abstract Class used to model different organizations found on a school.

## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationOrganization](../api/educationorganization_get.md) | [educationOrganization](educationorganization.md) |Read properties and relationships of educationOrganization object.|
|[Update](../api/educationorganization_update.md) | [educationOrganization](educationorganization.md)	|Update educationOrganization object. |
|[Delete](../api/educationorganization_delete.md) | None |Delete educationOrganization object. |

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|description|String| Organization description|
|displayName|String| Organization display name|
|externalSource|string| Source where this organization was created from.  Possible values are: `sis`, `manual`, `enum_sentinel`.|

## Relationships
None


## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationOrganization"
}-->

```json
{
  "description": "String",
  "displayName": "String",
  "externalSource": "string"
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationOrganization resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->