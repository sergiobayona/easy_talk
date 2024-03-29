# frozen_string_literal: true

# The EasyTalk module is the main namespace for the gem.
module EasyTalk
  class Error < StandardError; end
  require 'pry-byebug'
  require 'sorbet-runtime'
  require 'easy_talk/sorbet_extension'
  require 'easy_talk/model'
  require 'easy_talk/builder'
  require 'easy_talk/property'
  require 'easy_talk/schema_definition'
  require 'easy_talk/version'

  class UnsupportedTypeError < ArgumentError; end
  class UnsupportedConstraintError < ArgumentError; end

  def self.schemas
    @schemas ||= {}
  end

  def self.add_schema(ref, schema)
    schemas[ref] = schema
  end
end
