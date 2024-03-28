# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'rubocop/rspec_rails/version'

Gem::Specification.new do |spec|
  spec.name = 'rubocop-rspec_rails'
  spec.summary = 'Code style checking for RSpec Rails files'
  spec.description = <<~DESCRIPTION
    Code style checking for RSpec Rails files.
    A plugin for the RuboCop code style enforcing & linting tool.
  DESCRIPTION
  spec.homepage = 'https://github.com/rubocop/rubocop-rspec_rails'
  spec.authors = [
    'Benjamin Quorning', 'Phil Pirozhkov', 'Maxim Krizhanovsky', 'Yudai Takada'
  ]
  spec.licenses = ['MIT']

  spec.version = RuboCop::RSpecRails::Version::STRING
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.7.0'

  spec.require_paths = ['lib']
  spec.files = Dir[
    'lib/**/*',
    'config/*',
    '*.md'
  ]
  spec.extra_rdoc_files = ['MIT-LICENSE.md', 'README.md']

  spec.metadata = {
    'changelog_uri' => 'https://github.com/rubocop/rubocop-rspec_rails/blob/master/CHANGELOG.md',
    'documentation_uri' => 'https://docs.rubocop.org/rubocop-rspec_rails/',
    'rubygems_mfa_required' => 'true'
  }

  spec.add_runtime_dependency 'rubocop', '~> 1.40'
end
