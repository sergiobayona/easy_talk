## [0.2.1] - 2024-05-06
- Run JSON Schema validations using ActiveModel's validations.

## [0.2.0] - 2024-05-01
- Added ActiveModel::API functionality to EasyTalk::Model module. That means you get all the benefits of ActiveModel::API including attribute assignment, introspections, validations, translation (i18n) and more. See https://api.rubyonrails.org/classes/ActiveModel/API.html for more information.

## [0.1.10] - 2024-04-29
- Accept `:optional` key as constraint which excludes property from required node.
- Spec fixes
## [0.1.9] - 2024-04-29
- Added the ability to describe an object schema withing the define_schema block. Example:
```ruby
...
property :email, :object do
    property :address, :string
    property :verified, :boolean
end
```

## [0.1.8] - 2024-04-24
- mostly refactoring without changes to the public API.

## [0.1.7] - 2024-04-16
- general cleanup and refactoring.

## [0.1.6] - 2024-04-16
- model instance takes a hash and converts it to attribute methods.

## [0.1.5] - 2024-04-15
- Added helper method for generating an openai function.

## [0.1.4] - 2024-04-12
- Bumped activesupport gem version.

## [0.1.3] - 2024-04-12
- Bumped json-schema gem version.

## [0.1.2] - 2024-04-12
- Added json validation.

## [0.1.1] - 2024-04-10
- Removed pry-byebug.

## [0.1.0] - 2024-04-09
- Initial release