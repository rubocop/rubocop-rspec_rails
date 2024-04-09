# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecRails
      # Do not overwrite Settings directly, use mock instead.
      #
      # @example
      #   # bad
      #   Settings.foo = 'bar'
      #   Settings[:foo] = 'bar'
      #   Settings.foo[:bar] = 'baz'
      #   Settings.foo += 'bar'
      #   Settings.foo << 'bar'
      #
      #   # good
      #   allow(Settings).to receive(:foo).and_return('bar')
      #   allow(Settings).to receive(:[]).with(:foo).and_return('bar')
      #   allow(Settings.foo).to receive(:[]).with(:bar).and_return('baz')
      #   allow(Settings).to receive(:foo).and_return(Settings.foo + "bar")
      #
      class SettingsOverwritten < ::RuboCop::Cop::Base
        MSG = 'Do not overwrite Settings directly, use mock instead.'

        # @!method settings?(node)
        def_node_matcher :settings?, <<~PATTERN
          (const nil? :Settings)
        PATTERN

        def on_const(node)
          return unless settings?(node)
          return unless (assignment = first_assignment(node))

          add_offense(assignment)
        end

        private

        def first_assignment(node)
          node.each_ancestor.find(&:assignment_or_similar?)
        end
      end
    end
  end
end
