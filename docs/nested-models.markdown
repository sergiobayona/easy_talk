---
layout: page
title: Nested Models
permalink: /nested-models/
---

# Nested Models

EasyTalk supports composing complex schemas from simpler building blocks. This enables clean, reusable data structures.

## Basic Nesting

Reference another EasyTalk model as a property type:

```ruby
class Address
  include EasyTalk::Model

  define_schema do
    property :street, String
    property :city, String
    property :zip_code, String, pattern: /^\d{5}$/
  end
end

class Person
  include EasyTalk::Model

  define_schema do
    property :name, String
    property :home_address, Address
    property :work_address, Address, optional: true
  end
end
```

### Generated Schema

```json
{
  "type": "object",
  "properties": {
    "name": { "type": "string" },
    "home_address": {
      "type": "object",
      "properties": {
        "street": { "type": "string" },
        "city": { "type": "string" },
        "zip_code": { "type": "string", "pattern": "^\\d{5}$" }
      },
      "required": ["street", "city", "zip_code"]
    },
    "work_address": { ... }
  },
  "required": ["name", "home_address"]
}
```

## Arrays of Models

Use `T::Array[ModelClass]` for collections:

```ruby
class Order
  include EasyTalk::Model

  define_schema do
    property :id, String
    property :items, T::Array[LineItem], min_items: 1
    property :shipping_address, Address
  end
end

class LineItem
  include EasyTalk::Model

  define_schema do
    property :product_id, String
    property :quantity, Integer, minimum: 1
    property :price, Float, minimum: 0
  end
end
```

## Auto-Instantiation

When you pass a Hash to a nested model property, EasyTalk automatically instantiates the nested model:

```ruby
person = Person.new(
  name: "Alice",
  home_address: {
    street: "123 Main St",
    city: "Boston",
    zip_code: "02101"
  }
)

person.home_address.class  # => Address
person.home_address.city   # => "Boston"
```

This works recursively for deeply nested structures.

## Using $ref for Reusability

By default, nested models are inlined. Enable `$ref` for cleaner, more reusable schemas:

```ruby
class Person
  include EasyTalk::Model

  define_schema do
    property :name, String
    property :address, Address, ref: true
  end
end
```

This generates:

```json
{
  "type": "object",
  "properties": {
    "name": { "type": "string" },
    "address": { "$ref": "#/$defs/Address" }
  },
  "$defs": {
    "Address": {
      "type": "object",
      "properties": { ... }
    }
  }
}
```

## Nullable Nested Models

Allow null values for nested models:

```ruby
property :backup_address, T.nilable(Address)
```

Or make it both nullable and optional:

```ruby
property :backup_address, T.nilable(Address), optional: true
```

## Composition with compose

Use `compose` to merge multiple schemas into one:

```ruby
class BasicInfo
  include EasyTalk::Model
  define_schema do
    property :name, String
    property :email, String
  end
end

class ContactInfo
  include EasyTalk::Model
  define_schema do
    property :phone, String
    property :address, Address
  end
end

class FullProfile
  include EasyTalk::Model
  define_schema do
    compose T::AllOf[BasicInfo, ContactInfo]
  end
end
```

## Polymorphic Types

Use `T::OneOf` or `T::AnyOf` for polymorphic properties:

```ruby
class EmailContact
  include EasyTalk::Model
  define_schema do
    property :email, String, format: "email"
  end
end

class PhoneContact
  include EasyTalk::Model
  define_schema do
    property :phone, String
  end
end

class User
  include EasyTalk::Model
  define_schema do
    property :name, String
    property :primary_contact, T::OneOf[EmailContact, PhoneContact]
  end
end
```

This ensures the `primary_contact` matches exactly one of the specified schemas.

## Best Practices

1. **Keep models focused** - Each model should represent one concept
2. **Reuse models** - Define common structures (Address, Money, etc.) once
3. **Use $ref for large schemas** - Reduces duplication and improves readability
4. **Validate at boundaries** - Nested models validate automatically when the parent validates
