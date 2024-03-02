require_relative 'base_builder'

module EsquemaBase
  module Builders
    class StringBuilder < BaseBuilder
      extend T::Sig
      VALID_OPTIONS = {
        title: { type: T.nilable(String), key: :title },
        description: { type: T.nilable(String), key: :description },
        format: { type: T.nilable(String), key: :format },
        pattern: { type: T.nilable(String), key: :pattern },
        min_length: { type: T.nilable(Integer), key: :minLength },
        max_length: { type: T.nilable(Integer), key: :maxLength },
        enum: { type: T.nilable(T::Array[String]), key: :enum },
        const: { type: T.nilable(String), key: :const }
      }

      sig { params(name: String, options: T::Hash[Symbol, T.nilable(T.any(String, Integer))]).void }
      def initialize(name, options = {})
        options.assert_valid_keys(VALID_OPTIONS.keys)
        @name = name
        @options = options
        @schema = { type: 'string' }
      end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def build_property
        VALID_OPTIONS.each_with_object(schema) do |(key, value), obj|
          next if options[key].nil?

          obj[value[:key]] = T.let(options[key], value[:type])
        end
      end
    end
  end
end
