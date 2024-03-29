# frozen_string_literal: true

require 'pathname'
require 'yaml'

require 'rubocop'

require 'rubocop/rspec/language/node_pattern'

require 'rubocop/rspec/language'

require_relative 'rubocop/rspec_rails/version'

require 'rubocop/cop/rspec/base'
require_relative 'rubocop/cop/rspec_rails_cops'

project_root = File.join(__dir__, '..')
RuboCop::ConfigLoader.inject_defaults!(project_root)
