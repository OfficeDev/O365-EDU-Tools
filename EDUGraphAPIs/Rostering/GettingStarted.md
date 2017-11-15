# Microsoft Education Graph Rostering API :  Getting Started

 This document provides information for getting started with Rostering API.

 ### 1. Understanding Scopes

 The Rostering Service adds a few new Scopes to the Microsoft Graph. These Scopes need to be used to access Roster information.  Scopes are the way users or administrators decide what information an application (or more practically the vendor who creates an application) has access to.  In app+user scenarios, the intersection of the user’s permissions and the application’s scopes define the data that the running app can work with.

#### App-Only Context

| Role		   | Display Name	|Description|
|:-----------------|:-------------------|:----------|
|EduRostering.ReadBasic.All| Read a limited subset of the organization's roster. |Allows the app to read a limited subset of both the structure of schools and classes in an organization's roster and education-specific information about all users.|
|EduRostering.Read.All | Read the organization's roster. | Allows the app to read the structure of schools and classes in the organization's roster and education-specific information about all users to be read. |
|EduRostering.ReadWrite.All| Read and write the organization's roster. | Allows the app to read and write the structure of schools and classes in the organization's roster and education-specific information about all users to be read and written.  |


#### App+User Context

| Scope		   | Admin Display Name	| Admin Description | User Consent Display name | User Consent Description |
|:-----------------|:-------------------|:----------|--------------|------------|
EduRostering.ReadBasic| Read a limited subset of a user's view of the roster | Allows the app to read a limited subset of the data from the  structure of schools and classes in an organization's roster and  education-specific information about users to be read on behalf of the user.  |View a limited subset of your school, class and user information. |Allows the app to view a limited subset of the information about schools and classes in your organization and education-related information about you and other users on your behalf.  |


 ### 2. Understanding Education Roster Resources

assignment APIs provide the following key resources:

- [School](resources/educationschool.md) - A resource that represents the school.
- [Class](./resources/educationclass.md) - Represents a class within a school.
- [Term](resources/educationterm.md) - Represents a designated portion of the academic year.
- [Teacher  ](resources/educationteacher.md) - Represents a users with primary Role 'Teacher'.
- [Student](resources/educationstudent.md) - Represents a users with primary Role 'student'.

 ### 3. Overview of APIs
assignments endpoint in EDU Graph provide the following APIs.

- [Get Students and Teachers for a Class](./api/educationclass_list_members.md)
- [List Schools I teach](./api/educationclass_list_schools.md)
- [List Teachers for a class](./api/educationclass_list_teachers.md)
- [Add Members to a Class](./api/educationclass_post_members.md) 
- [Get All Classes](./api/educationroot_list_classes.md )
- [List All Schools](./api/educationroot_list_schools.md)
- [Get Classes in a School](./api/educationschool_list_classes.md)
- [Get users in a school](./api/educationschool_list_users.md)
- [Add Classes to a School](./api/educationschool_post_classes.md)
- [List of Classes for a user](./api/educationuser_list_classes.md)
- [List of Schools for a user](./api/educationuser_list_schools.md)


Check out the complete set of APIs [here](./api).


### 4. Building your first app

Follow the Microsoft Graph documentation [here](https://developer.microsoft.com/en-us/graph/docs/concepts/get-started) for building your first app using Rostering APIs.
 
Getting Started Sample : Browse [here](https://github.com/OfficeDev/O365-EDU-AspNetMVC-Samples) to checkout the end to end sample built on Rostering APIs.

