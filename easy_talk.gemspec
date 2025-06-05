# frozen_string_literal: true

require_relative 'lib/easy_talk/version'

Gem::Specification.new do |spec|
  spec.name = 'easy_talk'
  spec.version = EasyTalk::VERSION
  spec.authors = ['Sergio Bayona']
  spec.email = ['bayona.sergio@gmail.com']

  spec.summary = 'Generate json-schema from Ruby classes.'
  spec.description = 'Generate json-schema from plain Ruby classes.'
  spec.homepage = 'https://github.com/sergiobayona/easy_talk'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sergiobayona/easy_talk'
  spec.metadata['changelog_uri'] = 'https://github.com/sergiobayona/easy_talk/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ spec/ .git .github Gemfile])
    end
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'activemodel', '>= 7.0'
  spec.add_dependency 'activesupport', '>= 7.0'
  spec.add_dependency 'sorbet-runtime', '>= 0.5'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
