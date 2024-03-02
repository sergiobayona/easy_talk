require_relative 'base_builder'
require 'sorbet-runtime' # Add the import statement for the T module

module EsquemaBase
  module Builders
    class StringBuilder < BaseBuilder
      extend T::Sig
      VALID_OPTIONS = {
        title: { type: T.nilable(String), key: :title },
        description: { type: T.nilable(String), key: :description },
        format: { type: String, key: :format },
        pattern: { type: String, key: :pattern },
        min_length: { type: Integer, key: :minLength },
        max_length: { type: Integer, key: :maxLength },
        enum: { type: T::Array[String], key: :enum },
        const: { type: String, key: :const },
        default: { type: String, key: :default }
      }.freeze

      sig { params(name: String, options: T::Hash[Symbol, T.nilable(T.any(String, Integer))]).void }
      def initialize(name, options = {})
        options.assert_valid_keys(VALID_OPTIONS.keys)
        @name = name
        @options = options
        @valid_options = VALID_OPTIONS
        @schema = { type: 'string' }
      end
    end
  end
end
