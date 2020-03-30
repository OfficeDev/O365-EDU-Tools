# educationTerm resource type

> **Important:** APIs under the /beta version in Microsoft Graph are in preview and are subject to change. Use of these APIs in production applications is not supported.

A term. This represents a designated portion of the academic year. It is used within [educationClass](educationclass.md).

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|displayName| String| Display name of the term.| 
|externalId|String| ID of term in the syncing system.|
|startDate|Date|Start of the term.|
|endDate|Date|End of the term.|

## JSON representation

The following is a JSON representation of the resource.

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

<!-- uuid: 4e9d671f-3068-4e09-aba2-b39e81a0e452
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationTerm resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->