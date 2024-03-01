module EsquemaBase
  module Builders
    class BaseBuilder
      extend T::Sig

      attr_reader :name, :options, :schema

      def initialize(name, schema, options = {})
        @name = name
        @options = options
        @schema = schema
      end

      def build_property
        options.each_with_object(schema) do |(key, value), obj|
          obj[key] = value
        end
      end

      def self.build(name, options)
        builder = new(name, options)
        builder.build_property
      end
    end
  end
end
