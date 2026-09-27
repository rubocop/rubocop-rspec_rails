# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecRails::FileFixture do
  it 'registers an offense for a file under spec/fixtures' do
    expect_offense(<<~RUBY)
      Rails.root.join('spec', 'fixtures', 'something.pdf')
                 ^^^^ Prefer `file_fixture` for files under `spec/fixtures`.
    RUBY
  end

  it 'registers an offense when the fixture directory is one argument' do
    expect_offense(<<~RUBY)
      Rails.root.join('spec/fixtures', 'something.pdf')
                 ^^^^ Prefer `file_fixture` for files under `spec/fixtures`.
    RUBY
  end

  it 'does not register an offense for a fixture directory without a file' do
    expect_no_offenses(<<~RUBY)
      Rails.root.join('spec', 'fixtures')
    RUBY
  end

  it 'does not register an offense for another directory' do
    expect_no_offenses(<<~RUBY)
      Rails.root.join('spec', 'support', 'something.pdf')
      Rails.root.join('spec/fixtures_backup', 'something.pdf')
    RUBY
  end

  it 'does not register an offense for a different root or file_fixture' do
    expect_no_offenses(<<~RUBY)
      Other.root.join('spec', 'fixtures', 'something.pdf')
      file_fixture('something.pdf')
    RUBY
  end
end
