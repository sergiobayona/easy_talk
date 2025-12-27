# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builders::Registry do
  # Create a mock builder class for testing
  let(:mock_builder_class) do
    Class.new do
      def self.name = 'MockBuilder'

      def initialize(*args)
        @args = args
      end

      def build
        { type: 'mock' }
      end
    end
  end

  let(:mock_collection_builder_class) do
    Class.new do
      extend EasyTalk::Builders::CollectionHelpers

      def self.name = 'MockCollectionBuilder'

      def initialize(name, type, constraints)
        @name = name
        @type = type
        @constraints = constraints
      end

      def build
        { type: 'array', items: { type: 'mock' } }
      end
    end
  end

  # Custom type class for testing
  let(:custom_type_class) do
    Class.new do
      def self.name = 'CustomType'
    end
  end

  after do
    # Reset the registry after each test
    described_class.reset!
    # Re-register built-in types that were registered in easy_talk.rb
    # This is needed because reset! clears everything
  end

  describe '.register' do
    it 'registers a builder with a Class type key' do
      described_class.register(custom_type_class, mock_builder_class)
      expect(described_class.registered?('CustomType')).to be true
    end

    it 'registers a builder with a String type key' do
      described_class.register('CustomString', mock_builder_class)
      expect(described_class.registered?('CustomString')).to be true
    end

    it 'registers a builder with a Symbol type key' do
      described_class.register(:custom_symbol, mock_builder_class)
      expect(described_class.registered?('custom_symbol')).to be true
    end

    it 'registers a collection type builder' do
      described_class.register(custom_type_class, mock_collection_builder_class, collection: true)

      builder_class, is_collection = described_class.resolve(custom_type_class)
      expect(builder_class).to eq(mock_collection_builder_class)
      expect(is_collection).to be true
    end

    it 'raises ArgumentError if builder does not respond to .new' do
      invalid_builder = Module.new # Modules don't respond to .new

      expect do
        described_class.register(custom_type_class, invalid_builder)
      end.to raise_error(ArgumentError, /Builder must respond to .new/)
    end
  end

  describe '.resolve' do
    before do
      described_class.register(custom_type_class, mock_builder_class)
    end

    it 'resolves a builder by type class' do
      builder_class, is_collection = described_class.resolve(custom_type_class)
      expect(builder_class).to eq(mock_builder_class)
      expect(is_collection).to be false
    end

    it 'resolves a builder by instance with class name' do
      # For Sorbet types, the type's class.name is used
      type_instance = custom_type_class.new
      # This won't match because type_instance.class.name is not registered
      # but if we register with the instance's class name it will work
      described_class.register(type_instance.class.name, mock_builder_class)
      builder_class, = described_class.resolve(type_instance)
      expect(builder_class).to eq(mock_builder_class)
    end

    it 'returns nil for unregistered types' do
      unregistered_class = Class.new { def self.name = 'UnregisteredType' }
      result = described_class.resolve(unregistered_class)
      expect(result).to be_nil
    end

    context 'with collection type' do
      before do
        described_class.register('CollectionType', mock_collection_builder_class, collection: true)
      end

      it 'returns is_collection as true' do
        collection_class = Class.new { def self.name = 'CollectionType' }
        builder_class, is_collection = described_class.resolve(collection_class)
        expect(builder_class).to eq(mock_collection_builder_class)
        expect(is_collection).to be true
      end
    end
  end

  describe '.registered?' do
    it 'returns true for registered types' do
      described_class.register('TestType', mock_builder_class)
      expect(described_class.registered?('TestType')).to be true
    end

    it 'returns false for unregistered types' do
      expect(described_class.registered?('NonExistentType')).to be false
    end

    it 'accepts Class as type key' do
      described_class.register(custom_type_class, mock_builder_class)
      expect(described_class.registered?(custom_type_class)).to be true
    end

    it 'accepts Symbol as type key' do
      described_class.register(:symbol_type, mock_builder_class)
      expect(described_class.registered?(:symbol_type)).to be true
    end
  end

  describe '.unregister' do
    before do
      described_class.register('TypeToRemove', mock_builder_class)
    end

    it 'removes a registered type' do
      expect(described_class.registered?('TypeToRemove')).to be true
      described_class.unregister('TypeToRemove')
      expect(described_class.registered?('TypeToRemove')).to be false
    end

    it 'returns the removed registration' do
      result = described_class.unregister('TypeToRemove')
      expect(result[:builder]).to eq(mock_builder_class)
    end

    it 'returns nil for unregistered types' do
      result = described_class.unregister('NonExistent')
      expect(result).to be_nil
    end
  end

  describe '.registered_types' do
    before do
      described_class.register('TypeA', mock_builder_class)
      described_class.register('TypeB', mock_builder_class)
    end

    after do
      described_class.unregister('TypeA')
      described_class.unregister('TypeB')
    end

    it 'returns all registered type keys including custom types' do
      types = described_class.registered_types
      expect(types).to include('TypeA', 'TypeB')
      # Also verify built-in types are present
      expect(types).to include('String', 'Integer')
    end
  end

  describe '.reset!' do
    before do
      described_class.register('TestType', mock_builder_class)
    end

    it 'clears all registrations' do
      expect(described_class.registered?('TestType')).to be true
      described_class.reset!
      expect(described_class.registered?('TestType')).to be false
    end
  end

  describe 'resolution priority' do
    let(:original_builder) do
      Class.new do
        def self.name = 'OriginalBuilder'
        def initialize(*); end
        def build = { type: 'original' }
      end
    end

    let(:override_builder) do
      Class.new do
        def self.name = 'OverrideBuilder'
        def initialize(*); end
        def build = { type: 'override' }
      end
    end

    it 'later registrations override earlier ones' do
      described_class.register('TestType', original_builder)
      described_class.register('TestType', override_builder)

      builder_class, = described_class.resolve(Class.new { def self.name = 'TestType' })
      expect(builder_class).to eq(override_builder)
    end
  end
end
