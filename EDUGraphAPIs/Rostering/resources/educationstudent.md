# educationStudent resource type




## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|birthDate|Date||
|externalId|String||
|gender|String| Possible values are: `female`, `male`, `other`, `enum_sentinel`.|
|grade|String||
|graduationYear|String||
|studentNumber|String||

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationStudent"
}-->

```json
{
  "birthDate": "String (timestamp)",
  "externalId": "String",
  "gender": "String",
  "grade": "String",
  "graduationYear": "String",
  "studentNumber": "String"
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationStudent resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->