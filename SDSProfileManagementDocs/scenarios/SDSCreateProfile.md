# School Data Sync Profile APIs: Create Profile

This articles describes in detail how to create a profile for automated sync using School Data Sync Profile Management APIs. To get started with the APIs please refer to the document [School Data Sync Profile APIs : Introduction](
SDSProfileAPIIntroduction.md).


## Create a Profile for automated sync:
The School Data Sync profile APIs enables automated profile and Roster sync management. The CreateProfile API which used for setting up a profile supports two formats for providing the Roster data.

- CSV Files from SIS
- Direct API connection to the SIS.

This document describes how to create a profile with CSV files as the format for syncing. To  make a direct connect with the SIS and sync via an API please refer to the [CreateProfileAPI](SDCreateProfileAPI.md) document.

Setting up a sync profile with CSV files is a 4step process:

|   Operation	                            |  REST Verb 	|   Description                             	|   	
|------	                                    |---	        |---	                                        |
| [Create Profile ](./api/synchronizationProfile_create.md) (Mandatory)	                        |   POST	    |   Setup a profile for SDS Sync	            |   	
| [Get URL to upload Roster CSV files](./api/synchronizationProfile_get_uploadurl.md) (Mandatory)        |   GET	        |   Gets the SDS url to upload the files   |
| [VerifyFiles](./api/synchronizationProfile_post_verifyfiles.md) (Mandatory)                               |   POST	        |   Verify files are upload and trigger sync	    |   	
| [Get Status](./api/synchronizationProfile_get_status.md)    (Optional)     	                    |   GET	        |   Gets the status of the ongoing sync	        |   	


## Step 1 : Create Profile

Create Profile: Create Profile API allows you to create a profile that can be used syncing data, managing identities, assigning O365 licenses to the users. Once a profile has a been created it can reused for all future syncs. Most organizations just need one profile to sync the students, teachers and roster data.

**Note : Before calling these APIs, please review the permissions required for each of these in the corresponding API documentation.**

The following are the options for setting up the profile.
Please refer to the [Create Profile API documentation](./api/synchronizationProfile_create.md) to look at the API reference and a sample request

#### Select the profile Name:

Specify the [displayName](./resources/synchronizationProfile.md) for the profile .

#### Choose Services to setup:
Specifies the services to be configured in the profile. Intune for education is the currently supported service. Refer to API reference document for details.

#### Select the sync format:

  Create Profile supports two the following two mechanisms for data sync:

  - CSV Format:  This article describes how to using CSV files obtained from the SIS.

     Here is the sample code snippet:

          "dataProvider": {
          "@odata.type": "#microsoft.graph.csvDataProvider"
          }
  - API Format:  To directly connect to the SIS using an API, please refer to the  document [CreateProfileAPI](SDCreateProfileAPI.md)


#### Identity configuration options:

  Create profile API provides two options for Identity sync:
  - IdentityMatchingConfiguration for Existing users:  Selecting this option matches students and teachers in your source data with users already existing in Office 365 / Azure Active Directory, and adds more attributes to those users.

            "identitySyncConfiguration":{  
            "@odata.type":"#microsoft.graph.identityMatchingConfiguration",
            "matchingOptions":[  
               {  
                  "appliesTo":"student",
                  "options":{  
                     "sourcePropertyName":"Username",
                     "targetPropertyName":"userPrincipalName",
                     "targetDomain":"targetDomain.net"
                  }
               },
               {  
                  "appliesTo":"teacher",
                  "options":{  
                     "sourcePropertyName":"Username",
                     "targetPropertyName":"userPrincipalName",
                     "targetDomain":targetDomain.net"
                  }
               }
            ]
            }      
  - identityCreationConfiguration for New Users:  Selecting this option creates a new teacher or student account in Office 365 / Azure Active Directory for each user specified by your source data.

    Here is the sample code snippet :

          "identitySyncConfiguration": {
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

  For a detailed reference documentation on identity configuration option, please reference to the following resources : [IdentitySyncConfiguration](./resources/identitySyncConfiguration.md)

#### Select data customizations
SDS APIs providing for a mechanism for syncing custom data fields. For detailed API reference on customizations, please refer to the [documentation](./resources/synchronizationCustomizations.md)

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
While setting up a profile you can chose to assign Office 365 EDU licenses to teachers and students.  Note, this option is supported only if 'New users is selected in the identity creation option.

Create Profile returns the following:
            HTTP/1.1 202 Accepted
            Http 400 If model validation fails
            Http 500 otherwise


## Step 2 : Get File Upload URL and Upload files.

After setting up the profile, the next step is to create the 6 required CSV files and upload them to the location that SDS provides.
Click [here](https://support.office.com/en-us/article/CSV-files-for-School-Data-Sync-9f3c3c2b-7364-4f6e-a959-e8538feead70?ui=en-US&rs=en-US&ad=US) to learn more about the required CSV files.


#### Get file URL
 This returns the URL location for file upload. This is a Azure storage location thats provided by SDS.

|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| GET        | /{serviceroot}/SynchronizationProfiles/{profileId}/UploadUrl


**Note : This URL generated by SDS is valid for one hour only. The files have to be uplaoded before the end of the hours**

#### Upload files:

A tool like AzCopy or [Storage Explorer](http://storageexplorer.com/) to upload the file to the storage location.

This documentation uses AzCopy to upload the file.

Click [here](https://docs.microsoft.com/en-us/azure/storage/storage-use-azcopy) to download the windows version of AzCopy and [here](https://docs.microsoft.com/en-us/azure/storage/storage-use-azcopy-linux) for the Linux verion of Azcopy.

Run the following Azcopy command to upload all the files in the C:\myfolder to the storage url from the Get file URL API.


      AzCopy /Source:C:\myfolder /Dest:https://myaccount.blob.core.windows.net/mycontainer /DestKey:key /S


Once the completes successfully, roster sync starts automatically.

### Step 3 : Verify Files
This is a mandatory step to verify the files uploaded to a specific [synchronization profile](./resources/synchronizationProfile.md) in the tenant. If verification is successful, then synchronization will start on the profile automatically. Refer to [Verify File](./api/synchronizationProfile_post_verifyfiles.md) for detailed documentation.

|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| POST        | /synchronizationProfiles/{id}/verifyFiles

### Step 4 : Get Sync Status
Once roster sync is started in the background you can query the sync status using the Get Sync Status API


|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| GET        | /{serviceroot}/SynchronizationProfiles/{profileId}/status

Profile Management provides the  following upload status:

      <EnumType Name="synchronizationStatus">
        <Member Name="paused" Value="0"/>
        <Member Name="inProgress" Value="1"/>
        <Member Name="success" Value="2"/>
        <Member Name="error" Value="3"/>
        <Member Name="quarantined" Value="4"/>
