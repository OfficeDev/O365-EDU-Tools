# Get the status of a synchronization profile

Get the status of a specific [synchronization profile](../resources/educationsynchronizationprofile.md) in the tenant. The response will indicate the status of the sync.

## Permissions
One of the following permissions are required to call this API.
| Permission type | Permissions (from least to most privileged) |
|:-----------|:----------|
| Delegated (work or school account) | EduAdministration.Read, EduAdministration.ReadWrite |

## HTTP request
<!-- { "blockType": "ignored" } -->
```http
GET /synchronizationProfiles/{id}/profileStatus
```

## Request headers
| Name       | Type | Description|
|:-----------|:------|:----------|
| Authorization  | string  | Bearer {token}. Required.  |

## Request body
Do not supply a request body for this method.
## Response
If successful, this method returns a `200 OK` response code and a [educationsynchronizationprofilestatus](../resources/educationsynchronizationprofilestatus.md) object in the response body.

## Example
##### Request
Here is an example of the request.
<!-- {
  "blockType": "request",
  "name": "get_synchronizationProfile_status"
}-->
```http
GET https://graph.microsoft.com/beta/education/synchronizationProfiles/{id}/profileStatus
```

##### Response
Here is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.
<!-- {
  "blockType": "response",
  "@odata.type": "microsoft.graph.educationsynchronizationprofilestatus",
} -->
```http
{
    "@odata.context": "https://graph.microsoft.com/beta/$metadata#education/synchronizationProfiles('{id}')/profileStatus/$entity",
    "status": "inProgress",
    "lastSynchronizationDateTime": "2017-07-04T22:06:37.6472621Z"
}
```