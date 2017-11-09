# educationOneNoteResource resource type

A subclass of [educationResource](educationresource.md). This represents the location of the OneNote page.  

<!-- Will this issue be resolved when you publish the APIs to beta? If not, please see the guidance for documenting Known issues, here: https://microsoft.sharepoint.com/teams/OfficeDeveloperEducation/DevEdWiki/Microsoft%20Graph%20known%20issues%20guidelines.aspx.
-->

>**Important:** This API currently uses a different syntax. This will be 
replaced by the representation (single property).

## Properties
| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|pageUrl|String|The Microsoft Graph URL to the page in OneNote.|
|sectionName|String|Section name that distributions should be copied into or were copied into.|

## JSON representation

The following is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationOneNoteResource"
}-->

```json
{
  "pageUrl": "String",
  "sectionName": "String"
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationOneNoteResource resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->
