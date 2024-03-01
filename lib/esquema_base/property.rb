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

    def initialize(name, type, options = {})
      @name = name
      @type = type
      @options = options
    end

    def build_property # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity
      case type.name
      when 'String'
        Builders::StringBuilder.build(name, options)
      when 'Integer'
        Builders::IntegerBuilder.build(name, options)
      when 'Float', 'BigDecimal'
        Builders::NumberBuilder.build(name, options)
      when 'T::Boolean'
        Builders::BooleanBuilder.build(name, options)
      when 'NilClass'
        Builders::NullBuilder.build(name, options)
      when 'Date'
        Builders::DateBuilder.build(name, options)
      when 'DateTime'
        Builders::DatetimeBuilder.build(name, options)
      when 'Time'
        Builders::TimeBuilder.build(name, options)
      else
        case type.class.name
        when 'T::Types::TypedArray'
          inner_type = type.type.raw_type
          Builders::ArrayBuilder.build(name, inner_type, options)
        when 'T::Types::Hash'
          Builders::ObjectBuilder.build(name, options)
        else
          case type.respond_to?(:schema)
          when true
            type.schema
          when false
            Builders::ObjectBuilder.build(name, options)
          else
            raise "Type #{type} not supported"
          end
        end
      end
    end

    def as_json(*_args)
      build_property.as_json
    end
  end
end
