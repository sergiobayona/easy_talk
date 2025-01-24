# frozen_string_literal: true

# The EasyTalk module is the main namespace for the gem.
module EasyTalk
  class Error < StandardError; end
  require 'sorbet-runtime'
  require 'easy_talk/sorbet_extension'
  require 'easy_talk/configuration'
  require 'easy_talk/active_record_model'
  require 'easy_talk/types/any_of'
  require 'easy_talk/types/all_of'
  require 'easy_talk/types/one_of'
  require 'easy_talk/model'
  require 'easy_talk/property'
  require 'easy_talk/schema_definition'
  require 'easy_talk/tools/function_builder'
  require 'easy_talk/version'

  class UnsupportedTypeError < ArgumentError; end
  class UnsupportedConstraintError < ArgumentError; end
end
