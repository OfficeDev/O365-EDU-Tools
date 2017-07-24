# School Data Sync Profile APIs: Troubleshooting Sync failures

This articles describes in detail how to troubleshoot automated sync failures. To get started with the APIs please refer to the document [School Data Sync Profile APIs : Introduction](
SDSProfileAPIIntroduction.md)


## Troubleshooting sync failures
Once the admin setups an automated sync, a sync can sometimes failures because of various reason. The troubleshooting APIs can be used to drill into the failures.

**Note : Before calling these APIs, please review the permissions required for each of these in the corresponding API documentation.**

Here are the sequence of operations for troubleshooting:

|   Operation	                            |  REST Verb 	|   Description                                 |   	
|------	                                    |---	        |---	                      
| [Get Status](./api/synchronizationProfile_get_status.md)                            |   GET 	    |   Get Sync status	         
| [Get Errors](./api/synchronizationProfile_get_errors.md)         	                    |   GET	        |   Gets sync errors


#### Step 1 : Get Sync Status
Once roster sync is started in the background you can query the sync status using the Get Sync Status API


|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| GET        | /{serviceroot}/SynchronizationProfiles/{profileId}/Status

Sample Response Body

            {  
               "@odata.context":"https://localhost:44301/api/$metadata#synchronizationProfiles('97ed51b9-bc23-4994-a225-218890f49f90')/status/$entity",
               "syncStatus":"success",
               "lastSynchronizationTime":"2017-06-14T01:13:21.2495183Z",
               "id":"syncStatus:97ed51b9-bc23-4994-a225-218890f49f90"
            }

Profile Management provides the  following upload status:

      <EnumType Name="synchronizationStatus">
        <Member Name="paused" Value="0"/>
        <Member Name="inProgress" Value="1"/>
        <Member Name="success" Value="2"/>
        <Member Name="error" Value="3"/>
        <Member Name="quarantined" Value="4"/>   

If the status of sync is "error" or "quarantined" you can run the Get Error APIs to get the error details.

#### Step 2 : Get errors

|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| GET        | /{serviceroot}/SynchronizationProfiles/{profileId}/Errors


|  Parameter    |  Description                                                            |   
|---            |---                                                                      |
| profileId     | Profile Id

Sample Response for Get Errors

            {  
               "@odata.context":"https://localhost:44301/api/$metadata#synchronizationProfiles('653d3392-a1bf-412c-a16d-e1192fc8d8df')/errors",
               "@odata.count":220,
               "value":[  
                  {  
                     "id":"Student:UnsynchronizableChange:Tyler.Smith",
                     "entryType":"Student",
                     "errorCode":"UnsynchronizableChange",
                     "errorMessage":"Student cannot be updated as no matching entry in Active Directory was found for Student.  Verify the identity matching criteria for the profile.",
                     "joiningValue":"Tyler.Smith@zsd114.ccsctp.net",
                     "recordedTime":"2017-06-12T21:50:00Z",
                     "reportableIdentifier":"Tyler.Smith"
                  },
                  ...      {  
                     "id":"Student:UnsynchronizableChange:Colby.Garner",
                     "entryType":"Student",
                     "errorCode":"UnsynchronizableChange",
                     "errorMessage":"Student cannot be updated as no matching entry in Active Directory was found for Student.  Verify the identity matching criteria for the profile.",
                     "joiningValue":"Colby.Garner@zsd114.ccsctp.net",
                     "recordedTime":"2017-06-12T21:50:00Z",
                     "reportableIdentifier":"Colby.Garner"
                  }
               ],
               "@odata.nextLink":"https://localhost:44301/api/synchronizationProfiles/653d3392-a1bf-412c-a16d-e1192fc8d8df/errors?skipToken=eyJGaWxlTmFtZSI6IkFsbCBFcnJvcnMgb24gMTQtSnVuLTIwMTcgMTEtMjEtNTMgUE0gVVRDLmNzdiIsIlNraXBFbnRyaWVzIjo5OX0%3d"
            }

Follow the error description in the response code to perform remediation and retry by sync process again.


#### Reset Sync

If sync fails because of server errors, IT can chose to start from a clean start by resetting sync. Reset will delete any errors but will not remove any data that was already sync'ed.

|  Parameter    |  Description                                                            |   
|---            |---                                                                      |
| POST          | /{serviceroot}/SynchronizationProfiles/{profileId}/Reset
