require 'pry-byebug'
require_relative 'keywords'

module EasyTalk
  class SchemaDefinition
    extend T::Sig

    attr_reader :klass

    def initialize(klass, schema_definition)
      @schema_definition = schema_definition
      @klass = klass
    end

    EasyTalk::KEYWORDS.each do |method_name, keyword|
      define_method(method_name) do |*values|
        @schema_definition[keyword] = values.size > 1 ? values : values.first
      end
    end

    sig { params(name: Symbol, type: T.untyped, constraints: T.untyped).void }
    def property(name, type, **constraints)
      @schema_definition[:properties] ||= {}
      @schema_definition[:properties].merge!(name => constraints.merge!(type:))
    end
  end
end
