# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecRails
      # Prefer `have_enqueued_job` over `receive(:perform_later)`.
      #
      # The `have_enqueued_job` matcher is preferred for testing ActiveJob
      # enqueuing. It is more explicit and provides better clarity than
      # using `receive(:perform_later)`.
      #
      # @example
      #   # bad
      #   expect(MyJob).to receive(:perform_later)
      #   do_something
      #
      #   # bad
      #   allow(MyJob).to receive(:perform_later)
      #   do_something
      #   expect(MyJob).to have_received(:perform_later)
      #
      #   # bad
      #   expect(MyJob).to receive(:perform_later).with(user, order)
      #
      #   # good
      #   expect { do_something }.to have_enqueued_job(MyJob)
      #
      #   # good
      #   expect { do_something }.to have_enqueued_job(MyJob).with(user, order)
      #
      #   # good
      #   expect { do_something }
      #     .to have_enqueued_job(MyJob)
      #     .on_queue('mailers')
      #     .at(Date.tomorrow.noon)
      #
      class ReceivePerformLater < ::RuboCop::Cop::Base
        MSG = 'Prefer `expect { ... }.to have_enqueued_job(%<job_class>s)` ' \
              'over `%<receiver>s(%<job_class>s).%<to>s ' \
              '%<matcher>s(:perform_later)`.'

        RESTRICT_ON_SEND = %i[receive have_received].to_set
        EXPECT_METHODS = %i[expect allow].freeze
        RUNNERS = %i[to to_not not_to].freeze

        # @!method receive_perform_later?(node)
        def_node_matcher :receive_perform_later?, <<~PATTERN
          (send nil? {:receive :have_received}
            (sym :perform_later))
        PATTERN

        def on_send(node)
          return unless receive_perform_later?(node)
          return unless (to_node = find_to_node(node))

          expect_node = to_node.receiver
          return unless expect_node?(expect_node)

          job_class = expect_node.first_argument
          return unless valid_job_class?(job_class)
          return if allowed_combination?(expect_node, node)

          add_offense(to_node,
                      message: build_message(expect_node, job_class, to_node,
                                             node))
        end

        private

        def expect_node?(node)
          node&.send_type? && EXPECT_METHODS.include?(node.method_name)
        end

        def valid_job_class?(node)
          node&.const_type?
        end

        def allowed_combination?(expect_node, matcher_node)
          expect_node.method?(:allow) && matcher_node.method?(:receive)
        end

        def build_message(expect_node, job_class, to_node, matcher_node)
          format(MSG,
                 receiver: expect_node.method_name,
                 job_class: job_class.source,
                 to: to_node.method_name,
                 matcher: matcher_node.method_name)
        end

        def find_to_node(node)
          parent = node.parent
          return unless parent&.send_type?

          return parent if runner?(parent)
          if parent.parent&.send_type? && runner?(parent.parent)
            return parent.parent
          end

          nil
        end

        def runner?(node)
          RUNNERS.include?(node.method_name)
        end
      end
    end
  end
end
