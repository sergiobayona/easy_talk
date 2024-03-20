# frozen_string_literal: true

require 'rake'
require 'rspec'
require 'rspec/mocks'
require 'easy_talk'
require 'pry-byebug'
require 'rspec/json_expectations'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
