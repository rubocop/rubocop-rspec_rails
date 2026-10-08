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

  it 'registers an offense when the whole path is one argument' do
    expect_offense(<<~RUBY)
      Rails.root.join('spec/fixtures/something.pdf')
                 ^^^^ Prefer `file_fixture` for files under `spec/fixtures`.
    RUBY
  end

  it 'registers an offense for a subdirectory of spec/fixtures' do
    expect_offense(<<~RUBY)
      Rails.root.join('spec/fixtures/files', 'something.pdf')
                 ^^^^ Prefer `file_fixture` for files under `spec/fixtures`.
      Rails.root.join('spec', 'fixtures/files', 'something.pdf')
                 ^^^^ Prefer `file_fixture` for files under `spec/fixtures`.
      Rails.root.join('spec/fixtures/files/something.pdf')
                 ^^^^ Prefer `file_fixture` for files under `spec/fixtures`.
    RUBY
  end

  it 'registers an offense for a variable file name under spec/fixtures' do
    expect_offense(<<~RUBY)
      Rails.root.join('spec', 'fixtures', name)
                 ^^^^ Prefer `file_fixture` for files under `spec/fixtures`.
      Rails.root.join('spec/fixtures', name)
                 ^^^^ Prefer `file_fixture` for files under `spec/fixtures`.
    RUBY
  end

  it 'registers an offense for an interpolated path under spec/fixtures' do
    expect_offense(<<~'RUBY')
      Rails.root.join("spec/fixtures/#{name}")
                 ^^^^ Prefer `file_fixture` for files under `spec/fixtures`.
      Rails.root.join('spec', "fixtures/#{name}")
                 ^^^^ Prefer `file_fixture` for files under `spec/fixtures`.
      Rails.root.join("spec/fixtures/files/#{name}.pdf")
                 ^^^^ Prefer `file_fixture` for files under `spec/fixtures`.
      Rails.root.join("spec/fixtures/#{dir}/#{name}", 'other.pdf')
                 ^^^^ Prefer `file_fixture` for files under `spec/fixtures`.
    RUBY
  end

  it 'does not register an offense for an interpolated path ' \
     'outside spec/fixtures' do
    expect_no_offenses(<<~'RUBY')
      Rails.root.join("spec/support/#{name}")
      Rails.root.join("spec/fixtures_backup/#{name}")
      Rails.root.join("#{dir}/spec/fixtures/something.pdf")
    RUBY
  end

  it 'does not register an offense for a fixture directory without a file' do
    expect_no_offenses(<<~RUBY)
      Rails.root.join('spec', 'fixtures')
      Rails.root.join('spec/fixtures')
      Rails.root.join('spec/fixtures/')
    RUBY
  end

  it 'does not register an offense for another directory' do
    expect_no_offenses(<<~RUBY)
      Rails.root.join('spec', 'support', 'something.pdf')
      Rails.root.join('spec/fixtures_backup', 'something.pdf')
      Rails.root.join('spec', dir, 'something.pdf')
    RUBY
  end

  it 'does not register an offense when configuring `file_fixture_path`' do
    expect_no_offenses(<<~RUBY)
      config.file_fixture_path = Rails.root.join('spec/fixtures/files')
      self.file_fixture_path = Rails.root.join('spec', 'fixtures', 'files')
    RUBY
  end

  it 'does not register an offense for a different root or file_fixture' do
    expect_no_offenses(<<~RUBY)
      Other.root.join('spec', 'fixtures', 'something.pdf')
      file_fixture('something.pdf')
    RUBY
  end
end
