# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'schema cache corruption via merge!' do
  # This spec proves that using a nested EasyTalk model as a property type
  # with constraints (e.g., title:, description:) permanently mutates the
  # nested model's cached schema via merge! in Property#build (line 117).

  let(:address) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'Address'

      define_schema do
        property :street, String
        property :city, String
      end
    end
  end

  it 'does not corrupt the nested model schema when used with constraints' do
    addr = address

    # Capture the original schema before any parent model references it
    original_schema = addr.schema.dup

    # First parent references Address with a custom title
    parent_a = Class.new do
      include EasyTalk::Model

      def self.name = 'ParentA'

      define_schema do
        property :home, addr, title: 'Home Address'
      end
    end

    # Force ParentA's schema to build — this triggers Property#build
    # which calls addr.schema.merge!(title: 'Home Address')
    parent_a.json_schema

    # Address schema should be unchanged
    expect(addr.schema).to eq(original_schema),
                           "Address.schema was mutated by ParentA. " \
                           "Expected no :title key, but got: #{addr.schema.inspect}"
  end

  it 'produces correct schemas for both parent models independently' do
    addr = address

    parent_a = Class.new do
      include EasyTalk::Model

      def self.name = 'ParentA'

      define_schema do
        property :home, addr, title: 'Home Address'
      end
    end

    parent_b = Class.new do
      include EasyTalk::Model

      def self.name = 'ParentB'

      define_schema do
        property :work, addr, title: 'Work Address'
      end
    end

    # Build both schemas — the second build should NOT overwrite the first
    home_schema = parent_a.json_schema['properties']['home']
    work_schema = parent_b.json_schema['properties']['work']

    expect(home_schema['title']).to eq('Home Address'),
                                    "ParentA's :home property should have title 'Home Address', got '#{home_schema['title']}'"
    expect(work_schema['title']).to eq('Work Address'),
                                    "ParentB's :work property should have title 'Work Address', got '#{work_schema['title']}'"
  end

  it 'does not leak constraints between unrelated models using the same nested type' do
    addr = address

    # ParentA adds a description constraint
    parent_a = Class.new do
      include EasyTalk::Model

      def self.name = 'ParentA'

      define_schema do
        property :location, addr, description: 'A location'
      end
    end

    parent_a.json_schema

    # ParentB uses the same nested model with NO description
    parent_b = Class.new do
      include EasyTalk::Model

      def self.name = 'ParentB'

      define_schema do
        property :place, addr
      end
    end

    place_schema = parent_b.json_schema['properties']['place']

    expect(place_schema).not_to have_key('description'),
                                "ParentA's description leaked into ParentB's schema: #{place_schema.inspect}"
  end
end
