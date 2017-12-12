# educationSynchronizationLicenseAssignment resource type

Represents the license information to assign to user accounts. The resource will be used to set up license assignments when creating new user accounts.

## Properties

| Property | Type | Description |
|:-|:-|:-|
| **appliesTo** | string | The user role type to assign to license. Possible values: `student`, `teacher`.         |
| **skuIds** | collection of strings |  Represents the SKU identifiers of the licenses to assign.        |

## JSON representation

```json
{
    "appliesTo": "teacher",
    "skuIds": [
        "{License Sku Id}"
    ]
}
```
