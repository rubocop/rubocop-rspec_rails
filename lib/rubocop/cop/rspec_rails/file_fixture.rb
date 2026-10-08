# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecRails
      # Prefer `file_fixture` over hardcoded paths into `spec/fixtures`.
      #
      # @safety
      #   `file_fixture` uses the configured `file_fixture_path`, which defaults
      #   to `spec/fixtures/files`. A file under `spec/fixtures` may need to be
      #   moved or `file_fixture_path` configured before replacing the path.
      #
      # @example
      #   # bad
      #   Rails.root.join('spec', 'fixtures', 'files', 'example.pdf')
      #   Rails.root.join("spec/fixtures/files/#{name}.pdf")
      #
      #   # good
      #   file_fixture('example.pdf')
      #   file_fixture("#{name}.pdf")
      class FileFixture < RuboCop::Cop::Base
        MSG = 'Prefer `file_fixture` for files under `spec/fixtures`.'
        RESTRICT_ON_SEND = %i[join].freeze

        # @!method fixture_path?(node)
        def_node_matcher :fixture_path?, <<~PATTERN
          (send
            (send (const {nil? cbase} :Rails) :root)
            :join (str "spec") (str "fixtures") _ ...)
        PATTERN

        # @!method combined_fixture_path?(node)
        def_node_matcher :combined_fixture_path?, <<~PATTERN
          (send
            (send (const {nil? cbase} :Rails) :root)
            :join (str "spec/fixtures") _ ...)
        PATTERN

        # @!method interpolated_fixture_path?(node)
        def_node_matcher :interpolated_fixture_path?, <<~PATTERN
          (send
            (send (const {nil? cbase} :Rails) :root)
            :join (dstr (str #fixture_prefix?) ...) ...)
        PATTERN

        def on_send(node)
          return unless hardcoded_fixture_path?(node)

          add_offense(node.loc.selector)
        end

        private

        def hardcoded_fixture_path?(node)
          fixture_path?(node) ||
            combined_fixture_path?(node) ||
            interpolated_fixture_path?(node)
        end

        def fixture_prefix?(string)
          string.start_with?('spec/fixtures/')
        end
      end
    end
  end
end
