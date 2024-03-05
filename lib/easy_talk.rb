module EasyTalk
  class Error < StandardError; end
  require 'sorbet-runtime'
  require 'easy_talk/model'
  require 'easy_talk/builder'
  require 'easy_talk/property'
  require 'easy_talk/schema_definition'
  require 'easy_talk/version'

  class UnsupportedTypeError < ArgumentError; end
  class UnsupportedConstraintError < ArgumentError; end
end
