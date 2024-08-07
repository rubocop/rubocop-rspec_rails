# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecRails::Timecop, :config do
  shared_context 'with Rails 5.1', :rails51 do
    let(:rails_version) { 5.1 }
  end

  shared_context 'with Rails 5.2', :rails52 do
    let(:rails_version) { 5.2 }
  end

  shared_context 'with Rails 6.0', :rails60 do
    let(:rails_version) { 6.0 }
  end

  shared_context 'with Rails 7.0', :rails70 do
    let(:rails_version) { 7.0 }
  end

  include_context 'with Rails 7.0'

  shared_examples 'flags to constant, and does not correct' do |usage:|
    constant = usage.include?('::Timecop') ? '::Timecop' : 'Timecop'

    it 'flags, and does not correct' do
      expect_offense(<<~RUBY, constant: constant)
        #{usage}
        ^{constant} Use `ActiveSupport::Testing::TimeHelpers` instead of `Timecop`
      RUBY

      expect_no_corrections
    end
  end

  include_examples 'flags to constant, and does not correct',
                   usage: 'Timecop'

  describe '.*' do
    include_examples 'flags to constant, and does not correct',
                     usage: 'Timecop.foo'
  end

  shared_examples 'flags send, and does not correct' do |usage:,
                                                         flow_addendum: false|
    usage_without_arguments = usage.sub(/\(.*\)$/, '')
    addendum =
      if flow_addendum
        '. If you need time to keep flowing, simulate it by travelling again.'
      else
        ''
      end

    context 'when given no block' do
      it 'flags, and does not correct' do
        expect_offense(<<~RUBY, usage: usage)
          #{usage}
          ^{usage} Use `travel` or `travel_to` instead of `#{usage_without_arguments}`#{addendum}
        RUBY

        expect_no_corrections
      end
    end

    context 'when given a block' do
      it 'flags, and does not correct' do
        expect_offense(<<~RUBY, usage: usage)
          #{usage} { assert true }
          ^{usage} Use `travel` or `travel_to` instead of `#{usage_without_arguments}`#{addendum}
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
            Timecop.freeze
            ^^^^^^^^^^^^^^ Use `#{replacement}` instead of `Timecop.freeze`
          RUBY

          expect_correction(<<~RUBY)
            #{replacement}
          RUBY
        end
      end

      context 'when given a block' do
        it "flags, and corrects to `#{replacement}`" do
          expect_offense(<<~RUBY)
            Timecop.freeze { assert true }
            ^^^^^^^^^^^^^^ Use `#{replacement}` instead of `Timecop.freeze`
          RUBY

          expect_correction(<<~RUBY)
            #{replacement} { assert true }
          RUBY
        end
      end
    end

    context 'when Rails < 5.2', :rails51 do
      include_examples 'flags and corrects to',
                       replacement: 'travel_to(Time.now)'
    end

    context 'with Rails 5.2+', :rails52 do
      include_examples 'flags and corrects to',
                       replacement: 'freeze_time'
    end

    context 'with arguments' do
      include_examples 'flags send, and does not correct',
                       usage: 'Timecop.freeze(*time_args)'
    end
  end

  shared_examples 'return prefers' do
    context 'when given no block' do
      it 'flags, and corrects to `travel_back`' do
        expect_offense(<<~RUBY)
          Timecop.return
          ^^^^^^^^^^^^^^ Use `travel_back` instead of `Timecop.return`
        RUBY

        expect_correction(<<~RUBY)
          travel_back
        RUBY
      end
    end
  end

  describe '.return' do
    context 'with Rails < 6.1', :rails60 do
      include_examples 'return prefers'

      it 'flags, but does not correct return with a block' do
        expect_offense(<<~RUBY)
          Timecop.return { assert true }
          ^^^^^^^^^^^^^^ Use `travel_back` instead of `Timecop.return`
        RUBY

        expect_no_corrections
      end
    end

    context 'with Rails 6.1+', :rails61 do
      include_examples 'return prefers'

      it 'flags, and corrects return with a block' do
        expect_offense(<<~RUBY)
          Timecop.return { assert true }
          ^^^^^^^^^^^^^^ Use `travel_back` instead of `Timecop.return`
        RUBY

        expect_correction(<<~RUBY)
          travel_back { assert true }
        RUBY
      end
    end
  end

  describe '.scale' do
    include_examples 'flags send, and does not correct',
                     usage: 'Timecop.scale(factor)',
                     flow_addendum: true
  end

  describe '.travel' do
    include_examples 'flags send, and does not correct',
                     usage: 'Timecop.travel(*time_args)',
                     flow_addendum: true
  end

  describe '::Timecop' do
    include_examples 'flags to constant, and does not correct',
                     usage: '::Timecop'
  end

  describe 'Foo::Timecop' do
    it 'adds no offenses' do
      expect_no_offenses(<<~RUBY)
        Foo::Timecop
      RUBY
    end
  end
end
