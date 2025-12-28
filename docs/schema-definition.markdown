---
layout: page
title: Schema Definition
permalink: /schema-definition/
---

# Schema Definition

The `define_schema` block is where you declare your model's structure. It provides a clean DSL for defining JSON Schema properties and metadata.

## Basic Structure

```ruby
class MyModel
  include EasyTalk::Model

  define_schema do
    title "Model Title"
    description "What this model represents"

    property :field_name, Type, constraints...
  end
end
```

## Schema Metadata

### title

Sets the schema title (appears in JSON Schema output):

```ruby
define_schema do
  title "User Account"
end
```

### description

Adds a description to the schema:

```ruby
define_schema do
  description "Represents a user account in the system"
end
```

## Defining Properties

The `property` method defines a schema property:

```ruby
property :name, Type, option: value, ...
```

### Required vs Optional

By default, all properties are **required**. Use `optional: true` to make a property optional:

```ruby
define_schema do
  property :name, String                    # Required
  property :nickname, String, optional: true # Optional
end
```

### Property Titles and Descriptions

Add metadata to individual properties:

```ruby
property :email, String,
  title: "Email Address",
  description: "The user's primary email"
```

### Property Renaming

Use `:as` to rename a property in the JSON Schema output:

```ruby
property :created_at, String, as: :createdAt
```

This creates a property named `createdAt` in the schema while keeping `created_at` as the Ruby attribute.

## Type Constraints

Different types support different constraints. See [Property Types](property-types) for the full list.

### String Constraints

```ruby
property :username, String,
  min_length: 3,
  max_length: 20,
  pattern: /^[a-z0-9_]+$/
```

### Numeric Constraints

```ruby
property :age, Integer,
  minimum: 0,
  maximum: 150

property :price, Float,
  exclusive_minimum: 0
```

### Enum Values

```ruby
property :status, String, enum: %w[active inactive pending]
```

## Composition

### compose

Use `compose` to include schemas from other models:

```ruby
class FullProfile
  include EasyTalk::Model

  define_schema do
    compose T::AllOf[BasicInfo, ContactInfo, Preferences]
  end
end
```

### Composition Types

- `T::AllOf[A, B]` - Must match all schemas
- `T::AnyOf[A, B]` - Must match at least one schema
- `T::OneOf[A, B]` - Must match exactly one schema

## Configuration Options

### Per-Model Validation Control

Disable automatic validations for a specific model:

```ruby
define_schema(validations: false) do
  property :data, String
end
```

### Per-Property Validation Control

Disable validation for specific properties:

```ruby
property :legacy_field, String, validate: false
```

## Example: Complete Model

```ruby
class Product
  include EasyTalk::Model

  define_schema do
    title "Product"
    description "A product in the catalog"

    property :id, String, format: "uuid"
    property :name, String, min_length: 1, max_length: 100
    property :description, String, optional: true
    property :price, Float, minimum: 0
    property :currency, String, enum: %w[USD EUR GBP], default: "USD"
    property :category, String
    property :tags, T::Array[String], optional: true
    property :active, T::Boolean, default: true
    property :created_at, DateTime, as: :createdAt
  end
end
```
