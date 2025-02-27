require 'spec_helper'

RSpec.describe EasyTalk::Builders::BooleanBuilder do
  describe '#build' do
    context 'with basic configuration' do
      it 'returns type boolean with no options' do
        builder = described_class.new(:active)
        expect(builder.build).to eq({ type: 'boolean' })
      end

      it 'includes title when provided' do
        builder = described_class.new(:active, title: 'Account Status')
        expect(builder.build).to eq({ type: 'boolean', title: 'Account Status' })
      end

      it 'includes description when provided' do
        builder = described_class.new(:active, description: 'Whether the account is active')
        expect(builder.build).to eq({ type: 'boolean', description: 'Whether the account is active' })
      end
    end

    context 'with boolean-specific constraints' do
      it 'includes enum constraint' do
        builder = described_class.new(:active, enum: [true, false])
        expect(builder.build).to eq({ type: 'boolean', enum: [true, false] })
      end

      it 'includes default value when true' do
        builder = described_class.new(:active, default: true)
        expect(builder.build).to eq({ type: 'boolean', default: true })
      end

      it 'includes default value when false' do
        builder = described_class.new(:active, default: false)
        expect(builder.build).to eq({ type: 'boolean', default: false })
      end

      it 'combines multiple constraints' do
        builder = described_class.new(:active,
                                      title: 'Account Status',
                                      description: 'Whether the account is active',
                                      default: true,
                                      enum: [true, false])

        expect(builder.build).to eq({
                                      type: 'boolean',
                                      title: 'Account Status',
                                      description: 'Whether the account is active',
                                      default: true,
                                      enum: [true, false]
                                    })
      end
    end

    context 'with invalid configurations' do
      it 'raises ArgumentError for unknown constraints' do
        expect do
          described_class.new(:active, invalid_option: 'value').build
        end.to raise_error(EasyTalk::UnknownOptionError, "Unknown option 'invalid_option' for property 'active'. Valid options are: title, description, optional, enum, default.")
      end

      it 'raises TypeError when enum contains non-boolean values' do
        expect do
          described_class.new(:active, enum: [true, 'false']).build
        end.to raise_error(EasyTalk::ConstraintError, "Error in property 'active': Constraint 'enum' expects Boolean (true or false), but received [true, \"false\"] (Array).")
      end

      it 'raises TypeError when default is not a boolean' do
        expect do
          described_class.new(:active, default: 'true').build
        end.to raise_error(EasyTalk::ConstraintError, "Error in property 'active': Constraint 'default' expects Boolean (true or false), but received \"true\" (String).")
      end

      it 'raises TypeError when enum is not an array' do
        expect do
          described_class.new(:active, enum: 'true,false').build
        end.to raise_error(EasyTalk::ConstraintError, "Error in property 'active': Constraint 'enum' expects Boolean (true or false), but received \"true,false\" (String).")
      end
    end

    context 'with nil values' do
      it 'excludes constraints with nil values' do
        builder = described_class.new(:active,
                                      default: nil,
                                      enum: nil,
                                      description: nil)
        expect(builder.build).to eq({ type: 'boolean' })
      end
    end

    context 'with optional flag' do
      it 'includes optional flag when true' do
        builder = described_class.new(:subscribed, optional: true)
        expect(builder.build).to eq({ type: 'boolean', optional: true })
      end

      it 'excludes optional flag when false' do
        builder = described_class.new(:subscribed, optional: false)
        expect(builder.build).to eq({ type: 'boolean', optional: false })
      end
    end

    context 'with edge cases' do
      it 'handles empty enum array' do
        builder = described_class.new(:active, enum: [])
        expect(builder.build).to eq({ type: 'boolean', enum: [] })
      end

      it 'handles single enum value' do
        builder = described_class.new(:active, enum: [true])
        expect(builder.build).to eq({ type: 'boolean', enum: [true] })
      end
    end
  end
end
