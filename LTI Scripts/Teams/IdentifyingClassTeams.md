# Identify Class Teams created by Teams Classes LTI
Class Teams created through the Teams Classes LTI have a few specific properties that other Groups/Teams do not have. These properties should be present on both the Group entity in Graph.

### [Disclaimer](https://github.com/maxafritz/MSFTEDU/tree/main/LMSIntegrations#disclaimer)


## Find 'Groups' created by Teams Classes LTI
We will be using the [groups](https://docs.microsoft.com/en-us/graph/api/group-list?view=graph-rest-1.0&tabs=http) endpoint. The group object gets created alongsite the Class Team, and when created for LTI, is created with a special schemaExtension of _microsoft_EducationClassLmsExt_.  

_Microsoft_EducationClassLmsExt_ has several properties, not all of which are used, depending on your LMS:
- ltiContextId (required)
- lmsCourseId
- lmsSectionId
- lmsCourseName
- lmsSectionName
- lmsCourseSubject
- lmsCourseDescription

To identify groups created via LTI, we will filter looking for groups where ltiContextId is not blank.

**Graph API Request**: `GET https://graph.microsoft.com/v1.0/groups?$count=true&$select=displayname,id,mail,microsoft_EducationClassLmsExt&$filter=microsoft_EducationClassLmsExt/ltiContextId+ne+null`  
**Graph API Request headers** (_required_): `ConsistencyLevel:eventual` ([more info](https://docs.microsoft.com/en-us/graph/aad-advanced-queries?view=graph-rest-1.0&tabs=http))  
**Graph Permissions Required**: `Directory.Read.All`, `Group.Read.All`, `GroupMember.Read.All`


This will return a list of all LTI created groups, with _displayName_, _id_, _mail_ (upn), and the above _microsoft_EducationClassLmsExt_ properties. To see [more properties](https://docs.microsoft.com/en-us/graph/api/resources/group?view=graph-rest-1.0#properties), add them to the select statement in the request.

More than likely, you will see an `@odata.nextLink` property at the beginning of the response. This means you are not getting a full list, and you will need to [page the data](https://docs.microsoft.com/en-us/graph/paging).  

### Powershell Method (*coming soon*)

## Identify ALL Class Teams
_[Instructions to be created. Seperate article coming soon]_
