# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecRails
      # Prefer bang methods for persistence.
      #
      # @safety
      #   This cop is unsafe because by replacing non-bang versions
      #   of the persistence methods, you might:
      #   1. Catch persistence failures. This is what you want to catch.
      #   2. Might replace wrong object calls.
      #      The cop is unaware if the object is ActiveRecord instance
      #
      #
      # @example
      #   # bad
      #   before do
      #     post.update(title: "new title")
      #   end
      #
      #   # good
      #   before do
      #     post.update!(type: "new title")
      #   end
      #
      class BangPersistence < ::RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Prefer bang versions of the persistence methods.'

        PERSISTENCE_METHODS = %i[
          create
          destroy
          save
          update
          update_attribute
        ].to_set.freeze

        # Match `before` blocks
        # @!method before_block?(node)
        def_node_matcher :before_block?, <<-PATTERN
          (block (send nil? :before) ...)
        PATTERN

        # Match `save` and `update` method calls
        # @!method peristence_calls(node)
        def_node_search :peristence_calls, <<-PATTERN
          (send _ {#{PERSISTENCE_METHODS.map { |method| ":#{method}" }.join(' ')}} ...)
        PATTERN

        def on_block(node)
          return unless before_block?(node)

          peristence_calls(node) do |method_call|
            add_offense(method_call) do |corrector|
              corrector.replace(method_call.loc.selector,
                                "#{method_call.method_name}!")
            end
          end
        end

        alias on_numblock on_block
      end
    end
  end
end
