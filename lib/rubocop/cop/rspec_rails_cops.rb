require_relative 'rspec/capybara/current_path_expectation'
require_relative 'rspec/capybara/feature_methods'

require_relative 'rspec/factory_bot/attribute_defined_statically'
require_relative 'rspec/factory_bot/create_list'

begin
  require_relative 'rspec/rails/http_status'
rescue LoadError # rubocop:disable Lint/HandleExceptions
  # Rails/HttpStatus cannot be loaded if rack/utils is unavailable.
end

require_relative 'rspec/align_left_let_brace'
require_relative 'rspec/align_right_let_brace'
require_relative 'rspec/any_instance'
require_relative 'rspec/around_block'
require_relative 'rspec/be'
require_relative 'rspec/be_eql'
require_relative 'rspec/before_after_all'
require_relative 'rspec/context_wording'
require_relative 'rspec/describe_class'
require_relative 'rspec/describe_method'
require_relative 'rspec/describe_symbol'
require_relative 'rspec/described_class'
require_relative 'rspec/empty_example_group'
require_relative 'rspec/empty_line_after_example_group'
require_relative 'rspec/empty_line_after_final_let'
require_relative 'rspec/empty_line_after_hook'
require_relative 'rspec/empty_line_after_subject'
require_relative 'rspec/example_length'
require_relative 'rspec/example_without_description'
require_relative 'rspec/example_wording'
require_relative 'rspec/expect_actual'
require_relative 'rspec/expect_change'
require_relative 'rspec/expect_in_hook'
require_relative 'rspec/expect_output'
require_relative 'rspec/file_path'
require_relative 'rspec/focus'
require_relative 'rspec/hook_argument'
require_relative 'rspec/implicit_expect'
require_relative 'rspec/implicit_subject'
require_relative 'rspec/instance_spy'
require_relative 'rspec/instance_variable'
require_relative 'rspec/invalid_predicate_matcher'
require_relative 'rspec/it_behaves_like'
require_relative 'rspec/iterated_expectation'
require_relative 'rspec/leading_subject'
require_relative 'rspec/let_before_examples'
require_relative 'rspec/let_setup'
require_relative 'rspec/message_chain'
require_relative 'rspec/message_expectation'
require_relative 'rspec/message_spies'
require_relative 'rspec/missing_example_group_argument'
require_relative 'rspec/multiple_describes'
require_relative 'rspec/multiple_expectations'
require_relative 'rspec/multiple_subjects'
require_relative 'rspec/named_subject'
require_relative 'rspec/nested_groups'
require_relative 'rspec/not_to_not'
require_relative 'rspec/overwriting_setup'
require_relative 'rspec/pending'
require_relative 'rspec/predicate_matcher'
require_relative 'rspec/receive_counts'
require_relative 'rspec/receive_never'
require_relative 'rspec/repeated_description'
require_relative 'rspec/repeated_example'
require_relative 'rspec/return_from_stub'
require_relative 'rspec/scattered_let'
require_relative 'rspec/scattered_setup'
require_relative 'rspec/shared_context'
require_relative 'rspec/shared_examples'
require_relative 'rspec/single_argument_message_chain'
require_relative 'rspec/subject_stub'
require_relative 'rspec/verified_doubles'
require_relative 'rspec/void_expect'
