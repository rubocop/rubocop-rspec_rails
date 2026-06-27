# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecRails
      # Checks that tests use RSpec `before` hook over Rails `setup` method.
      #
      # @example
      #   # bad
      #   setup do
      #     allow(foo).to receive(:bar)
      #   end
      #
      #   # good
      #   before do
      #     allow(foo).to receive(:bar)
      #   end
      #
      class AvoidSetupHook < ::RuboCop::Cop::RSpec::Base
        extend AutoCorrector

        MSG = 'Use `before` instead of `setup`.'

        def on_block(node) # rubocop:disable InternalAffairs/ItblockHandler
          return unless (setup = setup_call(node))
          return unless inside_example_group?(node)

          add_offense(node) do |corrector|
            corrector.replace setup, 'before'
          end
        end
        alias on_numblock on_block

        private

        def setup_call(node)
          send_node = node.send_node
          return unless send_node.method?(:setup)
          return if send_node.receiver

          send_node
        end

        def inside_example_group?(node)
          node.each_ancestor(:block).any? do |ancestor|
            example_group?(ancestor)
          end
        end
      end
    end
  end
end
