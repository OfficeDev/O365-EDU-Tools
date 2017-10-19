# School Data Sync Profile APIs: Troubleshooting Sync failures

This articles describes in detail how to troubleshoot automated sync failures. To get started with the APIs please refer to the document [School Data Sync Profile APIs : Introduction](
SDSProfileAPIIntroduction.md)


## Troubleshooting sync failures
Once the admin setups an automated sync, a sync can sometimes have failures because of various reasons. The troubleshooting APIs can be used to drill into the failures.

**Note : Before calling these APIs, please review the permissions required for each of these in the corresponding API documentation.**

Here are the sequence of operations for troubleshooting:

|   Operation	                            |  REST Verb 	|   Description                                 |   	
|------	                                    |---	        |---	                      
| [Get Status](../api/synchronizationProfile_get_status.md)                            |   GET 	    |   Get Sync status	         
| [Get Errors](../api/synchronizationProfile_get_errors.md)         	                    |   GET	        |   Gets sync errors


#### Step 1 : Get Sync Status
Once sync is started in the background you can query the sync status using the Get Sync Status API


|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| GET        | /{serviceroot}/SynchronizationProfiles/{profileId}/profileStatus

Sample Response Body

            {  
               "@odata.context":"https://graph.microsoft.com/testEduApi/$metadata#education/synchronizationProfiles('{id}')/profileStatus/$entity",
               "status":"success",
               "lastSynchronizationDateTime":"2017-06-14T01:13:21.2495183Z"
            }

SDS Profile Management provides the  following upload status:

      <EnumType Name="synchronizationStatus">
        <Member Name="paused" Value="0" />
        <Member Name="inProgress" Value="1" />
        <Member Name="success" Value="2" />
        <Member Name="error" Value="3" />
        <Member Name="validationError" Value="4" />
        <Member Name="quarantined" Value="5" />

If the status of sync is "error", "validationError" or "quarantined" you can call the Get Error API to get error details.

#### Step 2 : Get errors

|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| GET        | /{serviceroot}/SynchronizationProfiles/{profileId}/Errors


|  Parameter    |  Description                                                            |   
|---            |---                                                                      |
| profileId     | Profile Id

Sample Response for Get Errors

            {  
               "@odata.context":"https://graph.microsoft.com/testEduApi/$metadata#education/synchronizationProfiles('{id}')/errors",
               "@odata.count":220,
               "value":[  
                  {  
                     "entryType":"Student",
                     "errorCode":"UnsynchronizableChange",
                     "errorMessage":"Student cannot be updated as no matching entry in Active Directory was found for Student.  Verify the identity matching criteria for the profile.",
                     "joiningValue":"Tyler.Smith@zsd114.ccsctp.net",
                     "recordedDateTime":"2017-06-12T21:50:00Z",
                     "reportableIdentifier":"Tyler.Smith"
                  },
                  ...      {  
                     "entryType":"Student",
                     "errorCode":"UnsynchronizableChange",
                     "errorMessage":"Student cannot be updated as no matching entry in Active Directory was found for Student.  Verify the identity matching criteria for the profile.",
                     "joiningValue":"Colby.Garner@zsd114.ccsctp.net",
                     "recordedDateTime":"2017-06-12T21:50:00Z",
                     "reportableIdentifier":"Colby.Garner"
                  }
               ],
               "@odata.nextLink":"https://graph.microsoft.com/testEduApi/$metadata#education/synchronizationProfiles/{id}/errors?skipToken={token}"
            }

Follow the error description in the response code to perform remediation and retry by sync process again.
Follow the ODATA next links ("@odata.nextLink") to retrieve next page of errors. When the last page is fetched, there is no next link in the response.


#### Reset Sync

If sync fails because of server errors, IT can chose to start from a clean slate by resetting sync. Reset will delete any errors but will not remove any data that was already synced.

|  Parameter    |  Description                                                            |   
|---            |---                                                                      |
| POST          | /{serviceroot}/SynchronizationProfiles/{profileId}/Reset
