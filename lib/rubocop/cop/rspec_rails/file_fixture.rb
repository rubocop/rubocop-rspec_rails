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
      #   Rails.root.join('spec/fixtures/files', 'example.pdf')
      #   Rails.root.join("spec/fixtures/files/#{name}.pdf")
      #
      #   # good
      #   file_fixture('example.pdf')
      #   file_fixture("#{name}.pdf")
      class FileFixture < RuboCop::Cop::Base
        MSG = 'Prefer `file_fixture` for files under `spec/fixtures`.'
        RESTRICT_ON_SEND = %i[join].freeze
        FIXTURES_DIR = 'spec/fixtures'

        # @!method rails_root_join(node)
        def_node_matcher :rails_root_join, <<~PATTERN
          (send
            (send (const {nil? cbase} :Rails) :root)
            :join $...)
        PATTERN

        def on_send(node)
          rails_root_join(node) do |arguments|
            add_offense(node.loc.selector) if fixture_path?(arguments)
          end
        end

        private

        # The literal prefix of the joined path points inside `spec/fixtures`,
        # or at `spec/fixtures` itself with dynamic segments after it.
        def fixture_path?(arguments)
          prefix, dynamic = literal_prefix(arguments)
          prefix = prefix.sub(%r{/+\z}, '')

          prefix.start_with?("#{FIXTURES_DIR}/") ||
            (prefix == FIXTURES_DIR && dynamic)
        end

        # Joins the leading string literals of the arguments and reports
        # whether a non-literal segment follows them.
        def literal_prefix(arguments)
          segments = []
          arguments.each do |argument|
            unless argument.str_type?
              head = argument.children.first if argument.dstr_type?
              segments << head.value if head&.str_type?
              return [segments.join('/'), true]
            end

            segments << argument.value
          end
          [segments.join('/'), false]
        end
      end
    end
  end
end
