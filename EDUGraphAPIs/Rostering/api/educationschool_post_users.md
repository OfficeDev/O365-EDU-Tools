# Create educationUser

Add a user to a school.

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
POST /education/schools/<id>/users
```
## Request headers
| Header       | Value |
|:---------------|:--------|
| Authorization  | Bearer {token}. Required.  |
| Content-Type  | application/json  |

## Request body
In the request body, supply a JSON representation of [educationUser](../resources/educationuser.md) object.


## Response
If successful, this method returns `201, Created` response code and [educationUser](../resources/educationuser.md) object in the response body.

## Example
##### Request
Here is an example of the request.
<!-- {
  "blockType": "request",
  "name": "create_educationuser_from_educationschool"
}-->
```http
POST https://graph.microsoft.com/beta/education/schools/<id>/users
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
In the request body, supply a JSON representation of [educationUser](../resources/educationuser.md) object.
##### Response
Here is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.
<!-- {
  "blockType": "response",
  "truncated": true,
  "@odata.type": "microsoft.graph.educationUser"
} -->
```http
HTTP/1.1 201 Created
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
  "description": "Create educationUser",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->