# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecRails::AvoidSetupHook do
  it 'registers an offense for `setup`' do
    expect_offense(<<~RUBY)
      RSpec.describe Foo do
        setup do
        ^^^^^^^^ Use `before` instead of `setup`.
          allow(foo).to receive(:bar)
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      RSpec.describe Foo do
        before do
          allow(foo).to receive(:bar)
        end
      end
    RUBY
  end

  it 'registers an offense for numbered block `setup`' do
    expect_offense(<<~RUBY)
      RSpec.describe Foo do
        setup { _1 }
        ^^^^^^^^^^^^ Use `before` instead of `setup`.
      end
    RUBY

    expect_correction(<<~RUBY)
      RSpec.describe Foo do
        before { _1 }
      end
    RUBY
  end

  it 'does not register an offense for `before`' do
    expect_no_offenses(<<~RUBY)
      RSpec.describe Foo do
        before do
          allow(foo).to receive(:bar)
        end
      end
    RUBY
  end

  it 'does not register an offense for `setup` outside an example group' do
    expect_no_offenses(<<~RUBY)
      SomeDSL.configure do
        setup do
          prepare
        end
      end
    RUBY
  end

  it 'does not register an offense for an unrelated `setup` call' do
    expect_no_offenses(<<~RUBY)
      RSpec.describe Foo do
        navigation.setup do
          direction 'to infinity!'
        end
      end
    RUBY
  end
end
