## [2.0.0] - 2025-06-05

  ### Added
  - Automatic ActiveModel Validations: Added ValidationBuilder class that automatically generates
  ActiveModel validations from JSON Schema constraints
  - Auto-validation Configuration: Added auto_validations configuration option (defaults to true) to
  control automatic validation generation
  - Enhanced Model Initialization: Improved model initialization to support nested EasyTalk::Model
  instantiation from hash attributes
  - Hash Comparison Support: Added equality comparison between EasyTalk models and hash objects

  ### Changed
  - BREAKING: Removed support for inline hash nested objects (block-style sub-schemas) - use class
  references as types instead
  - Improved Documentation: Enhanced inline documentation throughout the codebase with detailed
  examples and API documentation
  - Configuration Enhancement: Expanded configuration system with better organization and clearer
  option descriptions
  - Development Dependencies: Moved development dependencies from gemspec to Gemfile for better
  dependency management
  - CI/CD Improvements: Enhanced GitHub Actions workflow to support Ruby 3.3.0 and run on both main
  and development branches
  - Code Quality: Updated RuboCop configuration with more lenient rules for better developer
  experience

  ### Fixed
  - Property Validation: Improved property name validation with better error messages and edge case
  handling
  - Type Builder Resolution: Enhanced type-to-builder mapping logic for more reliable schema
  generation
  - Nilable Type Handling: Fixed nilable type processing to correctly handle union types with null
  - Empty Array Validation: Added validation to prevent empty arrays as property types

  ### Internal

  - Gem Security: Added MFA requirement for gem publishing
  - Code Organization: Improved module and class organization with better separation of concerns
  - Test Coverage: Enhanced test suite organization and coverage
  - Error Handling: Improved error messages and validation throughout the system

## [1.0.4] - 2024-03-12
### Changed
- Combined composition builders into a single file (#47)
  - Improved code organization and maintainability
  - Refactored internal builder implementation

### Fixed
- Added support for nilable properties when database column is null (#45)
  - Better handling of nullable database columns
  - More accurate schema generation for ActiveRecord models

## [1.0.3] - 2025-03-11
### Added
- Unified schema generation for both plain Ruby classes and ActiveRecord models (#40)
  - Single code path for generating schemas regardless of model type
  - More consistent behavior between different model types
  - Better handling of schema properties in ActiveRecord models

### Changed
- Improved error handling throughout the library (#31)
  - Added custom error types for better error classification
  - More descriptive error messages for constraint violations
  - Centralized validation of constraint values
  - Better type checking for array properties

### Developer Experience
- Removed unnecessary dependencies
  - Removed dartsass-rails from development dependencies
- Code quality improvements
  - Better test coverage for error conditions
  - More consistent return values in builder methods

## [1.0.2] - 2024-13-01
- Support "AdditionalProperties". see https://json-schema.org/understanding-json-schema/reference/object#additionalproperties
You can now define a schema that allows any additional properties. 
```ruby
class Company
  include EasyTalk::Model

  define_schema do
    property :name, String
    additional_properties true # or false
  end
end
```

You can then do:
```ruby
company = Company.new
company.name = "Acme Corp" # Defined property
company.location = "New York" # Additional property
company.employee_count = 100 # Additional property
```

company.as_json
# => {
#      "name" => "Acme Corp",
#      "location" => "New York",
#      "employee_count" => 100
#    }
```
- Fix that we don't conflate nilable properties with optional properties.
## [1.0.1] - 2024-09-01
- Fixed that property with custom type does not ignore the constraints hash https://github.com/sergiobayona/easy_talk/issues/17
## [1.0.0] - 2024-06-01
- Use `Hash` instead of `:object` for inline object schema definition.
example:
```ruby
    property :email, Hash do
        property :address, :string
        property :verified, :boolean
    end
```
- Loosen up the gemspec version requirement. Makes it flexible to use the library with future versions of Rails (i.e 8.*).
- Removed JSONScheemer gem dependency. 
- The library does not validate by default anymore. Validating an instance requires that you explicitly define ActiveModel validations in your EasyTalk model. See: https://github.com/sergiobayona/easy_talk/blob/main/spec/easy_talk/activemodel_integration_spec.rb.
- Internal improvements to `EasyTalk::ObjectBuilder` class. No changes to the public API.
- Expanded the test suite.

## [0.2.2] - 2024-05-17
- Fixed a bug where optional properties were not excluded from the required list.

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