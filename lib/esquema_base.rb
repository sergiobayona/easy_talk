module EsquemaBase
  class Error < StandardError; end
  require 'sorbet-runtime'
  require 'esquema_base/model'
  require 'esquema_base/builder'
  require 'esquema_base/property'
  require 'esquema_base/schema_definition'
  require 'esquema_base/version'

  class UnsupportedTypeError < ArgumentError; end
  class UnsupportedConstraintError < ArgumentError; end
end
