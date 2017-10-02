# educationUser resource type

A user in the system.  This is an education-specific variant of the user with the same `id` that Graph will return from the non-education-specific `/users` endpoint.
This object adds to the existing [user](user.md) a set of education-specific properties such as primaryRole, student and teacher data.


## Methods

| Method		   | Return Type	|Description|
|:---------------|:--------|:----------|
|[Get educationUser](../api/educationuser_get.md) | [educationUser](educationuser.md) |Read properties and relationships of educationUser object.|
|[List classes](../api/educationuser_list_classes.md) |[educationClass](educationclass.md) collection| Get an educationClass object collection.|
|[List schools](../api/educationuser_list_schools.md) |[educationSchool](educationschool.md) collection| Get an educationSchool object collection.|
|[Update](../api/educationuser_update.md) | [educationUser](educationuser.md)	|Update educationUser object. |
|[Delete](../api/educationuser_delete.md) | None |Delete educationUser object. |

## Properties
| Property	   | Type	|Description|n
|:---------------|:--------|:----------|
|id| String| Unique identifier for user.|
|displayName| String| Display Name of user.|
|givenName| String | First Name of user. |
|middleName| String | Middle Name of user.|
|surname| String | Surname of user.|
|mail| String| email address of user.|
|mobilePhone| String | Mobile number of user. |
|createdBy|[identitySet](identityset.md)| Entity who created the user. |
|externalSource|`educationExternalSource`| Where this user was created from.  Possible values are: `sis`, `manual`, `unkownFutureValue`.|
|mailingAddress|[physicalAddress](physicaladdress.md)| Mail address of user.|
|residenceAddress|[physicalAddress](physicaladdress.md)| Address where user lives.|
|primaryRole|string| Default Role for a user.  The user's role might be different in an individual class. Possible values are: `student`, `teacher`, `enum_sentinel`.|
|student|[educationStudent](educationstudent.md)| If the primary role is student, this block will contain student specific data.|
|teacher|[educationTeacher](educationteacher.md)| If the primary role is teacher, this block will conatin teacher specific data.|

## Relationships
| Relationship | Type	|Description|
|:---------------|:--------|:----------|
|classes|[educationClass](educationclass.md) collection| Classes to which the user belongs. Nullable.|
|schools|[educationSchool](educationschool.md) collection| Schools to which the user belongs. Nullable.|
|assignments| [educationAssignment](../../Assignments/resources/educationAssignment.md)| List of assignments for hte user.  Nullable.|

## JSON representation

Here is a JSON representation of the resource.

<!-- {
  "blockType": "resource",
  "optionalProperties": [

  ],
  "@odata.type": "microsoft.graph.educationUser"
}-->

```json
{
  "id": "string",
  "displayName": "string",
  "givenName": "string",
  "middleName": "string",
  "surname": "string",
  "mail": "string",
  "mobilePhone": "string",
  "createdBy": {"@odata.type": "microsoft.graph.identitySet"},
  "externalSource": "string",
  "mailingAddress": {"@odata.type": "microsoft.graph.physicalAddress"},
  "primaryRole": "string",
  "residenceAddress": {"@odata.type": "microsoft.graph.physicalAddress"},
  "student": {"@odata.type": "microsoft.graph.educationStudent"},
  "teacher": {"@odata.type": "microsoft.graph.educationTeacher"}
}

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "educationUser resource",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->