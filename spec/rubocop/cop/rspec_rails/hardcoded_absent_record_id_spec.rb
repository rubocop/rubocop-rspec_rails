# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecRails::HardcodedAbsentRecordId do
  let(:cop_config) { { 'MaxId' => 100_000 } }

  it 'registers an offense when a group says the record does not exist' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 123 }
                        ^^^ Use a negative id for a record expected to be absent.
      end
    RUBY

    expect_correction(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { -1 }
      end
    RUBY
  end

  it 'registers an offense for `let!`' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        let!(:user_id) { 123 }
                         ^^^ Use a negative id for a record expected to be absent.
      end
    RUBY
  end

  it 'registers an offense for a bare `id`' do
    expect_offense(<<~RUBY)
      context 'when the record is not found' do
        let(:id) { 7 }
                   ^ Use a negative id for a record expected to be absent.
      end
    RUBY
  end

  it 'registers an offense for a numeric string and keeps it a string' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { '123' }
                        ^^^^^ Use a negative id for a record expected to be absent.
      end
    RUBY

    expect_correction(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { '-1' }
      end
    RUBY
  end

  it 'registers an offense on a `RecordNotFound` assertion alone' do
    expect_offense(<<~RUBY)
      context 'and the state is success' do
        let(:user_id) { 123 }
                        ^^^ Use a negative id for a record expected to be absent.

        it { expect { subject }.to raise_error ActiveRecord::RecordNotFound }
      end
    RUBY
  end

  it 'registers an offense on a `raise_exception` assertion' do
    expect_offense(<<~RUBY)
      context 'and the state is success' do
        let(:user_id) { 123 }
                        ^^^ Use a negative id for a record expected to be absent.

        it { expect { subject }.to raise_exception(ActiveRecord::RecordNotFound) }
      end
    RUBY
  end

  it 'registers an offense on a `:not_found` response assertion' do
    expect_offense(<<~RUBY)
      context 'with an id that was deleted' do
        let(:user_id) { 123 }
                        ^^^ Use a negative id for a record expected to be absent.

        it { expect(response).to have_http_status(:not_found) }
      end
    RUBY
  end

  it 'registers an offense on a numeric 404 assertion' do
    expect_offense(<<~RUBY)
      context 'with an id that was deleted' do
        let(:user_id) { 123 }
                        ^^^ Use a negative id for a record expected to be absent.

        it { expect(response).to have_http_status(404) }
      end
    RUBY
  end

  it 'registers an offense on a `be_not_found` assertion' do
    expect_offense(<<~RUBY)
      context 'with an id that was deleted' do
        let(:user_id) { 123 }
                        ^^^ Use a negative id for a record expected to be absent.

        it { expect(response).to be_not_found }
      end
    RUBY
  end

  it 'does not register an offense for a cross-tenant description' do
    expect_no_offenses(<<~RUBY)
      context 'for another account' do
        let(:requested_account_id) { 2 }
      end
    RUBY
  end

  it 'does not register an offense for a mismatch description' do
    expect_no_offenses(<<~RUBY)
      context 'when the commit does not belong to the merge request' do
        let(:parent_ids) { [1] }
      end
    RUBY
  end

  it 'does not register an offense for a malformed-id description' do
    expect_no_offenses(<<~RUBY)
      context 'with invalid id' do
        let(:invalid_id) { 123 }
      end
    RUBY
  end

  it 'registers an offense for a symbol description' do
    expect_offense(<<~RUBY)
      context :'when the user does not exist' do
        let(:user_id) { 123 }
                        ^^^ Use a negative id for a record expected to be absent.
      end
    RUBY
  end

  it 'registers an offense for an interpolated description' do
    expect_offense(<<~'RUBY')
      context "when the #{model} does not exist" do
        let(:user_id) { 123 }
                        ^^^ Use a negative id for a record expected to be absent.
      end
    RUBY
  end

  it 'registers an offense inside a nested non-group block' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        with_some_wrapper do
          let(:user_id) { 123 }
                          ^^^ Use a negative id for a record expected to be absent.
        end
      end
    RUBY
  end

  it 'registers an offense inside a group written on RSpec explicitly' do
    expect_offense(<<~RUBY)
      RSpec.describe 'when the user does not exist' do
        let(:user_id) { 123 }
                        ^^^ Use a negative id for a record expected to be absent.
      end
    RUBY
  end

  it 'attributes the assertion to the innermost group' do
    expect_offense(<<~RUBY)
      context 'outer' do
        let(:outer_id) { 500 }

        context 'when the user does not exist' do
          let(:user_id) { 123 }
                          ^^^ Use a negative id for a record expected to be absent.
        end
      end
    RUBY
  end

  it 'registers an offense for a lone literal beside real record ids' do
    expect_offense(<<~RUBY)
      context 'with multiple user IDs' do
        let(:user_ids) { [user.id, other_user.id, 99999] }
                                                  ^^^^^ Use a negative id for a record expected to be absent.
      end
    RUBY

    expect_correction(<<~RUBY)
      context 'with multiple user IDs' do
        let(:user_ids) { [user.id, other_user.id, -1] }
      end
    RUBY
  end

  it 'registers an offense for a literal anywhere in the list' do
    expect_offense(<<~RUBY)
      context 'with multiple users provided' do
        let(:user_ids) { [999, user.id] }
                          ^^^ Use a negative id for a record expected to be absent.
      end
    RUBY
  end

  it 'registers an offense for a list the group calls absent' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_ids) { [99999] }
                          ^^^^^ Use a negative id for a record expected to be absent.
      end
    RUBY
  end

  it 'registers an offense for a plural id bound to a scalar' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_ids) { 999 }
                         ^^^ Use a negative id for a record expected to be absent.
      end
    RUBY
  end

  it 'does not register an offense for a negative id' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { -1 }
      end
    RUBY
  end

  it 'does not register an offense for a zero id' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 0 }
      end
    RUBY
  end

  it 'does not register an offense above MaxId' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 9_999_999_999 }
      end
    RUBY
  end

  it 'does not register an offense for a let that is not id-named' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:identifier) { 123 }
      end
    RUBY
  end

  it 'does not register an offense for a non-symbol let name' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let('user_id') { 123 }
      end
    RUBY
  end

  it 'does not register an offense for a reference' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { deleted_user.id }
      end
    RUBY
  end

  it 'does not register an offense for a non-numeric string' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 'abc' }
      end
    RUBY
  end

  it 'does not register an offense for a non-literal body type' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 1.5 }
      end
    RUBY
  end

  it 'does not register an offense for an empty let body' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) {}
      end
    RUBY
  end

  it 'does not register an offense outside any example group' do
    expect_no_offenses(<<~RUBY)
      let(:user_id) { 123 }
    RUBY
  end

  it 'does not register an offense when the description is a constant' do
    expect_no_offenses(<<~RUBY)
      describe User do
        let(:user_id) { 123 }
      end
    RUBY
  end

  it 'does not register an offense for a neutral interpolation' do
    expect_no_offenses(<<~'RUBY')
      context "when #{thing} is here" do
        let(:user_id) { 123 }
      end
    RUBY
  end

  it 'does not register an offense without any absence signal' do
    expect_no_offenses(<<~RUBY)
      context 'when the user is suspended' do
        let(:user_id) { 123 }

        it { expect(response).to have_http_status(:ok) }
      end
    RUBY
  end

  it 'does not register an offense for an unrelated error class' do
    expect_no_offenses(<<~RUBY)
      context 'when the user is suspended' do
        let(:user_id) { 123 }

        it { expect { subject }.to raise_error ArgumentError }
      end
    RUBY
  end

  it 'does not register an offense for a bare `raise_error`' do
    expect_no_offenses(<<~RUBY)
      context 'when the user is suspended' do
        let(:user_id) { 123 }

        it { expect { subject }.to raise_error }
      end
    RUBY
  end

  it 'does not register an offense for `have_http_status` with no argument' do
    expect_no_offenses(<<~RUBY)
      context 'when the user is suspended' do
        let(:user_id) { 123 }

        it { expect(response).to have_http_status }
      end
    RUBY
  end

  it 'does not register an offense for a forbidden response alone' do
    expect_no_offenses(<<~RUBY)
      context 'when the signature header is invalid' do
        let(:external_payout_id) { 12345 }

        it { expect(response).to have_http_status(:forbidden) }
      end
    RUBY
  end

  it 'does not register an offense for an ambiguous "missing" description' do
    expect_no_offenses(<<~RUBY)
      context 'when the signature header is missing' do
        let(:external_payout_id) { 12345 }
      end
    RUBY
  end

  it 'does not register an offense when the group builds that id' do
    expect_no_offenses(<<~RUBY)
      context 'when the cached data does not exist for the card' do
        let(:card_id) { 123 }
        let!(:card) { create(:card, external_card_id: card_id) }
      end
    RUBY
  end

  it 'does not register an offense when a nested group builds it' do
    expect_no_offenses(<<~RUBY)
      context 'when the cached data does not exist for the card' do
        let(:card_id) { 123 }

        context 'and the card exists' do
          let!(:card) { build_stubbed(:card, external_card_id: card_id) }
        end
      end
    RUBY
  end

  it 'does not register an offense when the literal is inlined' do
    expect_no_offenses(<<~RUBY)
      describe 'when the user does not exist' do
        let(:user_id) { 2 }

        before { create(:user, id: 2) }
      end
    RUBY
  end

  it 'registers an offense when the builder references a different id' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 123 }
                        ^^^ Use a negative id for a record expected to be absent.
        let!(:card) { create(:card, owner_id: other_id) }
      end
    RUBY
  end

  it 'registers an offense when the key is not id-like' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 2 }
                        ^ Use a negative id for a record expected to be absent.

        before { create(:user, headcount: 2) }
      end
    RUBY
  end

  it 'registers an offense when the builder carries a different id value' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 2 }
                        ^ Use a negative id for a record expected to be absent.

        before { create(:user, user_id: 3) }
      end
    RUBY
  end

  it 'does not register an offense when the built record carries it' do
    expect_no_offenses(<<~RUBY)
      context 'when the card does not exist' do
        let(:card_id) { 123 }

        before { create(:card, corepro_card_id: 123) }
      end
    RUBY
  end

  it 'registers an offense when the builder only points at the id' do
    expect_offense(<<~RUBY)
      context 'when the account does not exist' do
        let(:account_id) { 1 }
                           ^ Use a negative id for a record expected to be absent.

        before { create(:user, account_id: 1) }
      end
    RUBY
  end

  it 'registers an offense when a receiver builder points at the id' do
    expect_offense(<<~RUBY)
      context 'when the account does not exist' do
        let(:account_id) { 2 }
                           ^ Use a negative id for a record expected to be absent.

        before { User.create!(account_id: 2) }
      end
    RUBY
  end

  it 'does not register an offense when a receiver builder carries it' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 2 }

        before { User.create!(id: 2) }
      end
    RUBY
  end

  it 'registers an offense when a builder takes no arguments' do
    expect_offense(<<~RUBY)
      context 'when the account does not exist' do
        let(:account_id) { 1 }
                           ^ Use a negative id for a record expected to be absent.

        before { described_class.create }
      end
    RUBY
  end

  it 'does not register an offense when `create_pair` builds that id' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 123 }

        before { create_pair(:user, id: 123) }
      end
    RUBY
  end

  it 'registers an offense when the builder hash has a non-literal key' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 2 }
                        ^ Use a negative id for a record expected to be absent.

        before { create(:user, attribute => 2) }
      end
    RUBY
  end

  it 'does not register an offense for a reload assertion' do
    expect_no_offenses(<<~RUBY)
      describe 'the delete task' do
        let(:user_id) { 1 }

        it { expect { record.reload }.to raise_error(ActiveRecord::RecordNotFound) }
      end
    RUBY
  end

  it 'registers an offense when the matcher subject is not a block' do
    expect_offense(<<~RUBY)
      describe 'the delete task' do
        let(:user_id) { 1 }
                        ^ Use a negative id for a record expected to be absent.

        it { expect(result).to raise_error(ActiveRecord::RecordNotFound) }
      end
    RUBY
  end

  it 'registers an offense when the expect block is empty' do
    expect_offense(<<~RUBY)
      describe 'the delete task' do
        let(:user_id) { 1 }
                        ^ Use a negative id for a record expected to be absent.

        it { expect {}.to raise_error(ActiveRecord::RecordNotFound) }
      end
    RUBY
  end

  it 'registers an offense for a bare matcher with no surrounding call' do
    expect_offense(<<~RUBY)
      describe 'the delete task' do
        let(:user_id) { 1 }
                        ^ Use a negative id for a record expected to be absent.

        it { raise_error(ActiveRecord::RecordNotFound) }
      end
    RUBY
  end

  it 'does not register an offense for a group pinning two ids' do
    expect_no_offenses(<<~RUBY)
      context 'when the account does not exist' do
        let(:account_id) { 456 }
        let(:existing_setting_account_id) { 123 }
      end
    RUBY
  end

  it 'registers an offense for a lone id beside a non-collidable one' do
    expect_offense(<<~RUBY)
      context 'when the account does not exist' do
        let(:account_id) { 456 }
                           ^^^ Use a negative id for a record expected to be absent.
        let(:existing_setting_account_id) { -1 }
      end
    RUBY
  end

  it 'registers an offense for a lone id beside an id in a nested group' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 456 }
                        ^^^ Use a negative id for a record expected to be absent.

        context 'and the record is not found' do
          let(:other_id) { 123 }
                           ^^^ Use a negative id for a record expected to be absent.
        end
      end
    RUBY
  end

  it 'does not register an offense for a list with neither signal' do
    expect_no_offenses(<<~RUBY)
      context 'with several users' do
        let(:user_ids) { [999] }
      end
    RUBY
  end

  it 'registers an offense per literal in a list, corrected to differ' do
    expect_offense(<<~RUBY)
      context 'when the users do not exist' do
        let(:user_ids) { [user.id, 999, 1000] }
                                   ^^^ Use a negative id for a record expected to be absent.
                                        ^^^^ Use a negative id for a record expected to be absent.
      end
    RUBY

    expect_correction(<<~RUBY)
      context 'when the users do not exist' do
        let(:user_ids) { [user.id, -1, -2] }
      end
    RUBY
  end

  it 'does not register an offense for a format-validation list' do
    expect_no_offenses(<<~RUBY)
      context 'with several ids' do
        let(:invalid_ids) { ['story', 'story-', '-', '123', ''] }
      end
    RUBY
  end

  it 'does not register an offense for a list of only real record ids' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_ids) { [user.id, other_user.id] }
      end
    RUBY
  end

  it 'does not register an offense for a list whose literal is above MaxId' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_ids) { [user.id, 9999999999] }
      end
    RUBY
  end

  it 'does not register an offense when a list literal is built' do
    expect_no_offenses(<<~RUBY)
      context 'with multiple users' do
        let(:user_ids) { [user.id, 999] }

        before { create(:user, id: 999) }
      end
    RUBY
  end

  it 'does not register an offense under a VCR cassette' do
    expect_no_offenses(<<~RUBY)
      RSpec.describe Controller, vcr: { cassette_name: 'x', match_requests_on: [:method, :uri] } do
        context 'when the user does not exist' do
          let(:user_id) { 11111 }
        end
      end
    RUBY
  end

  it 'does not register an offense under bare `:vcr` metadata' do
    expect_no_offenses(<<~RUBY)
      RSpec.describe Controller, :vcr do
        context 'when the user does not exist' do
          let(:user_id) { 11111 }
        end
      end
    RUBY
  end

  it 'registers an offense under non-VCR metadata' do
    expect_offense(<<~RUBY)
      RSpec.describe Controller, :request, other: { a: 1 } do
        context 'when the user does not exist' do
          let(:user_id) { 11111 }
                          ^^^^^ Use a negative id for a record expected to be absent.
        end
      end
    RUBY
  end

  it 'registers an offense when group metadata has a non-literal key' do
    expect_offense(<<~RUBY)
      RSpec.describe Controller, some_key => 1 do
        context 'when the user does not exist' do
          let(:user_id) { 11111 }
                          ^^^^^ Use a negative id for a record expected to be absent.
        end
      end
    RUBY
  end

  it 'registers an offense beside a let with a non-symbol name' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 123 }
                        ^^^ Use a negative id for a record expected to be absent.
        let('other') { 5 }
      end
    RUBY
  end

  it 'does not register an offense for a block-pass let outside any group' do
    expect_no_offenses(<<~RUBY)
      let(:user_id, &builder)
    RUBY
  end

  it 'does not register an offense for a let with no name' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let { 123 }
      end
    RUBY
  end

  it 'does not register an offense when the group has no description' do
    expect_no_offenses(<<~RUBY)
      describe do
        let(:user_id) { 123 }
      end
    RUBY
  end

  it 'registers an offense beside a let with an empty body' do
    expect_offense(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id) { 123 }
                        ^^^ Use a negative id for a record expected to be absent.
        let(:other_id) {}
      end
    RUBY
  end

  context 'with AllowedNames' do
    let(:cop_config) { { 'AllowedNames' => ['wise_id'] } }

    it 'does not register an offense for an allowed field name' do
      expect_no_offenses(<<~RUBY)
        context 'when the transfer does not exist' do
          let(:wise_id) { 5678 }
        end
      RUBY
    end

    it 'does not register an offense for an allowed name in a list' do
      expect_no_offenses(<<~RUBY)
        context 'when the transfer does not exist' do
          let(:wise_id) { [transfer.id, 5678] }
        end
      RUBY
    end

    it 'still registers an offense for a name that is not allowed' do
      expect_offense(<<~RUBY)
        context 'when the user does not exist' do
          let(:user_id) { 5678 }
                          ^^^^ Use a negative id for a record expected to be absent.
        end
      RUBY
    end
  end

  it 'does not register an offense for a let-shaped call that is not a block' do
    expect_no_offenses(<<~RUBY)
      context 'when the user does not exist' do
        let(:user_id, &builder)
      end
    RUBY
  end
end
