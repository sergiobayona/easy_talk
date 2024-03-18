# frozen_string_literal: true

require 'json'
require_relative 'builders/integer_builder'
require_relative 'builders/number_builder'
require_relative 'builders/boolean_builder'
require_relative 'builders/null_builder'
require_relative 'builders/array_builder'
require_relative 'builders/string_builder'
require_relative 'builders/date_builder'
require_relative 'builders/datetime_builder'
require_relative 'builders/time_builder'

# frozen_string_literal: true

module EasyTalk
  # Property class for building a JSON schema property.
  class Property
    extend T::Sig
    attr_reader :name, :type, :constraints

    TYPE_TO_BUILDER = {
      'String' => Builders::StringBuilder,
      'Integer' => Builders::IntegerBuilder,
      'Float' => Builders::NumberBuilder,
      'BigDecimal' => Builders::NumberBuilder,
      'T::Boolean' => Builders::BooleanBuilder,
      'NilClass' => Builders::NullBuilder,
      'Date' => Builders::DateBuilder,
      'DateTime' => Builders::DatetimeBuilder,
      'Time' => Builders::TimeBuilder
    }.freeze

    # Initializes a new instance of the Property class.
    #
    # @param name [Symbol] The name of the property.
    # @param type [Object] The type of the property.
    # @param constraints [Hash] The property constraints.
    # @raise [ArgumentError] If the property type is missing.
    sig { params(name: Symbol, type: T.any(String, Object), constraints: T::Hash[Symbol, T.untyped]).void }
    def initialize(name, type = nil, constraints = {})
      @name = name
      @type = type
      @constraints = constraints
      raise ArgumentError, 'property type is missing' if type.blank?
    end

    def build
      build_with_builder || build_with_type
    end

    def build_with_builder
      builder = TYPE_TO_BUILDER[type.name]
      builder&.new(name, constraints)&.build
    end

    def build_with_type # rubocop:disable Metrics/MethodLength
      case type.class.name
      when 'T::Types::TypedArray'
        build_array_property
      when 'T::Private::Types::SimplePairUnion', 'T::Types::Union'
        build_union_property
      when 'T::Types::Simple'
        @type = type.raw_type
        self
      else
        build_object_property
      end
    end

    def as_json(*_args)
      build.as_json
    end

    private

    def build_array_property
      Builders::ArrayBuilder.new(name, type.type, constraints).build
    end

    def build_union_property
      type.types.each_with_object({ anyOf: [] }) do |type, hash|
        hash[:anyOf] << Property.new(name, type, constraints)
      end
    end

    def build_object_property
      case type.class
      when Class
        type.respond_to?(:schema) ? type.schema : { type: 'object' }
      else
        raise ArgumentError, "unsupported type: #{type.class.name}"
      end
    end
  end
end
