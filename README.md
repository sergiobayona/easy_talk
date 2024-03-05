# EasyTalk

EasyTalk is a Ruby library for defining and generating JSON Schema.

Example Use:

```ruby
class User
  include EasyTalk::Model

  define_schema do
    title "User"
    description "A user of the system"
    property :name, String, description: "The user's name", title: "Full Name"
    property :email, String, description: "The user's email", format: "email", title: "Email Address"
    property :group, String, enum: [1, 2, 3], default: 1, description: "The user's group"
    property :age, Integer, minimum: 18, maximum: 100, description: "The user's age"
    property :tags, T::Array[String], min_items: 1, unique_item: true, description: "The user's tags"
  end
end
```

Calling `User.json_schema` will return the JSON Schema for the User class:

```json
{
    "title": "User",
    "description": "A user of the system",
    "type": "object",
    "properties": {
        "name": {
            "title": "Full Name",
            "description": "The user's name",
            "type": "string"
        },
        "email": {
            "title": "Email Address",
            "description": "The user's email",
            "type": "string",
            "format": "email"
        },
        "group": {
            "type": "number",
            "enum": [1, 2, 3],
            "default": 1,
            "description": "The user's group"
        },
        "age": {
            "type": "integer",
            "minimum": 18,
            "maximum": 100,
            "description": "The user's age"
        },
        "tags": {
            "type": "array",
            "items": {
                "type": "string"
            },
            "minItems": 1,
            "uniqueItems": true,
            "description": "The user's tags"
        }
    },
    "required:": [
        "name",
        "email",
        "group",
        "age",
        "tags"
    ]
}
```

## Installation

 install the gem by running the following command in your terminal:

    $ gem install easy_talk

## Usage

Simply include the `EasyTalk::Model` module in your Ruby class, define your schema using and call the `json_schema` method to generate the JSON Schema for the model.


## Schema Definition

In the example above, the `define_schema` method is used to add a description and a title to the schema document. The `property` method is used to define the properties of the schema document. The `property` method accepts the name of the property and a hash of options.

## Type Checking and Schema Constraints

EasyTalk uses [Sorbet](https://sorbet.org/) to perform type checking on the property constraint values. The `property` method accepts a type as the second argument. The type can be a Ruby class or a Sorbet type. For example, `String`, `Integer`, `T::Array[String]`, etc.

EasyTalk raises an error if the constraint values do not match the property type. For example, if you specify the `enum` constraint with the values [1,2,3], but the property type is `String`, EasyTalk will raise a type error.

EasyTalk also raises an error if the constraints are not valid for the property type. For example, if you define a property with a `minimum` or a `maximum` constraint, but the type is `String`, EasyTalk will raise an error.

## Schema Validation

EasyTalk does not yet perform JSON validation. So far, it only aims to generate a valid JSON Schema document. You can use the `json_schema` method to generate the JSON Schema and use a JSON Schema validator library like [JSONSchemer](https://github.com/davishmcclurg/json_schemer) to validate JSON against. See https://json-schema.org/implementations#validators-ruby for a list of JSON Schema validator libraries for Ruby.

The goal is to introduce JSON validation in the near future.

## JSON Schema Specifications

EasyTalk is currently very loose about JSON Schema specifications. It does not enforce the use of the latest JSON Schema specifications. Support for the dictionary of JSON Schema keywords varies depending on the keyword. The goal is to have robust support for the latest JSON Schema specifications in the near future.

To learn about the current EasyTalk capabilities, take a look at the [spec/easy_talk/examples](https://github.com/sergiobayona/easy_talk/tree/main/spec/easy_talk/examples) folder. The examples are used to test the JSON Schema generation.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sergiobayona/easy_talk. 

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

