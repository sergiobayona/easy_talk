module EsquemaBase
  module Builders
    class BaseBuilder
      extend T::Sig

      COMMON_OPTIONS = {
        title: { type: T.nilable(String), key: :title },
        description: { type: T.nilable(String), key: :description },
        optional: { type: T::Boolean } # special option to skip from including in required array. Does not get printed.
      }.freeze

      attr_reader :name, :schema, :options, :valid_options

      def initialize(name, schema, options = {}, valid_options = {})
        @name = name
        @schema = schema
        @options = options
        @valid_options = valid_options
      end

      def build_property
        valid_options.each_with_object(schema) do |(key, value), obj|
          next if options[key].nil?

          obj[value[:key]] = T.let(options[key], value[:type])
        end
      end

      def self.build(name, options)
        builder = new(name, options)
        builder.build_property
      end
    end
  end
end
