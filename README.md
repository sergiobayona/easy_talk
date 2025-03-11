# EasyTalk

## Introduction

### What is EasyTalk?
EasyTalk is a Ruby library that simplifies defining and generating JSON Schema. It provides an intuitive interface for Ruby developers to define structured data models that can be used for validation and documentation.

### Key Features
* **Intuitive Schema Definition**: Use Ruby classes and methods to define JSON Schema documents easily.
* **Works for plain Ruby classes and ActiveRecord models**: Integrate with existing code or build from scratch.
* **LLM Function Support**: Ideal for integrating with Large Language Models (LLMs) such as OpenAI's GPT series. EasyTalk enables you to effortlessly create JSON Schema documents describing the inputs and outputs of LLM function calls.
* **Schema Composition**: Define EasyTalk models and reference them in other EasyTalk models to create complex schemas.
* **Validation**: Write validations using ActiveModel's validations.

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
- ActiveModel 7.0 or higher
- ActiveSupport 7.0 or higher

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
user.valid? # => true

user.age = 17
user.valid? # => false
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
- `Hash`: Object/dictionary values

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

### Schema Validation
EasyTalk models include ActiveModel validations. You can validate your models using the standard ActiveModel validation methods:

```ruby
class User
  include EasyTalk::Model
  
  validates :name, presence: true
  validates :age, numericality: { greater_than_or_equal_to: 18 }
  
  define_schema do
    property :name, String
    property :age, Integer, minimum: 18
  end
end

user = User.new(name: "John", age: 17)
user.valid? # => false
user.errors.full_messages # => ["Age must be greater than or equal to 18"]
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

### Nested Objects
You can define nested objects using a block:

```ruby
property :email, Hash do
  property :address, String, format: "email"
  property :verified, T::Boolean
end
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

### Constraints and Validations
Constraints can be added to properties and are used for schema generation:

```ruby
property :name, String, min_length: 2, max_length: 50
property :email, String, format: "email"
property :category, String, enum: ["A", "B", "C"], default: "A"
```

For validation, you can use ActiveModel validations:

```ruby
validates :name, presence: true, length: { minimum: 2, maximum: 50 }
validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
validates :category, inclusion: { in: ["A", "B", "C"] }
```

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

### Validations
EasyTalk models include ActiveModel validations:

```ruby
class User
  include EasyTalk::Model
  
  validates :age, comparison: { greater_than: 21 }
  validates :height, presence: true, numericality: { greater_than: 0 }
  
  define_schema do
    property :name, String
    property :age, Integer
    property :height, Float
  end
end
```

### Error Handling
You can access validation errors using the standard ActiveModel methods:

```ruby
user = User.new(name: "Jim", age: 18, height: -5.9)
user.valid? # => false
user.errors[:age] # => ["must be greater than 21"]
user.errors[:height] # => ["must be greater than 0"]
```

### Model Attributes
EasyTalk models provide getters and setters for all defined properties:

```ruby
user = User.new
user.name = "John"
user.age = 30
puts user.name # => "John"
```

You can also initialize a model with a hash of attributes:

```ruby
user = User.new(name: "John", age: 30, height: 5.9)
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
  config.excluded_columns = [:created_at, :updated_at, :deleted_at]
  config.exclude_foreign_keys = true
  config.exclude_primary_key = true
  config.exclude_timestamps = true
  config.exclude_associations = false
  config.default_additional_properties = false
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

### User Registration

```ruby
class User
  include EasyTalk::Model

  validates :name, :email, :password, presence: true
  validates :password, length: { minimum: 8 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  define_schema do
    title "User Registration"
    description "User registration information"
    property :name, String, description: "User's full name"
    property :email, String, format: "email", description: "User's email address"
    property :password, String, min_length: 8, description: "User's password"
    property :notify, T::Boolean, default: true, description: "Whether to send notifications"
  end
end
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

1. Define clear property names and descriptions
2. Use appropriate types for each property
3. Add validations for important business rules
4. Keep schemas focused and modular
5. Reuse models when appropriate
6. Use explicit types instead of relying on inference
7. Test your schemas with sample data

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
