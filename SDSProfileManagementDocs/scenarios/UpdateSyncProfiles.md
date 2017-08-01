# School Data Sync Profile APIs: Update/Pause/Resume Profile

This articles describes in detail how to update a sync profile. To create a sync profile please refer to the [School Data Sync Profile APIs : Create Profile API](
SDSCreateProfile.md)

Once the profile has been setup IT can choose to modify an existing profile or delete it.

## Update profile:

The School Data Sync APIs enable automated sync management. Updating a profile for sync is a two step process:

|   Operation	                            |  REST Verb 	|   Description                             	                    |   	
|------	                                    |---	        |---	                                                            |
| [Get all  Profiles](../api/synchronizationProfile_list.md)	                        |   GET 	    |  Get all the profiles in the tenant with profile Ids	            |   	   	                 
| [Update profile](../api/synchronizationProfile_update.md)       	                |   GET	        |  Update an existing profile                                       |   	

**Note : Before calling these APIs, please review the permissions required for each of these in the corresponding API documentation.**

### Step 1 : Get all Profiles

|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| GET        | /{serviceroot}/SynchronizationProfiles                                    |  


Note : If you already  know the profile Id , you can directly call the Get Profile API.

|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| GET        | /{serviceroot}/SynchronizationProfiles/{profileId}


|  Parameter    |  Description                                                            |   
|---            |---                                                                      |
| profileId     | Profile Id of the corresponding profile to update


### Step 2: Edit profile
After retrieving the profile the IT can make changes to the existing using the following API.

|  Method    |  Request URI                                                              |   
|---         |---                                                                        |
| PUT        | /{serviceroot}/SynchronizationProfiles/{profileId}


|  Parameter    |  Description                                                            |   
|---            |---                                                                      |
| profileId     | Profile ID of the corresponding profile

Update Profile returns the following:
            HTTP/1.1 202 Accepted
            Http 400 If model validation fails
            Http 500 otherwise

* Note : Sometime when a profile is updated, it might require a reset of sync for the new profile to become effective. Please see below for details.

## Reset Sync
After update, a profile might need to be reset if any optional sync fields were added or removed.

|  Method    |  Request URI                                                              |   
|---          |---                                                                        
| POST        |/{serviceroot}/SynchronizationProfiles/{profileId}/Reset

## Pause/Resume Sync
Updating a profile does not change the sync status, if the sync is enabled it continues to stay in enabled state.
The school IT can chose to temporarily pause sync and resume at a later time using the following APIs.

#### Pause Sync

|  Method    |  Request URI                                                              |   
|---          |---                                                                        
| POST        |/{serviceroot}/SynchronizationProfiles/{profileId}/Pause

#### Resume Sync

|  Parameter    |  Description                                                            |   
|---            |---                                                                      |
| POST          | /{serviceroot}/SynchronizationProfiles/{profileId}/Resume
