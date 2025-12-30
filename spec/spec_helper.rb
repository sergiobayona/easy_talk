# frozen_string_literal: true

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
