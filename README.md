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

- **Use a richer type system than "string/integer/object"**
  EasyTalk supports Sorbet-style types and composition:
  - `T.nilable(Type)` for nullable fields
  - `T::Array[Type]` for typed arrays
  - `T::Tuple[Type1, Type2, ...]` for fixed-position typed arrays
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
  Use the same contract to generate JSON Schema for function/tool calling. See [RubyLLM Integration](#rubyllm-integration).

EasyTalk is for teams who want their data contracts to be **correct, reusable, and boring** (the good kind of boring).

---

## Table of Contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Property constraints](#property-constraints)
- [Core concepts](#core-concepts)
  - [Required vs optional vs nullable](#required-vs-optional-vs-nullable-dont-get-tricked)
  - [Nested models](#nested-models-and-automatic-instantiation)
  - [Tuple arrays](#tuple-arrays-fixed-position-types)
  - [Composition (AnyOf / OneOf / AllOf)](#composition-anyof--oneof--allof)
- [Validations](#validations)
  - [Automatic validations](#automatic-validations-default)
  - [Per-model validation control](#per-model-validation-control)
  - [Per-property validation control](#per-property-validation-control)
  - [Validation adapters](#validation-adapters)
- [Error formatting](#error-formatting)
- [Schema-only mode](#schema-only-mode)
- [RubyLLM Integration](#rubyllm-integration)
- [Configuration highlights](#configuration-highlights)
- [Advanced topics](#advanced-topics)
  - [JSON Schema drafts, `$id`, and `$ref`](#json-schema-drafts-id-and-ref)
  - [Additional properties with types](#additional-properties-with-types)
  - [Object-level constraints](#object-level-constraints)
  - [Custom type builders](#custom-type-builders)
- [Known limitations](#known-limitations)
- [Contributing](#contributing)
- [License](#license)

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

<table>
<tr>
<th>EasyTalk Model</th>
<th>Generated JSON Schema</th>
</tr>
<tr>
<td>

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
```

</td>
<td>

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

</td>
</tr>
</table>

```ruby
User.json_schema   # => Ruby Hash (JSON Schema)
user = User.new(name: "A")  # invalid: min_length is 2
user.valid?        # => false
user.errors        # => ActiveModel::Errors
```

---

## Rails ActiveRecord integration (optional)

If you're storing EasyTalk schemas in JSON/JSONB columns, you can use the
ActiveModel::Type adapter to avoid custom `serialize` coders:

```ruby
class Space < ApplicationRecord
  attribute :prompt_settings, ConversationSettings::SpaceSettings.to_type
end
```

This keeps EasyTalk as the single schema source of truth while improving
Rails integration and allowing best-effort type casting.

---

## Property constraints

| Constraint | Applies to | Example |
|------------|-----------|---------|
| `min_length` / `max_length` | String | `property :name, String, min_length: 2, max_length: 50` |
| `minimum` / `maximum` | Integer, Float | `property :age, Integer, minimum: 18, maximum: 120` |
| `format` | String | `property :email, String, format: "email"` |
| `pattern` | String | `property :zip, String, pattern: '^\d{5}$'` |
| `enum` | Any | `property :status, String, enum: ["active", "inactive"]` |
| `min_items` / `max_items` | Array, Tuple | `property :tags, T::Array[String], min_items: 1` |
| `unique_items` | Array, Tuple | `property :ids, T::Array[Integer], unique_items: true` |
| `additional_items` | Tuple | `property :coords, T::Tuple[Float, Float], additional_items: false` |
| `optional` | Any | `property :nickname, String, optional: true` |
| `default` | Any | `property :role, String, default: "user"` |
| `description` | Any | `property :name, String, description: "Full name"` |
| `title` | Any | `property :name, String, title: "User Name"` |

**Object-level constraints** (applied in `define_schema` block):
- `min_properties` / `max_properties` - Minimum/maximum number of properties
- `pattern_properties` - Schema for properties matching regex patterns
- `dependent_required` - Conditional property requirements

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

### Tuple arrays (fixed-position types)

Use `T::Tuple` for arrays where each position has a specific type (e.g., coordinates, CSV rows, database records):

<table>
<tr>
<th>EasyTalk Model</th>
<th>Generated JSON Schema</th>
</tr>
<tr>
<td>

```ruby
class GeoLocation
  include EasyTalk::Model

  define_schema do
    property :name, String
    # Fixed: [latitude, longitude]
    property :coordinates, T::Tuple[Float, Float]
  end
end

location = GeoLocation.new(
  name: 'Office',
  coordinates: [40.7128, -74.0060]
)
```

</td>
<td>

```json
{
  "properties": {
    "coordinates": {
      "type": "array",
      "items": [
        { "type": "number" },
        { "type": "number" }
      ]
    }
  }
}
```

</td>
</tr>
</table>

**Mixed-type tuples:**

```ruby
class DataRow
  include EasyTalk::Model

  define_schema do
    # Fixed: [name, age, active]
    property :row, T::Tuple[String, Integer, T::Boolean]
  end
end
```

**Controlling extra items:**

```ruby
define_schema do
  # Reject extra items (strict tuple)
  property :rgb, T::Tuple[Integer, Integer, Integer], additional_items: false

  # Allow extra items of specific type
  property :header_values, T::Tuple[String], additional_items: Integer

  # Allow any extra items (default)
  property :flexible, T::Tuple[String, Integer]
end
```

**Tuple validation:**

```ruby
model = GeoLocation.new(coordinates: [40.7, "invalid"])
model.valid?  # => false
model.errors[:coordinates]
# => ["item at index 1 must be a Float"]
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

## RubyLLM Integration

EasyTalk integrates seamlessly with [RubyLLM](https://github.com/crmne/ruby_llm) for structured outputs and tool definitions.

### Structured Outputs

Use any EasyTalk model with RubyLLM's `with_schema` to get structured JSON responses:

```ruby
class Recipe
  include EasyTalk::Model

  define_schema do
    description "A cooking recipe"
    property :name, String, description: "Name of the dish"
    property :ingredients, T::Array[String], description: "List of ingredients"
    property :prep_time_minutes, Integer, description: "Preparation time in minutes"
  end
end

chat = RubyLLM.chat.with_schema(Recipe)
response = chat.ask("Give me a simple pasta recipe")

# RubyLLM returns parsed JSON - instantiate with EasyTalk model
recipe = Recipe.new(response.content)
recipe.name           # => "Spaghetti Aglio e Olio"
recipe.ingredients    # => ["spaghetti", "garlic", "olive oil", ...]
```

### Tools

Create LLM tools by inheriting from `RubyLLM::Tool` and including `EasyTalk::Model`:

```ruby
class Weather < RubyLLM::Tool
  include EasyTalk::Model

  define_schema do
    description 'Gets current weather for a location'
    property :latitude, String, description: 'Latitude (e.g., 52.5200)'
    property :longitude, String, description: 'Longitude (e.g., 13.4050)'
  end

  def execute(latitude:, longitude:)
    # Fetch weather data from API...
    { temperature: 22, conditions: "sunny" }
  end
end

chat = RubyLLM.chat.with_tool(Weather)
response = chat.ask("What's the weather in Berlin?")
```

This pattern gives you:
- Full access to `RubyLLM::Tool` features (`halt`, `call`, etc.)
- EasyTalk's schema DSL for parameter definitions
- Automatic JSON Schema generation for the LLM

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
  config.base_schema_uri = nil                 # Base URI for auto-generating $id
  config.auto_generate_ids = false             # Auto-generate $id from base_schema_uri
  config.prefer_external_refs = false          # Use external URI in $ref when available
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

#### External schema references

Use external URIs in `$ref` for modular, reusable schemas:

<table>
<tr>
<th>EasyTalk Model</th>
<th>Generated JSON Schema</th>
</tr>
<tr>
<td>

```ruby
EasyTalk.configure do |config|
  config.use_refs = true
  config.prefer_external_refs = true
  config.base_schema_uri = 'https://example.com/schemas'
  config.auto_generate_ids = true
end

class Address
  include EasyTalk::Model

  define_schema do
    property :street, String
    property :city, String
  end
end

class Customer
  include EasyTalk::Model

  define_schema do
    property :name, String
    property :address, Address
  end
end

Customer.json_schema
```

</td>
<td>

```json
{
  "properties": {
    "address": {
      "$ref": "https://example.com/schemas/address"
    }
  },
  "$defs": {
    "Address": {
      "$id": "https://example.com/schemas/address",
      "properties": {
        "street": { "type": "string" },
        "city": { "type": "string" }
      }
    }
  }
}
```

</td>
</tr>
</table>

**Explicit schema IDs:**

```ruby
class Address
  include EasyTalk::Model

  define_schema do
    schema_id 'https://example.com/schemas/address'
    property :street, String
  end
end
```

**Per-property ref control:**

```ruby
class Customer
  include EasyTalk::Model

  define_schema do
    property :address, Address, ref: false  # Inline instead of ref
    property :billing, Address              # Uses ref (global setting)
  end
end
```

### Additional properties with types

Beyond boolean values, `additional_properties` now supports type constraints for dynamic properties:

```ruby
class Config
  include EasyTalk::Model

  define_schema do
    property :name, String

    # Allow any string-typed additional properties
    additional_properties String
  end
end

config = Config.new(name: 'app')
config.label = 'Production'  # Dynamic property
config.as_json
# => { 'name' => 'app', 'label' => 'Production' }
```

**With constraints:**

<table>
<tr>
<th>EasyTalk Model</th>
<th>Generated JSON Schema</th>
</tr>
<tr>
<td>

```ruby
class StrictConfig
  include EasyTalk::Model

  define_schema do
    property :id, Integer
    # Integer values between 0 and 100 only
    additional_properties Integer,
      minimum: 0, maximum: 100
  end
end

StrictConfig.json_schema
```

</td>
<td>

```json
{
  "properties": {
    "id": { "type": "integer" }
  },
  "additionalProperties": {
    "type": "integer",
    "minimum": 0,
    "maximum": 100
  }
}
```

</td>
</tr>
</table>

**Nested models as additional properties:**

```ruby
class Person
  include EasyTalk::Model

  define_schema do
    property :name, String
    additional_properties Address  # All additional properties must be Address objects
  end
end
```

### Object-level constraints

Apply schema-wide constraints to limit or validate object structure:

```ruby
class StrictObject
  include EasyTalk::Model

  define_schema do
    property :required1, String
    property :required2, String
    property :optional1, String, optional: true
    property :optional2, String, optional: true

    # Require at least 2 properties
    min_properties 2
    # Allow at most 3 properties
    max_properties 3
  end
end

obj = StrictObject.new(required1: 'a')
obj.valid?  # => false (only 1 property, needs at least 2)
```

**Pattern properties:**

```ruby
class DynamicConfig
  include EasyTalk::Model

  define_schema do
    property :name, String

    # Properties matching /^env_/ must be strings
    pattern_properties(
      '^env_' => { type: 'string' }
    )
  end
end
```

**Dependent required:**

```ruby
class ShippingInfo
  include EasyTalk::Model

  define_schema do
    property :name, String
    property :credit_card, String, optional: true
    property :billing_address, String, optional: true

    # If credit_card is present, billing_address is required
    dependent_required(
      'credit_card' => ['billing_address']
    )
  end
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
