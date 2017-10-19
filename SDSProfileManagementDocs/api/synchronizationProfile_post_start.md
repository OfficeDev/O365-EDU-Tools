# Start sync after uploading files to a synchronization profile

Verify the files uploaded to a specific [synchronization profile](..\resources\synchronizationProfile.md) in the tenant. If verification is successful, then synchronization will start on the profile. Else, the response will contain errors and warnings due to which sync was not started. If the response contains only warnings, synchronization will still be started.

> **Note:** This API is applicable only when data provider is of type [csvDataProvider](../resources/csvDataProvider.md). Also, the profile's state property needs to be 'provisioned' before it can be started. This can be checked by polling the profile object and checking its state property.

## Prerequisites
The following **scopes** are required to execute this API: **EduAdministration.ReadWrite**

## HTTP request
<!-- { "blockType": "ignored" } -->
```http
POST /synchronizationProfiles/{id}/start
```

## Request headers
| Name       | Type | Description|
|:-----------|:------|:----------|
| Authorization  | string  | Bearer {token}. Required.  |

## Request body
Do not supply a request body for this method.
## Response
If successful, this method returns a `200 OK` response code. If unsuccessful it returns a `400 Bad Request`. Response contains a collection of [fileSynchronizationVerificationMessage](../resources/fileSynchronizationVerificationMessage.md) as part of the response body if any errors or warnings were found.

## Example
##### Request
Here is an example of the request.
<!-- {
  "blockType": "request",
  "name": "post_synchronizationProfile_start"
}-->
```http
POST https://graph.microsoft.com/testEduApi/education/synchronizationProfiles/{id}/start
```

##### Response
Here is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.
<!-- {
  "blockType": "response",
  "truncated": true,
  "@odata.type": "microsoft.graph.verificationMessage",
  "isCollection": true
} -->
```http
{
    "@odata.context": "https://graph.microsoft.com/testEduApi/$metadata#education/Collection(microsoft.graph.verificationMessage)",
    "value": [
        {
            "type": "Error",
            "fileName": "section.csv",
            "description": "5 row(s) have missing data for the field - SIS ID"
        },
        {
            "type": "Error",
            "fileName": "section.csv",
            "description": "5 row(s) have an invalid format for the field - SIS ID"
        },
        {
            "type": "Warning",
            "fileName": "student.csv",
            "description": "3 duplicates found in column SIS ID which requires values to be Unique."
        },
        {
            "type": "Warning",
            "fileName": "student.csv",
            "description": "3 duplicates found in column Username which requires values to be Unique."
        },
        {
            "type": "Error",
            "fileName": "studentenrollment.csv",
            "description": "125 row(s) have referenced data not found in source. Field - Section SIS ID"
        },
        {
            "type": "Error",
            "fileName": "studentenrollment.csv",
            "description": "35 row(s) have referenced data not found in source. Field - SIS ID"
        },
        {
            "type": "Warning",
            "fileName": "teacher.csv",
            "description": "3 duplicates found in column SIS ID which requires values to be Unique."
        },
        {
            "type": "Warning",
            "fileName": "teacher.csv",
            "description": "3 duplicates found in column Username which requires values to be Unique."
        },
        {
            "type": "Error",
            "fileName": "teacherroster.csv",
            "description": "10 row(s) have referenced data not found in source. Field - Section SIS ID"
        },
        {
            "type": "Error",
            "fileName": "teacherroster.csv",
            "description": "91 row(s) have referenced data not found in source. Field - SIS ID"
        }
    ]
}
```
