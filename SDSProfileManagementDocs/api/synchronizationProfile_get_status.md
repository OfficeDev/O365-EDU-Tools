# Get the status of a synchronization profile

Get the status of a specific [synchronization profile](..\resources\synchronizationProfile.md) in the tenant. The response will indicate the status of the sync.

## Prerequisites
The following **scopes** are required to execute this API: **EduAdministration.ReadWrite** or **EduAdministration.Read**

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
If successful, this method returns a `200 OK` response code and a [synchronizationProfileStatus](../resources/synchronizationProfileStatus.md) object in the response body.

## Example
##### Request
Here is an example of the request.
<!-- {
  "blockType": "request",
  "name": "get_synchronizationProfile_status"
}-->
```http
GET https://graph.microsoft.com/testEduApi/education/synchronizationProfiles/{id}/profileStatus
```

##### Response
Here is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.
<!-- {
  "blockType": "response",
  "@odata.type": "microsoft.graph.synchronizationProfileStatus",
} -->
```http
{
    "@odata.context": "https://graph.microsoft.com/testEduApi/$metadata#education/synchronizationProfiles('{id}')/profileStatus/$entity",
    "status": "inProgress",
    "lastSynchronizationDateTime": "2017-07-04T22:06:37.6472621Z"
}
```