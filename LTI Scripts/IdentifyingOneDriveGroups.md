Groups created to support the OneDrive LTI have a few specific property values that other Groups do not have.

## Find M365 Groups created by the OneDrive LTI
We will be using the [groups](https://docs.microsoft.com/en-us/graph/api/group-list?view=graph-rest-1.0&tabs=http) endpoint.

To identify groups created via the OneDrive LTI, we will filter looking for groups where the displayName starts with 'Course:' and the description contains the issuerName tag matching the name of the LMS.

**Graph API Request**: 
<pre>GET https://graph.microsoft.com/v1.0/groups?$count=true&$filter=startsWith(displayName,'Course:')&$search="description:issuerName: Canvas"&$select=id,displayName,email,description</pre>

In the above API call you must replace **Canvas** with the issuerName of your LMS in the $search expression. Possible values for issuerName are: **Canvas**, **Schoology**, **Blackboard**, and **Generic**. These values are case sensitive.

**Graph API Request headers** (_required_): `ConsistencyLevel:eventual` ([more info](https://docs.microsoft.com/en-us/graph/aad-advanced-queries?view=graph-rest-1.0&tabs=http)) 

**Graph Permissions Required**: `Directory.Read.All`, `Group.Read.All`

**User/Application Context**: If using delegated permissions with a particular user context, the query will only return Groups that the user is a member of. If run as a Global Administrator, or with Admin consented context then all Groups meeting the criteria can be viewed.


This will return the total count, and a list of all OneDrive LTI groups including _id_, _displayName_, _mail_ (upn), and _description_ properties. To return [additional property values](https://docs.microsoft.com/en-us/graph/api/resources/group?view=graph-rest-1.0#properties), add them to the comma delimited $select statement in the request.

More than likely, you will see an `@odata.nextLink` property at the beginning of the response. This means you are not getting a full list, and you will need to [page the data](https://docs.microsoft.com/en-us/graph/paging).  

### Powershell script example 
A [Powershell script example to log Groups](Get-OneDriveLTI-Groups.ps1) created by the OneDrive LTI is also available.

