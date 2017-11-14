# Create educationUser

Create a new user.

<!-- Add some additional text to better distinguish this method from the user_post_users (https://developer.microsoft.com/en-us/graph/docs/api-reference/v1.0/api/user_post_users) topic. -->

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
POST /education/users
```
## Request headers
| Header       | Value |
|:---------------|:--------|
| Authorization  | Bearer {token}. Required.  |
| Content-Type  | application/json  |

## Request body
In the request body, supply a JSON representation of an [educationUser](../resources/educationuser.md) object.


## Response
If successful, this method returns a `201 Created` response code and an [educationUser](../resources/educationuser.md) object in the response body.

## Example
##### Request
The following is an example of the request.
<!-- {
  "blockType": "request",
  "name": "create_educationuser_from_educationroot"
}-->
```http
POST https://graph.microsoft.com/beta/education/users
Content-type: application/json
Content-length: 508

{
  "displayName": "string",
  "givenName": "string",
  "middleName": "string",
  "surname": "string",
  "mail": "string",
  "mobilePhone": "string",
  "createdBy": {"@odata.type": "microsoft.graph.identitySet"},
  "externalSource": "string",
  "mailingAddress": {"@odata.type": "microsoft.graph.physicalAddress"},
  "primaryRole": "string",
  "residenceAddress": {"@odata.type": "microsoft.graph.physicalAddress"},
  "student": {"@odata.type": "microsoft.graph.educationStudent"},
}
```

##### Response
The following is an example of the response. 

>**Note:** The response object shown here might be shortened for readability. All the properties will be returned from an actual call.

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
  "id": "string",
  "displayName": "string",
  "givenName": "string",
  "middleName": "string",
  "surname": "string",
  "mail": "string",
  "mobilePhone": "string",
  "createdBy": {"@odata.type": "microsoft.graph.identitySet"},
  "externalSource": "string",
  "mailingAddress": {"@odata.type": "microsoft.graph.physicalAddress"},
  "primaryRole": "string",
  "residenceAddress": {"@odata.type": "microsoft.graph.physicalAddress"},
  "student": {"@odata.type": "microsoft.graph.educationStudent"},
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