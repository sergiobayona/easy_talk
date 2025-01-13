# EasyTalk

EasyTalk is a Ruby library that simplifies defining and generating JSON Schema documents, and validates that JSON data conforms to these schemas.

Key Features
* Intuitive Schema Definition: Use Ruby classes and methods to define JSON Schema documents easily.
* LLM Function Support: Ideal for integrating with Large Language Models (LLMs) such as OpenAI’s GPT series. EasyTalk enables you to effortlessly create JSON Schema documents describing the inputs and outputs of LLM function calls.
* Schema Composition: Define EasyTalk models and reference them in other EasyTalk models to create complex schemas.
* Validation: Write validations using ActiveModel’s validations.

Inspiration
Inspired by Python's Pydantic library, EasyTalk brings similar functionality to the Ruby ecosystem, providing a Ruby-friendly approach to JSON Schema operations.

Example Use:

```ruby
class User
  include EasyTalk::Model

  validates :name, :email, :group, presence: true
  validates :age, numericality: { greater_than_or_equal_to: 18, less_than_or_equal_to: 100 }

  define_schema do
    title "User"
    description "A user of the system"
    property :name, String, description: "The user's name", title: "Full Name"
    property :email, Hash do
      property :address, String, format: "email", description: "The user's email", title: "Email Address"
      property :verified, T::Boolean, description: "Whether the email is verified"
    end
    property :group, Integer, enum: [1, 2, 3], default: 1, description: "The user's group"
    property :age, Integer, minimum: 18, maximum: 100, description: "The user's age"
    property :tags, T::Array[String], min_items: 1, unique_items: true, description: "The user's tags"
  end
end
```

Calling `User.json_schema` will return the Ruby representation of the JSON Schema for the `User` class:

```ruby
{
  "type" => "object",
  "title" => "User",
  "description" => "A user of the system",
  "properties" => {
    "name" => {
      "type" => "string", "title" => "Full Name", "description" => "The user's name"
    },
    "email" => {
      "type" => "object",
      "properties" => {
        "address" => {
          "type" => "string", "title" => "Email Address", "description" => "The user's email", "format" => "email"
        },
        "verified" => {
          "type" => "boolean", "description" => "Whether the email is verified"
        }
      },
      "required" => ["address", "verified"]
    },
    "group" => {
      "type" => "integer", "description" => "The user's group", "enum" => [1, 2, 3], "default" => 1
    },
    "age" => {
      "type" => "integer", "description" => "The user's age", "minimum" => 18, "maximum" => 100
    },
    "tags" => {
      "type" => "array",
      "items" => { "type" => "string" },
      "description" => "The user's tags",
      "minItems" => 1,
      "uniqueItems" => true
    }
  },
  "required" => ["name", "email", "group", "age", "tags"]
}
```

Instantiate a User object and validate it with ActiveModel validations:

```ruby
user = User.new(name: "John Doe", email: { address: "john@test.com", verified: true }, group: 1, age: 25, tags: ["tag1", "tag2"])
user.valid? # => true

user.name = nil
user.valid? # => false

user.errors.full_messages # => ["Name can't be blank"]
user.errors["name"]       # => ["can't be blank"]
```

## Installation

 install the gem by running the following command in your terminal:

    $ gem install easy_talk

## Usage

Simply include the `EasyTalk::Model` module in your Ruby class, define the schema using the `define_schema` block, and call the `json_schema` class method to generate the JSON Schema document.


## Schema Definition

In the example above, the define_schema method adds a title and description to the schema. The property method defines properties of the schema document. property accepts:

* A name (symbol)
* A type (generic Ruby type like String/Integer, a Sorbet type like T::Boolean, or one of the custom types like T::AnyOf[...])
* A hash of constraints (e.g., minimum: 18, enum: [1, 2, 3], etc.)

## Why Sortbet-style types?

Ruby doesn’t natively allow complex types like Array[String] or Array[Integer]. Sorbet-style types let you define these compound types clearly. EasyTalk uses this style to handle property types such as T::Array[String] or T::AnyOf[ClassA, ClassB].

## Property Constraints

Property constraints are type-dependent. Refer to the [CONSTRAINTS.md](CONSTRAINTS.md) file for a list of constraints supported by the JSON Schema generator.


## Schema Composition

EasyTalk supports schema composition. You can define a schema for a nested object by defining a new class that includes `EasyTalk::Model`. You can then reference the nested schema in the parent using special types:

T::OneOf[Model1, Model2, ...] — The property must match at least one of the specified schemas
T::AnyOf[Model1, Model2, ...] — The property can match any of the specified schemas
T::AllOf[Model1, Model2, ...] — The property must match all of the specified schemas

Example: A Payment object that can be a credit card, PayPal, or bank transfer:


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

## Additional Properties

EasyTalk supports the JSON Schema `additionalProperties` keyword, allowing you to control whether instances of your model can accept properties beyond those explicitly defined in the schema.

### Usage

Use the `additional_properties` keyword in your schema definition to specify whether additional properties are allowed:

```ruby
class Company
  include EasyTalk::Model

  define_schema do
    property :name, String
    additional_properties true  # Allow additional properties
  end
end

# Additional properties are allowed
company = Company.new
company.name = "Acme Corp"        # Defined property
company.location = "New York"     # Additional property
company.employee_count = 100      # Additional property

company.as_json
# => {
#      "name" => "Acme Corp",
#      "location" => "New York",
#      "employee_count" => 100
#    }
```

### Behavior

When `additional_properties true`:
- Instances can accept properties beyond those defined in the schema
- Additional properties can be set both via the constructor and direct assignment
- Additional properties are included in JSON serialization
- Attempting to access an undefined additional property raises NoMethodError

```ruby
# Setting via constructor
company = Company.new(
  name: "Acme Corp",
  location: "New York"  # Additional property
)

# Setting via assignment
company.rank = 1        # Additional property

# Accessing undefined properties
company.undefined_prop  # Raises NoMethodError
```

When `additional_properties false` or not specified:
- Only properties defined in the schema are allowed
- Attempting to set or get undefined properties raises NoMethodError

```ruby
class RestrictedCompany
  include EasyTalk::Model

  define_schema do
    property :name, String
    additional_properties false  # Restrict to defined properties only
  end
end

company = RestrictedCompany.new
company.name = "Acme Corp"     # OK - defined property
company.location = "New York"  # Raises NoMethodError
```

### JSON Schema

The `additional_properties` setting is reflected in the generated JSON Schema:

```ruby
Company.json_schema
# => {
#      "type" => "object",
#      "properties" => {
#        "name" => { "type" => "string" }
#      },
#      "required" => ["name"],
#      "additionalProperties" => true
#    }
```

### Best Practices

1. **Default to Restrictive**: Unless you specifically need additional properties, it's recommended to leave `additional_properties` as false (the default) to maintain schema integrity.

2. **Documentation**: If you enable additional properties, document the expected additional property types and their purpose.

3. **Validation**: Consider implementing custom validation for additional properties if they need to conform to specific patterns or types.

4. **Error Handling**: When working with instances that allow additional properties, use `respond_to?` or `try` to handle potentially undefined properties safely:

```ruby
# Safe property access
value = company.try(:optional_property)
# or
value = company.optional_property if company.respond_to?(:optional_property)
```

## Type Checking and Schema Constraints

EasyTalk uses a combination of standard Ruby types (`String`, `Integer`), Sorbet types (`T::Boolean`, `T::Array[String]`, etc.), and custom Sorbet-style types (`T::AnyOf[]`, `T::OneOf[]`) to perform basic type checking. For example:

If you specify `enum: [1,2,3]` but the property type is `String`, EasyTalk raises a type error.
If you define `minimum: 1` on a `String` property, it raises an error because minimum applies only to numeric types.

## Schema Validation

You can instantiate an EasyTalk model with a hash of attributes and validate it using standard ActiveModel validations. EasyTalk does not automatically validate instances; you must explicitly define ActiveModel validations in your EasyTalk model. See [spec/easy_talk/activemodel_integration_spec.rb](ActiveModel Integration Spec) for examples.

## JSON Schema Specifications

EasyTalk is currently loose about JSON Schema versions. It doesn’t strictly enforce or adhere to any particular version of the specification. The goal is to add more robust support for the latest JSON Schema specs in the future.

To learn about current capabilities, see the [spec/easy_talk/examples](https://github.com/sergiobayona/easy_talk/tree/main/spec/easy_talk/examples) folder. The examples illustrate how EasyTalk generates JSON Schema in different scenarios.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that lets you experiment.

To install this gem onto your local machine, run:

```bash
bundle exec rake install
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sergiobayona/easy_talk. 

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

