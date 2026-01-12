# frozen_string_literal: true
# typed: true

require_relative 'keywords'
require_relative 'types/composer'
require_relative 'validation_builder'

module EasyTalk
  #
  #= EasyTalk \SchemaDefinition
  # SchemaDefinition provides the methods for defining a schema within the define_schema block.
  # The @schema is a hash that contains the unvalidated schema definition for the model.
  # A SchemaDefinition instanace is the passed to the Builder.build_schema method to validate and compile the schema.
  class SchemaDefinition
    extend T::Sig
    extend T::AnyOf
    extend T::OneOf
    extend T::AllOf

    attr_reader :name, :schema
    attr_accessor :klass # Add accessor for the model class

    sig { params(name: String, schema: T::Hash[Symbol, T.untyped]).void }
    def initialize(name, schema = {})
      @schema = schema.dup
      @schema[:additional_properties] = EasyTalk.configuration.default_additional_properties unless @schema.key?(:additional_properties)
      @name = name
      @klass = nil # Initialize klass to nil
      @property_naming_strategy = EasyTalk.configuration.property_naming_strategy
    end

    EasyTalk::KEYWORDS.each do |keyword|
      if keyword == :additional_properties
        # Special handling for additional_properties to support type + constraints syntax
        define_method(keyword) do |*args|
          value = parse_additional_properties_args(args)
          @schema[keyword] = value
        end
      else
        define_method(keyword) do |*values|
          @schema[keyword] = values.size > 1 ? values : values.first
        end
      end
    end

    sig { params(subschemas: T.untyped).void }
    def compose(*subschemas)
      @schema[:subschemas] ||= []
      @schema[:subschemas] += subschemas
    end

    sig { params(name: T.any(Symbol, String), type: T.untyped, constraints: T::Hash[Symbol, T.untyped], block: T.nilable(T.proc.void)).void }
    def property(name, type, constraints = {}, &block)
      validate_property_name(name)
      constraints[:as] ||= @property_naming_strategy.call(name)
      @schema[:properties] ||= {}

      if block_given?
        raise ArgumentError,
              'Block-style sub-schemas are no longer supported. Use class references as types instead.'
      end

      @schema[:properties][name] = { type:, constraints: }
    end

    sig { params(name: T.any(Symbol, String)).void }
    def validate_property_name(name)
      return if name.to_s.match?(/^[A-Za-z_][A-Za-z0-9_]*$/)

      message = "Invalid property name '#{name}'. Must start with letter/underscore " \
                'and contain only letters, numbers, underscores'
      raise InvalidPropertyNameError, message
    end

    sig { returns(T.nilable(T::Boolean)) }
    def optional?
      @schema[:optional]
    end

    # Helper method for nullable and optional properties
    sig { params(name: Symbol, type: T.untyped, constraints: T::Hash[Symbol, T.untyped]).void }
    def nullable_optional_property(name, type, constraints = {})
      # Ensure type is nilable
      nilable_type = if type.respond_to?(:nilable?) && type.nilable?
                       type
                     else
                       T.nilable(type)
                     end

      # Ensure constraints include optional: true
      constraints = constraints.merge(optional: true)

      # Call standard property method
      property(name, nilable_type, constraints)
    end

    sig { params(strategy: T.any(Symbol, T.proc.params(arg0: T.untyped).returns(Symbol))).void }
    def property_naming_strategy(strategy)
      @property_naming_strategy = EasyTalk::NamingStrategies.derive_strategy(strategy)
    end

    private

    # Parses arguments for additional_properties to support multiple syntaxes:
    # - additional_properties true/false (boolean)
    # - additional_properties String (type class)
    # - additional_properties Integer, minimum: 0, maximum: 100 (type + constraints)
    sig { params(args: T::Array[T.untyped]).returns(T.untyped) }
    def parse_additional_properties_args(args)
      return args.first if args.empty?

      # Single boolean argument
      first_arg = args.first
      return first_arg if args.size == 1 && (first_arg.is_a?(TrueClass) || first_arg.is_a?(FalseClass))

      # Single type class (String, Integer, custom model, etc.)
      return first_arg if args.size == 1 && first_arg.is_a?(Class)

      # Type + constraints: additional_properties Integer, minimum: 0, maximum: 100
      # args = [Integer, { minimum: 0, maximum: 100 }] or [Integer, minimum: 0, maximum: 100]
      if args.size >= 1 && args.first.is_a?(Class)
        type = args.first
        # Merge all hash arguments as constraints
        constraints = args[1..].select { |arg| arg.is_a?(Hash) }.reduce({}, :merge)
        return { type:, **constraints }
      end

      # Fallback: return as-is
      args.first
    end
  end
end
