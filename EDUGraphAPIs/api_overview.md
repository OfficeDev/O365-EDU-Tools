# Working with Edu assignments and rostering in Microsoft Graph


**Microsoft Graph Education Endpoint is available for private preview :
https://graph.microsoft.com/beta/education/**

The **Microsoft Graph API** is a valuable tool that gives developers access to Office 365 resources through one REST endpoint and one access token.  This is done by accessing the Graph through a set of URLs like the following examples:

    https://graph.microsost.com/<version>/users
    https://graph.microsost.com/<version>/groups
    https://graph.microsoft.com/<version>/me/calendars

While these **Office 365** resources are powerful and useful inside an educational institution that uses **Office 365**, the Education endpoint in Microsoft Graph also decorates **Office 365** graph data with education related information such as students, teachers, and classes. This makes it easier for ISV Office developers to integrate with educational resources.   

In addition, the Education endpoint also introduces two new education specific resources. **Rostering** and **Assignments** make it easy to interact with the assignment and rostering services within Microsoft Teams for Education.

The **Microsoft graph education** namespace allows developers access to schools, students, teachers, classes, enrollments, and **Assignments**.

## Authorization
 
Read about the API permissions needed for the assignment API in the Assignments API [Getting started](./Assignments/GettingStarted.md) article. The API permissions needed for the rostering API are described in the Rostering API [Getting started](./Rostering/GettingStarted.md) article.

For more information about permissions, including delegated and application permissions, see [Permissions](../../../concepts/permissions_reference.md). 

## Common use cases 

The core use cases for the Microsoft Education Graph API include automating student assignments and managing a school roster.

### Assignments APIs

Microsoft Graph **Assignments** Resources allow partners to integrate with the **Assignments** service under the Microsoft Teams in **Office 365** for Education tab of the same name.  The Public API is the same API that _Microsoft Teams in Office 365 for Education_ built it's user interface with.  Thus, the best sample of what can be built with the Microsoft **Assignments** API is _Microsoft Teams in Office 365 for Education_.  


#### 'Assignments' resource description 

An [Assignment](./Assignments/resources/educationassignmentresource.md) is a task or unit of work assigned to a student or team member in a class as part of their study.  Only teachers or team owners can create assignments.  Assignments contain handouts and tasks that the teacher wants the student to work on.  Each student assignment has an associated [submission](./assignments/resources/educationsubmissionresource.md) that contains any work their teacher asked to be turned in. A teacher can add scores and feedback to the submission turned in by the student.


#### Sample scenarios
As mentioned above the **Assignments** APIs allow partners to interact with the assignment Services. Here are some sample scenarios:

1. Create Assignment  - An external system can create assignment for the class and attach resources to the assignment.

2. Read assignment information - An analytics application can get information about assignments and student submissions including dates and grades.

3. Dashboard to track student submissions - A Teacher dashboard that shows how many Submissions have been submitted and how many need to be graded.

These are just a few examples. The assignment APIs provide a mechanism for external applications to interact with the life-cycle of the assignment.



### Rostering APIs

Rostering APIs in the **Microsoft Graph Education endpoint** are used to extract data from the school's **Office 365** tenant which has been synced to the cloud by Microsoft School Data Sync. These results provide information about schools, sections, teachers, students, and rosters. These APIs while functionally similar to the current Roster APIs, provide first class access to the roster data. The APIs provide both app-only APIs primarily for sync-centric scenarios and app+user APIs designed for interactive scenarios.  The app+user APIs will enforce region-appropriate RBAC policies based on the user role calling the API.  This will provide a consistent API and minimal policy surface regardless of administrative configuration within tenants. In addition, the APIs also provide EDU specific scopes to ensure the right user has access to the data.

#### Rostering resources description
The typical scenario for Rostering APIs to enable the user logged into a 3rd party ISV app to know:
- Who I am
- What classes I attend or teach
- What I need to do / by when

The Rostering APIs support this by providing APIs to support the following scenarios:

- get Roster
- get Schools
- get Classes
- get Teachers/Students
- get My Schools/Classes






## Next steps
Use your new understanding of the Microsoft Graph Education API to build education solutions around student assignments and school rosters.

### Getting started with assignments API
Read [Microsoft Education Graph Assignments API :  Getting Started](./Assignments/GettingStarted.md) to get started with  **Assignments** API including learning about Scopes, assignment Resources, APIs, Samples, and Building your first sample.


### Getting started with Rostering API
Read [Microsoft Education Graph Rostering API :  Getting Started](./Rostering/GettingStarted.md) to get started with Rostering API including learning about Scopes, Roster Resources , APIs, Samples and Building your first sample.

