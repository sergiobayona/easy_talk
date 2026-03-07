# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EasyTalk::Model define_schema called twice on the same class' do
  # When define_schema is called a second time on the same class object, three
  # pieces of memoized state are NOT reset:
  #
  #   @schema                       — cached via ||=, permanently returns old schema
  #   @schema_level_validations_applied — stays true, so schema-level constraints
  #                                    from the new definition are silently dropped
  #   @validated_properties         — stays as the old Set, so properties with names
  #                                    carried from the first definition skip validation
  #                                    setup for their new constraints
  #
  # This is triggered any time user-land code redefines a model, which happens in:
  #   - shared RSpec examples that reuse a named class
  #   - modules that call define_schema inside `included`
  #   - reopened class bodies (rare but valid Ruby)

  let(:model_class) do
    klass = Class.new do
      include EasyTalk::Model

      def self.name = 'DynamicModel'
    end
    klass
  end

  describe 'json_schema reflects the second definition' do
    it 'returns the schema from the most recent define_schema call' do
      model_class.define_schema do
        property :first_name, String
      end

      model_class.define_schema do
        property :email, String
      end

      schema = model_class.json_schema
      props = schema['properties']

      expect(props).to have_key('email'),
                       'json_schema still shows first_name from the stale first definition'
      expect(props).not_to have_key('first_name'),
                           'first_name should be gone after the second define_schema'
    end
  end

  describe 'validations reflect the second definition' do
    it 'enforces constraints from the second define_schema, not the first' do
      # First definition: :code must be exactly 3 characters
      model_class.define_schema do
        property :code, String, min_length: 3, max_length: 3
      end

      # Second definition: :code is unconstrained
      model_class.define_schema do
        property :code, String
      end

      instance = model_class.new(code: 'X') # only 1 char — would fail first def's min_length
      expect(instance.valid?).to be(true),
                                 'Validation from the stale first definition is still active'
    end

    it 'applies presence validation for required properties in the second definition' do
      model_class.define_schema do
        property :old_field, String
      end

      model_class.define_schema do
        property :new_required, String
      end

      instance = model_class.new
      instance.valid?

      expect(instance.errors[:new_required]).to include("can't be blank"),
                                                'Presence validation was not applied for new_required — ' \
                                                '@validated_properties retained the old Set'
    end
  end

  describe 'schema_level validations reflect the second definition' do
    it 'applies dependent_required from the second define_schema' do
      model_class.define_schema do
        property :a, String
      end

      model_class.define_schema do
        property :a, String
        property :b, String
        dependent_required a: [:b]
      end

      # a is present but b is missing — should fail the dependent_required rule
      instance = model_class.new(a: 'hello')
      instance.valid?

      expect(instance.errors).not_to be_empty,
                                     'dependent_required from the second define_schema was silently ' \
                                     'ignored because @schema_level_validations_applied was already true'
    end
  end
end
