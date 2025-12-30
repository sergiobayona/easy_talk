# frozen_string_literal: true
# typed: true

require_relative 'base_builder'
require 'js_regex' # Compile the ruby regex to JS regex
require 'sorbet-runtime' # Add the import statement for the T module

module EasyTalk
  module Builders
    # Builder class for string properties.
    class StringBuilder < BaseBuilder
      extend T::Sig

      VALID_OPTIONS = {
        format: { type: String, key: :format },
        pattern: { type: String, key: :pattern },
        min_length: { type: Integer, key: :minLength },
        max_length: { type: Integer, key: :maxLength },
        enum: { type: T::Array[String], key: :enum },
        const: { type: String, key: :const },
        default: { type: String, key: :default }
      }.freeze

      sig { params(name: Symbol, constraints: T::Hash[Symbol, T.untyped]).void }
      def initialize(name, constraints = {})
        super(name, { type: 'string' }, constraints, VALID_OPTIONS)
      end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def build
        super.tap do |schema|
          pattern = schema[:pattern]
          schema[:pattern] = JsRegex.new(pattern).source if pattern.is_a?(String)
        end
      end
    end
  end
end
