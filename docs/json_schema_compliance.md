# JSON Schema Compliance Guide

This document defines the strategy for testing and improving `EasyTalk`'s compliance with the official [JSON Schema Specification](https://json-schema.org/specification).

## Test Suite Setup

`EasyTalk` integrates the standard [JSON Schema Test Suite](https://github.com/json-schema-org/JSON-Schema-Test-Suite) as a git submodule in `spec/fixtures/json_schema_test_suite`. This provides a language-agnostic set of test cases covering all aspects of the specification.

### Infrastructure

- **Submodule**: Located at `spec/fixtures/json_schema_test_suite`.
- **Converter**: `spec/support/json_schema_converter.rb` dynamically converts raw JSON Schema definitions into `EasyTalk::Model` classes at runtime.
- **Runner**: `spec/integration/json_schema_compliance_spec.rb` iterates over the test suite files, generates models, and asserts valid/invalid behavior.

## Running the Tests

The compliance tests are **optional** and excluded from the default `rspec` run to prevent noise from known incompatibilities.

To run the compliance suite:

```bash
bundle exec rspec --tag json_schema_compliance spec/integration/json_schema_compliance_spec.rb
```

## Schema Wrapping Strategy

Since `EasyTalk` models are always objects, the JSON Schema test suite's root-level primitive tests (e.g., `{"type": "integer"}` with data `5`) require adaptation.

### How It Works

The `JsonSchemaConverter` uses a **wrapper property strategy**:

1. **Detection**: `needs_wrapping?` checks if the schema is non-object (no `type: object` or `properties` key)
2. **Wrapping**: Non-object schemas become a `value` property on a wrapper object
3. **Data transformation**: Primitive test data is wrapped as `{"value": data}`

**Example transformation:**

```
Original JSON Schema test:
  Schema: {"type": "integer", "minimum": 1}
  Data: 5
  Valid: true

Transformed for EasyTalk:
  Schema: {
    "type": "object",
    "properties": { "value": {"type": "integer", "minimum": 1} },
    "required": ["value"]
  }
  Data: {"value": 5}
  Valid: true
```

This preserves validation semantics while fitting EasyTalk's object-based model.

## Current Test Results

As of the latest run:

| Metric | Count |
|--------|-------|
| Total examples | 916 |
| Passing | ~193 |
| Failing | 165 |
| Pending (known unsupported) | 558 |

### Known Unsupported Features

The following test files are skipped entirely via `KNOWN_FAILURES`:

| File | Reason |
|------|--------|
| `not.json` | `not` keyword not supported |
| `anyOf.json` | `anyOf` validation not supported |
| `allOf.json` | `allOf` validation not supported |
| `oneOf.json` | `oneOf` validation not supported |
| `refRemote.json` | Remote `$ref` not supported |
| `dependencies.json` | Dependencies not supported |
| `definitions.json` | `$defs`/definitions not supported |
| `if-then-else.json` | Conditional logic not supported |
| `patternProperties.json` | Pattern properties not supported |
| `properties.json` | Complex property interactions not supported |
| `propertyNames.json` | Property names validation not supported |
| `ref.json` | Complex `$ref` not supported |
| `required.json` | Complex required checks not supported |
| `additionalItems.json` | Additional items not supported |
| `additionalProperties.json` | Additional properties validation not supported |
| `boolean_schema.json` | Boolean schemas (`true`/`false` as schema) not supported |
| `const.json` | `const` keyword not supported |
| `default.json` | Default keyword behavior not supported |
| `enum.json` | Enum validation not fully supported |
| `infinite-loop-detection.json` | Infinite loop detection not supported |
| `maxProperties.json` | Max properties not supported |
| `minProperties.json` | Min properties not supported |

## Compliance Gaps

The 165 failing tests reveal real validation gaps in EasyTalk:

### 1. Type Coercion (Intentional Behavior)

EasyTalk uses ActiveModel's numericality validation which coerces strings to numbers:

```ruby
user = User.new(age: "30")  # String
user.valid?  # => true (coerced to integer 30)
```

Per JSON Schema, `"30"` should be invalid for `type: integer`. This is documented as **intentional behavior** for Rails compatibility. A `strict_types` configuration option is planned (see [#137](https://github.com/sergiobayona/easy_talk/issues/137)).

### 2. Format Validation Scope

JSON Schema specifies that format validations should only apply to strings and ignore other types. EasyTalk currently validates format on the assigned value regardless of type.

### 3. Empty String Presence

EasyTalk uses ActiveModel's presence validation for required fields, which rejects empty strings. JSON Schema considers `""` a valid string.

### 4. Array Type Validation

Array element types are not strictly validated at runtime.

### 5. Null Type

The `null` type is not fully implemented as a standalone type.

### 6. uniqueItems

Array uniqueness constraint is not enforced during validation.

## Workflow for Improvements

1. **Select a Feature**: Pick a specific file from `KNOWN_FAILURES` or analyze failing tests.
2. **Enable Tests**: Remove the file from `KNOWN_FAILURES` in the spec.
3. **Run & Analyze**:
   ```bash
   bundle exec rspec --tag json_schema_compliance spec/integration/json_schema_compliance_spec.rb
   ```
4. **Implement Fix**: Modify EasyTalk internals to support the feature.
5. **Update Converter**: If needed, update `JsonSchemaConverter` for test adaptation.

## Critical Implementation Notes

### Reserved Words

Properties like `method`, `class`, `constructor` conflict with Ruby. The converter sanitizes these via `sanitize_property_name` and uses the `as:` option to preserve the original JSON key.

### Boolean Schemas

`properties: { foo: false }` is valid JSON Schema (property forbidden) but not currently supported.

### Strict Property Validation

EasyTalk raises `InvalidPropertyNameError` for invalid property names at definition time. Full compliance would require allowing arbitrary property keys.

## Contributing

When adding support for a new JSON Schema keyword:

1. Check if a test file exists in `spec/fixtures/json_schema_test_suite/tests/draft7/`.
2. Remove the filename from `KNOWN_FAILURES` in `spec/integration/json_schema_compliance_spec.rb`.
3. Run the tests and analyze failures.
4. Implement the feature in EasyTalk.
5. Update this document with any new findings.

## Related Issues

- [#137](https://github.com/sergiobayona/easy_talk/issues/137) - Add `strict_types` configuration option
