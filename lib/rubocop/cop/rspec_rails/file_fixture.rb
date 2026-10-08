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
      #   Rails.root.join('spec/fixtures/files/' + name)
      #   Rails.root.join('spec', 'fixtures') / 'files' / 'example.pdf'
      #
      #   # good
      #   file_fixture('example.pdf')
      #   file_fixture("#{name}.pdf")
      #
      #   # good - configuring `file_fixture_path` itself
      #   config.file_fixture_path = Rails.root.join('spec/fixtures/files')
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

        # @!method path_extension(node)
        def_node_matcher :path_extension, <<~PATTERN
          (send _ {:join :/} $...)
        PATTERN

        # @!method file_fixture_path_assignment?(node)
        def_node_matcher :file_fixture_path_assignment?, <<~PATTERN
          (send _ :file_fixture_path= ...)
        PATTERN

        def on_send(node)
          rails_root_join(node) do |arguments|
            outer, segments = extend_path(node, arguments)
            next if file_fixture_path_assignment?(outer.parent)

            add_offense(node.loc.selector) if fixture_path?(segments)
          end
        end

        private

        # Follows `join` and `/` calls chained onto the node, collecting their
        # arguments as further path segments.
        def extend_path(node, segments)
          while (extension = chained_segments(node.parent, node))
            segments += extension
            node = node.parent
          end
          [node, segments]
        end

        def chained_segments(parent, node)
          return unless parent&.send_type? && parent.receiver.equal?(node)

          path_extension(parent)
        end

        # The literal prefix of the joined path points inside `spec/fixtures`,
        # or at `spec/fixtures` itself with dynamic segments after it.
        def fixture_path?(arguments)
          prefix, dynamic = literal_prefix(arguments)
          prefix = prefix.sub(%r{/+\z}, '')

          prefix.start_with?("#{FIXTURES_DIR}/") ||
            (prefix == FIXTURES_DIR && dynamic)
        end

        # Joins the leading literal text of the arguments and reports
        # whether a non-literal part follows it.
        def literal_prefix(arguments)
          segments = []
          arguments.each do |argument|
            text, dynamic = literal_text(argument)
            segments << text
            return [segments.join('/'), true] if dynamic
          end
          [segments.join('/'), false]
        end

        # The leading literal text of one argument and whether a
        # non-literal part follows it.
        def literal_text(node)
          case node.type
          when :str then [node.value, false]
          when :dstr then literal_run(node.children)
          when :send then concatenation_text(node)
          else ['', true]
          end
        end

        # `'spec/fixtures/' + name`, including longer `+` chains.
        def concatenation_text(node)
          return ['', true] unless node.method?(:+)

          left, dynamic = literal_text(node.receiver)
          return [left, true] if dynamic

          right, dynamic = literal_text(node.first_argument)
          [left + right, dynamic]
        end

        def literal_run(nodes)
          literal = nodes.take_while(&:str_type?)
          [literal.map(&:value).join, literal.size < nodes.size]
        end
      end
    end
  end
end
