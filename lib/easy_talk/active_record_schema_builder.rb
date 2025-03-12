# frozen_string_literal: true

module EasyTalk
  # This class is responsible for building a SchemaDefinition from an ActiveRecord model
  # It analyzes the database schema and creates a SchemaDefinition that can be
  # passed to ObjectBuilder for final schema generation
  class ActiveRecordSchemaBuilder
    # Mapping of ActiveRecord column types to Ruby classes
    COLUMN_TYPE_MAP = {
      string: String,
      text: String,
      integer: Integer,
      bigint: Integer,
      float: Float,
      decimal: Float,
      boolean: T::Boolean,
      date: Date,
      datetime: DateTime,
      timestamp: DateTime,
      time: Time,
      json: Hash,
      jsonb: Hash
    }.freeze

    # Mapping for format constraints based on column type
    FORMAT_MAP = {
      date: 'date',
      datetime: 'date-time',
      timestamp: 'date-time',
      time: 'time'
    }.freeze

    attr_reader :model

    # Initialize the builder with an ActiveRecord model
    #
    # @param model [Class] An ActiveRecord model class
    # @raise [ArgumentError] If the provided class is not an ActiveRecord model
    def initialize(model)
      raise ArgumentError, 'Class must be an ActiveRecord model' unless model.ancestors.include?(ActiveRecord::Base)

      @model = model
    end

    # Build a SchemaDefinition object from the ActiveRecord model
    #
    # @return [EasyTalk::SchemaDefinition] A schema definition built from the database structure
    def build_schema_definition
      schema_def = SchemaDefinition.new(model.name)

      # Apply basic schema metadata
      apply_schema_metadata(schema_def)

      # Add all database columns as properties
      add_column_properties(schema_def)

      # Add model associations as properties
      add_association_properties(schema_def) unless EasyTalk.configuration.exclude_associations

      # Add virtual properties defined in schema_enhancements
      add_virtual_properties(schema_def)

      schema_def
    end

    private

    # Set top-level schema metadata like title, description, and additionalProperties
    #
    # @param schema_def [EasyTalk::SchemaDefinition] The schema definition to modify
    def apply_schema_metadata(schema_def)
      # Set title (from enhancements or derive from model name)
      title = schema_enhancements['title'] || model.name.demodulize.humanize
      schema_def.title(title)

      # Set description if provided
      if (description = schema_enhancements['description'])
        schema_def.description(description)
      end

      # Set additionalProperties (from enhancements or configuration default)
      additional_props = if schema_enhancements.key?('additionalProperties')
                           schema_enhancements['additionalProperties']
                         else
                           EasyTalk.configuration.default_additional_properties
                         end
      schema_def.additional_properties(additional_props)
    end

    # Add properties based on database columns
    #
    # @param schema_def [EasyTalk::SchemaDefinition] The schema definition to modify
    def add_column_properties(schema_def)
      filtered_columns.each do |column|
        # Get column enhancement info if it exists
        column_enhancements = schema_enhancements.dig('properties', column.name.to_s) || {}

        # Map the database type to Ruby type
        ruby_type = COLUMN_TYPE_MAP.fetch(column.type, String)

        # If the column is nullable, wrap the type in a Union with NilClass
        ruby_type = T::Types::Union.new([ruby_type, NilClass]) if column.null

        # Build constraints hash for this column
        constraints = build_column_constraints(column, column_enhancements)

        # Add the property to schema definition
        schema_def.property(column.name.to_sym, ruby_type, constraints)
      end
    end

    # Build constraints hash for a database column
    #
    # @param column [ActiveRecord::ConnectionAdapters::Column] The database column
    # @param enhancements [Hash] Any schema enhancements for this column
    # @return [Hash] The constraints hash
    def build_column_constraints(column, enhancements)
      constraints = {
        optional: enhancements['optional'],
        description: enhancements['description'],
        title: enhancements['title']
      }

      # Add format constraint for date/time columns
      if (format = FORMAT_MAP[column.type])
        constraints[:format] = format
      end

      # Add max_length for string columns with limits
      constraints[:max_length] = column.limit if column.type == :string && column.limit

      # Add precision/scale for numeric columns
      if column.type == :decimal && column.precision
        constraints[:precision] = column.precision
        constraints[:scale] = column.scale if column.scale
      end

      # Add default value if present and not a proc
      constraints[:default] = column.default if column.default && !column.default.is_a?(Proc)

      # Remove nil values
      constraints.compact
    end

    # Add properties based on ActiveRecord associations
    #
    # @param schema_def [EasyTalk::SchemaDefinition] The schema definition to modify
    def add_association_properties(schema_def)
      model.reflect_on_all_associations.each do |association|
        # Skip if we can't determine the class or it's in the association exclusion list
        next if association_excluded?(association)

        # Get association enhancement info if it exists
        assoc_enhancements = schema_enhancements.dig('properties', association.name.to_s) || {}

        case association.macro
        when :belongs_to, :has_one
          schema_def.property(
            association.name,
            association.klass,
            { optional: assoc_enhancements['optional'], description: assoc_enhancements['description'] }.compact
          )
        when :has_many, :has_and_belongs_to_many
          schema_def.property(
            association.name,
            T::Array[association.klass],
            { optional: assoc_enhancements['optional'], description: assoc_enhancements['description'] }.compact
          )
        end
      end
    end

    # Add virtual properties defined in schema_enhancements
    #
    # @param schema_def [EasyTalk::SchemaDefinition] The schema definition to modify
    def add_virtual_properties(schema_def)
      return unless schema_enhancements['properties']

      schema_enhancements['properties'].each do |name, options|
        next unless options['virtual']

        # Map string type name to Ruby class
        ruby_type = map_type_string_to_ruby_class(options['type'] || 'string')

        # Build constraints for virtual property
        constraints = {
          description: options['description'],
          title: options['title'],
          optional: options['optional'],
          format: options['format'],
          default: options['default'],
          min_length: options['minLength'],
          max_length: options['maxLength'],
          enum: options['enum']
        }.compact

        # Add the virtual property
        schema_def.property(name.to_sym, ruby_type, constraints)
      end
    end

    # Map a type string to a Ruby class
    #
    # @param type_str [String] The type string (e.g., 'string', 'integer')
    # @return [Class] The corresponding Ruby class
    def map_type_string_to_ruby_class(type_str)
      case type_str.to_s.downcase
      when 'string' then String
      when 'integer' then Integer
      when 'number' then Float
      when 'boolean' then T::Boolean
      when 'object' then Hash
      when 'array' then Array
      when 'date' then Date
      when 'datetime' then DateTime
      when 'time' then Time
      else String # Default fallback
      end
    end

    # Get all columns that should be included in the schema
    #
    # @return [Array<ActiveRecord::ConnectionAdapters::Column>] Filtered columns
    def filtered_columns
      model.columns.reject do |column|
        config = EasyTalk.configuration
        excluded_columns.include?(column.name.to_sym) ||
          (config.exclude_primary_key && column.name == model.primary_key) ||
          (config.exclude_timestamps && timestamp_column?(column.name)) ||
          (config.exclude_foreign_keys && foreign_key_column?(column.name))
      end
    end

    # Check if a column is a timestamp column
    #
    # @param column_name [String] The column name
    # @return [Boolean] True if the column is a timestamp column
    def timestamp_column?(column_name)
      %w[created_at updated_at].include?(column_name)
    end

    # Check if a column is a foreign key column
    #
    # @param column_name [String] The column name
    # @return [Boolean] True if the column is a foreign key column
    def foreign_key_column?(column_name)
      column_name.end_with?('_id')
    end

    # Check if an association should be excluded
    #
    # @param association [ActiveRecord::Reflection::AssociationReflection] The association
    # @return [Boolean] True if the association should be excluded
    def association_excluded?(association)
      !association.klass ||
        excluded_associations.include?(association.name.to_sym) ||
        association.options[:polymorphic] # Skip polymorphic associations (complex to model)
    end

    # Get schema enhancements
    #
    # @return [Hash] Schema enhancements
    def schema_enhancements
      @schema_enhancements ||= if model.respond_to?(:schema_enhancements)
                                 model.schema_enhancements.deep_transform_keys(&:to_s)
                               else
                                 {}
                               end
    end

    # Get all excluded columns
    #
    # @return [Array<Symbol>] Excluded column names
    def excluded_columns
      @excluded_columns ||= begin
        config = EasyTalk.configuration
        global_exclusions = config.excluded_columns || []
        model_exclusions = schema_enhancements['ignore'] || []

        # Combine and convert to symbols for consistent comparison
        (global_exclusions + model_exclusions).map(&:to_sym)
      end
    end

    # Get all excluded associations
    #
    # @return [Array<Symbol>] Excluded association names
    def excluded_associations
      @excluded_associations ||= begin
        model_exclusions = schema_enhancements['ignore_associations'] || []
        model_exclusions.map(&:to_sym)
      end
    end
  end
end
