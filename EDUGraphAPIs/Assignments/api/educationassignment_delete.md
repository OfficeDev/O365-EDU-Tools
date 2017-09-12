# Delete educationAssignment

Use this API to delete an existing Assignment.  No request body is necessary.  Only Teachers within a Class can delete Assignments.

## Permissions
One of the following permissions is required to call this API. To learn more, including how to choose permissions, see [Permissions](../../../concepts/permissions_reference.md).

|Permission type      | Permissions (from least to most privileged)              |
|:--------------------|:---------------------------------------------------------|
|Delegated (work or school account)| EduAssignments.ReadWriteBasic, EduAssignments.ReadWrite |
|Delegated (personal Microsoft account) |   Not Supported. |
|Application | Not Supported.  | 

## HTTP request
<!-- { "blockType": "ignored" } -->
```http
DELETE /education/classes/<id>/assignments/<id>

```
## Request headers
| Header       | Value |
|:---------------|:--------|
| Authorization  | Bearer {token}. Required.  |

## Request body
Do not supply a request body for this method.


## Response
If successful, this method returns `204, No Content` response code. It does not return anything in the response body.

## Example
##### Request
Here is an example of the request.
<!-- {
  "blockType": "request",
  "name": "delete_educationassignment"
}-->
```http
DELETE https://graph.microsoft.com/beta/education/classes/<id>/assignments/<id>
```
##### Response
Here is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.
<!-- {
  "blockType": "response",
  "truncated": true
} -->
```http
HTTP/1.1 204 No Content
```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "Delete educationAssignment",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->