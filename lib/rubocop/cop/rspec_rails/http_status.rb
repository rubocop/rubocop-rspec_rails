# frozen_string_literal: true

begin
  require 'rack/utils'
rescue LoadError
  # RSpecRails/HttpStatus cannot be loaded if rack/utils is unavailable.
end

module RuboCop
  module Cop
    module RSpecRails
      # Enforces use of symbolic or numeric value to describe HTTP status.
      #
      # This cop inspects only `have_http_status` calls.
      # So, this cop does not check if a method starting with `be_*` is used
      # when setting for `EnforcedStyle: symbolic` or
      # `EnforcedStyle: numeric`.
      # This cop is also capable of detecting unknown HTTP status codes.
      #
      # @example `EnforcedStyle: symbolic` (default)
      #   # bad
      #   it { is_expected.to have_http_status 200 }
      #   it { is_expected.to have_http_status 404 }
      #   it { is_expected.to have_http_status "403" }
      #
      #   # good
      #   it { is_expected.to have_http_status :ok }
      #   it { is_expected.to have_http_status :not_found }
      #   it { is_expected.to have_http_status :forbidden }
      #   it { is_expected.to have_http_status :success }
      #   it { is_expected.to have_http_status :error }
      #
      # @example `EnforcedStyle: numeric`
      #   # bad
      #   it { is_expected.to have_http_status :ok }
      #   it { is_expected.to have_http_status :not_found }
      #   it { is_expected.to have_http_status "forbidden" }
      #
      #   # good
      #   it { is_expected.to have_http_status 200 }
      #   it { is_expected.to have_http_status 404 }
      #   it { is_expected.to have_http_status 403 }
      #   it { is_expected.to have_http_status :success }
      #   it { is_expected.to have_http_status :error }
      #
      # @example `EnforcedStyle: be_status`
      #   # bad
      #   it { is_expected.to have_http_status :ok }
      #   it { is_expected.to have_http_status :not_found }
      #   it { is_expected.to have_http_status "forbidden" }
      #   it { is_expected.to have_http_status 200 }
      #   it { is_expected.to have_http_status 404 }
      #   it { is_expected.to have_http_status "403" }
      #
      #   # good
      #   it { is_expected.to be_ok }
      #   it { is_expected.to be_not_found }
      #   it { is_expected.to have_http_status :success }
      #   it { is_expected.to have_http_status :error }
      #
      # @example
      #   # bad
      #   it { is_expected.to have_http_status :oki_doki }
      #
      #   # good
      #   it { is_expected.to have_http_status :ok }
      class HttpStatus < ::RuboCop::Cop::Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle
        RESTRICT_ON_SEND = %i[have_http_status].freeze

        # @!method http_status(node)
        def_node_matcher :http_status, <<~PATTERN
          (send nil? :have_http_status ${int sym str})
        PATTERN

        def on_send(node) # rubocop:disable Metrics/MethodLength
          return unless defined?(::Rack::Utils::SYMBOL_TO_STATUS_CODE)

          http_status(node) do |arg|
            return if arg.str_type? && arg.heredoc?

            checker = checker_class.new(arg)
            return unless checker.offensive?

            add_offense(checker.offense_range,
                        message: checker.message) do |corrector|
              next unless checker.autocorrectable?

              corrector.replace(checker.offense_range, checker.prefer)
            end
          end
        end

        private

        def checker_class
          case style
          when :symbolic
            SymbolicStyleChecker
          when :numeric
            NumericStyleChecker
          when :be_status
            BeStatusStyleChecker
          else
            # :nocov:
            :noop
            # :nocov:
          end
        end

        # :nodoc:
        class StyleCheckerBase
          MSG = 'Prefer `%<prefer>s` over `%<current>s` ' \
                'to describe HTTP status code.'
          MSG_UNKNOWN_STATUS_CODE = 'Unknown status code.'
          ALLOWED_STATUSES = %i[error success missing redirect].freeze

          attr_reader :node

          def initialize(node)
            @node = node
          end

          def message
            if autocorrectable?
              format(MSG, prefer: prefer, current: current)
            else
              MSG_UNKNOWN_STATUS_CODE
            end
          end

          def current
            offense_range.source
          end

          def offense_range
            node
          end

          def allowed_symbol?
            node.sym_type? && ALLOWED_STATUSES.include?(node.value)
          end

          def known_status_symbol?
            node.sym_type? &&
              ::Rack::Utils::SYMBOL_TO_STATUS_CODE.key?(node.value)
          end

          def known_status_code?
            numeric_status_code? &&
              ::Rack::Utils::SYMBOL_TO_STATUS_CODE.value?(status_code_number)
          end

          def custom_http_status_code?
            numeric_status_code? && !known_status_code?
          end

          def numeric_status_code?
            node.int_type? || numeric_string?
          end

          def numeric_string?
            node.str_type? && node.value.match?(/\A\d+\z/)
          end

          def status_code_number
            node.value.to_i
          end

          def status_code_symbol
            ::Rack::Utils::SYMBOL_TO_STATUS_CODE.key(status_code_number)
          end
        end

        # :nodoc:
        class SymbolicStyleChecker < StyleCheckerBase
          def offensive?
            return false if allowed_symbol? || known_status_symbol?
            return false if custom_http_status_code?

            true
          end

          def autocorrectable?
            !!symbol
          end

          def prefer
            symbol.inspect
          end

          private

          def symbol
            status_code_symbol if known_status_code?
          end
        end

        # :nodoc:
        class NumericStyleChecker < StyleCheckerBase
          def offensive?
            return false if node.int_type? || allowed_symbol?
            return false if custom_http_status_code?

            true
          end

          def autocorrectable?
            !!number
          end

          def prefer
            number.to_s
          end

          private

          def number
            return status_code_number if known_status_code?

            ::Rack::Utils::SYMBOL_TO_STATUS_CODE[node.value.to_sym]
          end
        end

        # :nodoc:
        class BeStatusStyleChecker < StyleCheckerBase
          def offensive?
            return false if allowed_symbol? || custom_http_status_code?

            true
          end

          def autocorrectable?
            !!status_code
          end

          def offense_range
            node.parent
          end

          def prefer
            "be_#{status_code}"
          end

          private

          def status_code
            if known_status_symbol?
              node.value
            elsif known_status_code?
              status_code_symbol
            else
              normalize_str
            end
          end

          def normalize_str
            str = node.value.to_s
            str if ::Rack::Utils::SYMBOL_TO_STATUS_CODE.key?(str.to_sym)
          end
        end
      end
    end
  end
end
