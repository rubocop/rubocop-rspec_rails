# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecRails::BangPersistence do
  context 'with `save!` in `before`' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        before { post.save! }
      RUBY
    end
  end

  context 'with `update!` in `before`' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        before { post.update!(title: "new title") }
      RUBY
    end
  end

  context 'with `save` in `before`' do
    it 'registers offense' do
      expect_offense(<<~RUBY)
        before { post.save }
                 ^^^^^^^^^ Prefer bang versions of the persistence methods.
      RUBY

      expect_correction(<<~RUBY)
        before { post.save! }
      RUBY
    end
  end

  context 'with `update_attribute` in `before`' do
    it 'registers offense' do
      expect_offense(<<~RUBY)
        before do
          post.update_attribute(title: "new title")
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer bang versions of the persistence methods.
        end
      RUBY

      expect_correction(<<~RUBY)
        before do
          post.update_attribute!(title: "new title")
        end
      RUBY
    end
  end
end
