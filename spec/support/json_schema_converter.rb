require 'easy_talk'

class JsonSchemaConverter
  def initialize(schema, name = "TestModel_#{SecureRandom.hex(4)}")
    @schema = schema
    @name = name
  end

  def to_class
    schema_data = @schema
    model_name = @name

    Class.new do
      include EasyTalk::Model

      # Define a closure to capture schema_data within the class scope if needed, 
      # though we mostly process it before define_schema.
      
      # We need to process properties outside define_schema or pass them in a way 
      # that doesn't lose context, but define_schema block runs in class context.
      # The cleanest way is to define a local variable and use it.
      
      singleton_class.send(:define_method, :name) { model_name }

      define_schema do
        # JSON Schema defaults to allowing additional properties.
        # EasyTalk defaults to disallowing them.
        # We must explicitly allow them unless the schema says false.
        if schema_data.key?('additionalProperties') && schema_data['additionalProperties'] == false
          additional_properties false
        else
          additional_properties true
        end

        if schema_data['title']
          title schema_data['title']
        end

        if schema_data['description']
           description schema_data['description']
        end

        if schema_data['properties']
          schema_data['properties'].each do |prop_name, prop_def|
            # Sanitize property name for Ruby method
            safe_prop_name = prop_name.to_s.gsub(/[^a-zA-Z0-9_]/, '_')
            safe_prop_name = "prop_#{safe_prop_name}" if safe_prop_name =~ /^\d/
            safe_prop_name = safe_prop_name + "_" if safe_prop_name.empty? # Handle empty string key?

            # Determine constraints
            constraints = {}

            # Handle Boolean Schemas or other non-Hash definitions
            if prop_def.is_a?(TrueClass) || prop_def.is_a?(FalseClass)
               # In JSON Schema, property: true means valid, property: false means invalid.
               # For now, let's treat 'true' as Optional String (loose approximation).
               type = String # Placeholder
               constraints[:optional] = true 
            elsif prop_def.is_a?(Hash)
              # Determine type
              type = case prop_def['type']
                     when 'string' then String
                     when 'integer' then Integer
                     when 'number' then Float
                     when 'boolean' then T::Boolean
                     when 'array' then T::Array[String] # simplified
                     else String # fallback
                     end

              # Constraints Mapping
              constraints[:minimum] = prop_def['minimum'] if prop_def['minimum']
              constraints[:maximum] = prop_def['maximum'] if prop_def['maximum']
              constraints[:min_length] = prop_def['minLength'] if prop_def['minLength']
              constraints[:max_length] = prop_def['maxLength'] if prop_def['maxLength']
              constraints[:pattern] = prop_def['pattern'] if prop_def['pattern']
              constraints[:enum] = prop_def['enum'] if prop_def['enum']
              constraints[:format] = prop_def['format'] if prop_def['format']
            else
               # Fallback
               type = String
            end

            # Always map original name
            constraints[:as] = prop_name

            # Optional/Required Handling
            # JSON Schema: properties optional by default, required in 'required' list
            # EasyTalk: properties required by default, optional: true explicitly
            is_required = schema_data['required']&.include?(prop_name)
            if !is_required
               constraints[:optional] = true
            end

            property safe_prop_name.to_sym, type, **constraints
          end
        end
      end
    end
  end
end
