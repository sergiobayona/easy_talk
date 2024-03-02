require 'spec_helper'
require 'esquema_base/property_validation'

RSpec.describe EsquemaBase::PropertyValidation, 'Constraint key validation' do
  context 'with valid values' do
    it 'does not raise an error' do
      expect { described_class.validate_constraints!('property_name', String, { format: 'email' }) }.not_to raise_error
    end

    it 'does not raise an error' do
      expect do
        described_class.validate_constraints!('property_name', String, { pattern: '^[a-zA-Z]+$' })
      end.not_to raise_error
    end

    it 'does not raise an error' do
      expect { described_class.validate_constraints!('property_name', String, { title: 'title' }) }.not_to raise_error
    end

    it 'does not raise an error' do
      expect do
        described_class.validate_constraints!('property_name', String, { description: 'description' })
      end.not_to raise_error
    end

    context 'with unsupported constraints' do
      it 'raises an error' do
        expect { described_class.validate_constraints!('property_name', String, { format: 1 }) }
          .to raise_error(ArgumentError,
                          "Value of 'format' in 'property_name' must be a string.")
      end
    end
  end
end
