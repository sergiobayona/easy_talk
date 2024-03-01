require 'spec_helper'
require 'esquema_base/property_validation'

RSpec.describe EsquemaBase::PropertyValidation do
  context 'with valid types' do
    context "with 'null' type" do
      it 'does not raise an error' do
        expect { described_class.validate!('property_name', NilClass, {}) }.not_to raise_error
      end
    end

    context "with 'object' type" do
      it 'does not raise an error' do
        expect { described_class.validate!('property_name', Object, {}) }.not_to raise_error
      end
    end

    context "with 'array' type" do
      it 'does not raise an error' do
        expect { described_class.validate!('property_name', Array, {}) }.not_to raise_error
      end
    end

    context "with 'string' type" do
      it 'does not raise an error' do
        expect { described_class.validate!('property_name', String, {}) }.not_to raise_error
      end
    end

    context "with 'integer' type" do
      it 'does not raise an error' do
        expect { described_class.validate!('property_name', Integer, {}) }.not_to raise_error
      end
    end

    context "with 'number' type" do
      it 'does not raise an error' do
        expect { described_class.validate!('property_name', Float, {}) }.not_to raise_error
      end
    end

    context 'with boolean type' do
      it 'does not raise an error' do
        expect { described_class.validate!('property_name', T::Boolean, {}) }.not_to raise_error
      end
    end

    context 'with date type' do
      it 'does not raise an error' do
        expect { described_class.validate!('property_name', Date, {}) }.not_to raise_error
      end
    end

    context 'with datetime type' do
      it 'does not raise an error' do
        expect { described_class.validate!('property_name', DateTime, {}) }.not_to raise_error
      end
    end

    context 'with time type' do
      it 'does not raise an error' do
        expect { described_class.validate!('property_name', Time, {}) }.not_to raise_error
      end
    end

    context 'with multiple types' do
      it 'does not raise an error' do
        expect { described_class.validate!('property_name', [String, Integer], nil) }
          .not_to raise_error
      end

      it 'does not raise an error' do
        expect { described_class.validate!('property_name', [String, NilClass], {}) }
          .not_to raise_error
      end
    end

    context 'with invalid types' do
      context 'with boolean type' do
        it 'does not raise an error' do
          expect do
            described_class.validate!('property_name', Boolean,
                                      {})
          end.to raise_error(NameError, 'uninitialized constant Boolean')
        end
      end

      it 'raises an error' do
        expect { described_class.validate!('property_name', 'invalid_type', {}) }
          .to raise_error(EsquemaBase::UnsupportedTypeError,
                          "Unsupported type: 'invalid_type' for property: 'property_name'.")
      end

      it 'raises an error' do
        expect { described_class.validate!('property_name', 1, nil) }
          .to raise_error(EsquemaBase::UnsupportedTypeError, "Unsupported type: '1' for property: 'property_name'.")
      end

      it 'raises an error' do
        expect { described_class.validate!('property_name', [1], nil) }
          .to raise_error(EsquemaBase::UnsupportedTypeError, "Unsupported type: '1' for property: 'property_name'.")
      end

      it 'raises an error' do
        expect { described_class.validate!('property_name', '', nil) }
          .to raise_error(EsquemaBase::UnsupportedTypeError, "Unsupported type: '' for property: 'property_name'.")
      end

      it 'raises an error' do
        expect { described_class.validate!('property_name', true, nil) }
          .to raise_error(EsquemaBase::UnsupportedTypeError, "Unsupported type: 'true' for property: 'property_name'.")
      end

      it 'raises an error' do
        expect { described_class.validate!('property_name', false, nil) }
          .to raise_error(EsquemaBase::UnsupportedTypeError, "Unsupported type: 'false' for property: 'property_name'.")
      end

      it 'raises an error' do
        expect { described_class.validate!('property_name', {}, {}) }
          .to raise_error(EsquemaBase::UnsupportedTypeError,
                          "Unsupported type: '{}' for property: 'property_name'.")
      end

      context 'with argument types that lead to an empty array' do
        it 'raises an error' do
          expect { described_class.validate!('property_name', [], {}) }
            .to raise_error(EsquemaBase::UnsupportedTypeError, "Property: 'property_name' must have a valid type.")
        end

        it 'raises an error' do
          expect { described_class.validate!('property_name', nil, {}) }
            .to raise_error(EsquemaBase::UnsupportedTypeError, "Property: 'property_name' must have a valid type.")
        end
      end
    end
  end
end
