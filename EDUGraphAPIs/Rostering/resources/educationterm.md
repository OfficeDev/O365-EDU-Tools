# educationTerm resource type

A Term. This represents a designated portion of the academic year. It is used within [educationClass](educationclass.md).

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|displayName| String| Display name of the term| 
|externalId|String| Id of term in syncing system. |
|startDate|Date|Start of a Term.|
|endDate|Date|End of a Term.

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationTerm"
}-->

```json
{
  "displayName": "String",
  "externalId": "String",
  "startDate": "Date",
  "endDate": "Date"
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