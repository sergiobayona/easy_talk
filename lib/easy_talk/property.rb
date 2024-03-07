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
  class Property
    extend T::Sig
    attr_reader :name, :type, :options

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
    # @param options [Hash] The property constraints.
    # @raise [ArgumentError] If the property type is missing.
    sig { params(name: Symbol, type: T.any(String, Object), options: T::Hash[Symbol, T.untyped]).void }
    def initialize(name, type = nil, options = {})
      @name = name
      @type = type
      @options = options
      raise ArgumentError, 'property type is missing' if type.blank?
    end

    def build
      builder = TYPE_TO_BUILDER[type.name]
      return builder.new(name, options).build if builder

      case type.class.name
      when 'T::Types::TypedArray'
        build_array_property
      when 'T::Private::Types::SimplePairUnion', 'T::Types::Union'
        build_union_property
      when 'T::Types::Simple'
        Property.new(name, type.raw_type, options)
      else
        build_object_property
      end
    end

    def as_json(*_args)
      build.as_json
    end

    private

    def build_array_property
      Builders::ArrayBuilder.new(name, type.type, options).build
    end

    def build_union_property
      type.types.each_with_object({ anyOf: [] }) do |type, hash|
        hash[:anyOf] << Property.new(name, type, options)
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
