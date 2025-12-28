---
layout: page
title: Getting Started
permalink: /getting-started/
---

# Getting Started with EasyTalk

## Requirements

- Ruby 3.2 or later
- ActiveModel/ActiveSupport 7.0-8.x

## Installation

Add EasyTalk to your Gemfile:

```ruby
gem 'easy_talk'
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install easy_talk
```

## Basic Usage

### 1. Define a Model

Include `EasyTalk::Model` in your class and use `define_schema` to declare properties:

```ruby
require 'easy_talk'

class Person
  include EasyTalk::Model

  define_schema do
    title "Person"
    description "A person record"

    property :name, String
    property :age, Integer
    property :email, String, format: "email"
  end
end
```

### 2. Generate JSON Schema

Call `.json_schema` on your class to get the JSON Schema:

```ruby
Person.json_schema
```

This produces:

```json
{
  "type": "object",
  "title": "Person",
  "description": "A person record",
  "properties": {
    "name": { "type": "string" },
    "age": { "type": "integer" },
    "email": { "type": "string", "format": "email" }
  },
  "required": ["name", "age", "email"],
  "additionalProperties": false
}
```

### 3. Create and Validate Instances

EasyTalk models work like ActiveModel objects:

```ruby
person = Person.new(name: "Alice", age: 30, email: "alice@example.com")
person.valid?  # => true
person.name    # => "Alice"

# Invalid data triggers validation errors
invalid = Person.new(name: "", age: -5, email: "not-an-email")
invalid.valid?       # => false
invalid.errors.full_messages
# => ["Name is too short", "Age must be greater than or equal to 0", ...]
```

## Next Steps

- [Schema Definition](schema-definition) - Learn the full DSL
- [Property Types](property-types) - Explore available types and constraints
- [Nested Models](nested-models) - Build complex, composable schemas
