---
layout: page
title: Property Types
permalink: /property-types/
---

# Property Types

EasyTalk supports Ruby's built-in types plus Sorbet-style generic types for more complex schemas.

## Basic Types

### String

```ruby
property :name, String
# => { "type": "string" }
```

**Constraints:**

| Constraint | Description | Example |
|------------|-------------|---------|
| `min_length` | Minimum length | `min_length: 1` |
| `max_length` | Maximum length | `max_length: 100` |
| `pattern` | Regex pattern | `pattern: /^[a-z]+$/` |
| `format` | JSON Schema format | `format: "email"` |
| `enum` | Allowed values | `enum: %w[a b c]` |

**Common formats:** `email`, `uri`, `uuid`, `date`, `date-time`, `time`, `ipv4`, `ipv6`, `hostname`

### Integer

```ruby
property :age, Integer
# => { "type": "integer" }
```

**Constraints:**

| Constraint | Description | Example |
|------------|-------------|---------|
| `minimum` | Minimum value (inclusive) | `minimum: 0` |
| `maximum` | Maximum value (inclusive) | `maximum: 100` |
| `exclusive_minimum` | Minimum value (exclusive) | `exclusive_minimum: 0` |
| `exclusive_maximum` | Maximum value (exclusive) | `exclusive_maximum: 100` |
| `multiple_of` | Must be multiple of | `multiple_of: 5` |
| `enum` | Allowed values | `enum: [1, 2, 3]` |

### Float / Number

```ruby
property :price, Float
# => { "type": "number" }
```

Supports the same constraints as Integer.

### Boolean

```ruby
property :active, T::Boolean
# => { "type": "boolean" }
```

Note: Use `T::Boolean` (not Ruby's `TrueClass`/`FalseClass`).

## Date and Time Types

### Date

```ruby
property :birth_date, Date
# => { "type": "string", "format": "date" }
```

### DateTime

```ruby
property :created_at, DateTime
# => { "type": "string", "format": "date-time" }
```

### Time

```ruby
property :start_time, Time
# => { "type": "string", "format": "time" }
```

## Generic Types

EasyTalk uses Sorbet-style generics for complex types.

### Arrays

```ruby
property :tags, T::Array[String]
# => { "type": "array", "items": { "type": "string" } }
```

**Array Constraints:**

| Constraint | Description | Example |
|------------|-------------|---------|
| `min_items` | Minimum array length | `min_items: 1` |
| `max_items` | Maximum array length | `max_items: 10` |
| `unique_items` | All items must be unique | `unique_items: true` |

```ruby
property :scores, T::Array[Integer], min_items: 1, max_items: 5
```

### Nullable Types

Use `T.nilable` to allow null values:

```ruby
property :nickname, T.nilable(String)
# => { "anyOf": [{ "type": "string" }, { "type": "null" }] }
```

**Note:** `T.nilable` makes the property nullable but still required. To make it optional as well:

```ruby
property :nickname, T.nilable(String), optional: true
```

Or use the helper method:

```ruby
nullable_optional_property :nickname, String
```

## Nested Models

Reference other EasyTalk models directly:

```ruby
class Address
  include EasyTalk::Model
  define_schema do
    property :street, String
    property :city, String
  end
end

class User
  include EasyTalk::Model
  define_schema do
    property :name, String
    property :address, Address  # Nested model
  end
end
```

Arrays of models:

```ruby
property :addresses, T::Array[Address]
```

## Composition Types

### OneOf

Exactly one schema must match:

```ruby
property :contact, T::OneOf[Email, Phone]
```

### AnyOf

At least one schema must match:

```ruby
property :identifier, T::AnyOf[UserId, Email, Username]
```

### AllOf

All schemas must match (for combining schemas):

```ruby
property :profile, T::AllOf[BasicInfo, ExtendedInfo]
```

## Null Type

For explicit null-only values:

```ruby
property :deprecated_field, NilClass
# => { "type": "null" }
```

## Type Summary

| Ruby Type | JSON Schema Type |
|-----------|------------------|
| `String` | `"string"` |
| `Integer` | `"integer"` |
| `Float` | `"number"` |
| `T::Boolean` | `"boolean"` |
| `Date` | `"string"` + `"date"` format |
| `DateTime` | `"string"` + `"date-time"` format |
| `Time` | `"string"` + `"time"` format |
| `T::Array[T]` | `"array"` |
| `T.nilable(T)` | `anyOf` with null |
| `NilClass` | `"null"` |
| Model class | `"object"` (inline or `$ref`) |
