# Update educationclass

Update the properties of a class.

## Permissions
One of the following permissions is required to call this API. To learn more, including how to choose permissions, see [Permissions](../../../concepts/permissions_reference.md).

|Permission type      | Permissions (from least to most privileged)              |
|:--------------------|:---------------------------------------------------------|
|Delegated (work or school account) |  Not supported.  |
|Delegated (personal Microsoft account) | Not supported.   |
|Application | EduRoster.ReadWrite.All | 

## HTTP request
<!-- { "blockType": "ignored" } -->
```http
PATCH /education/classes/<id>
```
## Request headers
| Header       | Value |
|:---------------|:--------|
| Authorization  | Bearer {token}. Required.  |
| Content-Type  | application/json  |

## Request body
In the request body, supply the values for relevant fields that should be updated. Existing properties that are not included in the request body will maintain their previous values or be recalculated based on changes to other property values. For best performance you shouldn't include existing values that haven't changed.

| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|classNumber|String||
|createdBy|identitySet||
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

## Response
If successful, this method returns a `200 OK` response code and updated [educationClass](../resources/educationclass.md) object in the response body.
## Example
##### Request
Here is an example of the request.
<!-- {
  "blockType": "request",
  "name": "update_educationclass"
}-->
```http
PATCH https://graph.microsoft.com/beta/education/classes/<id>
Content-type: application/json
Content-length: 224

{
  "displayName": "displayName-value",
  "description": "description-value",
  "mailNickname": "mailNickname-value",
  "period": "period-value",
  "classNumber": "classNumber-value",
  "externalName": "externalName-value"
}
```
##### Response
Here is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.
<!-- {
  "blockType": "response",
  "truncated": true,
  "@odata.type": "microsoft.graph.educationClass"
} -->
```http
HTTP/1.1 200 OK
Content-type: application/json
Content-length: 224

{
  "displayName": "displayName-value",
  "description": "description-value",
  "mailNickname": "mailNickname-value",
  "period": "period-value",
  "classNumber": "classNumber-value",
  "externalName": "externalName-value"
}
```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "Update educationclass",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->