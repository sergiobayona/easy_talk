# frozen_string_literal: true

require_relative 'base_builder'
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

      sig { params(name: Symbol, _type: T.untyped, constraints: Hash).void }
      def initialize(name, _type, constraints)
        super(name, { type: 'string' }, constraints, VALID_OPTIONS)
      end
    end
  end
end
