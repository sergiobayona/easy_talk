# frozen_string_literal: true

require_relative 'lib/esquema_base/version'

Gem::Specification.new do |spec|
  spec.name = 'esquema_base'
  spec.version = EsquemaBase::VERSION
  spec.authors = ['Sergio Bayona']
  spec.email = ['bayona.sergio@gmail.com']

  spec.summary = 'Generate json-schema from Ruby classes.'
  spec.description = 'Generate json-schema from plain Ruby classes.'
  spec.homepage = 'https://github.com/sergiobayona/esquema_base'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sergiobayona/esquema_base'
  spec.metadata['changelog_uri'] = 'https://github.com/sergiobayona/esquema_base/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ spec/ .git .github Gemfile])
    end
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 6.0'
  spec.add_dependency 'sorbet-runtime'
  spec.add_development_dependency 'pry-byebug', '>= 3.10.1'
  spec.add_development_dependency 'rake', '~> 13.1'
end
