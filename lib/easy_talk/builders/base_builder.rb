# typed: true

module EasyTalk
  module Builders
    class BaseBuilder
      extend T::Sig

      COMMON_OPTIONS = {
        title: { type: T.nilable(String), key: :title },
        description: { type: T.nilable(String), key: :description },
        optional: { type: T::Boolean } # special option to skip from including in required array. Does not get printed.
      }.freeze

      attr_reader :name, :schema

      sig do
        params(
          name: Symbol,
          schema: T::Hash[Symbol, T.untyped],
          options: T::Hash[Symbol, String],
          valid_options: T::Hash[Symbol, T.untyped]
        ).void
      end
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

          # Work around for Sorbet's default inability to type check the items inside an array
          if value[:type].respond_to?(:recursively_valid?) && !value[:type].recursively_valid?(@options[key])
            raise TypeError, "Invalid type for #{key}"
          end

          obj[value[:key]] = T.let(@options[key], value[:type])
        end
      end
    end
  end
end
