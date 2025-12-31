# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'

  add_group 'Builders', 'lib/easy_talk/builders'
  add_group 'Core', 'lib/easy_talk'

  enable_coverage :branch

  if ENV['CI']
    formatter SimpleCov::Formatter::CoberturaFormatter
  else
    formatter SimpleCov::Formatter::HTMLFormatter
  end
end

require 'rake'
require 'rspec'
require 'rspec/mocks'
require 'easy_talk'
require 'rspec/json_expectations'

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Exclude JSON Schema compliance tests by default
  config.filter_run_excluding :json_schema_compliance
end
