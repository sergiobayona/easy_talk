module EasyTalk
  module CompositionalKeyword
    def ref_template(name)
      "#/$defs/#{name}"
    end

    def insert_definition(name, model_schema)
      binding.pry
      schema[:defs] ||= {}
      schema[:defs][name] = model_schema
    end

    def insert_reference(name)
      schema[keyword] ||= []
      schema[keyword] << { '$ref': ref_template(name) }
    end

    def schema
      context.schema_definition.schema
    end

    def context
      CurrentContext.model
    end

    def keyword
      self.class.name.underscore.to_sym
    end

    def insert_schemas
      types.each do |type|
        unless type.is_a?(Class) && type.included_modules.include?(EasyTalk::Model)
          raise ArgumentError, "Invalid argument: #{type}. Must be a class that includes EasyTalk::Model"
        end

        insert_definition(type.name.to_sym, type.schema)
        insert_reference(type.name)
      end
    end

    attr_reader :types
  end
end
