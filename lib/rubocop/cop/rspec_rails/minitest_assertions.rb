# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecRails
      # Check if using Minitest-like matchers.
      #
      # Check the use of minitest-like matchers
      # starting with `assert_` or `refute_`.
      #
      # @example
      #   # bad
      #   assert_equal(a, b)
      #   assert_equal a, b, "must be equal"
      #   assert_not_includes a, b
      #   refute_equal(a, b)
      #   assert_nil a
      #   refute_empty(b)
      #   assert_true(a)
      #   assert_false(a)
      #   assert_response :ok
      #   assert_redirected_to '/users'
      #
      #   # good
      #   expect(b).to eq(a)
      #   expect(b).to(eq(a), "must be equal")
      #   expect(a).not_to include(b)
      #   expect(b).not_to eq(a)
      #   expect(a).to eq(nil)
      #   expect(a).not_to be_empty
      #   expect(a).to be(true)
      #   expect(a).to be(false)
      #   expect(response).to have_http_status(:ok)
      #   expect(response).to redirect_to('/users')
      #
      class MinitestAssertions < ::RuboCop::Cop::Base
        extend AutoCorrector

        # :nodoc:
        class BasicAssertion
          extend NodePattern::Macros

          attr_reader :expected, :actual, :failure_message

          def self.match_assertions(*matchers, captures:)
            const_set(:MATCHERS, matchers.freeze)

            matcher_pattern = matchers.map { |matcher| ":#{matcher}" }.join(' ')
            def_node_matcher 'self.minitest_assertion', <<~PATTERN # rubocop:disable InternalAffairs/NodeMatcherDirective
              (send nil? {#{matcher_pattern}} #{captures})
            PATTERN
          end

          def self.minitest_assertion
            # :nocov:
            raise NotImplementedError
            # :nocov:
          end

          def self.match(expected, actual, failure_message)
            new(expected, actual, failure_message.first)
          end

          def initialize(expected, actual, failure_message)
            @expected = expected&.source
            @actual = actual.source
            @failure_message = failure_message&.source
          end

          def replaced(node)
            runner = negated?(node) ? 'not_to' : 'to'
            if failure_message.nil?
              "expect(#{actual}).#{runner} #{assertion}"
            else
              "expect(#{actual}).#{runner}(#{assertion}, #{failure_message})"
            end
          end

          def negated?(node)
            node.method_name.start_with?('assert_not_', 'refute_')
          end

          def assertion
            # :nocov:
            raise NotImplementedError
            # :nocov:
          end
        end

        # :nodoc:
        class EqualAssertion < BasicAssertion
          match_assertions :assert_equal,
                           :assert_not_equal,
                           :refute_equal,
                           captures: '$_ $_ $_?'

          def assertion
            "eq(#{expected})"
          end
        end

        # :nodoc:
        class KindOfAssertion < BasicAssertion
          match_assertions :assert_kind_of,
                           :assert_not_kind_of,
                           :refute_kind_of,
                           captures: '$_ $_ $_?'

          def assertion
            "be_a_kind_of(#{expected})"
          end
        end

        # :nodoc:
        class InstanceOfAssertion < BasicAssertion
          match_assertions :assert_instance_of,
                           :assert_not_instance_of,
                           :refute_instance_of,
                           captures: '$_ $_ $_?'

          def assertion
            "be_an_instance_of(#{expected})"
          end
        end

        # :nodoc:
        class IncludesAssertion < BasicAssertion
          match_assertions :assert_includes,
                           :assert_not_includes,
                           :refute_includes,
                           captures: '$_ $_ $_?'

          def self.match(collection, expected, failure_message)
            new(expected, collection, failure_message.first)
          end

          def assertion
            "include(#{expected})"
          end
        end

        # :nodoc:
        class InDeltaAssertion < BasicAssertion
          match_assertions :assert_in_delta,
                           :assert_not_in_delta,
                           :refute_in_delta,
                           captures: '$_ $_ $_? $_?'

          def self.match(expected, actual, delta, failure_message)
            new(expected, actual, delta.first, failure_message.first)
          end

          def initialize(expected, actual, delta, fail_message)
            super(expected, actual, fail_message)

            @delta = delta&.source || '0.001'
          end

          def assertion
            "be_within(#{@delta}).of(#{expected})"
          end
        end

        # :nodoc:
        class PredicateAssertion < BasicAssertion
          match_assertions :assert_predicate,
                           :assert_not_predicate,
                           :refute_predicate,
                           captures: '$_ ${sym} $_?'

          def self.match(subject, predicate, failure_message)
            predicate_name = predicate.value.to_s
            return nil unless predicate_name.end_with?('?')

            matcher_name = predicate_name.delete_suffix('?')
            return nil unless valid_matcher_name?(matcher_name)

            new(predicate, subject, failure_message.first, matcher_name)
          end

          def self.valid_matcher_name?(matcher_name)
            matcher_name.match?(/\A\w+\z/)
          end

          def initialize(expected, actual, failure_message, matcher_name)
            super(expected, actual, failure_message)

            @matcher_name = matcher_name
          end

          def assertion
            "be_#{@matcher_name}"
          end
        end

        # :nodoc:
        class MatchAssertion < BasicAssertion
          match_assertions :assert_match,
                           :refute_match,
                           captures: '$_ $_ $_?'

          def assertion
            "match(#{expected})"
          end
        end

        # :nodoc:
        class NilAssertion < BasicAssertion
          match_assertions :assert_nil,
                           :assert_not_nil,
                           :refute_nil,
                           captures: '$_ $_?'

          def self.match(actual, failure_message)
            new(nil, actual, failure_message.first)
          end

          def assertion
            'eq(nil)'
          end
        end

        # :nodoc:
        class EmptyAssertion < BasicAssertion
          match_assertions :assert_empty,
                           :assert_not_empty,
                           :refute_empty,
                           captures: '$_ $_?'

          def self.match(actual, failure_message)
            new(nil, actual, failure_message.first)
          end

          def assertion
            'be_empty'
          end
        end

        # :nodoc:
        class TrueAssertion < BasicAssertion
          match_assertions :assert_true, captures: '$_ $_?'

          def self.match(actual, failure_message)
            new(nil, actual, failure_message.first)
          end

          def assertion
            'be(true)'
          end
        end

        # :nodoc:
        class FalseAssertion < BasicAssertion
          match_assertions :assert_false, captures: '$_ $_?'

          def self.match(actual, failure_message)
            new(nil, actual, failure_message.first)
          end

          def assertion
            'be(false)'
          end
        end

        # :nodoc:
        module ResponseAssertionActual
          RESPONSE_NODE = Struct.new(:source).new('response')

          def match(expected, failure_message)
            new(expected, RESPONSE_NODE, failure_message.first)
          end
        end

        # :nodoc:
        class ResponseAssertion < BasicAssertion
          extend ResponseAssertionActual

          match_assertions :assert_response, captures: '$_ $_?'

          def assertion
            "have_http_status(#{expected})"
          end
        end

        # :nodoc:
        class RedirectAssertion < BasicAssertion
          extend ResponseAssertionActual

          match_assertions :assert_redirected_to, captures: '$_ $_?'

          def assertion
            "redirect_to(#{expected})"
          end
        end

        MSG = 'Use `%<prefer>s`.'

        # TODO: replace with `BasicAssertion.subclasses` in Ruby 3.1+
        ASSERTION_MATCHERS = constants(false).filter_map do |c|
          const = const_get(c)

          const if const.is_a?(Class) && const.superclass == BasicAssertion
        end

        RESTRICT_ON_SEND = ASSERTION_MATCHERS.flat_map { |m| m::MATCHERS }

        def on_send(node)
          ASSERTION_MATCHERS.each do |m|
            m.minitest_assertion(node) do |*args|
              assertion = m.match(*args)

              next if assertion.nil?

              on_assertion(node, assertion)
            end
          end
        end

        def on_assertion(node, assertion)
          preferred = assertion.replaced(node)
          add_offense(node, message: message(preferred)) do |corrector|
            corrector.replace(node, preferred)
          end
        end

        def message(preferred)
          format(MSG, prefer: preferred)
        end
      end
    end
  end
end
