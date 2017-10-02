# Microsoft Education Graph API :  Preview

## Introduction

**Microsoft Graph Education Endpoint is available for private preview :
https://graph.microsoft.com/beta/education/**

The Microsoft Graph is an amazing resource where developers can access all the Office constructs through a single Rest API.  This can be done by access the graph through a series of URLs:

    https://graph.microsost.com/<version>/users
    https://graph.microsost.com/<version>/groups
    https://graph.microsoft.com/<version>/me/calendars

While these constructs are powerful and useful inside an educational institution that uses Office365, the Education endpoint in Microsoft Graph decorates the existing graph data with education related information(i.e  students, teachers, classes etc) making it easier for ISV developers integrate with educational resources.   

In addition, the Education endpoint also introduces a new education specific resource called "Assignments" for interaction with the assignment service within Microsoft Teams for Education.

The Microsoft graph education namespace allows developers access to schools, students, teachers, classes, enrollments, and assignments.

In this documentation we'll learn about two core scenarios:

### [Assignments APIs](./Assignments/README.md)

### [Rostering APIs](./Rostering/README.md)


## Contribute
Send a pull request out to contribute.
