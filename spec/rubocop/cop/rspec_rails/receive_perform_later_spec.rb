# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecRails::ReceivePerformLater do
  context 'when using expect with receive(:perform_later)' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        it 'enqueues a job' do
          expect(MyJob).to receive(:perform_later)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
          do_something
        end
      RUBY
    end

    it 'registers an offense with not_to' do
      expect_offense(<<~RUBY)
        it 'does not enqueue a job' do
          expect(MyJob).not_to receive(:perform_later)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).not_to receive(:perform_later)`.
          do_something
        end
      RUBY
    end

    it 'registers an offense with to_not' do
      expect_offense(<<~RUBY)
        it 'does not enqueue a job' do
          expect(MyJob).to_not receive(:perform_later)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to_not receive(:perform_later)`.
          do_something
        end
      RUBY
    end
  end

  context 'when using expect with receive(:perform_later).with()' do
    it 'registers an offense for receive with arguments' do
      expect_offense(<<~RUBY)
        it 'enqueues a job with arguments' do
          expect(MyJob).to receive(:perform_later).with(user, order)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
          do_something
        end
      RUBY
    end

    it 'registers an offense for receive with keyword arguments' do
      expect_offense(<<~RUBY)
        it 'enqueues a job with keyword arguments' do
          expect(MyJob).to receive(:perform_later).with(user_id: 1)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
          do_something
        end
      RUBY
    end
  end

  context 'when using allow with have_received(:perform_later)' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        it 'enqueues a job' do
          allow(MyJob).to receive(:perform_later)
          do_something
          expect(MyJob).to have_received(:perform_later)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to have_received(:perform_later)`.
        end
      RUBY
    end

    it 'registers an offense with arguments' do
      expect_offense(<<~RUBY)
        it 'enqueues a job with arguments' do
          allow(MyJob).to receive(:perform_later)
          do_something
          expect(MyJob).to have_received(:perform_later).with(user)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to have_received(:perform_later)`.
        end
      RUBY
    end
  end

  context 'when using allow with receive(:perform_later)' do
    it 'does not register an offense for allow alone' do
      expect_no_offenses(<<~RUBY)
        it 'allows job enqueuing' do
          allow(MyJob).to receive(:perform_later)
          do_something
        end
      RUBY
    end
  end

  context 'when using have_enqueued_job matcher' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        it 'enqueues a job' do
          expect { do_something }.to have_enqueued_job(MyJob)
        end
      RUBY
    end

    it 'does not register an offense with arguments' do
      expect_no_offenses(<<~RUBY)
        it 'enqueues a job with arguments' do
          expect { do_something }.to have_enqueued_job(MyJob).with(user, order)
        end
      RUBY
    end

    it 'does not register an offense with queue and timing' do
      expect_no_offenses(<<~RUBY)
        it 'enqueues a job with options' do
          expect { do_something }
            .to have_enqueued_job(MyJob)
            .on_queue('mailers')
            .at(Date.tomorrow.noon)
        end
      RUBY
    end
  end

  context 'when using receive with other methods' do
    it 'does not register an offense for receive(:perform_now)' do
      expect_no_offenses(<<~RUBY)
        it 'performs a job' do
          expect(MyJob).to receive(:perform_now)
          do_something
        end
      RUBY
    end

    it 'does not register an offense for receive(:some_method)' do
      expect_no_offenses(<<~RUBY)
        it 'calls some method' do
          expect(MyJob).to receive(:some_method)
          do_something
        end
      RUBY
    end
  end

  context 'when using receive on non-job objects' do
    it 'does not register an offense for instance methods' do
      expect_no_offenses(<<~RUBY)
        it 'receives a method' do
          expect(instance).to receive(:perform_later)
          instance.perform_later
        end
      RUBY
    end
  end
end
