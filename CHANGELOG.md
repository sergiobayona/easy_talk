## [3.2.0] - 2025-12-28

### Added

- **Pluggable Validation Adapter System**: Complete overhaul of the validation layer to make it a distinct, pluggable component (#89)
  - New `EasyTalk::ValidationAdapters::Base` abstract class defining the adapter interface
  - New `EasyTalk::ValidationAdapters::Registry` for adapter registration and lookup
  - New `EasyTalk::ValidationAdapters::ActiveModelAdapter` as the default adapter
  - New `EasyTalk::ValidationAdapters::NoneAdapter` for schema-only use cases
  - Per-model validation configuration: `define_schema(validations: false)`, `define_schema(validations: :none)`, or `define_schema(validations: CustomAdapter)`
  - Per-property validation control with `validate: false` constraint
  - Global configuration via `config.validation_adapter = :active_model`

- **Schema-Only Module**: New `EasyTalk::Schema` module for schema generation without ActiveModel (#89)
  - Does not include `ActiveModel::API` or `ActiveModel::Validations`
  - Ideal for API documentation, OpenAPI specs, and schema-first design

- **Pluggable Type Registry**: Runtime registration of custom types with their corresponding schema builders (#80)
  - New `EasyTalk::Builders::Registry` class with `register`, `resolve`, `registered?`, `unregister`, `registered_types`, and `reset!` methods
  - Added `EasyTalk.register_type` convenience method at module level
  - Added `config.register_type` for configuration block registration
  - Allows extending EasyTalk with custom types (e.g., Money, GeoPoint) without modifying gem source

- **Robust Type Introspection**: New `TypeIntrospection` module replacing brittle string-based type detection (#83)
  - Predicate methods: `boolean_type?`, `typed_array?`, `nilable_type?`, `primitive_type?`
  - Helper methods: `json_schema_type`, `get_type_class`, `extract_inner_type`
  - Uses Sorbet's type system properly instead of string pattern matching

- **Standardized Validation Error Output**: Helper methods for API-friendly error formats (#88)
  - **Flat format**: Simple array of field/message/code objects
  - **JSON Pointer (RFC 6901)**: Paths like `/properties/name`
  - **RFC 7807**: Problem Details for HTTP APIs
  - **JSON:API**: Standard JSON:API error format
  - Instance methods: `validation_errors(format:)`, `validation_errors_flat`, `validation_errors_json_pointer`, `validation_errors_rfc7807`, `validation_errors_jsonapi`
  - Configuration options: `default_error_format`, `error_type_base_uri`, `include_error_codes`

- **Naming Strategies**: Support for automatic property name transformation (#61)
  - Built-in strategies: `CAMEL_CASE`, `SNAKE_CASE`
  - Optional `as:` property constraint for per-property name override
  - Per-schema configuration: `define_schema { naming_strategy :camel_case }`
  - Global configuration: `config.naming_strategy = :camel_case`

- **Array Composition Support**: `T::AnyOf`, `T::OneOf`, and `T::AllOf` now work with `T::Array` (#63)
  - Example: `property :items, T::Array[T::OneOf[ProductA, ProductB]]`

- **Nested Model Validation in Arrays**: Arrays of EasyTalk::Model objects are now recursively validated (#112)
  - Hash items in arrays are auto-instantiated to model instances
  - Errors from nested models are merged with indexed paths (e.g., `addresses[0].street`)

### Changed

- **Deprecated `EasyTalk::ValidationBuilder`**: Use `EasyTalk::ValidationAdapters::ActiveModelAdapter` instead (deprecation warning shown on first use)

### Fixed

- **Default Value Assignment**: Default values are now properly assigned during initialization (#72)
- **Explicit Nil Preservation**: Explicitly passed `nil` values are preserved instead of being replaced with defaults (#79)
- **Optional Enum Validation**: Allow `nil` for optional properties with enum constraints (#64)
- **Optional Pattern Validation**: Allow `nil` for optional properties with pattern validation (#65)
- **Optional Format Validation**: Allow `nil` for optional properties with format validation (email, uri, uuid, etc.) (#75)
- **Optional Length Validation**: Allow `nil` for optional properties with length constraints (#76)
- **Schema Definition Mutation**: Avoid mutating schema definition during property building (#95)
- **Unknown Property Types**: Fail fast with `UnknownPropertyTypeError` instead of silently returning 'object' (#97)
- **respond_to_missing?**: Fixed `respond_to_missing?` implementation for additional properties (#98)
- **VALID_OPTIONS Mutation**: Avoid mutating `VALID_OPTIONS` constant in TypedArrayBuilder (#99)
- **Registry Reset**: `ValidationAdapters::Registry.reset!` now repopulates defaults (#100)
- **FunctionBuilder Error**: Replace deprecated Instructor error with `EasyTalk::UnsupportedTypeError` (#96)
- **Missing snake_case Strategy**: Added `SNAKE_CASE` constant to NamingStrategies module (#77)

### Internal

- Extracted shared schema methods into `SchemaMethods` mixin for code reuse between `Model` and `Schema` modules (#103)
- Centralized built-in type registration in `Builders::Registry` (#102)
- Added json_schemer for systematic validation testing with custom RSpec matchers

## [3.1.0] - 2025-12-18

### Added
- **JSON Schema `$schema` Keyword Support**: Added ability to declare which JSON Schema draft version schemas conform to
  - New `schema_version` configuration option supporting Draft-04, Draft-06, Draft-07, Draft 2019-09, and Draft 2020-12
  - Global configuration via `EasyTalk.configure { |c| c.schema_version = :draft202012 }`
  - Per-model override using `schema_version` keyword in `define_schema` block
  - Support for custom schema URIs
  - `$schema` only appears at root level (not in nested models)
  - Default is `:none` for backward compatibility

- **JSON Schema `$id` Keyword Support**: Added ability to provide a unique identifier URI for schemas
  - New `schema_id` configuration option for setting schema identifiers
  - Global configuration via `EasyTalk.configure { |c| c.schema_id = 'https://example.com/schema.json' }`
  - Per-model override using `schema_id` keyword in `define_schema` block
  - Supports absolute URIs, relative URIs, and URN formats
  - `$id` only appears at root level (not in nested models)
  - Default is `nil` for backward compatibility

- **JSON Schema `$ref` and `$defs` Support**: Added ability to reference reusable schema definitions for nested models
  - New `use_refs` configuration option to globally enable `$ref` for nested EasyTalk models
  - Global configuration via `EasyTalk.configure { |c| c.use_refs = true }`
  - Per-property override using `ref: true` or `ref: false` constraint
  - Nested models are automatically added to `$defs` when `$ref` is enabled
  - Supports direct model properties, `T::Array[Model]`, and `T.nilable(Model)` types
  - Nilable models with `$ref` use `anyOf` with `$ref` and `null` type
  - Multiple references to the same model only create one `$defs` entry
  - Additional constraints (title, description) can be combined with `$ref`
  - Default is `false` for backward compatibility (nested schemas are inlined)

## [3.0.0] - 2025-01-03

### BREAKING CHANGES
- **Removed ActiveRecord Support**: Completely removed ActiveRecord integration including:
  - Deleted `ActiveRecordSchemaBuilder` class and database schema introspection
  - Removed `enhance_schema` method for ActiveRecord models
  - Removed ActiveRecord-specific configuration options (`excluded_columns`, `exclude_foreign_keys`, 
    `exclude_primary_key`, `exclude_timestamps`, `exclude_associations`)
  - Deleted all ActiveRecord integration tests

### Changed  
- **Simplified Architecture**: EasyTalk now focuses exclusively on Plain Ruby classes with ActiveModel integration
- **Unified Integration Path**: All models now follow the same integration pattern using `ActiveModel::API` and `ActiveModel::Validations`
- **Streamlined Configuration**: Removed ActiveRecord-specific configuration options, keeping only core options
- **Updated Documentation**: Removed ActiveRecord examples and configuration references from README

### Fixed
- **Code Quality**: Fixed ValidationBuilder class length violation by consolidating format validation methods
- **Documentation**: Updated all examples to use `define_schema` pattern instead of removed `enhance_schema`

### Migration Guide
If you were using EasyTalk with ActiveRecord models:
- Replace `enhance_schema` calls with `define_schema` blocks
- Manually define properties instead of relying on database schema introspection  
- Remove ActiveRecord-specific configuration options from your EasyTalk.configure blocks

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