# Microsoft Education Graph API :  Rostering APIs

## Introduction

Rostering  APIs in Microsoft Graph Education endpoint help extract data from the school's Office 365 tenant which has been synced to the cloud by Microsoft School Data Sync. These results provide information about schools, sections, teachers, students and rosters. These APIs while functionally similar to the current [Roster APIs](https://msdn.microsoft.com/office/office365/api/school-rest-operations), provide access to the Roster data in a first class way. The APIs provide both app-only APIs primarily for sync-centric scenarios and app+user APIs designed for interactive scenarios.  The app+user APIs will enforce region-appropriate RBAC policies based on the user role calling the API.  This will provide a consistent API and minimal policy surface regardless of administrative configuration within tenants. In addition, the APIs also provide EDU specific scopes to ensure the right user has access to the data.

### Description
The typical scenario for Rostering APIs to enable the user logged into a 3rd party ISV app to know
- Who Iam
- What classes I attend or teach
- What I need to do / by when

The Rostering APIs support this by providing APIs to support the following scenarios:

- get Roster
- get Schools


[Click here](./GettingStarted.md)  to get started with  Rostering API including learning about Scopes, Roster Resources , APIs, Samples and Building your first sample.


