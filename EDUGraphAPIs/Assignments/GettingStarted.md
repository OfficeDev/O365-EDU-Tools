# Microsoft Education Graph Assigments API :  Getting Started

 This document provides information for getting started with Assigments API.

 ### 1. Understanding Scopes

 The Assignment Service adds a few new Scopes to the Microsoft Graph. These Scopes need to be used to access Assignment information.  The Scope applies to all the Assignment objects including Assignment, Resource, and Submission.  With an App+User Context, the API will only return objects to which the User has access (Students can only access their own Submission for instance).  The “Basic” Scopes work the same as the non-basic equivalents, however grade information will not be returned in the Submission objects for “Basic” scopes.

#### App-Only Context

| Role		   | Display Name	|Description|
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
|

 ### 2. Understanding Assigment Resources

Assigment APIs provide the following key resources:

- [Assigment](./resources/educationassignment.md) - Assignment is the core object of the Assignments API and owned by the class.
- [Submission](.resources/educationsubmission.md) - Submissions are objects that are owned by an assignment. It represents the resources that an individual (or group) turn-in for an assignment and the grade/feedback that is returned.
- [Resource](resources/educationresource.md) - A resource is something that is associated with an Assignment and/or Submission which represents the learning object that is being handed-out or handed-in.

 ### 3. Overview of APIs
Assigments endpoint in EDU Graph provide the following APIs.

- [Create Assignment](./api/educationclass_post_assignments.md)
- [Publish Assignment](./api/educationassignment_publish.md)
- [Create Assignment Resource](./api/educationassignment_post_resources.md)
- [Create Submission Resource](./api/educationsubmission_post_resources.md)
- [Submit Assignment](./api/educationsubmission_submit.md)   
- [Release Grades to student](./api/educationsubmission_release.md) 
- [Get Assigment Details](./api/educationuser_list_assignments.md)

Check out the complete set of APIs [here](./api).


### 4. Building your first app

Follow the Microsoft Graph documentation [here](https://developer.microsoft.com/en-us/graph/docs/concepts/get-started) for building your first app using Assigment APIs.
 
Getting Started Sample : Browse [here](coming soon) to checkout the end to end sample built on Assignments APIs.

