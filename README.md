# EasyTalk

EasyTalk is a Ruby library that simplifies defining and generating JSON Schema documents, and validates that JSON data conforms to these schemas.

Key Features
* Intuitive Schema Definition: Use Ruby classes and methods to define JSON Schema documents easily.
* LLM Function Support: Ideal for integrating with Large Language Models (LLMs) such as OpenAI's GPT series models EasyTalk enables you to effortlessly create JSON Schema documents needed to describe the inputs and outputs of LLM function calls.
* Schema Composition: Define EasyTalk models and reference them in other EasyTalk models to create complex schemas.
* Validation: Write validations using ActiveModel's validations.

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

Calling `User.json_schema` will return the Ruby representation of the JSON Schema for the User class:

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
        }, "verified" => {
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
      "type" => "array", "items" => {
        "type" => "string"
      }, "description" => "The user's tags", "minItems" => 1, "uniqueItems" => true
    }
  },
  "required" => ["name", "email", "group", "age", "tags"]
}
```

Instantiate a User object and validate it using ActiveModel's validations:

```ruby
user = User.new(name: "John Doe", email: { address: "john@test.com", verified: true }, group: 1, age: 25, tags: ["tag1", "tag2"])
user.valid? # => true
user.name = nil
user.valid? # => false
user.errors.full_messages # => ["Name can't be blank"]
user.errors["name"] # => ["can't be blank"]
``

## Installation

 install the gem by running the following command in your terminal:

    $ gem install easy_talk

## Usage

Simply include the `EasyTalk::Model` module in your Ruby class, define the schema using the `define_schema` block and call the `json_schema` class method to generate the JSON Schema document.


## Schema Definition

In the example above, the `define_schema` method is used to add a description and a title to the schema document. The `property` method is used to define the properties of the schema document. The `property` method accepts the name of the property as a symbol, the type, which can be a generic Ruby type or a [Sorbet type](https://sorbet.org/docs/stdlib-generics), and a hash of constraints as options.

## Why Sortbet-style types?

Ruby does not have a way to define complex types like `Array[String]` or `Array[Integer]`. Sorbet-style types provide a way to define these complex types. EasyTalk uses Sorbet-style types to define the property types.

## Property Constraints

Property constraints are type-dependent. Refer to the [CONSTRAINTS.md](CONSTRAINTS.md) file for a list of constraints supported by the JSON Schema generator.


## Schema Composition

EasyTalk supports schema composition. You can define a schema for a nested object by defining a new class and including the `EasyTalk::Model` module. You can then reference the nested schema in the parent schema using the following special types:

- T::OneOf[Model1, Model2, ...] - The property must match at least one of the specified schemas.
- T::AnyOf[Model1, Model2, ...] - The property can match any of the specified schemas.
- T::AllOf[Model1, Model2, ...] - The property must match all of the specified schemas.

Here is an example where we define a schema for a payment object that can be a credit card, a PayPal account, or a bank transfer. The first three classes represent the schemas for the different payment methods. The `Payment` class represents the schema for the payment object where the `Details` property can be any of the payment method schemas.

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

## Type Checking and Schema Constraints

EasyTalk uses Ruby standard types (i.e. String, Integer), [Sorbet](https://sorbet.org/) types (i.e. T::Boolean, T::Array[String]) and custom Sorbet-style types (i.e T::AnyOf[], T::OneOf[]) to perform type checking on the property constraint values only. The `property` method accepts a type as the second argument. The type can be a Ruby class or a Sorbet type. For example, `String`, `Integer`, `T::Array[String]`, etc.

EasyTalk raises an error if the constraint values do not match the property type. For example, if you specify the `enum` constraint with the values [1,2,3], but the property type is `String`, EasyTalk will raise a type error.

EasyTalk also raises an error if the constraints are not valid for the property type. For example, if you define a property with a `minimum` or a `maximum` constraint, but the type is `String`, EasyTalk will raise an error.

## Schema Validation

You can instantiate an EasyTalk model with a hash of attributes and validate the instance using ActiveModel's validations. EasyTalk does not validate by default. You must explicitly define ActiveModel validations in your EasyTalk model to validate an instance. See the [spec/easy_talk/activemodel_integration_spec.rb](ActiveModel Integration Spec) for an examples.

## JSON Schema Specifications

EasyTalk is currently very loose about JSON Schema specifications. It does not enforce or adhere to using a given JSON Schema specification vesion. Support for the dictionary of JSON Schema keywords varies depending on the keyword. The goal is to have robust support for the latest JSON Schema specifications in the near future.

To learn about the current EasyTalk capabilities, take a look at the [spec/easy_talk/examples](https://github.com/sergiobayona/easy_talk/tree/main/spec/easy_talk/examples) folder. The examples are used to test the JSON Schema generation.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sergiobayona/easy_talk. 

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

