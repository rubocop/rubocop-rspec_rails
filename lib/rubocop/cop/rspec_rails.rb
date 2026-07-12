# frozen_string_literal: true

module RuboCop
  module Cop
    # Cops for the `RSpecRails` department. The department's cops are
    # registered for lazy loading and their files are loaded on demand.
    module RSpecRails
      extend LazyLoader

      register_cop :AvoidSetupHook, "#{__dir__}/rspec_rails/avoid_setup_hook"
      register_cop :HaveHttpStatus, "#{__dir__}/rspec_rails/have_http_status"
      register_cop :HttpStatus, "#{__dir__}/rspec_rails/http_status"
      register_cop :HttpStatusNameConsistency, "#{__dir__}/rspec_rails/http_status_name_consistency"
      register_cop :InferredSpecType, "#{__dir__}/rspec_rails/inferred_spec_type"
      register_cop :MinitestAssertions, "#{__dir__}/rspec_rails/minitest_assertions"
      register_cop :NegationBeValid, "#{__dir__}/rspec_rails/negation_be_valid"
      register_cop :ReceivePerformLater, "#{__dir__}/rspec_rails/receive_perform_later"
      register_cop :TravelAround, "#{__dir__}/rspec_rails/travel_around"
    end
  end
end
