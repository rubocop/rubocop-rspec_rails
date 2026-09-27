# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecRails::Timecop, :config do
  shared_context 'with Rails 5.1' do
    let(:rails_version) { 5.1 }
  end

  shared_context 'with Rails 5.2' do
    let(:rails_version) { 5.2 }
  end

  shared_context 'with Rails 6.0' do
    let(:rails_version) { 6.0 }
  end

  shared_context 'with Rails 6.1' do
    let(:rails_version) { 6.1 }
  end

  shared_context 'with Rails 7.0' do
    let(:rails_version) { 7.0 }
  end

  include_context 'with Rails 7.0'

  shared_examples 'flags to constant, and does not correct' do |usage:|
    let(:constant) { usage.include?('::Timecop') ? '::Timecop' : 'Timecop' }

    it 'flags, and does not correct' do
      expect_offense(<<~RUBY, constant: constant)
        it do
          #{usage}
          ^{constant} Use `ActiveSupport::Testing::TimeHelpers` instead of `Timecop`
        end
      RUBY

      expect_no_corrections
    end
  end

  it_behaves_like 'flags to constant, and does not correct',
                  usage: 'Timecop'

  describe '.*' do
    it_behaves_like 'flags to constant, and does not correct',
                    usage: 'Timecop.foo'
  end

  shared_examples 'flags send, and does not correct' do |usage:,
                                                         flow_addendum: false|
    let(:usage_without_arguments) { usage.sub(/\(.*\)$/, '') }
    let(:addendum) do
      if flow_addendum
        '. If you need time to keep flowing, simulate it by travelling again.'
      else
        ''
      end
    end

    context 'when given no block' do
      it 'flags, and does not correct' do
        expect_offense(<<~RUBY, usage: usage)
          it do
            #{usage}
            ^{usage} Use `travel` or `travel_to` instead of `#{usage_without_arguments}`#{addendum}
          end
        RUBY

        expect_no_corrections
      end
    end

    context 'when given a block' do
      it 'flags, and does not correct' do
        expect_offense(<<~RUBY, usage: usage)
          it do
            #{usage} { assert true }
            ^{usage} Use `travel` or `travel_to` instead of `#{usage_without_arguments}`#{addendum}
          end
        RUBY

        expect_no_corrections
      end
    end
  end

  describe '.freeze' do
    shared_examples 'flags and corrects to' do |replacement:|
      context 'when given no block' do
        it "flags, and corrects to `#{replacement}`" do
          expect_offense(<<~RUBY)
            it do
              Timecop.freeze
              ^^^^^^^^^^^^^^ Use `#{replacement}` instead of `Timecop.freeze`
            end
          RUBY

          expect_correction(<<~RUBY)
            it do
              #{replacement}
            end
          RUBY
        end
      end

      context 'when given a block' do
        it "flags, and corrects to `#{replacement}`" do
          expect_offense(<<~RUBY)
            it do
              Timecop.freeze { assert true }
              ^^^^^^^^^^^^^^ Use `#{replacement}` instead of `Timecop.freeze`
            end
          RUBY

          expect_correction(<<~RUBY)
            it do
              #{replacement} { assert true }
            end
          RUBY
        end
      end
    end

    context 'when Rails < 5.2' do
      include_context 'with Rails 5.1'
      it_behaves_like 'flags and corrects to',
                      replacement: 'travel_to(Time.now)'
    end

    context 'with Rails 5.2+' do
      include_context 'with Rails 5.2'
      it_behaves_like 'flags and corrects to',
                      replacement: 'freeze_time'
    end

    context 'with arguments' do
      it_behaves_like 'flags send, and does not correct',
                      usage: 'Timecop.freeze(*time_args)'
    end
  end

  shared_examples 'return prefers' do
    context 'when given no block' do
      it 'flags, and corrects to `travel_back`' do
        expect_offense(<<~RUBY)
          it do
            Timecop.return
            ^^^^^^^^^^^^^^ Use `travel_back` instead of `Timecop.return`
          end
        RUBY

        expect_correction(<<~RUBY)
          it do
            travel_back
          end
        RUBY
      end
    end
  end

  describe '.return' do
    context 'with Rails < 6.1' do
      include_context 'with Rails 6.0'
      it_behaves_like 'return prefers'

      it 'flags, but does not correct return with a block' do
        expect_offense(<<~RUBY)
          it do
            Timecop.return { assert true }
            ^^^^^^^^^^^^^^ Use `travel_back` instead of `Timecop.return`
          end
        RUBY

        expect_no_corrections
      end
    end

    context 'with Rails 6.1+' do
      include_context 'with Rails 6.1'
      it_behaves_like 'return prefers'

      it 'flags, and corrects return with a block' do
        expect_offense(<<~RUBY)
          it do
            Timecop.return { assert true }
            ^^^^^^^^^^^^^^ Use `travel_back` instead of `Timecop.return`
          end
        RUBY

        expect_correction(<<~RUBY)
          it do
            travel_back { assert true }
          end
        RUBY
      end
    end
  end

  describe '.scale' do
    it_behaves_like 'flags send, and does not correct',
                    usage: 'Timecop.scale(factor)',
                    flow_addendum: true
  end

  describe '.travel' do
    it_behaves_like 'flags send, and does not correct',
                    usage: 'Timecop.travel(*time_args)',
                    flow_addendum: true
  end

  describe '::Timecop' do
    it_behaves_like 'flags to constant, and does not correct',
                    usage: '::Timecop'
  end

  describe 'Foo::Timecop' do
    it 'adds no offenses' do
      expect_no_offenses(<<~RUBY)
        it do
          Foo::Timecop
        end
      RUBY
    end
  end

  describe 'inside an example scope' do
    it 'flags in a `before` hook' do
      expect_offense(<<~RUBY)
        before do
          Timecop.freeze
          ^^^^^^^^^^^^^^ Use `freeze_time` instead of `Timecop.freeze`
          Timecop.return
          ^^^^^^^^^^^^^^ Use `travel_back` instead of `Timecop.return`
          Timecop.scale(factor)
          ^^^^^^^^^^^^^^^^^^^^^ Use `travel` or `travel_to` instead of `Timecop.scale`. If you need time to keep flowing, simulate it by travelling again.
          Timecop.travel(time)
          ^^^^^^^^^^^^^^^^^^^^ Use `travel` or `travel_to` instead of `Timecop.travel`. If you need time to keep flowing, simulate it by travelling again.
        end
      RUBY
    end

    it 'flags in an `around` hook' do
      expect_offense(<<~RUBY)
        around do |example|
          Timecop.freeze
          ^^^^^^^^^^^^^^ Use `freeze_time` instead of `Timecop.freeze`
          example.run
        end
      RUBY

      expect_correction(<<~RUBY)
        around do |example|
          freeze_time
          example.run
        end
      RUBY
    end

    it 'flags in a nested example group' do
      expect_offense(<<~RUBY)
        RSpec.describe Foo do
          context 'when frozen' do
            it do
              Timecop.freeze
              ^^^^^^^^^^^^^^ Use `freeze_time` instead of `Timecop.freeze`
            end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        RSpec.describe Foo do
          context 'when frozen' do
            it do
              freeze_time
            end
          end
        end
      RUBY
    end
  end

  describe 'outside an example scope' do
    it 'does not flag calls with a `TimeHelpers` counterpart' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Foo do
          Timecop.freeze
          Timecop.return
          Timecop.scale(factor)
          Timecop.travel(time)
        end
      RUBY
    end

    it 'does not flag in a `before(:all)` hook' do
      expect_no_offenses(<<~RUBY)
        before(:all) do
          Timecop.freeze
        end
      RUBY
    end

    it 'does not flag in a `before(:suite)` hook' do
      expect_no_offenses(<<~RUBY)
        before(:suite) do
          Timecop.freeze
        end
      RUBY
    end

    it 'still flags the constant on its own' do
      expect_offense(<<~RUBY)
        RSpec.describe Foo do
          Timecop.safe_mode = true
          ^^^^^^^ Use `ActiveSupport::Testing::TimeHelpers` instead of `Timecop`
        end
      RUBY

      expect_no_corrections
    end
  end
end
