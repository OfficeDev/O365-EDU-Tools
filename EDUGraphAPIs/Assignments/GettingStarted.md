# Microsoft Education Graph Assignments API :  Getting Started

 This document provides information for getting started with assignments API.

 ### Understanding Scopes

 The Assignment Service adds a few new scopes to the **Microsoft Graph**. These scopes are used to access Assignment information.  The scope applies to all the **Assignment** objects including [Assignment](./resources/educationassignment.md), [Resource](./resources/educationresource.md), and [Submission](./resources/educationsubmission.md).  With an App+User Context, the API will only return objects that the user has access to. The "Basic" scopes work the same as the non-basic equivalent scopes, however grade information will not be returned in the Submission objects for "Basic" scopes.

 >**Note:** Students can only access their own Submission.

#### App-Only Context

| Role (scope)		   | Display Name	|Description|
|:-----------------|:-------------------|:----------|
|EduAssignments.ReadBasic.All| Read class assignments without grades|Allows the app to read assignments without grades for all users|
|EduAssignments.ReadWriteBasic.All | Read and write class assignments without grades | Allows the app to read and write assignments without grades for all users|
|EduAssignments.Read.All| Read class assignments with grades | Allows the app to read assignments and their grades for all users |
|EduAssignments.ReadWrite.All | Read and write class assignments with grades | Allows the app to read and write assignments and their grades for all users |
|


#### App+User Context

| Scope		   | Admin Display Name	| Admin Description | User Consent Display name | User Consent Description |
|:-----------------|:-------------------|:----------|--------------|------------|
|EduAssignments.ReadBasic| Read a user's view of class assignments without grades | Allows the app to read assignments without grades on behalf of the user | View your assignments without grades | Allows the app to view your assignments on your behalf without seeing grades |
|EduAssignments.ReadWriteBasic|Read and write a user's view of class assignments without grades|Allows the app to read and write assignments without grades on behalf of the user|View and modify your assignments without grades|Allows the app to view and modify your assignments on your behalf without seeing grades|
|EduAssignments.Read|Read a user's view of class assignments and their grades|Allows the app to read assignments and their grades on behalf of the user|View your assignments and grades|Allows the app to view your assignments on your behalf including grades|
|EduAssignments.ReadWrite|Read and write a user's view of class assignments and their grades|Allows the app to read and write assignments and their grades on behalf of the user|View and modify your assignments and grades|Allows the app to view and modify your assignments on your behalf including  grades|
 

 ### Understanding assignment Resources

Assignment APIs provide the following key resources:

- [assignment](./resources/educationassignment.md) - **Assignment** is the core object of the Assignments API and owned by the class.
- [Submission](.resources/educationsubmission.md) - **Submission** objects are owned by an assignment. They represents the resources that an individual (or group) submit for an assignment and associated grade/feedback.
- [Resource](resources/educationresource.md) - A resource is associated with an **Assignment** and/or **Submission** and represents the learning object that is being assigned or submitted.

 ### Overview of APIs
Assignments endpoint in EDU Graph provide the following APIs.

- [Create Assignment](./api/educationclass_post_assignments.md)
- [Publish Assignment](./api/educationassignment_publish.md)
- [Create Assignment Resource](./api/educationassignment_post_resources.md)
- [Create Submission Resource](./api/educationsubmission_post_resources.md)
- [Submit Assignment](./api/educationsubmission_submit.md)   
- [Release Grades to student](./api/educationsubmission_release.md) 
- [Get assignment Details](./api/educationuser_list_assignments.md)

Check out the complete set of APIs [here](./api).


### Building your first app

Read the [Microsoft Graph documentation](https://developer.microsoft.com/en-us/graph/docs/concepts/get-started) for building your first app using assignment APIs.
 
 The [EDUGraphAPI - Office 365 Education Code Sample](https://github.com/OfficeDev/O365-EDU-AspNetMVC-Samples) is available from our _GitHub_ repository. Clone the repository to learn about the end to end sample built on Assignments APIs.

