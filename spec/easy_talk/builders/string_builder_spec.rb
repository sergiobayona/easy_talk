# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builders::StringBuilder do
  describe '#build' do
    context 'with basic configuration' do
      it 'returns type string with no options' do
        builder = described_class.new(:name)
        expect(builder.build).to eq({ type: 'string' })
      end

      it 'includes title when provided' do
        builder = described_class.new(:name, title: 'Full Name')
        expect(builder.build).to eq({ type: 'string', title: 'Full Name' })
      end

      it 'includes description when provided' do
        builder = described_class.new(:name, description: 'Person\'s full name')
        expect(builder.build).to eq({ type: 'string', description: 'Person\'s full name' })
      end
    end

    context 'with string-specific validations' do
      it 'includes format constraint' do
        builder = described_class.new(:email, format: 'email')
        expect(builder.build).to eq({ type: 'string', format: 'email' })
      end

      it 'includes pattern constraint' do
        builder = described_class.new(:zip, pattern: '^\d{5}(-\d{4})?$')
        expect(builder.build).to eq({ type: 'string', pattern: '^\d{5}(-\d{4})?$' })
      end

      it 'includes minLength constraint' do
        builder = described_class.new(:password, min_length: 8)
        expect(builder.build).to eq({ type: 'string', minLength: 8 })
      end

      it 'includes maxLength constraint' do
        builder = described_class.new(:username, max_length: 20)
        expect(builder.build).to eq({ type: 'string', maxLength: 20 })
      end

      it 'includes enum constraint' do
        builder = described_class.new(:status, enum: %w[active inactive pending])
        expect(builder.build).to eq({ type: 'string', enum: %w[active inactive pending] })
      end

      it 'includes const constraint' do
        builder = described_class.new(:type, const: 'user')
        expect(builder.build).to eq({ type: 'string', const: 'user' })
      end

      it 'includes default value' do
        builder = described_class.new(:role, default: 'member')
        expect(builder.build).to eq({ type: 'string', default: 'member' })
      end

      it 'combines multiple constraints' do
        builder = described_class.new(:password,
                                      min_length: 8,
                                      max_length: 32,
                                      pattern: '^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$',
                                      description: 'Must contain letters and numbers')

        expect(builder.build).to eq({
                                      type: 'string',
                                      minLength: 8,
                                      maxLength: 32,
                                      pattern: '^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$',
                                      description: 'Must contain letters and numbers'
                                    })
      end
    end

    context 'with invalid configurations' do
      it 'raises ArgumentError for unknown constraints' do
        expect do
          described_class.new(:name, invalid_option: 'value').build
        end.to raise_error(EasyTalk::UnknownOptionError, "Unknown option 'invalid_option' for property 'name'. Valid options are: title, description, optional, format, pattern, min_length, max_length, enum, const, default.")
      end

      it 'raises TypeError when format is not a string' do
        expect do
          described_class.new(:email, format: 123).build
        end.to raise_error(EasyTalk::ConstraintError, "Error in property 'email': Constraint 'format' expects String, but received 123 (Integer).")
      end

      it 'raises TypeError when pattern is not a string' do
        expect do
          described_class.new(:zip, pattern: 123).build
        end.to raise_error(EasyTalk::ConstraintError, "Error in property 'zip': Constraint 'pattern' expects String, but received 123 (Integer).")
      end

      it 'raises TypeError when minLength is not an integer' do
        expect do
          described_class.new(:name, min_length: '8').build
        end.to raise_error(EasyTalk::ConstraintError, "Error in property 'name': Constraint 'min_length' expects Integer, but received \"8\" (String).")
      end

      it 'raises TypeError when maxLength is not an integer' do
        expect do
          described_class.new(:name, max_length: '20').build
        end.to raise_error(EasyTalk::ConstraintError, "Error in property 'name': Constraint 'max_length' expects Integer, but received \"20\" (String).")
      end

      it 'raises TypeError when enum contains non-string values' do
        expect do
          described_class.new(:status, enum: ['active', 123, 'pending']).build
        end.to raise_error(EasyTalk::ConstraintError, "Error in property 'status': Constraint 'enum' at index 1 expects String, but received 123 (Integer).")
      end

      it 'raises TypeError when const is not a string' do
        expect do
          described_class.new(:hair_color, const: 123).build
        end.to raise_error(EasyTalk::ConstraintError, "Error in property 'hair_color': Constraint 'const' expects String, but received 123 (Integer).")
      end
    end

    context 'with nil values' do
      it 'excludes constraints with nil values' do
        builder = described_class.new(:name,
                                      min_length: nil,
                                      max_length: nil,
                                      pattern: nil,
                                      format: nil)
        expect(builder.build).to eq({ type: 'string' })
      end
    end

    context 'with empty values on lenght validators' do
      it 'raises a type error' do
        builder = described_class.new(:name, min_length: '')
        expect do
          builder.build
        end.to raise_error(EasyTalk::ConstraintError, "Error in property 'name': Constraint 'min_length' expects Integer, but received \"\" (String).")
      end

      it 'raises a type error' do
        builder = described_class.new(:name, max_length: '')
        expect do
          builder.build
        end.to raise_error(EasyTalk::ConstraintError, "Error in property 'name': Constraint 'max_length' expects Integer, but received \"\" (String).")
      end
    end

    context 'with empty values on pattern' do
      it 'returns empty pattern' do
        # this is invalid in json schema but there is not practical way to validate non empty strings.
        builder = described_class.new(:name, pattern: '')
        expect(builder.build).to eq({ type: 'string', pattern: '' })
      end
    end

    context 'with optional flag' do
      it 'includes optional flag when true' do
        builder = described_class.new(:middle_name, optional: true)
        expect(builder.build).to eq({ type: 'string', optional: true })
      end

      it 'includes optional flag when false' do
        builder = described_class.new(:name, optional: false)
        expect(builder.build).to eq({ type: 'string', optional: false })
      end
    end
  end
end
