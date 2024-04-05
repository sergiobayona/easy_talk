The following constraints are supported by the JSON Schema generator:

## String Properties

| Constraint    |   Description |
|---------------|---------------|
| format        |   Specifies the format that the string should match (e.g., email, uuid). |
| pattern       |	A regular expression pattern that the string must match. |
| min_length    |	The minimum number of characters for the string. |
| max_length	|   The maximum number of characters for the string. |
| enum          |	An array that specifies the enumerated values the string can take. |
| const         |	Specifies a single constant value the string must be equal to. |
| default       |	The default value for the string. |

## Integer and Number Properties
| Constraint            |	Description |
|-----------------------|---------------|
| minimum               |	The minimum value the integer can be. |
| maximum               |	The maximum value the integer can be. |
| exclusive_minimum     |	If true, the value must be strictly greater than the minimum value. |
| exclusive_maximum     |	If true, the value must be strictly less than the maximum value. |
| multiple_of           |	A number that the integer must be a multiple of. |
| enum                  |	An array that specifies the enumerated values the integer can take. |
| const                 |	Specifies a single constant value the integer must be equal to. |
| default               |	The default value for the integer. |


## Array Properties
| Constraint            |	Description |
|-----------------------|---------------|
| min_items             |	The minimum number of items in the array. |
| max_items             |	The maximum number of items in the array. |
| unique_items          |	If true, all items in the array must be unique. |
| items                 |	An object that specifies the schema for each item in the array. |
| enum                  |	An array that specifies the enumerated values the array can take. |
| const                 |	Specifies a single constant value the array must be equal to. |
| default               |	The default value for the array. |


## Boolean Properties
| Constraint            |	Description |
|-----------------------|---------------|
| enum                  |	An array that specifies the enumerated values the boolean can take. |
| const                 |	Specifies a single constant value the boolean must be equal to. |
| default               |	The default value for the boolean. |

## Object Properties

| Constraint            |	Description |
|-----------------------|---------------|
| properties            |	An object that specifies the schema for each property in the object. |
| required              |	An array that specifies the required properties in the object. |
| min_properties        |	The minimum number of properties in the object. |
| max_properties        |	The maximum number of properties in the object. |
| additional_properties |	An object that specifies the schema for additional properties in the object. |
| pattern_properties    |	An object that specifies the schema for properties that match a regular expression pattern. |

## Null Properties
| Constraint            |	Description |
|-----------------------|---------------|
| enum                  |	An array that specifies the enumerated values the null can take. |
| const                 |	Specifies a single constant value the null must be equal to. |
| default               |	The default value for the null. |


## All Properties 
| Constraint    |	Description |
|---------------|---------------|
| title         |	A short summary of what the property represents. |
| description   |	A detailed description of what the property represents. |
