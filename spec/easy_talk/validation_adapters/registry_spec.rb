# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ValidationAdapters::Registry do
  # Store original adapters and restore after each test
  let(:original_adapters) { described_class.adapters.dup }

  after do
    described_class.reset!
    # Re-register the default adapters
    described_class.register(:active_model, EasyTalk::ValidationAdapters::ActiveModelAdapter)
    described_class.register(:none, EasyTalk::ValidationAdapters::NoneAdapter)
  end

  describe '.register' do
    it 'registers an adapter by symbol name' do
      custom_adapter = Class.new(EasyTalk::ValidationAdapters::Base) do
        def apply_validations; end
      end

      described_class.register(:custom, custom_adapter)
      expect(described_class.adapters[:custom]).to eq(custom_adapter)
    end

    it 'registers an adapter with string name (converted to symbol)' do
      custom_adapter = Class.new(EasyTalk::ValidationAdapters::Base) do
        def apply_validations; end
      end

      described_class.register('string_name', custom_adapter)
      expect(described_class.adapters[:string_name]).to eq(custom_adapter)
    end

    it 'raises ArgumentError if adapter does not respond to build_validations' do
      bad_adapter = Class.new

      expect { described_class.register(:bad, bad_adapter) }
        .to raise_error(ArgumentError, 'Adapter must respond to .build_validations')
    end

    it 'allows overwriting existing adapters' do
      new_adapter = Class.new(EasyTalk::ValidationAdapters::Base) do
        def apply_validations; end
      end

      described_class.register(:active_model, new_adapter)
      expect(described_class.adapters[:active_model]).to eq(new_adapter)
    end
  end

  describe '.resolve' do
    it 'resolves :active_model to ActiveModelAdapter' do
      expect(described_class.resolve(:active_model))
        .to eq(EasyTalk::ValidationAdapters::ActiveModelAdapter)
    end

    it 'resolves :none to NoneAdapter' do
      expect(described_class.resolve(:none))
        .to eq(EasyTalk::ValidationAdapters::NoneAdapter)
    end

    it 'resolves nil to the default :active_model adapter' do
      expect(described_class.resolve(nil))
        .to eq(EasyTalk::ValidationAdapters::ActiveModelAdapter)
    end

    it 'passes through a Class directly' do
      custom_class = Class.new(EasyTalk::ValidationAdapters::Base) do
        def apply_validations; end
      end

      expect(described_class.resolve(custom_class)).to eq(custom_class)
    end

    it 'raises ArgumentError for unknown symbol' do
      expect { described_class.resolve(:unknown) }
        .to raise_error(ArgumentError, 'Unknown validation adapter: :unknown')
    end

    it 'raises ArgumentError for invalid type' do
      expect { described_class.resolve('string') }
        .to raise_error(ArgumentError, /Invalid adapter type/)
    end
  end

  describe '.registered?' do
    it 'returns true for registered adapters' do
      expect(described_class.registered?(:active_model)).to be true
      expect(described_class.registered?(:none)).to be true
    end

    it 'returns false for unregistered adapters' do
      expect(described_class.registered?(:unknown)).to be false
    end

    it 'accepts string names' do
      expect(described_class.registered?('active_model')).to be true
    end
  end

  describe '.reset!' do
    it 'clears all registered adapters' do
      described_class.reset!
      expect(described_class.adapters).to be_empty
    end
  end
end
