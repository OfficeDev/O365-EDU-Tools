# Update educationschool

Update the properties of educationschool object.
## Permissions
One of the following permissions is required to call this API. To learn more, including how to choose permissions, see [Permissions](../../../concepts/permissions_reference.md).

|Permission type      | Permissions (from least to most privileged)              |
|:--------------------|:---------------------------------------------------------|
|Delegated (work or school account) |    |
|Delegated (personal Microsoft account) |    |
|Application |  | 

## HTTP request
<!-- { "blockType": "ignored" } -->
```http
PATCH /education/schools
PATCH /education/me/schools
PATCH /education/users/schools
```
## Optional request headers
| Name       | Description|
|:-----------|:-----------|
| Authorization  | Bearer {code}|

## Request body
In the request body, supply the values for relevant fields that should be updated. Existing properties that are not included in the request body will maintain their previous values or be recalculated based on changes to other property values. For best performance you shouldn't include existing values that haven't changed.

| Property	   | Type	|Description|
|:---------------|:--------|:----------|
|address|physicalAddress||
|address.city|String||
|address.countryOrRegion|String||
|address.postalCode|String||
|address.state|String||
|address.street|String||
|createdBy|identitySet||
|createdBy.application.displayName|String||
|createdBy.application.id|String||
|createdBy.user.displayName|String||
|createdBy.user.id|String||
|externalId|String||
|externalSchoolPrincipalId|String||
|fax|String||
|highestGrade|String||
|lowestGrade|String||
|phone|String||
|schoolNumber|String||
|schoolPrincipalEmail|String||
|schoolPrincipalName|String||
|schoolZone|String||

## Response
If successful, this method returns a `200 OK` response code and updated [educationSchool](../resources/educationschool.md) object in the response body.
## Example
##### Request
Here is an example of the request.
<!-- {
  "blockType": "request",
  "name": "update_educationschool"
}-->
```http
PATCH https://graph.microsoft.com/beta/education/schools
Content-type: application/json
Content-length: 292

{
  "schoolZone": "schoolZone-value",
  "schoolPrincipalEmail": "schoolPrincipalEmail-value",
  "schoolPrincipalName": "schoolPrincipalName-value",
  "externalSchoolPrincipalId": "externalSchoolPrincipalId-value",
  "lowestGrade": "lowestGrade-value",
  "highestGrade": "highestGrade-value"
}
```
##### Response
Here is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.
<!-- {
  "blockType": "response",
  "truncated": true,
  "@odata.type": "microsoft.graph.educationSchool"
} -->
```http
HTTP/1.1 200 OK
Content-type: application/json
Content-length: 292

{
  "schoolZone": "schoolZone-value",
  "schoolPrincipalEmail": "schoolPrincipalEmail-value",
  "schoolPrincipalName": "schoolPrincipalName-value",
  "externalSchoolPrincipalId": "externalSchoolPrincipalId-value",
  "lowestGrade": "lowestGrade-value",
  "highestGrade": "highestGrade-value"
}
```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "Update educationschool",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->