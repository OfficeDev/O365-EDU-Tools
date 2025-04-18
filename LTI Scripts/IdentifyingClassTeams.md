# Identify Teams visualized by the Teams Classes LTI
Teams created through the Canvas Teams sync, Blackboard Ultra Teams sync, D2L Course Connector for Class Teams, or connected to an LMS course using the Connect Teams UX have a specific extension property set that other Teams and underlying M365 Groups do not have. These special extension properties can be found on Group entity in Graph.

## Find 'Groups' visualized by the Teams LTI
We will be using the [groups](https://docs.microsoft.com/en-us/graph/api/group-list?view=graph-rest-1.0&tabs=http) endpoint. A underlying M365 Group object exists for each Team, and when created by the LMS sync mechanisms the schemaExtension of _microsoft_EducationClassLmsExt_ is populated and the [LTI Context ID](https://www.imsglobal.org/spec/lti/v1p3/#lti-context-variable) that the LMS uses to identfy the course or section associated with the team is written in the ltiContextId property of that extension.

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

**Graph Permissions Required**: `Directory.Read.All`, `Group.Read.All`


This will return the total count, and a list of all LMS associated groups including _displayName_, _id_, _mail_ (upn), and the above _microsoft_EducationClassLmsExt_ properties. To see [more properties](https://docs.microsoft.com/en-us/graph/api/resources/group?view=graph-rest-1.0#properties), add them to the select statement in the request.

More than likely, you will see an `@odata.nextLink` property at the beginning of the response. This means you are not getting a full list, and you will need to [page the data](https://docs.microsoft.com/en-us/graph/paging).  

