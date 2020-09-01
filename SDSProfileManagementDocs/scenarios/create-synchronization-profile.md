# School Data Sync APIs: Create Profile

This articles describes in detail how to create a profile for automated sync using School Data Sync Profile Management APIs. To get started with the APIs please refer to the document [School Data Sync APIs : Introduction](
synchronization-profile-api-introduction.md).


## Create a Profile for automated sync:
The School Data Sync APIs enable automated Accounts and Roster sync management. The CreateProfile API for setting up a profile supports two formats for providing the Roster data.

- CSV Files from SIS
- Direct API connection provider to the SIS.

This document describes how to create a profile with CSV files as the format for syncing. To  make a direct connection with the SIS and sync via an API data provider refer to the [CreateProfileAPI](create-api-synchronization-profile.md) document.

Setting up a sync profile with CSV files is a 4step process:

|   Operation	                            |  REST Verb 	|   Description                             	|   	
|------	                                    |---	        |---	                                        |
| [Create Profile ](../api/educationsynchronizationprofile_post.md) (Mandatory)	                        |   POST	    |   Setup a profile for SDS Sync	            |   
| [Monitor Provisioning ](../api/educationsynchronizationprofile_get.md) (Mandatory)	                        |   GET	    |   Verify profile is provisioned by checking the state property   |
| [Get URL to upload CSV files](../api/educationsynchronizationprofile_uploadurl.md) (Mandatory)         |   GET	        |   Gets the SDS url to upload the files   |
| [Start sync after uploading files](../api/educationsynchronizationprofile_start.md) (Mandatory)                               |   POST        |   Verify files are valid and trigger sync	    |   	
| [Get Status](../api/educationsynchronizationprofilestatus_get.md)    (Optional)                           |   GET	        |   Gets the status of the ongoing sync	        |   


## Step 1 : Create Profile

Create Profile: Create Profile API allows you to create a profile that can be used for syncing data, managing identities, assigning O365 licenses to the users. Once a profile has a been created it can be reused for all future syncs. Most organizations just need one profile to sync the students, teachers and roster data.

**Note : Before calling these APIs, please review the permissions required for each of these in the corresponding API documentation.**

The following are the options for setting up the profile.
Please refer to the [Create Profile API documentation](../api/synchronizationprofile_post.md) to look at the API reference and a sample request

#### Select the profile Name:

Specify the [displayName](../resources/educationsynchronizationprofile.md) for the profile .

#### Select the sync format:

  Create Profile supports two the following two mechanisms for data sync:

  - CSV Format:  This article describes how to using CSV files obtained from the SIS.

     Here is the sample code snippet:

          "dataProvider": {
          "@odata.type": "#microsoft.graph.csvDataProvider"
          }
  - API Format:  To directly connect to the SIS using an API, please refer to the  document [CreateProfileAPI](create-api-synchronization-profile.md)


#### Identity configuration options:

  Create profile API provides two options for Identity sync:
  - IdentityMatchingConfiguration for Existing users:  Selecting this option matches students and teachers in your source data with users already existing in Office 365 / Azure Active Directory, and adds more attributes to those users.

            "identitySynchronizationConfiguration":{  
            "@odata.type":"#microsoft.graph.identityMatchingConfiguration",
            "matchingOptions":[  
               {  
                  "appliesTo":"student",
                  "sourcePropertyName":"Username",
                  "targetPropertyName":"userPrincipalName",
                  "targetDomain":"targetDomain.net"
               },
               {  
                  "appliesTo":"teacher",
                  "sourcePropertyName":"Username",
                  "targetPropertyName":"userPrincipalName",
                  "targetDomain":targetDomain.net"
               }
            ]
            }
  - identityCreationConfiguration for New Users:  Selecting this option creates a new teacher or student account in Office 365 / Azure Active Directory for each user specified by your source data.

    Here is the sample code snippet :

          "identitySynchronizationConfiguration": {
          "@odata.type": "#microsoft.graph.identityCreationConfiguration",
          "userDomains": [
          {
              "appliesTo": "student",
              "name": "testschool.edu"
          },
          {
              "appliesTo": "teacher",
              "name": "testschool.edu"
          }
          ]
          },

  For a detailed reference documentation on identity configuration option, please reference to the following resources : [educationIdentitySynchronizationConfiguration](../resources/educationidentitysynchronizationconfiguration.md)

#### Select data customizations
SDS APIs providing for a mechanism for syncing custom data fields. If skipped, all available attributes will be synced. For detailed API reference on customizations, please refer to the [documentation](../resources/educationsynchronizationcustomizations.md)

Here is an overview of the properties:

School  :  

Default Properties : SISID, Name.
Optional Properties:

    "school":{  
                "optionalPropertiesToSync":[  
                   "School Number",
                   "School NCES_ID",
                   "State ID",
                   "Grade Low",
                   "Grade High",
                   "Principal SIS ID",
                   "Principal Name",
                   "Principal Secondary Email",
                   "Address",
                   "City",
                   "State",
                   "Country",
                   "Zip",
                   "Phone",
                   "Zone"
                ],

Section:

Default Properties : SIS ID, School SIS ID,  Section Name.
Optional Properties:

    "section":{  
                "optionalPropertiesToSync":[  
                   "Section Number",
                   "Term SIS ID",
                   "Term Name",
                   "Term StartDate",
                   "Term EndDate",
                   "Course SIS ID",
                   "Course Name",
                   "Course Description",
                   "Course Number",
                   "Course Subject",
                   "Periods"
                ]
Student :

    "student":{  
                "optionalPropertiesToSync":[  
                   "State ID",
                   "Secondary Email",
                   "Student Number",
                   "Mailing Address",
                   "Mailing City",
                   "Mailing State",
                   "Mailing Zip",
                   "Mailing Latitude",
                   "Mailing Longitude",
                   "Mailing Country",
                   "Residence Address",
                   "Residence City",
                   "Residence State",
                   "Residence Zip",
                   "Residence Latitude",
                   "Residence Longitude",
                   "Residence Country",
                   "Gender",
                   "Birthdate",
                   "Grade",
                   "ELL Status",
                   "FederalRace",
                   "Graduation Year",
                   "Status",
                   "Username"
                ],
Teacher :

    "teacher":{  
                "optionalPropertiesToSync":[  
                   "State ID",
                   "Teacher Number",
                   "Status",
                   "Secondary Email",
                   "Username",
                   "Title",
                   "Qualification"
                ],

5. Chose licenses to assign:
While setting up a profile you can chose to assign Office 365 EDU licenses to teachers and students.  Note, this option is supported only if 'New users' is selected in the identity creation option.

Create Profile returns the following:
            HTTP/1.1 202 Accepted
            Http 400 If model validation fails
            Http 500 otherwise


## Step 2 : Monitor profile provisioning.

After a profile creation is accepted, it is provisioned by the system. The object returned in the response by the Create Profile API has a state of 'provisioning' and an 'id' which will be the unique identifier for the profile. To monitor the provisioning, perform a [GET operation on the profile](../api/synchronizationprofile_get.md) and check the profile state in the response. As soon as the state returned is 'provisioned', the profile is ready to sync.


## Step 3 : Get File Upload URL and Upload files.

After setting up the profile, the next step is to create the 6 required CSV files and upload them to the location that SDS provides.
Click [here](https://support.office.com/en-us/article/CSV-files-for-School-Data-Sync-9f3c3c2b-7364-4f6e-a959-e8538feead70?ui=en-US&rs=en-US&ad=US) to learn more about the required CSV files.


#### Get file URL
 This returns the URL location for file upload. This is an Azure storage location that is provided by SDS.

|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| GET        | /{serviceroot}/SynchronizationProfiles/{profileId}/UploadUrl


**Note : This URL generated by SDS is valid for one hour only. The files have to be uplaoded before the end of the hour**

#### Upload files:

A tool like AzCopy or [Storage Explorer](http://storageexplorer.com/) can be used to upload the files to the storage location.
The URL can also be used to upload files programatically using [Azure storage SDKs](https://github.com/search?q=org%3AAzure+azure-storage).
The files should be the same format as required by the School Data Sync Website.

This documentation uses AzCopy to upload the file.

Click [here](https://docs.microsoft.com/en-us/azure/storage/storage-use-azcopy) to download the windows version of AzCopy and [here](https://docs.microsoft.com/en-us/azure/storage/storage-use-azcopy-linux) for the Linux verion of Azcopy.

Run the following Azcopy command to upload all the files in the C:\myfolder to the storage url from the Get file URL API.


      AzCopy /Source:'C:\myfolder' /Dest:'{Upload URL}'


### Step 4 :  Start sync
This is a mandatory step to verify the files uploaded to a specific [synchronization profile](../resources/educationsynchronizationprofile.md) in the tenant. If verification is successful, then synchronization will start on the profile automatically. Refer to [Start sync](../api/synchronizationprofile_start.md) for detailed documentation.

|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| POST        | /synchronizationProfiles/{id}/start

### Step 5 : Get Sync Status
Once sync is started in the background you can query the sync status using the Get Sync Status API


|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| GET        | /{serviceroot}/SynchronizationProfiles/{profileId}/profileStatus

Profile Management provides the  following statuses:

    <EnumType Name="synchronizationStatus">
        <Member Name="paused" Value="0" />
        <Member Name="inProgress" Value="1" />
        <Member Name="success" Value="2" />
        <Member Name="error" Value="3" />
        <Member Name="validationError" Value="4" />
        <Member Name="quarantined" Value="5" />

A status of 'validationError' indicates that sync was automatically paused as potential errors were detected. To ignore and continue, [Resume Sync](../api/synchronizationprofile_resume.md) on the profile.
