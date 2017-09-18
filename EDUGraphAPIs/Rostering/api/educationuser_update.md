# Update educationuser

Update the properties of educationuser object.
## Permissions
One of the following permissions is required to call this API. To learn more, including how to choose permissions, see [Permissions](../../../concepts/permissions_reference.md).

|Permission type      | Permissions (from least to most privileged)              |
|:--------------------|:---------------------------------------------------------|
|Delegated (work or school account) |  Not supported.  |
|Delegated (personal Microsoft account) |  Not supported.  |
|Application | EduRoster.ReadWrite.All |

## HTTP request
<!-- { "blockType": "ignored" } -->
```http
PATCH /education/me
PATCH /education/users/<id>
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
|createdBy|identitySet||
|createdBy.application.displayName|String||
|createdBy.application.id|String||
|createdBy.user.displayName|String||
|createdBy.user.id|String||
|externalSource|string| Possible values are: `sis`, `manual`, `enum_sentinel`.|
|mailingAddress|physicalAddress||
|mailingAddress.city|String||
|mailingAddress.countryOrRegion|String||
|mailingAddress.postalCode|String||
|mailingAddress.state|String||
|mailingAddress.street|String||
|middleName|String||
|primaryRole|string| Possible values are: `student`, `teacher`, `enum_sentinel`.|
|residenceAddress|physicalAddress||
|residenceAddress.city|String||
|residenceAddress.countryOrRegion|String||
|residenceAddress.postalCode|String||
|residenceAddress.state|String||
|residenceAddress.street|String||
|student|educationStudent||
|teacher|educationTeacher||

## Response
If successful, this method returns a `200 OK` response code and updated [educationUser](../resources/educationuser.md) object in the response body.
## Example
##### Request
Here is an example of the request.
<!-- {
  "blockType": "request",
  "name": "update_educationuser"
}-->
```http
PATCH https://graph.microsoft.com/beta/education/me
Content-type: application/json
Content-length: 508

{
  "primaryRole": "primaryRole-value",
  "middleName": "middleName-value",
  "externalSource": "externalSource-value",
  "residenceAddress": {
    "type": "type-value",
    "postOfficeBox": "postOfficeBox-value",
    "street": "street-value",
    "city": "city-value",
    "state": "state-value",
    "countryOrRegion": "countryOrRegion-value",
    "postalCode": "postalCode-value"
  },
  "residenceAddress.street": "residenceAddress.street-value",
  "residenceAddress.city": "residenceAddress.city-value"
}
```
##### Response
Here is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.
<!-- {
  "blockType": "response",
  "truncated": true,
  "@odata.type": "microsoft.graph.educationUser"
} -->
```http
HTTP/1.1 200 OK
Content-type: application/json
Content-length: 508

{
  "primaryRole": "primaryRole-value",
  "middleName": "middleName-value",
  "externalSource": "externalSource-value",
  "residenceAddress": {
    "type": "type-value",
    "postOfficeBox": "postOfficeBox-value",
    "street": "street-value",
    "city": "city-value",
    "state": "state-value",
    "countryOrRegion": "countryOrRegion-value",
    "postalCode": "postalCode-value"
  },
  "residenceAddress.street": "residenceAddress.street-value",
  "residenceAddress.city": "residenceAddress.city-value"
}
```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "Update educationuser",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->