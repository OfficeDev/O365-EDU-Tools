# Create educationAssignmentResource

Create an assignment resource. The **Assignment** resource is a wrapper around the resource that the teacher wants to add to the assignment with the "distributeForStudentWork" flag which indicates whether this resource should be automatically copied to each student's submission during the assignment process. Items which indicate distribution will be the basis for work that each student should modify to complete the assignment. The resource itself has an @odata.type to indicate which type of resource is being created.  Note that file based resources must first be uploaded to the assignments "resourceFolder"

## Permissions
One of the following permissions is required to call this API. To learn more, including how to choose permissions, see [Permissions](../../../concepts/permissions_reference.md).

|Permission type      | Permissions (from least to most privileged)              |
|:--------------------|:---------------------------------------------------------|
|Delegated (work or school account) |  EduAssignments.ReadWriteBasic, EduAssignments.ReadWrite  |
|Delegated (personal Microsoft account) |  Not supported.  |
|Application | Not supported.  | 

## HTTP request
<!-- { "blockType": "ignored" } -->
```http
POST /education/classes/<id>/assignments/<id>/resources
```
## Request headers
| Header       | Value |
|:---------------|:--------|
| Authorization  | Bearer {token}. Required.  |
| Content-Type  | application/json  |

## Request body
In the request body, supply a JSON representation of [educationAssignmentResource](../resources/educationassignmentresource.md) object.


## Response
If successful, this method returns `201, Created` response code and [educationAssignmentResource](../resources/educationassignmentresource.md) object in the response body.

## Example
##### Request
Here is an example of the request.
<!-- {
  "blockType": "request",
  "name": "create_educationassignmentresource_from_educationassignment"
}-->
```http
POST https://graph.microsoft.com/beta/education/classes/<id>/assignments/<id>/resources
Content-type: application/json
Content-length: 822

{
  "distributeForStudentWork": false,
  "resource": {
    "displayName": "Bing",
    "link": "https://www.bing.com",
    "@odata.type": "#microsoft.education.assignments.api.educationLinkResource"
  }
}
```
In the request body, supply a JSON representation of [educationAssignmentResource](../resources/educationassignmentresource.md) object.
##### Response
Here is an example of the response. 

>**Note:** The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.

```http
<!-- {
  "blockType": "response",
  "truncated": true,
  "@odata.type": "microsoft.graph.educationAssignmentResource"
} -->

HTTP/1.1 201 Created
Content-type: application/json
Content-length: 842

{
  "id": "String (identifier)",
  "distributeForStudentWork": false,
  "resource": {
    "displayName": "Bing",
    "link": "https://www.bing.com",
    "@odata.type": "#microsoft.education.assignments.api.educationLinkResource"
  }
}


<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "Create educationAssignmentResource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->
```