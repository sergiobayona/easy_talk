require 'spec_helper'

RSpec.describe 'nilable and optional properties' do
  context 'with default configuration' do
    before do
      EasyTalk.configure { |config| config.nilable_is_optional = false }
    end

    let(:user_class) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'User'
        end

        define_schema do
          property :name, String # Required, not nullable
          property :age, T.nilable(Integer) # Required, nullable
          property :email, String, optional: true # Optional, not nullable
          nullable_optional_property :bio, String # Optional and nullable
        end
      end
    end

    it 'correctly handles nullable vs optional properties' do
      schema = user_class.json_schema

      # name should be required, not nullable
      expect(schema['required']).to include('name')
      expect(schema['properties']['name']['type']).to eq('string')

      # age should be required, but nullable
      expect(schema['required']).to include('age')
      expect(schema['properties']['age']['type']).to eq(%w[integer null])

      # email should not be required, not nullable
      expect(schema['required']).not_to include('email')
      expect(schema['properties']['email']['type']).to eq('string')

      # bio should not be required, but nullable
      expect(schema['required']).not_to include('bio')
      expect(schema['properties']['bio']['type']).to eq(%w[string null])
    end
  end

  context 'with nilable_is_optional = true' do
    before do
      EasyTalk.configure { |config| config.nilable_is_optional = true }
    end

    after do
      EasyTalk.configure { |config| config.nilable_is_optional = false }
    end

    let(:user_class) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'User'
        end

        define_schema do
          property :name, String # Required, not nullable
          property :age, T.nilable(Integer) # Optional because of config, nullable
        end
      end
    end

    it 'treats nilable properties as optional' do
      schema = user_class.json_schema

      # name should be required, not nullable
      expect(schema['required']).to include('name')

      # age should NOT be required, but nullable
      expect(schema['required']).not_to include('age')
      expect(schema['properties']['age']['type']).to eq(%w[integer null])
    end
  end
end
