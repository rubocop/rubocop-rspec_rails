# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecRails::HttpStatusNameConsistency, :config do
  context 'when Rack is older than 3.1' do
    let(:gem_versions) { { 'rack' => '3.0.0' } }

    it 'does nothing when using :unprocessable_entity' do
      expect_no_offenses(<<~RUBY)
        it { is_expected.to have_http_status :unprocessable_entity }
      RUBY
    end

    it 'does nothing when using :payload_too_large' do
      expect_no_offenses(<<~RUBY)
        it { is_expected.to have_http_status :payload_too_large }
      RUBY
    end
  end

  context 'when Rack is 3.1 or later' do
    let(:gem_versions) { { 'rack' => '3.1.0' } }

    it 'registers an offense when using :unprocessable_entity' do
      expect_offense(<<~RUBY)
        it { is_expected.to have_http_status :unprocessable_entity }
                                             ^^^^^^^^^^^^^^^^^^^^^ Prefer `:unprocessable_content` over `:unprocessable_entity`.
      RUBY

      expect_correction(<<~RUBY)
        it { is_expected.to have_http_status :unprocessable_content }
      RUBY
    end

    it 'does not register an offense when using :unprocessable_content' do
      expect_no_offenses(<<~RUBY)
        it { is_expected.to have_http_status :unprocessable_content }
      RUBY
    end

    it 'registers an offense when using :payload_too_large' do
      expect_offense(<<~RUBY)
        it { is_expected.to have_http_status :payload_too_large }
                                             ^^^^^^^^^^^^^^^^^^ Prefer `:content_too_large` over `:payload_too_large`.
      RUBY

      expect_correction(<<~RUBY)
        it { is_expected.to have_http_status :content_too_large }
      RUBY
    end

    it 'does not register an offense when using :content_too_large' do
      expect_no_offenses(<<~RUBY)
        it { is_expected.to have_http_status :content_too_large }
      RUBY
    end

    it 'does nothing when using numeric value' do
      expect_no_offenses(<<~RUBY)
        it { is_expected.to have_http_status 200 }
      RUBY
    end

    it 'does nothing when using string value' do
      expect_no_offenses(<<~RUBY)
        it { is_expected.to have_http_status "200" }
      RUBY
    end
  end
end
