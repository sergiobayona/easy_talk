# frozen_string_literal: true

module EasyTalk
  module ModelHelper
    def self.easytalk_model?(type)
      type.is_a?(Class) &&
        type.respond_to?(:schema) &&
        type.respond_to?(:ref_template) &&
        defined?(EasyTalk::Model) &&
        type.include?(EasyTalk::Model)
    end
  end
end
