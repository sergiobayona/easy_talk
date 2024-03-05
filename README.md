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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sergiobayona/easy_talk. 

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

