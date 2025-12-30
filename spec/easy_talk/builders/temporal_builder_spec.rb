# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builders::TemporalBuilder do
  describe '#build' do
    context 'with basic configuration' do
      it 'returns type string with no format when format is nil' do
        builder = described_class.new(:timestamp)
        expect(builder.build).to eq({ type: 'string' })
      end

      it 'includes custom format when provided' do
        builder = described_class.new(:timestamp, {}, 'date')
        expect(builder.build).to eq({ type: 'string', format: 'date' })
      end
    end

    context 'with inherited string constraints' do
      it 'includes title when provided' do
        builder = described_class.new(:timestamp, { title: 'Event Time' }, 'date-time')
        expect(builder.build).to eq({ type: 'string', title: 'Event Time', format: 'date-time' })
      end

      it 'includes description when provided' do
        builder = described_class.new(:timestamp, { description: 'When the event occurred' }, 'date')
        expect(builder.build).to eq({ type: 'string', description: 'When the event occurred', format: 'date' })
      end

      it 'includes min_length constraint' do
        builder = described_class.new(:timestamp, { min_length: 10 }, 'date')
        expect(builder.build).to eq({ type: 'string', minLength: 10, format: 'date' })
      end

      it 'includes max_length constraint' do
        builder = described_class.new(:timestamp, { max_length: 25 }, 'date-time')
        expect(builder.build).to eq({ type: 'string', maxLength: 25, format: 'date-time' })
      end
    end

    context 'with nil format' do
      it 'does not include format in schema' do
        builder = described_class.new(:timestamp, {}, nil)
        expect(builder.build).to eq({ type: 'string' })
        expect(builder.build).not_to have_key(:format)
      end
    end
  end
end

RSpec.describe EasyTalk::Builders::TemporalBuilder::DateBuilder do
  describe '#build' do
    context 'with basic configuration' do
      it 'returns type string with date format' do
        builder = described_class.new(:birth_date)
        expect(builder.build).to eq({ type: 'string', format: 'date' })
      end
    end

    context 'with string constraints' do
      it 'includes title when provided' do
        builder = described_class.new(:birth_date, title: 'Birth Date')
        expect(builder.build).to eq({ type: 'string', title: 'Birth Date', format: 'date' })
      end

      it 'includes description when provided' do
        builder = described_class.new(:birth_date, description: 'Date of birth')
        expect(builder.build).to eq({ type: 'string', description: 'Date of birth', format: 'date' })
      end

      it 'includes optional flag when true' do
        builder = described_class.new(:birth_date, optional: true)
        expect(builder.build).to eq({ type: 'string', optional: true, format: 'date' })
      end

      it 'includes min_length constraint' do
        builder = described_class.new(:birth_date, min_length: 10)
        expect(builder.build).to eq({ type: 'string', minLength: 10, format: 'date' })
      end

      it 'includes max_length constraint' do
        builder = described_class.new(:birth_date, max_length: 10)
        expect(builder.build).to eq({ type: 'string', maxLength: 10, format: 'date' })
      end

      it 'includes pattern constraint' do
        builder = described_class.new(:birth_date, pattern: '\\d{4}-\\d{2}-\\d{2}')
        expect(builder.build[:pattern]).to eq('\\d{4}-\\d{2}-\\d{2}')
      end
    end

    context 'with invalid configurations' do
      it 'raises error for unknown options' do
        expect do
          described_class.new(:birth_date, invalid_option: 'value').build
        end.to raise_error(EasyTalk::UnknownOptionError)
      end

      it 'raises error when min_length is not an integer' do
        expect do
          described_class.new(:birth_date, min_length: '10').build
        end.to raise_error(EasyTalk::ConstraintError)
      end
    end

    context 'with multiple constraints' do
      it 'combines multiple constraints with format' do
        builder = described_class.new(:birth_date,
                                      title: 'Birth Date',
                                      description: 'Date of birth in ISO format',
                                      min_length: 10,
                                      max_length: 10)
        expect(builder.build).to eq({
                                      type: 'string',
                                      title: 'Birth Date',
                                      description: 'Date of birth in ISO format',
                                      minLength: 10,
                                      maxLength: 10,
                                      format: 'date'
                                    })
      end
    end
  end

  describe '.collection_type?' do
    it 'returns false' do
      expect(described_class.collection_type?).to be false
    end
  end
end

RSpec.describe EasyTalk::Builders::TemporalBuilder::DatetimeBuilder do
  describe '#build' do
    context 'with basic configuration' do
      it 'returns type string with date-time format' do
        builder = described_class.new(:created_at)
        expect(builder.build).to eq({ type: 'string', format: 'date-time' })
      end
    end

    context 'with string constraints' do
      it 'includes title when provided' do
        builder = described_class.new(:created_at, title: 'Created At')
        expect(builder.build).to eq({ type: 'string', title: 'Created At', format: 'date-time' })
      end

      it 'includes description when provided' do
        builder = described_class.new(:created_at, description: 'Timestamp when record was created')
        expect(builder.build).to eq({ type: 'string', description: 'Timestamp when record was created', format: 'date-time' })
      end

      it 'includes optional flag when true' do
        builder = described_class.new(:updated_at, optional: true)
        expect(builder.build).to eq({ type: 'string', optional: true, format: 'date-time' })
      end
    end

    context 'with invalid configurations' do
      it 'raises error for unknown options' do
        expect do
          described_class.new(:created_at, unknown: 'value').build
        end.to raise_error(EasyTalk::UnknownOptionError)
      end
    end
  end

  describe '.collection_type?' do
    it 'returns false' do
      expect(described_class.collection_type?).to be false
    end
  end
end

RSpec.describe EasyTalk::Builders::TemporalBuilder::TimeBuilder do
  describe '#build' do
    context 'with basic configuration' do
      it 'returns type string with time format' do
        builder = described_class.new(:start_time)
        expect(builder.build).to eq({ type: 'string', format: 'time' })
      end
    end

    context 'with string constraints' do
      it 'includes title when provided' do
        builder = described_class.new(:start_time, title: 'Start Time')
        expect(builder.build).to eq({ type: 'string', title: 'Start Time', format: 'time' })
      end

      it 'includes description when provided' do
        builder = described_class.new(:start_time, description: 'Time the event starts')
        expect(builder.build).to eq({ type: 'string', description: 'Time the event starts', format: 'time' })
      end

      it 'includes optional flag when true' do
        builder = described_class.new(:end_time, optional: true)
        expect(builder.build).to eq({ type: 'string', optional: true, format: 'time' })
      end

      it 'includes min_length constraint' do
        builder = described_class.new(:start_time, min_length: 5)
        expect(builder.build).to eq({ type: 'string', minLength: 5, format: 'time' })
      end

      it 'includes max_length constraint' do
        builder = described_class.new(:start_time, max_length: 12)
        expect(builder.build).to eq({ type: 'string', maxLength: 12, format: 'time' })
      end
    end

    context 'with invalid configurations' do
      it 'raises error for unknown options' do
        expect do
          described_class.new(:start_time, invalid: 'option').build
        end.to raise_error(EasyTalk::UnknownOptionError)
      end
    end

    context 'with multiple constraints' do
      it 'combines multiple constraints with format' do
        builder = described_class.new(:start_time,
                                      title: 'Start Time',
                                      description: 'Event start time')
        expect(builder.build).to eq({
                                      type: 'string',
                                      title: 'Start Time',
                                      description: 'Event start time',
                                      format: 'time'
                                    })
      end
    end
  end

  describe '.collection_type?' do
    it 'returns false' do
      expect(described_class.collection_type?).to be false
    end
  end
end
