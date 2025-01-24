module EasyTalk
  class SchemaBuilder
    attr_reader :model, :required_properties

    def initialize(model)
      raise ArgumentError, 'Class must be an ActiveRecord model' unless model.ancestors.include?(ActiveRecord::Base)

      @model = model
      @properties = {}
      @required_properties = []
    end

    def build
      {
        title: build_title,
        description: build_description,
        type: 'object',
        properties: build_properties,
        required: required_properties
      }.compact
    end

    private

    def build_properties
      add_column_properties
      add_association_properties
      add_virtual_properties
      @properties
    end

    def add_column_properties
      columns.each do |column|
        next if column.name.end_with?('_id') && EasyTalk.configuration.exclude_foreign_keys

        required_properties << column.name unless column.null
        options = schema_enhancements.dig(:properties, column.name.to_sym) || {}
        @properties[column.name] = build_property(column, options)
      end
    end

    def add_association_properties
      return if EasyTalk.configuration.exclude_associations

      model.reflect_on_all_associations.each do |association|
        @properties[association.name.to_s] = build_association_property(association)
      end
    end

    def add_virtual_properties
      return unless schema_enhancements[:properties]

      schema_enhancements[:properties].select { |_, v| v[:virtual] }.each do |name, options|
        @properties[name] = build_virtual_property(name, options)
      end
    end

    def build_property(column, options)
      {
        type: column_type_to_json_type(column.type),
        format: column_format(column),
        maxLength: column.limit,
        description: options[:description]
      }.compact
    end

    def build_association_property(association)
      case association.macro
      when :belongs_to, :has_one
        { type: 'object' }
      when :has_many
        {
          type: 'array',
          items: { type: 'object' }
        }
      end
    end

    def build_virtual_property(name, options)
      {
        type: options[:type].to_s.downcase,
        description: options[:description]
      }.compact
    end

    def columns
      model.columns.reject { |c| EasyTalk.configuration.excluded_columns.include?(c.name.to_sym) }
    end

    def column_type_to_json_type(type)
      case type
      when :string, :text then 'string'
      when :integer, :bigint then 'integer'
      when :float, :decimal then 'number'
      when :boolean then 'boolean'
      when :date then 'string'
      when :datetime, :timestamp then 'string'
      else 'string'
      end
    end

    def column_format(column)
      case column.type
      when :date then 'date'
      when :datetime, :timestamp then 'date-time'
      end
    end

    def build_title
      schema_enhancements[:title] || model.name.demodulize.humanize
    end

    def build_description
      schema_enhancements[:description]
    end

    def schema_enhancements
      @schema_enhancements ||= model.respond_to?(:schema_enhancements) ? model.schema_enhancements : {}
    end
  end
end
