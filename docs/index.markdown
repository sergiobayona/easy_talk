---
layout: home
title: Home
---

# EasyTalk

EasyTalk is a Ruby library for defining and generating JSON Schema from Ruby classes. It provides an ActiveModel-like interface for defining structured data models with validation and JSON Schema generation capabilities.

## Key Features

- **Schema Definition DSL** - Define JSON Schema using a clean Ruby DSL
- **Type System** - Support for Ruby types and Sorbet-style generics
- **ActiveModel Integration** - Built-in validations from schema constraints
- **Nested Models** - Compose complex schemas from simple building blocks
- **LLM Function Calling** - Generate OpenAI-compatible function schemas

## Quick Start

```ruby
class User
  include EasyTalk::Model

  define_schema do
    title "User"
    description "A user in the system"
    property :name, String, min_length: 2
    property :email, String, format: "email"
    property :age, Integer, minimum: 0, optional: true
  end
end

# Generate JSON Schema
User.json_schema
# => {"type"=>"object", "title"=>"User", ...}

# Create and validate instances
user = User.new(name: "Alice", email: "alice@example.com")
user.valid? # => true
```

## Documentation

- [Getting Started](getting-started) - Installation and basic usage
- [Schema Definition](schema-definition) - How to define schemas
- [Property Types](property-types) - Available types and constraints
- [Nested Models](nested-models) - Composing complex schemas
- [API Reference](api/) - Generated API documentation

## Links

- [GitHub Repository](https://github.com/sergiobayona/easy_talk)
- [RubyGems](https://rubygems.org/gems/easy_talk)
- [Changelog](https://github.com/sergiobayona/easy_talk/blob/main/CHANGELOG.md)
