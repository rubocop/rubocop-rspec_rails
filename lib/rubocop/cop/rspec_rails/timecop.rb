# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpecRails
      # Enforces use of ActiveSupport TimeHelpers instead of Timecop.
      #
      # ## Migration
      # `Timecop.freeze` should be replaced with `freeze_time` when used
      # without arguments. Where a `duration` has been passed to `freeze`, it
      # should be replaced with `travel`. Likewise, where a `time` has been
      # passed to `freeze`, it should be replaced with `travel_to`.
      #
      # `travel` accepts an `ActiveSupport::Duration`, and is a shorthand for
      # `travel_to(Time.now + duration)`, so it already leaves the clock
      # frozen, exactly as `Timecop.freeze(duration)` does. Neither call is
      # offered as an autocorrection, because a duration and a time are
      # indistinguishable in the source while needing different replacements.
      #
      # `Timecop.scale` should be replaced by explicitly calling `travel` or
      # `travel_to` with the expected `durations` or `times`, respectively,
      # rather than relying on allowing time to continue to flow.
      #
      # `Timecop.return` should be replaced with `travel_back`, with or
      # without a block.
      #
      # `Timecop.travel` should be replaced by `travel` or `travel_to` when
      # passed a `duration` or `time`, respectively. As with `Timecop.scale`,
      # rather than relying on time continuing to flow, it should be travelled
      # to explicitly.
      #
      # Only these four calls are flagged. A bare `Timecop` reference, or any
      # other message sent to it, is left alone.
      #
      # ## Sub-second precision
      #
      # `Timecop` keeps the microseconds of the time it is given, while
      # `travel`, `travel_to` and `freeze_time` set them to zero unless
      # `with_usec: true` is passed. Add that keyword wherever a test depends
      # on the fractional part of a second. It is available from Rails 7.1.
      #
      # ## Rails version
      #
      # The cop only runs on Rails 7.1 and newer, where every replacement it
      # suggests exists. The version is taken from `TargetRailsVersion`, then
      # from the `railties` entry of the lock file, and Rails 7.1 is assumed
      # when neither is available.
      #
      # ## RSpec Caveats
      #
      # Note that if using RSpec, `TimeHelpers` are not included by default,
      # and must be manually included by updating `rails_helper` accordingly:
      #
      # ```ruby
      # RSpec.configure do |config|
      #   config.include ActiveSupport::Testing::TimeHelpers
      # end
      # ```
      #
      # Moreover, `TimeHelpers` undoes time travel in `after_teardown`, which
      # rspec-rails only runs in example groups that include
      # `RSpec::Rails::RailsExampleGroup`. Those groups are selected by their
      # `type:` metadata, so this cop only inspects code that sits inside an
      # example, or inside an example-level hook, of an example group carrying
      # one of the `SpecTypes` types. Anywhere else, replacing `Timecop` with
      # `TimeHelpers` would leak a frozen clock into the following examples.
      #
      # This also means `rails_helper` has to be required instead of
      # `spec_helper`, or a similar adapter layer has to be in effect.
      #
      # `RSpec::Rails::RailsExampleGroup` can be included into a type of your
      # own, in which case add that type to `SpecTypes`:
      #
      # ```ruby
      # RSpec.configure do |config|
      #   config.include RSpec::Rails::RailsExampleGroup, type: :service
      # end
      # ```
      #
      # @example
      #   # bad
      #   Timecop.freeze
      #   Timecop.freeze(duration)
      #   Timecop.freeze(time)
      #
      #   # good
      #   freeze_time
      #   travel(duration)
      #   travel_to(time)
      #
      #   # bad
      #   Timecop.freeze { assert true }
      #   Timecop.freeze(duration) { assert true }
      #   Timecop.freeze(time) { assert true }
      #
      #   # good
      #   freeze_time { assert true }
      #   travel(duration) { assert true }
      #   travel_to(time) { assert true }
      #
      #   # bad
      #   Timecop.travel(duration)
      #   Timecop.travel(time)
      #
      #   # good
      #   travel(duration)
      #   travel_to(time)
      #
      #   # bad
      #   Timecop.return
      #   Timecop.return { assert true }
      #
      #   # good
      #   travel_back
      #   travel_back { assert true }
      #
      #   # bad
      #   Timecop.scale(factor)
      #   Timecop.scale(factor) { assert true }
      #
      #   # good
      #   travel(duration)
      #   travel_to(time)
      #   travel(duration) { assert true }
      #   travel_to(time) { assert true }
      class Timecop < RuboCop::Cop::RSpec::Base
        extend AutoCorrector

        FREEZE_MESSAGE = 'Use `freeze_time` instead of `Timecop.freeze`'
        FREEZE_WITH_ARGUMENTS_MESSAGE =
          'Use `travel` or `travel_to` instead of `Timecop.freeze`'
        RETURN_MESSAGE = 'Use `travel_back` instead of `Timecop.return`'
        ADDENDUM =
          'If you need time to keep flowing, simulate it by travelling again.'
        TRAVEL_MESSAGE =
          "Use `travel` or `travel_to` instead of `Timecop.travel`. #{ADDENDUM}"
        SCALE_MESSAGE =
          "Use `travel` or `travel_to` instead of `Timecop.scale`. #{ADDENDUM}"

        RESTRICT_ON_SEND = %i[freeze return scale travel].to_set
        MINIMUM_RAILS_VERSION = Gem::Version.new('7.1')

        # @!method timecop?(node)
        def_node_matcher :timecop?, <<~PATTERN
          (const {nil? cbase} :Timecop)
        PATTERN

        # @!method timecop_send(node)
        def_node_matcher :timecop_send, <<~PATTERN
          (send
            #timecop? ${:freeze :return :scale :travel}
            $...
          )
        PATTERN

        # @!method rails_group?(node, types)
        def_node_matcher :rails_group?, <<~PATTERN
          (block (send #rspec?
              #ExampleGroups.all ... #rails_metadata?(%1)
            ) ... )
        PATTERN

        # @!method rails_metadata?(node, types)
        def_node_matcher :rails_metadata?, <<~PATTERN
          (hash <(pair (sym :type) (sym %1)) ...>)
        PATTERN

        def on_send(node)
          return if rails_version < MINIMUM_RAILS_VERSION

          timecop_send(node) do |message, arguments|
            on_timecop_send(node, message, arguments)
          end
        end

        private

        def on_timecop_send(node, message, arguments)
          return unless inside_example_scope?(node)
          return unless inside_rails_example_group?(node)

          case message
          when :freeze then on_timecop_freeze(node, arguments)
          when :return then on_timecop_return(node)
          when :scale  then on_timecop_scale(node)
          when :travel then on_timecop_travel(node)
          # :nocov:
          else nil # rubocop:disable Style/EmptyElse
            # :nocov:
          end
        end

        def on_timecop_freeze(node, arguments)
          if arguments.any?
            return add_offense(node, message: FREEZE_WITH_ARGUMENTS_MESSAGE)
          end

          add_offense(node, message: FREEZE_MESSAGE) do |corrector|
            corrector.replace(receiver_and_message_range(node), 'freeze_time')
          end
        end

        def on_timecop_return(node)
          add_offense(node, message: RETURN_MESSAGE) do |corrector|
            corrector.replace(receiver_and_message_range(node), 'travel_back')
          end
        end

        def on_timecop_scale(node)
          add_offense(node, message: SCALE_MESSAGE)
        end

        def on_timecop_travel(node)
          add_offense(node, message: TRAVEL_MESSAGE)
        end

        def receiver_and_message_range(node)
          node.source_range.with(end_pos: node.location.selector.end_pos)
        end

        # `TargetRailsVersion` wins, then the lock file, with a fallback to 7.1
        def rails_version
          version = config.for_all_cops['TargetRailsVersion'] ||
            target_gem_version('railties') || MINIMUM_RAILS_VERSION
          Gem::Version.new(version.to_s)
        end

        def inside_rails_example_group?(node)
          node.each_ancestor(:block)
            .any? { |group| rails_group?(group, spec_types) }
        end

        def spec_types
          @spec_types ||= cop_config['SpecTypes'].to_set(&:to_sym)
        end

        # FIXME: shamelessly borrowed from rubocop-rspec's expect_output.rb
        def inside_example_scope?(node)
          return false if node.nil? || example_group?(node)
          return true if example?(node)
          return RuboCop::RSpec::Hook.new(node).example? if hook?(node)

          inside_example_scope?(node.parent)
        end
      end
    end
  end
end
