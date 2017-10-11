# Pause sync on an active synchronization profile

Pause sync of a specific [synchronization profile](..\resources\synchronizationProfile.md) in the tenant.

## Prerequisites
The following **scopes** are required to execute this API: **EduAdministration.ReadWrite**

## HTTP request
<!-- { "blockType": "ignored" } -->
```http
POST /synchronizationProfiles/{id}/pause
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
  "name": "post_synchronizationProfile_pause"
}-->
```http
POST https://graph.microsoft.com/testEduApi/education/synchronizationProfiles/{id}/pause
```

##### Response

There is no response body.