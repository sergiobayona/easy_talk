require 'spec_helper'
require 'esquema_base/options_normalizer'

RSpec.describe EsquemaBase::OptionsNormalizer do
  describe '.normalize' do
    context 'when given valid options' do
      let(:options) { { type: 'value1', title: 'value2', additional_properties: {} } }

      it 'returns a normalized hash' do
        normalized_options = described_class.normalize(options)

        expect(normalized_options).to be_a(Hash)
        expect(normalized_options).to eq({ type: 'value1', title: 'value2', additionalProperties: {} })
      end
    end

    context 'when given unsupported options' do
      let(:options) { { unsupported_key: 'value' } }

      it 'raises an UnsupportedConstraintError' do
        expect do
          described_class.normalize(options)
        end.to raise_error(EsquemaBase::UnsupportedConstraintError,
                           'Unsupported constraint: unsupported_key')
      end
    end
  end
end
