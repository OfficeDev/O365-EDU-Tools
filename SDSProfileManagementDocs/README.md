# School Data Sync Profile Management Preview : Introduction
This document provides information on setting up automated sync and profile management using the Preview version of School Data Sync APIs.

[School Data Sync](https://sds.microsoft.com/) helps to automate the process of importing and synchronizing roster data from student information systems around the world with Azure AAD and Office 365. To setup the sync, school IT can chose to login to the SDS portal and create a sync profile and chose a deployment method – either using a CSV file or a supported SIS API connector.  In addition to enabling sync from the SDS portal you can also setup one using the APIs described in this document.

Here are some helpful links to get started:

Getting Started:

- [Introduction to Automated Sync and Profile Management APIs](./scenarios/SDSProfileAPIIntroduction.md)

Profile Management Scenarios:
- [Create Profile using CSV Files](./scenarios/create-synchronization-profile.md)
- [Create Profile using an API Connector](./scenarios/create-api-synchronization-profile.md)
- [Update operations on SDS Sync Profiles](./scenarios/update-synchronization-profile.md)
- [Troubleshooting Sync failures](./scenarios/troubleshooting-sync-failures.md)

Profile Management APIs:
- [CreateProfile](./api/educationsynchronizationprofile_post.md)
- [DeleteProfile](./api/educationsynchronizationprofile_delete.md)
- [GetErrors](./api/educationsynchronizationerrors_get.md)
- [GetStatus](./api/educationsynchronizationprofilestatus_get.md)
- [GetUploadURL](./api/educationsynchronizationprofile_uploadurl.md)
- [GetProfile](./api/educationsynchronizationprofile_get.md)
- [ListProfile](./api/educationsynchronizationprofile_list.md)
- [PauseProfileSync](./api/educationsynchronizationprofile_pause.md)
- [ResetProfile](./api/educationsynchronizationprofile_reset.md)
- [ResumeProfile](./api/educationsynchronizationprofile_resume.md)
- [UpdateProfile](./api/educationsynchronizationprofile_put.md)
- [Start](./api/educationsynchronizationprofile_start.md)

## Contribute
Send a pull request out to contribute.
