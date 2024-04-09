# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecRails::SettingsOverwritten, :config do
  it 'registers an offense when using `Settings.foo = "bar"`' do
    expect_offense(<<~RUBY)
      Settings.foo = "bar"
      ^^^^^^^^^^^^^^^^^^^^ Do not overwrite Settings directly, use mock instead.
    RUBY
  end

  it 'registers an offense when using `Settings[:foo] = "bar"`' do
    expect_offense(<<~RUBY)
      Settings[:foo] = "bar"
      ^^^^^^^^^^^^^^^^^^^^^^ Do not overwrite Settings directly, use mock instead.
    RUBY
  end

  it 'registers an offense when using `Settings.foo[:bar] = "baz"`' do
    expect_offense(<<~RUBY)
      Settings.foo[:bar] = "baz"
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not overwrite Settings directly, use mock instead.
    RUBY
  end

  it 'registers an offense when using `Settings.foo += "bar"`' do
    expect_offense(<<~RUBY)
      Settings.foo += "bar"
      ^^^^^^^^^^^^^^^^^^^^^ Do not overwrite Settings directly, use mock instead.
    RUBY
  end

  it 'registers an offense when using `Settings.foo << "bar"`' do
    expect_offense(<<~RUBY)
      Settings.foo << "bar"
      ^^^^^^^^^^^^^^^^^^^^^ Do not overwrite Settings directly, use mock instead.
    RUBY
  end

  it 'does not register an offense when using mock' do
    expect_no_offenses(<<~RUBY)
      allow(Settings).to receive(:foo).and_return("bar")
    RUBY
  end
end
