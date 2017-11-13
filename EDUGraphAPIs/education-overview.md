# Working with education APIs in Microsoft Graph

<!-- This content is not specific to the Education APIs. This overview topic should tell the story about the EDU APIs in Microsoft Graph specifically, rather than the Microsoft Graph API in general (that's covered in other topics).
The Microsoft Graph API provides access to Office 365 resources through one REST endpoint and one access token. This is done by accessing the Graph through a set of URLs like the following examples:

    https://graph.microsost.com/<version>/users
    https://graph.microsost.com/<version>/groups
    https://graph.microsoft.com/<version>/me/calendars
-->

The education APIs in Microsoft Graph enhance Office 365 resources and data with information that is relevant for education scenarios, including schools, students, teachers, classes, enrollments, and assignments. This makes it easy for you to build solutions that integrate with educational resources.

The education APIs include two new resources, **rostering** and [educationAssignment](Assignments/resources/educationassignment.md), that you can use to interact with the assignment and rostering services in Microsoft Teams. You can use these resources to automate student assignments and manage a school roster.

<!-- What resource should we link to for rostering? Is there a resource for rostering? If not, please update the text so that it does not imply that rostering is a resource. -->

## Authorization

To call the education APIs in Microsoft Graph, your app will need to acquire an access token. For details about access tokens, see [Get access tokens to call Microsoft Graph](https://developer.microsoft.com/en-us/graph/docs/concepts/auth_overview). Your app will also need the appropriate permissions. For more information, see [Education permissions](EDUGraphAPIs/permissions_reference.md#education-permissions). 

### App permissions to enable school IT admins to consent 

To deploy apps that are integrated with the Education APIs in Microsoft Graph, school IT admins must first grant consent to the permissions requested by the app. This consent has to be granted only once, unless the permissions change. After the admin consents, the app is provisioned for all users in the tenant.

To trigger a consent dialog box, use the following REST call.

```
GET https://login.microsoftonline.com/{tenant}/adminconsent?
client_id={clientId}&state=12345&redirect_uri={redirectUrl}
```

|Parameter|Description|
|:--------|:----------|
|Tenant|Tenant ID of the school.|
|clientId|Client ID of the app.|
|redirectUrl|App redirect URL.|


## Rostering

The rostering APIs enable you to extract data from a school's Office 365 tenant provisioned with Microsoft School Data Sync. These APIs provide access to information about schools, sections, teachers, students, and rosters. The APIs support both app-only (sync) scenarios, and app + user (interactive) scenarios. The APIs that support interactive scenarios enforce region-appropriate RBAC policies based on the user role calling the API. This provides a consistent API and minimal policy surface, regardless of the administrative configuration within tenants. In addition, the APIs also provide education-specific permissions to ensure that the right user has access to the data.

You can use the rostering APIs to enable an app user to know:

- Who I am
- What classes I attend or teach
- What I need to do and by when

The rostering APIs provide the following key resources:
<!-- 
- [educationSchool](resources/educationschool.md) - Represents the school.
- [educationClass](resources/educationclass.md) - Represents a class within a school.
- [educationTerm](resources/educationterm.md) - Represents a designated portion of the academic year.
- [educationTeacher](resources/educationteacher.md) - Represents a users with the primary role of 'Teacher'.
- [educationStudent](resources/educationstudent.md) - Represents a users with the primary role of 'student'.
-->
- [educationSchool](Rostering/resources/educationschool.md) - Represents the school.
- [educationClass](Rostering/resources/educationclass.md) - Represents a class within a school.
- [educationTerm](Rostering/resources/educationterm.md) - Represents a designated portion of the academic year.
- [educationTeacher](Rostering/resources/educationteacher.md) - Represents a users with the primary role of 'Teacher'.
- [educationStudent](Rostering/resources/educationstudent.md) - Represents a users with the primary role of 'student'.

The rostering APIs support the following scenarios:

<!--
- [List all schools](./api/educationroot_list_schools.md) 
- [List schools in which a class is taught](./api/educationclass_list_schools.md)
- [List schools for a user](./api/educationuser_list_schools.md)
- [Get all classes](./api/educationroot_list_classes.md )
- [Get classes in a school](./api/educationschool_list_classes.md)
- [List classes for a user](./api/educationuser_list_classes.md)
- [Add classes to a school](./api/educationschool_post_classes.md)
- [Get students and teachers for a class](./api/educationclass_list_members.md)
- [Add members to a class](./api/educationclass_post_members.md) 
- [List teachers for a class](./api/educationclass_list_teachers.md)
- [Get users in a school](./api/educationschool_list_users.md)
-->

- [List all schools](Rostering/api/educationroot_list_schools.md) 
- [List schools in which a class is taught](Rostering/api/educationclass_list_schools.md)
- [List schools for a user](Rostering/api/educationuser_list_schools.md)
- [Get all classes](Rostering/api/educationroot_list_classes.md )
- [Get classes in a school](Rostering/api/educationschool_list_classes.md)
- [List classes for a user](Rostering/api/educationuser_list_classes.md)
- [Add classes to a school](Rostering/api/educationschool_post_classes.md)
- [Get students and teachers for a class](Rostering/api/educationclass_list_members.md)
- [Add members to a class](Rostering/api/educationclass_post_members.md) 
- [List teachers for a class](Rostering/api/educationclass_list_teachers.md)
- [Get users in a school](Rostering/api/educationschool_list_users.md)

## Assignments 

You can use the assignment-related education APIs to integrate with assignments in Microsoft Teams. Microsoft Teams in Office 365 for Education is based on the same education APIs, and provides a use case for what you can do with the APIs. Your app can use these APIs to interact with assignments throughout the assignment lifecycle. 

<!-- I'm not sure that this text is clear. See the sentence that I added to the previous paragraph; please update to clarify the meaning.
The Public API is the same API that _Microsoft Teams in Office 365 for Education_ built it's user interface with.  Thus, the best sample of what can be built with the Microsoft **Assignments** API is _Microsoft Teams in Office 365 for Education_.  
-->

The assignment APIs provide the following key resources:

- [educationAssignment](Assignments/resources/educationassignment.md) - The core object of the assignments API. Represents a task or unit of work assigned to a student or team member in a class as part of their study.
- [educationSubmission](Assignments/resources/educationsubmission.md) - Represents the resources that an individual (or group) submits for an assignment and the associated grade and feedback for that assignment.
- [educationResource](Assignments/resources/educationresource.md) - Represents the learning object that is being assigned or submitted. An **educationResource** is associated with an **educationAssignment** and/or an **educationSubmission**.

The assignment APIs support the following scenarios:

- [Create assignment](Assignments/api/educationclass_post_assignments.md)
- [Publish assignment](Assignments/api/educationassignment_publish.md)
- [Create assignment resource](Assignments/api/educationassignment_post_resources.md)
- [Create submission resource](Assignments/api/educationsubmission_post_resources.md)
- [Submit assignment](Assignments/api/educationsubmission_submit.md)   
- [Release grades to student](Assignments/api/educationsubmission_release.md) 
- [Get assignment details](Assignments/api/educationuser_list_assignments.md)

The following are some common use cases for the assignment-related education APIs.

|Use case|Description|See also|
|:-------|:----------|:-------|
|Create assignments|An external system can create an assignment for the class and attach resources to the assignment.|[Create assignment](Assignments/api/educationassignment_post_resources.md)|
|Read assignment information|An analytics application can get information about assignments and student submissions, including dates and grades.|[Get assignment](Assignments/api/educationassignment_get.md)|
|Track student submissions|Your app can provide a teacher dashboard that shows how many submissions from students need to be graded.|[Submission resource](Assignments/resources/educationsubmission.md)|


## Next steps
Use the Microsoft Graph education APIs to build education solutions that access student assignments and school rosters. To learn more:

- Explore the resources and methods that are most helpful to your scenario.
- Try the API in the [Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer).

