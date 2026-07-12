# frozen_string_literal: true

RSpec.describe 'cop lazy loading' do
  def run_script(source)
    Dir.mktmpdir do |dir|
      script = File.join(dir, 'script.rb')
      File.write(script, source)
      lib = File.expand_path('../../lib', __dir__)
      output = `#{RbConfig.ruby} -I #{lib} #{script} 2>&1`
      raise "script failed:\n#{output}" unless $CHILD_STATUS.success?

      output
    end
  end

  it 'registers every cop file in `lib/rubocop/cop/rspec_rails` exactly once' do
    cop_root = File.expand_path('../../lib/rubocop/cop', __dir__)
    files = Dir[File.join(cop_root, 'rspec_rails', '*.rb')].sort

    department = RuboCop::Cop::Registry.global.cops_for_department(:RSpecRails)
    registered = department.map do |cop|
      Object.const_source_location(cop.name).first
    end

    expect(registered.sort).to eq(files)
  end

  it 'registers all cops without loading their files' do
    output = run_script(<<~RUBY)
      require 'rubocop-rspec_rails'

      registry = RuboCop::Cop::Registry.global
      loaded = $LOADED_FEATURES.grep(%r{/rubocop/cop/rspec_rails/})

      puts "registered=\#{registry.names.grep(%r{\\ARSpecRails/}).size}"
      puts "loaded_cop_files=\#{loaded.size}"
    RUBY

    expect(output).to include('registered=9', 'loaded_cop_files=0')
  end

  it 'does not register a cop twice when its file is required directly' do
    output = run_script(<<~RUBY)
      require 'rubocop-rspec_rails'

      before = RuboCop::Cop::Registry.global.length
      require 'rubocop/cop/rspec_rails/http_status'
      after = RuboCop::Cop::Registry.global.length

      puts "stable=\#{before == after}"
      puts "class=\#{RuboCop::Cop::Registry.global.find_by_cop_name('RSpecRails/HttpStatus')}"
    RUBY

    expect(output).to include('stable=true', 'class=RuboCop::Cop::RSpecRails::HttpStatus')
  end
end
