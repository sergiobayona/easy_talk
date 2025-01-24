require 'easy_talk/schema_builder'
require 'active_support/concern'

module EasyTalk
  module ActiveRecordModel
    extend ActiveSupport::Concern

    included do
      include EasyTalk::Model

      def self.json_schema
        @json_schema ||= SchemaBuilder.new(self).build
      end

      def self.schema_enhancements
        @schema_enhancements ||= {}
      end

      def self.enhance_schema(enhancements)
        @schema_enhancements = enhancements
      end
    end
  end
end
