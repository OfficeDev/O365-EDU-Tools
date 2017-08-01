# School Data Sync Profile Management Preview : Introduction
This document provides information on setting up automated sync and profile management using the Preview version of School Data Sync APIs.

[School Data Sync](https://sds.microsoft.com/) helps to automate the process of importing and synchronizing roster data from student information systems around the world with Azure AAD and Office 365. To setup the sync, school IT can chose to login to the SDS portal and create a sync profile and chose a deployment method – either using a CSV file or a supported SIS API connector.  In addition to enabling sync from the SDS portal you can also setup one using the APIs described in this document.

Here are some helpful links to get started:

Getting Started:

- [Introduction to Automated Sync and Profile Management APIs](./scenarios/SDSProfileAPIIntroduction.md)

Profile Management Scenarios:
- [Create Profile using CSV Files](./scenarios/SDSCreateProfile.md)
- [Create Profile using an API Connector](./scenarios/SDSCreateProfileAPI.md)
- [Update operations on SDS Sync Profiles](./scenarios/UpdateSyncProfiles.md)
- [Troubleshooting Sync failures](./scenarios/TroubleshootingSyncFailures.md)

Profile Management APIs:
- [CreateProfile](./api/synchronizationProfile_create.md)
- [DeleteProfile](./api/synchronizationProfile_delete.md)
- [GetErrors](./api/synchronizationProfile_get_errors.md)
- [GetStatus](./api/synchronizationProfile_get_status.md)
- [GetUploadURL](./api/synchronizationProfile_get_uploadurl.md)
- [GetProfile](./api/synchronizationProfile_get.md)
- [ListProfile](./api/synchronizationProfile_list.md)
- [PauseProfileSync](./api/synchronizationProfile_post_reset.md)
- [ResetProfile](./api/synchronizationProfile_get.md)
- [ResumeProfile](./api/synchronizationProfile_post_resume.md)
- [UpdateProfile](./api/synchronizationProfile_update.md)
- [Start](./api/synchronizationProfile_post_start.md)

## Contribute
Send a pull request out to contribute.
