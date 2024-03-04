# typed: true

module EsquemaBase
  module Builders
    class BaseBuilder
      extend T::Sig

      COMMON_OPTIONS = {
        title: { type: T.nilable(String), key: :title },
        description: { type: T.nilable(String), key: :description },
        optional: { type: T::Boolean } # special option to skip from including in required array. Does not get printed.
      }.freeze

      attr_reader :name, :schema

      def initialize(name, schema, options = {}, valid_options = {})
        @valid_options = COMMON_OPTIONS.merge(valid_options)
        options.assert_valid_keys(@valid_options.keys)
        @name = name
        @schema = schema
        @options = options
      end

      def build
        @valid_options.each_with_object(schema) do |(key, value), obj|
          next if @options[key].nil?

          obj[value[:key]] = T.let(@options[key], value[:type])
        end
      end
    end
  end
end
