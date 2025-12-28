# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:spec)

RuboCop::RakeTask.new

YARD::Rake::YardocTask.new(:yard) do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['--readme', 'README.md', '--output-dir', 'docs/api']
end

namespace :docs do
  desc 'Generate YARD API documentation'
  task api: :yard

  desc 'Serve Jekyll documentation locally'
  task :serve do
    Dir.chdir('docs') do
      sh 'bundle install --quiet'
      sh 'bundle exec jekyll serve'
    end
  end

  desc 'Build all documentation (Jekyll + YARD)'
  task build: :yard do
    Dir.chdir('docs') do
      sh 'bundle install --quiet'
      sh 'bundle exec jekyll build'
    end
  end
end

task default: %i[spec rubocop]
