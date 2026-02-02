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
        RUNNERS = %i[to to_not not_to].freeze

        # @!method receive_perform_later?(node)
        def_node_matcher :receive_perform_later?, <<~PATTERN
          (send nil? {:receive :have_received}
            (sym :perform_later))
        PATTERN

        # @!method expect_or_allow?(node)
        def_node_matcher :expect_or_allow?, <<~PATTERN
          (send nil? {:expect :allow} const_type?)
        PATTERN

        def on_send(node)
          return unless receive_perform_later?(node)
          return unless (runner_node = find_runner_node(node))

          expect_node = runner_node.receiver
          return unless expect_or_allow?(expect_node)
          return if allow_receive_combination?(expect_node, node)

          job_class = expect_node.first_argument
          offense_node = find_offense_range(runner_node)
          add_offense(offense_node,
                      message: offense_message(expect_node, job_class,
                                               runner_node, node))
        end

        private

        def allow_receive_combination?(expect_node, matcher_node)
          expect_node.method?(:allow) && matcher_node.method?(:receive)
        end

        def offense_message(expect_node, job_class, runner_node, matcher_node)
          format(MSG,
                 receiver: expect_node.method_name,
                 job_class: job_class.source,
                 to: runner_node.method_name,
                 matcher: matcher_node.method_name)
        end

        def find_runner_node(node)
          node.each_ancestor(:send).find { |ancestor| runner?(ancestor) }
        end

        def find_offense_range(runner_node)
          current = runner_node
          current = current.parent while chained_send?(current)
          current
        end

        def chained_send?(node)
          node.parent&.send_type? && node.parent.receiver == node
        end

        def runner?(node)
          RUNNERS.include?(node.method_name)
        end
      end
    end
  end
end
