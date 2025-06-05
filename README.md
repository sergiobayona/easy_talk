# EasyTalk

[![Gem Version](https://badge.fury.io/rb/easy_talk.svg)](https://badge.fury.io/rb/easy_talk)
[![Ruby](https://github.com/sergiobayona/easy_talk/actions/workflows/dev-build.yml/badge.svg)](https://github.com/sergiobayona/easy_talk/actions/workflows/dev-build.yml)

## Introduction

### What is EasyTalk?
EasyTalk is a Ruby library that simplifies defining and generating JSON Schema. It provides an intuitive interface for Ruby developers to define structured data models that can be used for validation and documentation.

### Key Features
* **Intuitive Schema Definition**: Use Ruby classes and methods to define JSON Schema documents easily.
* **Automatic ActiveModel Validations**: Schema constraints automatically generate corresponding ActiveModel validations (configurable).
* **Works for plain Ruby classes and ActiveRecord models**: Integrate with existing code or build from scratch.
* **LLM Function Support**: Ideal for integrating with Large Language Models (LLMs) such as OpenAI's GPT series. EasyTalk enables you to effortlessly create JSON Schema documents describing the inputs and outputs of LLM function calls.
* **Schema Composition**: Define EasyTalk models and reference them in other EasyTalk models to create complex schemas.
* **Enhanced Model Integration**: Automatic instantiation of nested EasyTalk models from hash attributes.
* **Flexible Configuration**: Global and per-model configuration options for fine-tuned control.

### Use Cases
- API request/response validation
- LLM function definitions
- Object structure documentation
- Data validation and transformation
- Configuration schema definitions

### Inspiration
Inspired by Python's Pydantic library, EasyTalk brings similar functionality to the Ruby ecosystem, providing a Ruby-friendly approach to JSON Schema operations.

## Installation

### Requirements
- Ruby 3.2 or higher

### Version 2.0.0 Breaking Changes

⚠️ **IMPORTANT**: Version 2.0.0 includes breaking changes. Please review before upgrading:

- **Removed**: Block-style nested object definitions (using `Hash do ... end`)
- **Migration**: Use class references instead of inline Hash definitions

```ruby
# ❌ No longer supported (v1.x style)
define_schema do
  property :address, Hash do
    property :street, String
    property :city, String
  end
end

# ✅ New approach (v2.x style)
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
    property :address, Address  # Reference the class directly
  end
end
```

### Installation Steps
Add EasyTalk to your application's Gemfile:

```ruby
gem 'easy_talk'
```

Or install it directly:

```bash
$ gem install easy_talk
```

### Verification
After installation, you can verify it's working by creating a simple model:

```ruby
require 'easy_talk'

class Test
  include EasyTalk::Model
  
  define_schema do
    property :name, String
  end
end

puts Test.json_schema
```

## Quick Start

### Minimal Example
Here's a basic example to get you started with EasyTalk:

```ruby
class User
  include EasyTalk::Model

  define_schema do
    title "User"
    description "A user of the system"
    property :name, String, description: "The user's name"
    property :email, String, format: "email"
    property :age, Integer, minimum: 18
  end
end
```

### Generated JSON Schema
Calling `User.json_schema` will generate:

```ruby
{
  "type" => "object",
  "title" => "User",
  "description" => "A user of the system",
  "properties" => {
    "name" => {
      "type" => "string", 
      "description" => "The user's name"
    },
    "email" => {
      "type" => "string", 
      "format" => "email"
    },
    "age" => {
      "type" => "integer", 
      "minimum" => 18
    }
  },
  "required" => ["name", "email", "age"]
}
```

### Basic Usage
Creating and validating an instance of your model:

```ruby
user = User.new(name: "John Doe", email: "john@example.com", age: 25)
user.valid? # => true (automatically validates based on schema constraints)

user.age = 17
user.valid? # => false (violates minimum: 18 constraint)
user.errors[:age] # => ["must be greater than or equal to 18"]
```

## Core Concepts

### Schema Definition
In EasyTalk, you define your schema by including the `EasyTalk::Model` module and using the `define_schema` method. This method takes a block where you can define the properties and constraints of your schema.

```ruby
class MyModel
  include EasyTalk::Model

  define_schema do
    title "My Model"
    description "Description of my model"
    property :some_property, String
    property :another_property, Integer
  end
end
```

### Property Types

#### Ruby Types
EasyTalk supports standard Ruby types directly:

- `String`: String values
- `Integer`: Integer values
- `Float`: Floating-point numbers
- `Date`: Date values
- `DateTime`: Date and time values

#### Sorbet-Style Types
For complex types, EasyTalk uses Sorbet-style type notation:

- `T::Boolean`: Boolean values (true/false)
- `T::Array[Type]`: Arrays with items of a specific type
- `T.nilable(Type)`: Type that can also be nil

#### Custom Types
EasyTalk supports special composition types:

- `T::AnyOf[Type1, Type2, ...]`: Value can match any of the specified schemas
- `T::OneOf[Type1, Type2, ...]`: Value must match exactly one of the specified schemas
- `T::AllOf[Type1, Type2, ...]`: Value must match all of the specified schemas

### Property Constraints
Property constraints depend on the type of property. Some common constraints include:

- `description`: A description of the property
- `title`: A title for the property
- `format`: A format hint for the property (e.g., "email", "date")
- `enum`: A list of allowed values
- `minimum`/`maximum`: Minimum/maximum values for numbers
- `min_length`/`max_length`: Minimum/maximum length for strings
- `pattern`: A regular expression pattern for strings
- `min_items`/`max_items`: Minimum/maximum number of items for arrays
- `unique_items`: Whether array items must be unique

### Required vs Optional Properties
By default, all properties defined in an EasyTalk model are required. You can make a property optional by specifying `optional: true`:

```ruby
define_schema do
  property :name, String
  property :middle_name, String, optional: true
end
```

In this example, `name` is required but `middle_name` is optional.

### Automatic Validation Generation
EasyTalk automatically generates ActiveModel validations from your schema constraints. This feature is enabled by default but can be configured:

```ruby
class User
  include EasyTalk::Model
  
  define_schema do
    property :name, String, min_length: 2, max_length: 50
    property :email, String, format: "email"
    property :age, Integer, minimum: 18, maximum: 120
    property :status, String, enum: ["active", "inactive", "pending"]
  end
  # Validations are automatically generated:
  # validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  # validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # validates :age, presence: true, numericality: { greater_than_or_equal_to: 18, less_than_or_equal_to: 120 }
  # validates :status, presence: true, inclusion: { in: ["active", "inactive", "pending"] }
end

user = User.new(name: "Jo", email: "invalid-email", age: 17)
user.valid? # => false
user.errors.full_messages 
# => ["Name is too short (minimum is 2 characters)", 
#     "Email is invalid", 
#     "Age must be greater than or equal to 18"]
```

### Manual Validation Overrides
You can still add manual validations alongside automatic ones:

```ruby
class User
  include EasyTalk::Model
  
  # Custom validation in addition to automatic ones
  validates :email, uniqueness: true
  validate :complex_business_rule
  
  define_schema do
    property :name, String
    property :email, String, format: "email"
    property :age, Integer, minimum: 18
  end
  
  private
  
  def complex_business_rule
    # Custom validation logic
  end
end
```

## Defining Schemas

### Basic Schema Structure
A schema definition consists of a class that includes `EasyTalk::Model` and a `define_schema` block:

```ruby
class Person
  include EasyTalk::Model

  define_schema do
    title "Person"
    property :name, String
    property :age, Integer
  end
end
```

### Property Definitions
Properties are defined using the `property` method, which takes a name, a type, and optional constraints:

```ruby
property :name, String, description: "The person's name", title: "Full Name"
property :age, Integer, minimum: 0, maximum: 120, description: "The person's age"
```

### Arrays and Collections
Arrays can be defined using the `T::Array` type:

```ruby
property :tags, T::Array[String], min_items: 1, unique_items: true
property :scores, T::Array[Integer], description: "List of scores"
```

You can also define arrays of complex types:

```ruby
property :addresses, T::Array[Address], description: "List of addresses"
```

### Constraints and Automatic Validations
Constraints are added to properties and are used for both schema generation and automatic validation generation:

```ruby
define_schema do
  property :name, String, min_length: 2, max_length: 50
  property :email, String, format: "email"
  property :category, String, enum: ["A", "B", "C"]
  property :score, Float, minimum: 0.0, maximum: 100.0
  property :tags, T::Array[String], min_items: 1, max_items: 10
end
# Automatically generates equivalent ActiveModel validations:
# validates :name, presence: true, length: { minimum: 2, maximum: 50 }
# validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
# validates :category, presence: true, inclusion: { in: ["A", "B", "C"] }
# validates :score, presence: true, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 100.0 }
# validates :tags, presence: true, length: { minimum: 1, maximum: 10 }
```

### Supported Constraint-to-Validation Mappings

| Constraint | Validation Generated |
|------------|---------------------|
| `min_length`, `max_length` | `length: { minimum: X, maximum: Y }` |
| `minimum`, `maximum` | `numericality: { greater_than_or_equal_to: X, less_than_or_equal_to: Y }` |
| `format: "email"` | `format: { with: URI::MailTo::EMAIL_REGEXP }` |
| `format: "url"` or `format: "uri"` | `format: { with: URI::regexp }` |
| `pattern: /regex/` | `format: { with: /regex/ }` |
| `enum: [...]` | `inclusion: { in: [...] }` |
| `min_items`, `max_items` (arrays) | `length: { minimum: X, maximum: Y }` |
| `optional: true` | Skips presence validation |
| `T.nilable(Type)` | Allows nil values, skips presence validation |

### Additional Properties
By default, EasyTalk models do not allow additional properties beyond those defined in the schema. You can change this behavior using the `additional_properties` keyword:

```ruby
define_schema do
  property :name, String
  additional_properties true
end
```

With `additional_properties true`, you can add arbitrary properties to your model instances:

```ruby
company = Company.new
company.name = "Acme Corp"        # Defined property
company.location = "New York"     # Additional property
company.employee_count = 100      # Additional property
```

## Schema Composition

### Using T::AnyOf
The `T::AnyOf` type allows a property to match any of the specified schemas:

```ruby
class Payment
  include EasyTalk::Model

  define_schema do
    property :details, T::AnyOf[CreditCard, Paypal, BankTransfer]
  end
end
```

### Using T::OneOf
The `T::OneOf` type requires a property to match exactly one of the specified schemas:

```ruby
class Contact
  include EasyTalk::Model

  define_schema do
    property :contact, T::OneOf[PhoneContact, EmailContact]
  end
end
```

### Using T::AllOf
The `T::AllOf` type requires a property to match all of the specified schemas:

```ruby
class VehicleRegistration
  include EasyTalk::Model
  
  define_schema do
    compose T::AllOf[VehicleIdentification, OwnerInfo, RegistrationDetails]
  end
end
```

### Complex Compositions
You can combine composition types to create complex schemas:

```ruby
class ComplexObject
  include EasyTalk::Model
  
  define_schema do
    property :basic_info, BaseInfo
    property :specific_details, T::OneOf[DetailTypeA, DetailTypeB]
    property :metadata, T::AnyOf[AdminMetadata, UserMetadata, nil]
  end
end
```

### Reusing Models
Models can reference other models to create hierarchical schemas:

```ruby
class Address
  include EasyTalk::Model
  
  define_schema do
    property :street, String
    property :city, String
    property :state, String
    property :zip, String
  end
end

class User
  include EasyTalk::Model
  
  define_schema do
    property :name, String
    property :address, Address
  end
end
```

## ActiveModel Integration

### Enhanced Validation System
EasyTalk models include comprehensive ActiveModel validation support with automatic generation:

```ruby
class User
  include EasyTalk::Model
  
  # Manual validations work alongside automatic ones
  validates :age, comparison: { greater_than: 21 }  # Additional business rule
  validates :height, numericality: { greater_than: 0 }  # Overrides auto-validation
  
  define_schema do
    property :name, String, min_length: 2  # Auto-generates presence + length validations
    property :age, Integer, minimum: 18   # Auto-generates presence + numericality validations
    property :height, Float               # Auto-generates presence validation (overridden above)
  end
end
```

### Error Handling
You can access validation errors using the standard ActiveModel methods:

```ruby
user = User.new(name: "J", age: 18, height: -5.9)
user.valid? # => false
user.errors[:name] # => ["is too short (minimum is 2 characters)"]
user.errors[:age] # => ["must be greater than 21"] # Custom validation
user.errors[:height] # => ["must be greater than 0"] # Overridden validation
```

### Model Attributes
EasyTalk models provide getters and setters for all defined properties:

```ruby
user = User.new
user.name = "John"
user.age = 30
puts user.name # => "John"
```

You can also initialize a model with a hash of attributes, including nested EasyTalk models:

```ruby
user = User.new(name: "John", age: 30, height: 5.9)

# NEW in v2.0.0: Automatic nested model instantiation
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

# Hash attributes automatically instantiate nested models
user = User.new(
  name: "John",
  address: { street: "123 Main St", city: "Boston" }
)
user.address.class # => Address (automatically instantiated)
user.address.street # => "123 Main St"
```

## ActiveRecord Integration

### Automatic Schema Generation
For ActiveRecord models, EasyTalk automatically generates a schema based on the database columns:

```ruby
class Product < ActiveRecord::Base
  include EasyTalk::Model
end
```

This will create a schema with properties for each column in the `products` table.

### Enhancing Generated Schemas
You can enhance the auto-generated schema with the `enhance_schema` method:

```ruby
class Product < ActiveRecord::Base
  include EasyTalk::Model
  
  enhance_schema({
    title: "Retail Product",
    description: "A product available for purchase",
    properties: {
      name: {
        description: "Product display name",
        title: "Product Name"
      },
      price: {
        description: "Retail price in USD"
      }
    }
  })
end
```

### Column Exclusion Options
EasyTalk provides several ways to exclude columns from your JSON schema:

#### 1. Global Configuration

```ruby
EasyTalk.configure do |config|
  # Exclude specific columns by name from all models
  config.excluded_columns = [:created_at, :updated_at, :deleted_at]
  
  # Exclude all foreign key columns (columns ending with '_id')
  config.exclude_foreign_keys = true   # Default: false
  
  # Exclude all primary key columns ('id')
  config.exclude_primary_key = true    # Default: true
  
  # Exclude timestamp columns ('created_at', 'updated_at')
  config.exclude_timestamps = true     # Default: true
  
  # Exclude all association properties
  config.exclude_associations = true   # Default: false
end
```

#### 2. Model-Specific Column Ignoring

```ruby
class Product < ActiveRecord::Base
  include EasyTalk::Model
  
  enhance_schema({
    ignore: [:internal_ref_id, :legacy_code]  # Model-specific exclusions
  })
end
```

### Virtual Properties
You can add properties that don't exist as database columns:

```ruby
class Product < ActiveRecord::Base
  include EasyTalk::Model
  
  enhance_schema({
    properties: {
      full_details: {
        virtual: true,
        type: :string,
        description: "Complete product information"
      }
    }
  })
end
```

### Associations and Foreign Keys
By default, EasyTalk includes your model's associations in the schema:

```ruby
class Product < ActiveRecord::Base
  include EasyTalk::Model
  belongs_to :category
  has_many :reviews
end
```

This will include `category` (as an object) and `reviews` (as an array) in the schema.

You can control this behavior with configuration:

```ruby
EasyTalk.configure do |config|
  config.exclude_associations = true    # Don't include associations  
  config.exclude_foreign_keys = true    # Don't include foreign key columns
end
```

## Advanced Features

### LLM Function Generation
EasyTalk provides a helper method for generating OpenAI function specifications:

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

This generates a function specification compatible with OpenAI's function calling API.

### Schema Transformation
You can transform EasyTalk schemas into various formats:

```ruby
# Get Ruby hash representation
schema_hash = User.schema

# Get JSON Schema representation
json_schema = User.json_schema

# Convert to JSON string
json_string = User.json_schema.to_json
```

### Type Checking and Validation
EasyTalk performs basic type checking during schema definition:

```ruby
# This will raise an error because "minimum" should be used with numeric types
property :name, String, minimum: 1  # Error!

# This will raise an error because enum values must match the property type
property :age, Integer, enum: ["young", "old"]  # Error!
```

### Custom Type Builders
For advanced use cases, you can create custom type builders:

```ruby
module EasyTalk
  module Builders
    class MyCustomTypeBuilder < BaseBuilder
      # Custom implementation
    end
  end
end
```

## Configuration

### Global Settings
You can configure EasyTalk globally:

```ruby
EasyTalk.configure do |config|
  # ActiveRecord integration options
  config.excluded_columns = [:created_at, :updated_at, :deleted_at]
  config.exclude_foreign_keys = true
  config.exclude_primary_key = true
  config.exclude_timestamps = true
  config.exclude_associations = false
  
  # Schema behavior options
  config.default_additional_properties = false
  config.nilable_is_optional = false  # Makes T.nilable properties also optional
  
  # NEW in v2.0.0: Automatic validation generation
  config.auto_validations = true      # Automatically generate ActiveModel validations
end
```

### Automatic Validation Configuration
The new `auto_validations` option (enabled by default) automatically generates ActiveModel validations from your schema constraints:

```ruby
# Disable automatic validations globally
EasyTalk.configure do |config|
  config.auto_validations = false
end

# Now you must manually define validations
class User
  include EasyTalk::Model
  
  validates :name, presence: true, length: { minimum: 2 }
  validates :age, presence: true, numericality: { greater_than_or_equal_to: 18 }
  
  define_schema do
    property :name, String, min_length: 2
    property :age, Integer, minimum: 18
  end
end
```

### Per-Model Configuration
Some settings can be configured per model:

```ruby
class Product < ActiveRecord::Base
  include EasyTalk::Model
  
  enhance_schema({
    additionalProperties: true,
    ignore: [:internal_ref_id, :legacy_code]
  })
end
```

### Exclusion Rules
Columns are excluded based on the following rules (in order of precedence):

1. Explicitly listed in `excluded_columns` global setting
2. Listed in the model's `schema_enhancements[:ignore]` array
3. Is a primary key when `exclude_primary_key` is true (default)
4. Is a timestamp column when `exclude_timestamps` is true (default)
5. Matches a foreign key pattern when `exclude_foreign_keys` is true

### Customizing Output
You can customize the JSON Schema output by enhancing the schema:

```ruby
class User < ActiveRecord::Base
  include EasyTalk::Model
  
  enhance_schema({
    title: "User Account",
    description: "User account information",
    properties: {
      name: {
        title: "Full Name",
        description: "User's full name"
      }
    }
  })
end
```

## Examples

### User Registration (with Auto-Validations)

```ruby
class User
  include EasyTalk::Model

  # Additional custom validations beyond automatic ones
  validates :email, uniqueness: true
  validates :password, confirmation: true

  define_schema do
    title "User Registration"
    description "User registration information"
    property :name, String, min_length: 2, max_length: 100, description: "User's full name"
    property :email, String, format: "email", description: "User's email address"
    property :password, String, min_length: 8, max_length: 128, description: "User's password"
    property :notify, T::Boolean, optional: true, description: "Whether to send notifications"
  end
  # Auto-generated validations:
  # validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  # validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # validates :password, presence: true, length: { minimum: 8, maximum: 128 }
  # validates :notify, inclusion: { in: [true, false] } - only if present (optional: true)
end

# Usage with automatic validation
user = User.new(
  name: "John Doe",
  email: "john@example.com",
  password: "secretpassword123",
  notify: true
)
user.valid? # => true (assuming email is unique)

# Invalid data triggers auto-generated validations
invalid_user = User.new(
  name: "J",                    # Too short
  email: "invalid-email",      # Invalid format
  password: "123"               # Too short
)
invalid_user.valid? # => false
invalid_user.errors.full_messages
# => ["Name is too short (minimum is 2 characters)",
#     "Email is invalid",
#     "Password is too short (minimum is 8 characters)"]
```

### Payment Processing

```ruby
class CreditCard
  include EasyTalk::Model

  define_schema do
    property :CardNumber, String
    property :CardType, String, enum: %w[Visa MasterCard AmericanExpress]
    property :CardExpMonth, Integer, minimum: 1, maximum: 12
    property :CardExpYear, Integer, minimum: Date.today.year, maximum: Date.today.year + 10
    property :CardCVV, String, pattern: '^[0-9]{3,4}$'
    additional_properties false
  end
end

class Paypal
  include EasyTalk::Model

  define_schema do
    property :PaypalEmail, String, format: 'email'
    property :PaypalPasswordEncrypted, String
    additional_properties false
  end
end

class BankTransfer
  include EasyTalk::Model

  define_schema do
    property :BankName, String
    property :AccountNumber, String
    property :RoutingNumber, String
    property :AccountType, String, enum: %w[Checking Savings]
    additional_properties false
  end
end

class Payment
  include EasyTalk::Model

  define_schema do
    title 'Payment'
    description 'Payment info'
    property :PaymentMethod, String, enum: %w[CreditCard Paypal BankTransfer]
    property :Details, T::AnyOf[CreditCard, Paypal, BankTransfer]
  end
end
```

### Complex Object Hierarchies

```ruby
class Address
  include EasyTalk::Model

  define_schema do
    property :street, String
    property :city, String
    property :state, String
    property :zip, String, pattern: '^[0-9]{5}(?:-[0-9]{4})?$'
  end
end

class Employee
  include EasyTalk::Model

  define_schema do
    title 'Employee'
    description 'Company employee'
    property :name, String, title: 'Full Name'
    property :gender, String, enum: %w[male female other]
    property :department, T.nilable(String)
    property :hire_date, Date
    property :active, T::Boolean, default: true
    property :addresses, T.nilable(T::Array[Address])
  end
end

class Company
  include EasyTalk::Model

  define_schema do
    title 'Company'
    property :name, String
    property :employees, T::Array[Employee], title: 'Company Employees', description: 'A list of company employees'
  end
end
```

### API Integration

```ruby
# app/controllers/api/users_controller.rb
class Api::UsersController < ApplicationController
  def create
    schema = User.json_schema
    
    # Validate incoming request against the schema
    validation_result = JSONSchemer.schema(schema).valid?(params.to_json)
    
    if validation_result
      user = User.new(user_params)
      if user.save
        render json: user, status: :created
      else
        render json: { errors: user.errors }, status: :unprocessable_entity
      end
    else
      render json: { errors: "Invalid request" }, status: :bad_request
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:name, :email, :password)
  end
end
```

## Troubleshooting

### Common Errors

#### "Invalid property name"
Property names must start with a letter or underscore and can only contain letters, numbers, and underscores:

```ruby
# Invalid
property "1name", String  # Starts with a number
property "name!", String  # Contains a special character

# Valid
property :name, String
property :user_name, String
```

#### "Property type is missing"
You must specify a type for each property:

```ruby
# Invalid
property :name

# Valid
property :name, String
```

#### "Unknown option"
You specified an option that is not valid for the property type:

```ruby
# Invalid (min_length is for strings, not integers)
property :age, Integer, min_length: 2

# Valid
property :age, Integer, minimum: 18
```

### Schema Validation Issues
If you're having issues with validation:

1. Make sure you've defined ActiveModel validations for your model
2. Check for mismatches between schema constraints and validations
3. Verify that required properties are present

### Type Errors
Type errors usually occur when there's a mismatch between a property type and its constraints:

```ruby
# Error: enum values must be strings for a string property
property :status, String, enum: [1, 2, 3]

# Correct
property :status, String, enum: ["active", "inactive", "pending"]
```

### Best Practices

1. **Define clear property names and descriptions** for better documentation
2. **Use appropriate types** for each property with proper constraints
3. **Leverage automatic validations** by defining schema constraints instead of manual validations
4. **Keep schemas focused and modular** - extract nested objects to separate classes
5. **Reuse models when appropriate** instead of duplicating schema definitions
6. **Use explicit types** instead of relying on inference
7. **Test your schemas with sample data** to ensure validations work as expected
8. **Configure auto-validations globally** to maintain consistency across your application
9. **Use nullable_optional_property** for fields that can be omitted or null
10. **Document breaking changes** when updating schema definitions

# Nullable vs Optional Properties in EasyTalk

One of the most important distinctions when defining schemas is understanding the difference between **nullable** properties and **optional** properties. This guide explains these concepts and how to use them effectively in EasyTalk.

## Key Concepts

| Concept | Description | JSON Schema Effect | EasyTalk Syntax |
|---------|-------------|-------------------|-----------------|
| **Nullable** | Property can have a `null` value | Adds `"null"` to the type array | `T.nilable(Type)` |
| **Optional** | Property doesn't have to exist | Omits property from `"required"` array | `optional: true` constraint |

## Nullable Properties

A **nullable** property can contain a `null` value, but the property itself must still be present in the object:

```ruby
property :age, T.nilable(Integer)
```

This produces the following JSON Schema:

```json
{
  "properties": {
    "age": { "type": ["integer", "null"] }
  },
  "required": ["age"]
}
```

In this case, the following data would be valid:
- `{ "age": 25 }`
- `{ "age": null }`

But this would be invalid:
- `{ }` (missing the age property entirely)

## Optional Properties

An **optional** property doesn't have to be present in the object at all:

```ruby
property :nickname, String, optional: true
```

This produces:

```json
{
  "properties": {
    "nickname": { "type": "string" }
  }
  // Note: "nickname" is not in the "required" array
}
```

In this case, the following data would be valid:
- `{ "nickname": "Joe" }`
- `{ }` (omitting nickname entirely)

But this would be invalid:
- `{ "nickname": null }` (null is not allowed because the property isn't nullable)

## Nullable AND Optional Properties

For properties that should be both nullable and optional (can be omitted or null), you need to combine both approaches:

```ruby
property :bio, T.nilable(String), optional: true
```

This produces:

```json
{
  "properties": {
    "bio": { "type": ["string", "null"] }
  }
  // Note: "bio" is not in the "required" array
}
```

For convenience, EasyTalk also provides a helper method:

```ruby
nullable_optional_property :bio, String
```

Which is equivalent to the above.

## Configuration Options

By default, nullable properties are still required. You can change this global behavior:

```ruby
EasyTalk.configure do |config|
  config.nilable_is_optional = true # Makes all T.nilable properties also optional
end
```

With this configuration, any property defined with `T.nilable(Type)` will be treated as both nullable and optional.

## Practical Examples

### User Profile Schema

```ruby
class UserProfile
  include EasyTalk::Model
  
  define_schema do
    # Required properties (must exist, cannot be null)
    property :id, String
    property :name, String
    
    # Required but nullable (must exist, can be null)
    property :age, T.nilable(Integer)
    
    # Optional but not nullable (can be omitted, cannot be null if present)
    property :email, String, optional: true
    
    # Optional and nullable (can be omitted, can be null if present)
    nullable_optional_property :bio, String
  end
end
```

This creates clear expectations for data validation:
- `id` and `name` must be present and cannot be null
- `age` must be present but can be null
- `email` doesn't have to be present, but if it is, it cannot be null
- `bio` doesn't have to be present, and if it is, it can be null

## Common Gotchas

### Misconception: Nullable Implies Optional

A common mistake is assuming that `T.nilable(Type)` makes a property optional. By default, it only allows the property to have a null value - the property itself is still required to exist in the object.

### Misconception: Optional Properties Accept Null

An optional property (defined with `optional: true`) can be omitted entirely, but if it is present, it must conform to its type constraint. If you want to allow null values, you must also make it nullable with `T.nilable(Type)`.

## Migration from Earlier Versions

If you're upgrading from EasyTalk version 1.0.1 or earlier, be aware that the handling of nullable vs optional properties has been improved for clarity.

To maintain backward compatibility with your existing code, you can use:

```ruby
EasyTalk.configure do |config|
  config.nilable_is_optional = true # Makes T.nilable properties behave as they did before
end
```

We recommend updating your schema definitions to explicitly declare which properties are optional using the `optional: true` constraint, as this makes your intent clearer.

## Best Practices

1. **Be explicit about intent**: Always clarify whether properties should be nullable, optional, or both
2. **Use the helper method**: For properties that are both nullable and optional, use `nullable_optional_property`
3. **Document expectations**: Use comments to clarify validation requirements for complex schemas
4. **Consider validation implications**: Remember that ActiveModel validations operate independently of the schema definition

## JSON Schema Comparison

| EasyTalk Definition | Required | Nullable | JSON Schema Equivalent |
|--------------------|----------|----------|------------------------|
| `property :p, String` | Yes | No | `{ "properties": { "p": { "type": "string" } }, "required": ["p"] }` |
| `property :p, T.nilable(String)` | Yes | Yes | `{ "properties": { "p": { "type": ["string", "null"] } }, "required": ["p"] }` |
| `property :p, String, optional: true` | No | No | `{ "properties": { "p": { "type": "string" } } }` |
| `nullable_optional_property :p, String` | No | Yes | `{ "properties": { "p": { "type": ["string", "null"] } } }` |

## Migration Guide from v1.x to v2.0

### Breaking Changes Summary

1. **Removed Block-Style Sub-Schemas**: Hash-based nested definitions are no longer supported
2. **Enhanced Validation System**: Automatic validation generation is now enabled by default
3. **Improved Model Initialization**: Better support for nested model instantiation

### Migration Steps

#### 1. Replace Hash-based Nested Schemas

```ruby
# OLD (v1.x) - No longer works
class User
  include EasyTalk::Model
  define_schema do
    property :address, Hash do
      property :street, String
      property :city, String
    end
  end
end

# NEW (v2.x) - Extract to separate classes
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
    property :address, Address
  end
end
```

#### 2. Review Automatic Validations

With `auto_validations: true` (default), you may need to remove redundant manual validations:

```ruby
# OLD (v1.x) - Manual validations required
class User
  include EasyTalk::Model
  
  validates :name, presence: true, length: { minimum: 2 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  define_schema do
    property :name, String
    property :email, String
  end
end

# NEW (v2.x) - Automatic validations from constraints
class User
  include EasyTalk::Model
  
  # Only add validations not covered by schema constraints
  validates :email, uniqueness: true
  
  define_schema do
    property :name, String, min_length: 2     # Auto-generates presence + length
    property :email, String, format: "email"  # Auto-generates presence + format
  end
end
```

#### 3. Configuration Updates

Review your configuration for new options:

```ruby
EasyTalk.configure do |config|
  # New option in v2.0
  config.auto_validations = true  # Enable/disable automatic validation generation
  
  # Existing options (unchanged)
  config.nilable_is_optional = false
  config.exclude_foreign_keys = true
  # ... other existing config
end
```

### Compatibility Notes

- **Ruby Version**: Still requires Ruby 3.2+
- **Dependencies**: Core dependencies remain the same
- **JSON Schema Output**: No changes to generated schemas
- **ActiveRecord Integration**: Fully backward compatible

## Development and Contributing

### Setting Up the Development Environment
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that lets you experiment.

To install this gem onto your local machine, run:

```bash
bundle exec rake install
```

### Running Tests
Run the test suite with:

```bash
bundle exec rake spec
```

### Code Quality
Run the linter:

```bash
bundle exec rubocop
```

### Contributing Guidelines
Bug reports and pull requests are welcome on GitHub at https://github.com/sergiobayona/easy_talk.

## JSON Schema Compatibility

### Supported Versions
EasyTalk is currently loose about JSON Schema versions. It doesn't strictly enforce or adhere to any particular version of the specification. The goal is to add more robust support for the latest JSON Schema specs in the future.

### Specification Compliance
To learn about current capabilities, see the [spec/easy_talk/examples](https://github.com/sergiobayona/easy_talk/tree/main/spec/easy_talk/examples) folder. The examples illustrate how EasyTalk generates JSON Schema in different scenarios.

### Known Limitations
- Limited support for custom formats
- No direct support for JSON Schema draft 2020-12 features
- Complex composition scenarios may require manual adjustment

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
