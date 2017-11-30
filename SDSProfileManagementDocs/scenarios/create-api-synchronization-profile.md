# School Data Sync Profile APIs: Create Profile using APIs

This articles describes in detail how to create a profile for automated sync using School Data Sync Profile Management APIs with an API provider. To get started with the APIs and the pre-requisite please refer to the document [School Data Sync Profile APIs : Introduction](
synchronization-profile-api-introduction.md).


## Create a Profile for automated sync:
The School Data Sync APIs enable automated profile and Roster sync management. Setting up a profile for sync using an API connector is a two step process:

|   Operation	                            |  REST Verb 	|   Description                             	|   	
|------	                                    |---	        |---	                                        |
|[Create Profile](../api/synchronizationprofile_post.md) (Mandatory)	                        |   POST	    |   Setup a profile for SDS Sync	            |   	
| [Monitor Provisioning ](../api/synchronizationprofile_get.md) (Mandatory)	                        |   GET	    |   Verify profile is provisioned by checking the state property   |
| [Get Status](../api/synchronizationprofilestatus_get.md) (Optional)         	                    |   GET	        |   Gets the status of the ongoing sync	        |   	


## Step 1 : Create Profile

Create Profile: Create Profile API with API provider option allows you to setup a school data sync profile for syncing. Once a profile has a been created it can reused for all future syncs.

**Note : Before calling these APIs, please review the permissions required for each of these in the corresponding API documentation.**

Please refer to the [Create Profile API documentation](../api/synchronizationprofile_post.md) to look at the API reference and a sample request

Most of the options for CreateProfile with API format are similar to CSV format with one key difference - sync format type which is API instead of CSV.

#### Sync format:

  To use Create Profile support with the API format specify the corresponding Data provider. SDS currently supports PowerSchool Data Provider. In future the support will expand to more data providers.

     Here is the sample code snippet:

         @odata.type":"#microsoft.graph.powerSchoolDataProvider",
         "connectionUrl":"http://contoso.cloudapp.net",
         "clientId":"37e81c3f-73a2-4ecd-a314-xxxxxxxxx",
         "clientSecret":"secret",
         "schoolsIds":[  
            "55"
         ],

Create Profile returns the following:
  - Http/1.1 202 Accepted
  - Http 400 If model validation fails
  - Http 500 otherwise

Once the profile with API provider is created successfully, sync is started automatically.

#### Create Profile with Powerschool API Provider:
Powerschool is one of the custom API provider that's currently supported, to integrate with that specify #microsoft.graph.powerSchoolDataProvider" as the data type. Once profile is created, it starts syncing automatically.

      "dataProvider":{  
           "@odata.type":"#microsoft.graph.powerSchoolDataProvider",
           "connectionUrl":"http://contoso.clouddapp.net",
           "clientId":"37e81c3f-73a2-4ecd-a314-40eab50f68b8",
           "clientSecret":"secret",
           "schoolsIds":[  
              "55"
      }

## Step 2 : Monitor profile provisioning.

After a profile creation is accepted, it is provisioned by the system. The object returned in the response by the Create Profile API has a state of 'provisioning' and an 'id' which will be the unique identifier for the profile. To monitor the provisioning, perform a [GET operation on the profile](../api/synchronizationprofile_get.md) and check the profile state in the response. As soon as the state returned is 'provisioned', the profile is ready to sync.

### Step 2 : Get Sync Status
Once sync is started in the background you can query the sync status using the GetSyncStatus API


|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| GET        | /{serviceroot}/SynchronizationProfiles/{profileId}/Status


Profile Management provides the  following upload status:

      <EnumType Name="status">
        <Member Name="paused" Value="0" />
        <Member Name="inProgress" Value="1" />
        <Member Name="success" Value="2" />
        <Member Name="error" Value="3" />
        <Member Name="validationError" Value="4" />
        <Member Name="quarantined" Value="5" />

A status of 'validationError' indicates that sync was automatically paused as potential errors were detected. To ignore and continue, [Resume Sync](../api/synchronizationprofile_resume.md) on the profile.
