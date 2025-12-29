# JSON Schema Compliance Guide

This document defines the strategy for testing and improving `EasyTalk`'s compliance with the official [JSON Schema Specification](https://json-schema.org/specification).

## Test Suite Setup

`EasyTalk` integrates the standard [JSON Schema Test Suite](https://github.com/json-schema-org/JSON-Schema-Test-Suite) as a git submodule in `spec/fixtures/json_schema_test_suite`. This provides a language-agnostic set of test cases covering all aspects of the specification.

### Infrastructure

*   **Submodule**: Located at `spec/fixtures/json_schema_test_suite`.
*   **Converter**: `spec/support/json_schema_converter.rb` dynamically converts raw JSON Schema definitions into `EasyTalk::Model` classes at runtime.
*   **Runner**: `spec/integration/json_schema_compliance_spec.rb` iterates over the test suite files, generates models, and asserts valid/invalid behavior.

## Running the Tests

The compliance tests are **optional** and excluded from the default `rspec` run to prevent noise from known incompatibilities.

To run the compliance suite:

```bash
bundle exec rspec --tag json_schema_compliance spec/integration/json_schema_compliance_spec.rb
```

## Compliance Strategy

The goal is to incrementally improve compliance by enabling more tests and fixing the underlying issues in `EasyTalk`.

### 1. Identify Gaps
The current test runner skips many tests (marked as `pending` or explicit `skip`).
*   **Root Primitives**: `EasyTalk` models are Objects. Tests for root integers/strings are skipped.
*   **Strict Naming**: Tests with property names that are invalid Ruby identifiers (e.g., `foo-bar`, `123`, `constructor`) are currently skipped.
*   **Missing Keywords**: Keywords like `patternProperties`, `const`, and `oneOf` (in specific contexts) may fail.

### 2. Workflow for Improvements
1.  **Select a Feature**: Pick a specific file (e.g., `properties.json`, `required.json`) or a skipped section.
2.  **Un-skip Tests**: Remove the `skip` logic in `spec/integration/json_schema_compliance_spec.rb` for that feature.
3.  **Run & Analyze**: Run the specific test file.
    ```bash
    bundle exec rspec --tag json_schema_compliance
    ```
4.  **Implement Fix**: Modify `EasyTalk` internals (e.g., `keywords.rb`, `schema_definition.rb`) to support the feature.
5.  **Sanitize Inputs**: Update `JsonSchemaConverter` if the test case requires adaptation (e.g., mapping a JSON key to a safe Ruby method name via `as:`) without changing the underlying validation logic.

### 3. Known Critical Issues
*   **Reserved Words**: Properties like `method`, `class`, `constructor` conflict with Ruby. Fix requires a robust proxy or sanitization layer in `EasyTalk::Model`.
*   **Boolean Schemas**: `properties: { foo: false }` is valid JSON Schema (property forbidden) but not currently supported by `EasyTalk`.
*   **Strict Property Validation**: `EasyTalk` raises errors for invalid property names at definition time. Compliance requires allowing arbitrary property keys (perhaps via `validates_with` logic instead of metaprogramming methods).

## Contributing

When adding support for a new JSON Schema keyword:
1.  Check if a test file exists in `spec/fixtures/json_schema_test_suite/tests/draft7/`.
2.  Add the filename to the `FOCUS_FILES` list in `spec/integration/json_schema_compliance_spec.rb`.
3.  Implement the feature and verify pass.
