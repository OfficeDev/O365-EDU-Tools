# Get an upload URL

Retrieve a shared access signature (SAS) for uploading source files to azure blob storage for a specific [synchronization profile](..\resources\synchronizationProfile.md) in the tenant. The SAS token has a validity of 1 hour.

> **Note:** To access the blob storage with the SAS token use [Azure storage SDKs](https://github.com/search?q=org%3AAzure+azure-storage) or [AzCopy](https://docs.microsoft.com/en-us/azure/storage/storage-use-azcopy).

## Prerequisites
The following **scopes** are required to execute this API: **EduAdministration.ReadWrite**

## HTTP request
<!-- { "blockType": "ignored" } -->
```http
GET /synchronizationProfiles/{id}/uploadUrl
```

## Request headers
| Name       | Type | Description|
|:-----------|:------|:----------|
| Authorization  | string  | Bearer {token}. Required.  |

## Request body
Do not supply a request body for this method.
## Response
If successful, this method returns a `200 OK` response code and a SAS URL for the [synchronizationProfile](../resources/synchronizationProfile.md) in the response body.

## Example
##### Request
Here is an example of the request.
<!-- {
  "blockType": "request",
  "name": "get_synchronizationProfile_uploadurl"
}-->
```http
GET https://graph.microsoft.com/testEduApi/education/synchronizationProfiles/{id}/uploadUrl
```

##### Response
Here is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.
<!-- {
  "blockType": "response",
  "@odata.type": "Edm.String",
} -->
```http
{
    "@odata.context": "https://graph.microsoft.com/testEduApi/$metadata#Edm.String",
    "value": "https://sdsstorage.blob.core.windows.net/86904b1e-c7d0-4ead-b13a-98f11fc400ee?sv=2015-07-08&sr=c&si=SharedAccessPolicy_20170704044441&sig=CH65vxxqXETCkQNH0Lfsu31cUo0s0XcEEo0OE2YiL6Q%3D&se=2017-07-04T08%3A43%3A01Z&sp=w"
}
```