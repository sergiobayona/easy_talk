require 'json'
require_relative 'builders/integer_builder'
require_relative 'builders/number_builder'
require_relative 'builders/boolean_builder'
require_relative 'builders/null_builder'
require_relative 'builders/array_builder'
require_relative 'builders/object_builder'
require_relative 'builders/string_builder'
require_relative 'builders/date_builder'
require_relative 'builders/datetime_builder'
require_relative 'builders/time_builder'

# frozen_string_literal: true

module EsquemaBase
  class Property
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

    def initialize(name, type, options = {})
      @name = name
      @type = type
      @options = options
    end

    def build_property
      builder = TYPE_TO_BUILDER[type.name]
      return builder.build(name, options) if builder

      case type.class.name
      when 'T::Types::TypedArray'
        build_array_property
      when 'T::Types::Hash'
        Builders::ObjectBuilder.build(name, options)
      else
        build_object_property
      end
    end

    def build_array_property
      inner_type = type.type.raw_type
      Builders::ArrayBuilder.build(name, inner_type, options)
    end

    def build_object_property
      return type.schema if type.respond_to?(:schema)

      Builders::ObjectBuilder.build(name, options)
    end

    def as_json(*_args)
      build_property.as_json
    end
  end
end
