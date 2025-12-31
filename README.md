# EasyTalk

[![Gem Version](https://badge.fury.io/rb/easy_talk.svg)](https://badge.fury.io/rb/easy_talk)
[![Ruby](https://github.com/sergiobayona/easy_talk/actions/workflows/dev-build.yml/badge.svg)](https://github.com/sergiobayona/easy_talk/actions/workflows/dev-build.yml)
[![codecov](https://codecov.io/gh/sergiobayona/easy_talk/graph/badge.svg)](https://codecov.io/gh/sergiobayona/easy_talk)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby](https://img.shields.io/badge/ruby-3.2%2B-ruby.svg)](https://www.ruby-lang.org)
[![Downloads](https://img.shields.io/gem/dt/easy_talk.svg)](https://rubygems.org/gems/easy_talk)
[![Documentation](https://img.shields.io/badge/docs-rubydoc.info-blue.svg)](https://rubydoc.info/gems/easy_talk)
[![GitHub stars](https://img.shields.io/github/stars/sergiobayona/easy_talk?style=social)](https://github.com/sergiobayona/easy_talk)

Ruby library for defining **structured data contracts** that generate **JSON Schema** *and* (optionally) **runtime validations** from the same definition.

Think “Pydantic-style ergonomics” for Ruby, with first-class JSON Schema output.

---

## Why EasyTalk?

You can hand-write JSON Schema, then hand-write validations, then hand-write error responses… and eventually you’ll ship a bug where those three disagree.

EasyTalk makes the schema definition the single source of truth, so you can:

- **Define once, use everywhere**  
  One Ruby DSL gives you:
  - `json_schema` for docs, OpenAPI, LLM tools, and external validators
  - `valid?` / `errors` (when using `EasyTalk::Model`) for runtime validation

- **Stop arguing with JSON Schema’s verbosity**  
  Express constraints in Ruby where you already live:
  ```ruby
  property :email, String, format: "email"
  property :age, Integer, minimum: 18
  property :tags, T::Array[String], min_items: 1
  ```

- **Use a richer type system than “string/integer/object”**  
  EasyTalk supports Sorbet-style types and composition:
  - `T.nilable(Type)` for nullable fields
  - `T::Array[Type]` for typed arrays
  - `T::Boolean`
  - `T::AnyOf`, `T::OneOf`, `T::AllOf` for schema composition

- **Get validations for free (when you want them)**  
  With `auto_validations` enabled (default), schema constraints generate ActiveModel validations—**including nested models**, even inside arrays.

- **Make API errors consistent**  
  Format validation errors as:
  - flat lists
  - JSON Pointer
  - **RFC 7807** problem details
  - **JSON:API** error objects

- **LLM tool/function schemas without a second schema layer**  
  Use the same contract to generate JSON Schema for function/tool calling.

EasyTalk is for teams who want their data contracts to be **correct, reusable, and boring** (the good kind of boring).

---

## Installation

### Requirements
- Ruby **3.2+**

Add to your Gemfile:

```ruby
gem "easy_talk"
```

Then:

```bash
bundle install
```

---

## Quick start

```ruby
require "easy_talk"

class User
  include EasyTalk::Model

  define_schema do
    title "User"
    description "A user of the system"

    property :id, String
    property :name, String, min_length: 2
    property :email, String, format: "email"
    property :age, Integer, minimum: 18
  end
end

User.json_schema   # => Ruby Hash (JSON Schema)
user = User.new(name: "A")  # invalid: min_length is 2
user.valid?        # => false
user.errors        # => ActiveModel::Errors
```

**Generated JSON Schema:**

```json
{
  "type": "object",
  "title": "User",
  "description": "A user of the system",
  "properties": {
    "id": { "type": "string" },
    "name": { "type": "string", "minLength": 2 },
    "email": { "type": "string", "format": "email" },
    "age": { "type": "integer", "minimum": 18 }
  },
  "required": ["id", "name", "email", "age"]
}
```

---

## Property constraints

| Constraint | Applies to | Example |
|------------|-----------|---------|
| `min_length` / `max_length` | String | `property :name, String, min_length: 2, max_length: 50` |
| `minimum` / `maximum` | Integer, Float | `property :age, Integer, minimum: 18, maximum: 120` |
| `format` | String | `property :email, String, format: "email"` |
| `pattern` | String | `property :zip, String, pattern: '^\d{5}$'` |
| `enum` | Any | `property :status, String, enum: ["active", "inactive"]` |
| `min_items` / `max_items` | Array | `property :tags, T::Array[String], min_items: 1` |
| `unique_items` | Array | `property :ids, T::Array[Integer], unique_items: true` |
| `optional` | Any | `property :nickname, String, optional: true` |
| `default` | Any | `property :role, String, default: "user"` |
| `description` | Any | `property :name, String, description: "Full name"` |
| `title` | Any | `property :name, String, title: "User Name"` |

When `auto_validations` is enabled (default), these constraints automatically generate corresponding ActiveModel validations.

---

## Core concepts

### Required vs optional vs nullable (don't get tricked)

JSON Schema distinguishes:
- **Optional**: property may be omitted (not in `required`)
- **Nullable**: property may be `null` (type includes `"null"`)

EasyTalk mirrors that precisely:

```ruby
class Profile
  include EasyTalk::Model

  define_schema do
    # required, not nullable
    property :name, String

    # required, nullable (must exist, may be null)
    property :age, T.nilable(Integer)

    # optional, not nullable (may be omitted, but cannot be null if present)
    property :nickname, String, optional: true

    # optional + nullable (may be omitted OR null)
    property :bio, T.nilable(String), optional: true
    # or, equivalently:
    nullable_optional_property :website, String
  end
end
```

By default, `T.nilable(Type)` makes a field **nullable but still required**.  
If you want “nilable implies optional” behavior globally:

```ruby
EasyTalk.configure do |config|
  config.nilable_is_optional = true
end
```

---

### Nested models (and automatic instantiation)

Define nested objects as separate classes, then reference them:

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
    property :address, Address
  end
end

user = User.new(
  name: "John",
  address: { street: "123 Main St", city: "Boston" } # Hash becomes Address automatically
)

user.address.class  # => Address
```

Nested models inside arrays work too:

```ruby
class Order
  include EasyTalk::Model

  define_schema do
    property :line_items, T::Array[Address], min_items: 1
  end
end
```

---

### Composition (AnyOf / OneOf / AllOf)

```ruby
class ProductA
  include EasyTalk::Model
  define_schema do
    property :sku, String
    property :weight, Float
  end
end

class ProductB
  include EasyTalk::Model
  define_schema do
    property :sku, String
    property :color, String
  end
end

class Cart
  include EasyTalk::Model

  define_schema do
    property :items, T::Array[T::AnyOf[ProductA, ProductB]]
  end
end
```

---

## Validations

### Automatic validations (default)

EasyTalk can generate ActiveModel validations from constraints:

```ruby
EasyTalk.configure do |config|
  config.auto_validations = true
end
```

Disable globally:

```ruby
EasyTalk.configure do |config|
  config.auto_validations = false
end
```

When auto validations are off, you can still write validations manually:

```ruby
class User
  include EasyTalk::Model

  validates :name, presence: true, length: { minimum: 2 }

  define_schema do
    property :name, String, min_length: 2
  end
end
```

### Per-model validation control

```ruby
class LegacyModel
  include EasyTalk::Model

  define_schema(validations: false) do
    property :data, String, min_length: 1  # no validation generated
  end
end
```

### Per-property validation control

```ruby
class User
  include EasyTalk::Model

  define_schema do
    property :name, String, min_length: 2
    property :legacy_field, String, validate: false
  end
end
```

### Validation adapters

EasyTalk uses a pluggable adapter system:

```ruby
EasyTalk.configure do |config|
  config.validation_adapter = :active_model  # default
  # config.validation_adapter = :none        # disable validation generation
end
```

---

## Error formatting

Instance helpers:

```ruby
user.validation_errors_flat
user.validation_errors_json_pointer
user.validation_errors_rfc7807
user.validation_errors_jsonapi
```

Format directly:

```ruby
EasyTalk::ErrorFormatter.format(user.errors, format: :rfc7807, title: "User Validation Failed")
```

Global defaults:

```ruby
EasyTalk.configure do |config|
  config.default_error_format = :rfc7807
  config.error_type_base_uri = "https://api.example.com/errors"
  config.include_error_codes = true
end
```

---

## Schema-only mode

If you want schema generation and attribute accessors **without** ActiveModel validation:

```ruby
class ApiContract
  include EasyTalk::Schema

  define_schema do
    title "API Contract"
    property :name, String, min_length: 2
    property :age, Integer, minimum: 0
  end
end

ApiContract.json_schema
contract = ApiContract.new(name: "Test", age: 25)

# No validations available:
# contract.valid?  # => NoMethodError
```

Use this for documentation, OpenAPI generation, or when validation happens elsewhere.

---

## LLM function/tool schemas

EasyTalk can generate function specs compatible with LLM tool calling:

```ruby
class Weather
  include EasyTalk::Model

  define_schema do
    title "GetWeather"
    description "Get the current weather in a given location"
    property :location, String, description: "The city and state, e.g. San Francisco, CA"
    property :unit, String, enum: ["celsius", "fahrenheit"], default: "fahrenheit"
  end
end

function_spec = EasyTalk::Tools::FunctionBuilder.new(Weather)
```

---

## Configuration highlights

```ruby
EasyTalk.configure do |config|
  # Schema behavior
  config.default_additional_properties = false
  config.nilable_is_optional = false
  config.schema_version = :none
  config.schema_id = nil
  config.use_refs = false
  config.property_naming_strategy = :identity  # :snake_case, :camel_case, :pascal_case

  # Validations
  config.auto_validations = true
  config.validation_adapter = :active_model

  # Error formatting
  config.default_error_format = :flat          # :flat, :json_pointer, :rfc7807, :jsonapi
  config.error_type_base_uri = "about:blank"
  config.include_error_codes = true
end
```

---

## Advanced topics

For more detailed documentation, see the [full API reference on RubyDoc](https://rubydoc.info/gems/easy_talk).

### JSON Schema drafts, `$id`, and `$ref`

EasyTalk can emit `$schema` for multiple drafts (Draft-04 through 2020-12), supports `$id`, and can use `$ref`/`$defs` for reusable definitions:

```ruby
EasyTalk.configure do |config|
  config.schema_version = :draft202012
  config.schema_id = "https://example.com/schemas/user.json"
  config.use_refs = true  # Use $ref/$defs for nested models
end
```

### Custom type builders

Register custom types with their own schema builders:

```ruby
EasyTalk.configure do |config|
  config.register_type(Money, MoneySchemaBuilder)
end

# Or directly:
EasyTalk::Builders::Registry.register(Money, MoneySchemaBuilder)
```

See the [Custom Type Builders documentation](https://rubydoc.info/gems/easy_talk/EasyTalk/Builders/Registry) for details on creating builders.

---

## Known limitations

EasyTalk aims to produce broadly compatible JSON Schema, but:
- Some draft-specific keywords/features may require manual schema tweaks
- Custom formats are limited (extend via custom builders when needed)
- Extremely complex composition can outgrow “auto validations” and may need manual validations or external schema validators

---

## Contributing

- Run `bin/setup`
- Run specs: `bundle exec rake spec`
- Run lint: `bundle exec rubocop`

Bug reports and PRs welcome.

---

## License

MIT
