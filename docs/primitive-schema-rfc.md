# RFC: Primitive Schema Feature with Convention-Based Type Inference

**Status**: Proposed
**Author**: Claude Code
**Created**: 2025-12-30
**Updated**: 2025-12-30

---

## Abstract

This document proposes adding three interrelated features to EasyTalk:

1. **Primitive Type Classes** — Reusable primitive schema definitions via `EasyTalk::Primitive`
2. **Convention-Based Type Inference** — Auto-infer types from property names (conservative defaults)
3. **Symbol-Based Type Syntax** — Alternative to Ruby constants for type declarations

These features address user feedback about API verbosity and enable more expressive, DRY schema definitions while maintaining full backward compatibility.

---

## Motivation

### Problem Statement

Users have expressed that the current API requires explicit type declarations that can feel verbose:

```ruby
# Current API
property :email, String, format: 'email'
property :phone, String, pattern: '^\+?[1-9]\d{1,14}$'
property :age, Integer, minimum: 0
property :is_active, T::Boolean
```

Common patterns are repeated across models, and property names often imply their types (`:email` is almost always an email-formatted string).

### Goals

1. **Reduce boilerplate** for common patterns
2. **Enable reusable type definitions** across models
3. **Provide intuitive defaults** based on naming conventions
4. **Maintain backward compatibility** — existing code must continue to work unchanged

---

## Detailed Design

### Feature 1: Primitive Type Classes

#### Overview

Create reusable primitive schema definitions that encapsulate type + constraints.

#### Syntax

```ruby
class Email < EasyTalk::Primitive(:string) { format 'email' }
class PhoneNumber < EasyTalk::Primitive(:string) { pattern '^\+?[1-9]\d{1,14}$' }
class PositiveInteger < EasyTalk::Primitive(:integer) { minimum 0 }
class Percentage < EasyTalk::Primitive(:number) { minimum 0; maximum 100 }
```

#### Usage in Models

```ruby
class User
  include EasyTalk::Model

  define_schema do
    property :email, Email
    property :phone, PhoneNumber
    property :age, PositiveInteger
  end
end
```

#### Generated Schema

```json
{
  "type": "object",
  "properties": {
    "email": { "type": "string", "format": "email" },
    "phone": { "type": "string", "pattern": "^\\+?[1-9]\\d{1,14}$" },
    "age": { "type": "integer", "minimum": 0 }
  },
  "required": ["email", "phone", "age"]
}
```

#### Implementation

**New File**: `lib/easy_talk/primitive.rb`

```ruby
module EasyTalk
  class Primitive
    class << self
      # Factory method for creating primitive type classes
      # Usage: class Email < EasyTalk::Primitive(:string) { format 'email' }
      def call(type_name, &block)
        Class.new(self) do
          @base_type = type_name
          @schema_block = block

          class << self
            attr_reader :base_type, :schema_block

            # IMPORTANT: Must be named `schema` (not `json_schema`) to match
            # Property#build expectation at lib/easy_talk/property.rb:111
            # Property checks: type.respond_to?(:schema) and calls type.schema
            def schema
              @schema ||= build_schema
            end

            # Public: Returns the underlying Ruby type (String, Integer, etc.)
            # Used by ActiveModelAdapter to apply correct validations
            def ruby_type
              EasyTalk::TypeResolver.resolve(@base_type)
            end

            # Public: Returns the constraints hash defined in the block
            # Used by ActiveModelAdapter to merge with property constraints
            def constraints
              return {} unless @schema_block
              ConstraintCollector.new.tap { |c| c.instance_eval(&@schema_block) }.constraints
            end

            private

            def build_schema
              builder_class = EasyTalk::Builders::Registry.fetch(ruby_type)
              builder = builder_class.new(:value, **constraints)
              builder.build
            end
          end
        end
      end
      alias_method :[], :call
    end
  end

  # DSL for collecting constraints in block
  class ConstraintCollector
    attr_reader :constraints

    def initialize
      @constraints = {}
    end

    # String constraints
    def min_length(val); @constraints[:min_length] = val; end
    def max_length(val); @constraints[:max_length] = val; end
    def pattern(val); @constraints[:pattern] = val; end
    def format(val); @constraints[:format] = val; end

    # Numeric constraints
    def minimum(val); @constraints[:minimum] = val; end
    def maximum(val); @constraints[:maximum] = val; end
    def exclusive_minimum(val); @constraints[:exclusive_minimum] = val; end
    def exclusive_maximum(val); @constraints[:exclusive_maximum] = val; end
    def multiple_of(val); @constraints[:multiple_of] = val; end

    # Common constraints
    def enum(*vals); @constraints[:enum] = vals.flatten; end
    def const(val); @constraints[:const] = val; end
    def default(val); @constraints[:default] = val; end
  end
end
```

#### ActiveModel Validation Integration (CRITICAL)

**Problem**: The `ActiveModelAdapter#apply_type_validations` method checks for `String`, `Integer`, `Float`, etc., but has no handling for `Primitive` subclasses. Without a fix:
- ✅ JSON Schema generation works correctly
- ❌ ActiveModel validations are NOT generated

**Solution**: Unwrap Primitive types in the adapter.

**Modified File**: `lib/easy_talk/validation_adapters/active_model_adapter.rb`

```ruby
def apply_type_validations(type)
  # Handle Primitive subclasses - unwrap to base type and merge constraints
  if type.respond_to?(:ancestors) && type.ancestors.include?(EasyTalk::Primitive)
    # Merge Primitive's constraints with property constraints (property wins on conflict)
    @constraints = type.constraints.merge(@constraints)
    # Recurse with the underlying Ruby type
    return apply_type_validations(type.ruby_type)
  end

  # ... existing type checks for String, Integer, etc. ...
end
```

#### Property Integration

**No changes needed to `lib/easy_talk/property.rb`**. The existing code already handles types with `.schema`:

```ruby
# Line 111-114 in property.rb (existing code)
elsif type.respond_to?(:schema)
  type.schema.merge!(constraints)
```

Since Primitive implements `.schema`, Property will:
1. Detect `Email.respond_to?(:schema)` → true
2. Call `Email.schema` → `{ type: 'string', format: 'email' }`
3. Merge property-level constraints

---

### Feature 2: Symbol-Based Type Syntax

#### Overview

Allow symbols as type declarations, providing a more JSON Schema-aligned syntax.

#### Syntax

```ruby
class User
  include EasyTalk::Model

  define_schema do
    property :name, :string, min_length: 1
    property :age, :integer, minimum: 0
    property :score, :number
    property :active, :boolean
  end
end
```

#### Supported Symbols

| Symbol | Maps To |
|--------|---------|
| `:string` | `String` |
| `:integer` | `Integer` |
| `:number` | `Float` |
| `:boolean` | `T::Boolean` |
| `:array` | `Array` |
| `:null` | `NilClass` |

#### Implementation

**New File**: `lib/easy_talk/type_resolver.rb`

**CRITICAL**: Symbol resolution MUST happen in SchemaDefinition BEFORE the type is passed to:
1. Property (for JSON Schema generation)
2. ActiveModelAdapter (for validation generation)

Both components expect Ruby classes, not symbols. Passing `:string` instead of `String` will break `type.is_a?(Class)` checks.

```ruby
module EasyTalk
  class TypeResolver
    SYMBOL_TO_TYPE = {
      string: String,
      integer: Integer,
      number: Float,
      boolean: T::Boolean,
      array: Array,
      null: NilClass
    }.freeze

    class << self
      # Resolves type to a Ruby class
      # @param type [Symbol, Class, Object] the type to resolve
      # @return [Class] the resolved Ruby class
      # @raise [ArgumentError] if symbol is unknown
      def resolve(type)
        case type
        when Symbol
          SYMBOL_TO_TYPE.fetch(type) do
            raise ArgumentError, "Unknown type symbol: #{type.inspect}. Valid symbols: #{SYMBOL_TO_TYPE.keys.join(', ')}"
          end
        when Class
          type
        else
          type  # Pass through T:: types, etc.
        end
      end

      # Check if a value is a resolvable symbol
      def symbol_type?(type)
        type.is_a?(Symbol) && SYMBOL_TO_TYPE.key?(type)
      end
    end
  end
end
```

---

### Feature 3: Convention-Based Type Inference

#### Overview

Automatically infer property types and constraints based on naming patterns.

#### Design Principles

- **Conservative defaults** — Only unambiguous, safe patterns
- **No Float inference for financial fields** — Risk of precision loss
- **Per-schema override capability** — Full control when needed
- **Explicit opt-in required** — No magic by default

#### Activation

**Per-schema** (recommended):
```ruby
define_schema do
  infer_types true
  property :email  # Inferred as String with format: 'email'
end
```

**With custom conventions** (merged with global):
```ruby
define_schema do
  infer_types conventions: {
    /\A.*_at\z/ => { type: String, constraints: { format: 'date-time' } },
    /\Aurl\z/i => { type: String, constraints: { format: 'uri' } }
  }
end
```

**With ONLY specific conventions** (ignores global):
```ruby
define_schema do
  infer_types only: {
    /\Aemail\z/i => { type: String, constraints: { format: 'email' } }
  }
end
```

#### Conservative Default Conventions

Only patterns that are **unambiguous**, **safe**, and **standard**:

| Pattern | Type | Constraints | Why Safe |
|---------|------|-------------|----------|
| `/\Aemail\z/i` | String | `format: 'email'` | Always a string, always email format |
| `/\A(is_\|has_\|can_\|should_\|was_\|will_)/` | T::Boolean | — | Ruby/Rails boolean naming convention |
| `/\Auuid\z/i` | String | `format: 'uuid'` | Explicit field name, clear intent |

#### Intentionally EXCLUDED Patterns

| Pattern | Why Excluded |
|---------|--------------|
| `price`, `cost`, `total` → Float | **Dangerous for financial data**. Float precision issues cause real bugs. Use Integer (cents) or BigDecimal. |
| `*_id` → uuid format | Could be integer auto-increment IDs, not UUIDs |
| `*_count` → Integer | Could be Float for averages |
| `*_at`, `*_date` → date-time | Could be DateTime objects, not strings |

#### Usage Examples

```ruby
# Per-schema activation with conservative global defaults
class User
  include EasyTalk::Model

  define_schema do
    infer_types true

    property :email           # Inferred: String, format: 'email'
    property :is_admin        # Inferred: T::Boolean (is_ prefix)
    property :has_verified    # Inferred: T::Boolean (has_ prefix)
    property :uuid            # Inferred: String, format: 'uuid'
    property :name, String    # Explicit type - no inference
    property :age, Integer    # Explicit type - no inference
  end
end

# Per-schema with custom conventions (merged with global)
class Event
  include EasyTalk::Model

  define_schema do
    infer_types conventions: {
      /\A.*_at\z/ => { type: String, constraints: { format: 'date-time' } },
      /\Aurl\z/i => { type: String, constraints: { format: 'uri' } }
    }

    property :email           # From global: String, format: 'email'
    property :created_at      # From local: String, format: 'date-time'
    property :url             # From local: String, format: 'uri'
  end
end

# Per-schema with ONLY specific conventions (ignores global)
class Payment
  include EasyTalk::Model

  define_schema do
    infer_types only: {
      /\Aemail\z/i => { type: String, constraints: { format: 'email' } }
    }

    property :email           # Inferred: String, format: 'email'
    property :is_refunded, T::Boolean  # Must be explicit (only: ignores global)
  end
end
```

#### Implementation

**Modified File**: `lib/easy_talk/configuration.rb`

```ruby
class Configuration
  attr_accessor :infer_types
  attr_reader :type_conventions

  def initialize
    @infer_types = false  # Disabled by default
    @type_conventions = default_conventions
  end

  def register_convention(pattern, type:, **constraints)
    @type_conventions[pattern] = { type: type, constraints: constraints }
  end

  def clear_conventions!
    @type_conventions = {}
  end

  def reset_conventions!
    @type_conventions = default_conventions
  end

  private

  # CONSERVATIVE DEFAULTS: Only include patterns that are:
  # 1. Unambiguous (email is always email-formatted string)
  # 2. Safe (no precision-sensitive types like Float for money)
  # 3. Standard (widely accepted conventions)
  def default_conventions
    {
      /\Aemail\z/i => { type: String, constraints: { format: 'email' } },
      /\A(is_|has_|can_|should_|was_|will_)/ => { type: T::Boolean, constraints: {} },
      /\Auuid\z/i => { type: String, constraints: { format: 'uuid' } }
    }
  end
end
```

**Modified File**: `lib/easy_talk/schema_definition.rb`

**Resolution Order** (CRITICAL for compatibility):
1. Resolve symbols to Ruby classes (`:string` → `String`)
2. Infer type from name if no explicit type and inference enabled
3. Store the resolved Ruby class (never a symbol)

```ruby
class SchemaDefinition
  def initialize(name, options = {})
    # ... existing code ...
    @infer_types_enabled = false
    @local_conventions = nil  # nil = use global, hash = use local
  end

  def property(name, type = nil, **constraints, &block)
    # CRITICAL: resolved_type is ALWAYS a Ruby class, never a symbol
    resolved_type, inferred_constraints = resolve_property_type(name, type)
    merged_constraints = inferred_constraints.merge(constraints)

    # Store the resolved class - Property and ActiveModelAdapter expect classes
    # ... rest of existing property logic ...
  end

  # Per-schema DSL option with flexible arguments
  def infer_types(enabled_or_options = true)
    case enabled_or_options
    when true
      @infer_types_enabled = true
      @local_conventions = nil  # Use global
    when false
      @infer_types_enabled = false
    when Hash
      @infer_types_enabled = true
      if enabled_or_options[:only]
        @local_conventions = enabled_or_options[:only]
      elsif enabled_or_options[:conventions]
        @local_conventions = EasyTalk.configuration.type_conventions
                               .merge(enabled_or_options[:conventions])
      end
    end
  end

  private

  def resolve_property_type(name, explicit_type)
    if explicit_type
      resolved = resolve_type(explicit_type)
      return [resolved, {}]
    end

    return [String, {}] unless @infer_types_enabled

    infer_type_from_name(name)
  end

  def resolve_type(type)
    case type
    when Symbol
      EasyTalk::TypeResolver.resolve(type)
    when Class
      type
    else
      type
    end
  end

  def infer_type_from_name(name)
    conventions = @local_conventions || EasyTalk.configuration.type_conventions

    conventions.each do |pattern, config|
      if name.to_s.match?(pattern)
        return [config[:type], config[:constraints] || {}]
      end
    end

    [String, {}]  # Default fallback
  end
end
```

---

## Files Summary

### New Files

| File | Purpose |
|------|---------|
| `lib/easy_talk/primitive.rb` | Primitive base class + ConstraintCollector DSL |
| `lib/easy_talk/type_resolver.rb` | Symbol → Ruby type resolution |
| `spec/easy_talk/primitive_spec.rb` | Unit tests for Primitive class |
| `spec/easy_talk/type_inference_spec.rb` | Unit tests for type inference |

### Modified Files

| File | Changes |
|------|---------|
| `lib/easy_talk/configuration.rb` | Add `infer_types`, `type_conventions`, convention methods |
| `lib/easy_talk/schema_definition.rb` | Add type inference, symbol resolution, `infer_types` DSL |
| `lib/easy_talk/validation_adapters/active_model_adapter.rb` | **CRITICAL**: Unwrap Primitive types for validation generation |
| `lib/easy_talk.rb` | Require new files |

**Note**: `lib/easy_talk/property.rb` does NOT need modification. It already handles types with `.schema` via duck typing (line 111-114).

---

## Backward Compatibility

This proposal is **fully backward compatible**:

| Aspect | Impact |
|--------|--------|
| `infer_types` | Defaults to `false` — no behavior change |
| Existing `property :name, Type` | Works unchanged |
| Symbol types | New syntax, doesn't affect existing code |
| Primitive classes | New feature, doesn't affect existing code |
| Configuration | New options only, existing options unchanged |

**No breaking changes.**

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| Empty convention list | Falls back to `String` |
| Conflicting conventions | First match wins (hash iteration order) |
| Primitive with no constraints | Valid — creates type-only schema |
| Inference disabled globally, enabled per-schema | Per-schema takes precedence |
| Explicit type with inference enabled | Explicit type always wins |
| Unknown symbol type | Raises `ArgumentError` with helpful message |

---

## Test Plan

### Unit Tests

1. **Primitive class** (`spec/easy_talk/primitive_spec.rb`)
   - Creates valid schema from block
   - Handles all constraint types (string, numeric, common)
   - Works with both symbol and constant type syntax
   - Generates correct JSON Schema output
   - Exposes `ruby_type` and `constraints` for ActiveModelAdapter

2. **Type inference** (`spec/easy_talk/type_inference_spec.rb`)
   - Default conventions work correctly
   - Custom conventions can be registered
   - Per-schema `infer_types` DSL works
   - `infer_types conventions: {...}` merges with global
   - `infer_types only: {...}` ignores global
   - Explicit types override inference
   - Unknown names default to String

3. **Symbol types** (`spec/easy_talk/type_resolver_spec.rb`)
   - All symbol types resolve correctly
   - Unknown symbols raise errors with helpful message
   - Classes pass through unchanged

4. **Symbol resolution timing** (CRITICAL)
   - `property :name, :string` resolves to `String` before reaching Property
   - `property :name, :string` resolves to `String` before reaching ActiveModelAdapter
   - Unknown symbols raise `ArgumentError` with helpful message

5. **ActiveModel validation** (CRITICAL)
   - Primitive constraints generate correct ActiveModel validations
   - `Email` primitive with `format 'email'` validates email format
   - `PositiveInteger` primitive with `minimum 0` rejects negative numbers
   - Property-level constraints override Primitive constraints
   - Both JSON Schema AND ActiveModel validation work correctly

### Integration Tests

- Primitives work in Model properties
- Inference works with Model properties
- Symbol types work everywhere
- Constraints merge correctly (explicit overrides inferred)

### Edge Cases

- Empty convention list
- Conflicting conventions (first match wins)
- Primitive with no constraints
- Inference disabled globally but enabled per-schema
- Nested models with mixed inference settings

---

## Design Rationale: Conservative Defaults

### Why Minimal Default Conventions?

1. **Financial Data Safety**: Inferring `Float` for `price`, `cost`, `total` is dangerous. Float precision issues can cause real financial bugs. Users should explicitly choose `Integer` (cents), `BigDecimal`, or `Float` based on their needs.

2. **ID Ambiguity**: `*_id` fields could be:
   - Integer auto-increment IDs
   - UUID strings
   - External system IDs (various formats)

   Assuming `format: 'uuid'` would break many applications.

3. **Count Ambiguity**: `*_count` could be:
   - Integer counts
   - Float averages
   - Decimal for precision

4. **Explicit is Better Than Implicit**: Schema definitions should be predictable. Magic that "just works" until it doesn't is worse than requiring explicit types.

### Per-Schema Override Philosophy

- `infer_types true` — Opt-in to global conventions
- `infer_types conventions: {...}` — Add project-specific patterns
- `infer_types only: {...}` — Full control, no surprises from global config

This ensures models remain isolated and predictable.

---

## Alternatives Considered

### Alternative 1: Schema-Only Mode via Class Method

```ruby
EasyTalk.schema(:string, min_length: 1, format: 'email')
# => { "type": "string", "minLength": 1, "format": "email" }
```

**Rejected**: Produces schemas but not reusable types. Doesn't integrate with Model properties.

### Alternative 2: Anonymous Property Builder

```ruby
EasyTalk::Property.build(:value, String, format: 'email').schema
```

**Rejected**: More verbose than Primitive classes. Awkward API for reuse.

### Alternative 3: Type inference only (no Primitives)

**Rejected**: Primitives provide explicit, documented types that are easier to understand and test than convention-based inference alone.

### Alternative 4: Aggressive default conventions

**Rejected**: Patterns like `price` → `Float` are dangerous for financial applications. Conservative defaults prevent subtle bugs.

---

## Implementation Order

1. **Phase 1**: TypeResolver + symbol types (smallest scope, foundational)
2. **Phase 2**: Primitive class (builds on Phase 1)
3. **Phase 3**: ActiveModelAdapter Primitive support (CRITICAL)
4. **Phase 4**: Convention registry in Configuration
5. **Phase 5**: Type inference in SchemaDefinition
6. **Phase 6**: Documentation and comprehensive tests

---

## Open Questions

1. **Convention ordering**: Should we use an ordered data structure instead of Hash to ensure deterministic matching?

2. **Primitive composition**: Should Primitives support composing with other Primitives?
   ```ruby
   class NonEmptyEmail < EasyTalk::Primitive(Email) { min_length 1 }
   ```

3. **Array item type inference**: Should `property :emails` infer `T::Array[Email]`?

4. **Symbols in T:: types**: Should `T::Array[:string]` work, or raise an error?

---

## References

- [Pydantic Field Types](https://docs.pydantic.dev/latest/concepts/types/) — Inspiration for Primitive concept
- [JSON Schema Specification](https://json-schema.org/specification.html)
- [Rails Convention over Configuration](https://rubyonrails.org/doctrine#convention-over-configuration)
