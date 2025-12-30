# frozen_string_literal: true
# typed: true

require_relative 'model_helper'

module EasyTalk
  module RefHelper
    extend T::Sig

    sig { params(type: T.untyped, constraints: T::Hash[Symbol, T.untyped]).returns(T::Boolean) }
    def self.should_use_ref?(type, constraints)
      ModelHelper.easytalk_model?(type) && should_use_ref_for_type?(type, constraints)
    end

    sig { params(type: T.untyped, constraints: T::Hash[Symbol, T.untyped]).returns(T::Boolean) }
    def self.should_use_ref_for_type?(type, constraints)
      return false unless ModelHelper.easytalk_model?(type)

      # Per-property constraint takes precedence
      if constraints.key?(:ref)
        constraints[:ref]
      else
        EasyTalk.configuration.use_refs
      end
    end

    sig { params(type: T.untyped, constraints: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
    def self.build_ref_schema(type, constraints)
      # Remove ref and optional from constraints as they're not JSON Schema keywords
      { '$ref': type.ref_template }.merge(constraints.except(:ref, :optional))
    end
  end
end
