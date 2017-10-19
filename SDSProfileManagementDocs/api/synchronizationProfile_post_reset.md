# Reset sync on a synchronization profile

Reset sync of a specific [synchronization profile](..\resources\synchronizationProfile.md) in the tenant.

> **Note:** Reset will cause synchronization to re-start. Any errors encountered will be deleted. No data will be deleted from Azure Active Directory. 

## Prerequisites
The following **scopes** are required to execute this API: **EduAdministration.ReadWrite**

## HTTP request
<!-- { "blockType": "ignored" } -->
```http
POST /synchronizationProfiles/{id}/reset
```

## Request headers
| Name       | Type | Description|
|:-----------|:------|:----------|
| Authorization  | string  | Bearer {token}. Required.  |

## Request body
Do not supply a request body for this method.
## Response
If successful, this method returns a `200 OK` response code.

## Example
##### Request
Here is an example of the request.
<!-- {
  "blockType": "request",
  "name": "post_synchronizationProfile_reset"
}-->
```http
POST https://graph.microsoft.com/testEduApi/education/synchronizationProfiles/{id}/reset
```

##### Response

There is no response body.