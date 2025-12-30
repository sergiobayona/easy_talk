# frozen_string_literal: true
# typed: true

module EasyTalk
  module ModelHelper
    extend T::Sig

    sig { params(type: T.untyped).returns(T::Boolean) }
    def self.easytalk_model?(type)
      type.is_a?(Class) &&
        type.respond_to?(:schema) &&
        type.respond_to?(:ref_template) &&
        defined?(EasyTalk::Model) &&
        type.include?(EasyTalk::Model)
    end
  end
end
