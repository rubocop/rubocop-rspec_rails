# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecRails::PendingOnlyExampleGroup do
  context 'with pending only example group' do
    it 'registers offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Post do
        ^^^^^^^^^^^^^^^^^^^^^^ Remove pending-only test files.
          pending "add some examples to (or delete) \#{__FILE__}"
        end
      RUBY
    end
  end

  context 'with some examples' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Post do
          pending "TODO"

          it 'does something' do
            expect(foo).to eq(1)
          end
        end
      RUBY
    end
  end
end
