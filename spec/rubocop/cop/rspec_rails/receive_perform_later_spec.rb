# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecRails::ReceivePerformLater do
  it 'registers an offense when using ' \
     '`expect(Job).to receive(:perform_later)`' do
    expect_offense(<<~RUBY)
      it 'enqueues a job' do
        expect(MyJob).to receive(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
        do_something
      end
    RUBY
  end

  it 'registers an offense when using ' \
     '`expect(Job).not_to receive(:perform_later)`' do
    expect_offense(<<~RUBY)
      it 'does not enqueue a job' do
        expect(MyJob).not_to receive(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).not_to receive(:perform_later)`.
        do_something
      end
    RUBY
  end

  it 'registers an offense when using ' \
     '`expect(Job).to_not receive(:perform_later)`' do
    expect_offense(<<~RUBY)
      it 'does not enqueue a job' do
        expect(MyJob).to_not receive(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to_not receive(:perform_later)`.
        do_something
      end
    RUBY
  end

  it 'registers an offense when using ' \
     '`expect(Job).to receive(:perform_later).with(...)`' do
    expect_offense(<<~RUBY)
      it 'enqueues a job with arguments' do
        expect(MyJob).to receive(:perform_later).with(user, order)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
        do_something
      end
    RUBY
  end

  it 'registers an offense when using ' \
     '`expect(Job).to receive(:perform_later).with(keyword:)`' do
    expect_offense(<<~RUBY)
      it 'enqueues a job with keyword arguments' do
        expect(MyJob).to receive(:perform_later).with(user_id: 1)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
        do_something
      end
    RUBY
  end

  it 'registers an offense when using ' \
     '`expect(Job).to receive(:perform_later).with(...).and_return(...)`' do
    expect_offense(<<~RUBY)
      it 'enqueues a job with chained methods' do
        expect(MyJob).to receive(:perform_later).with(user).and_return(true)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
        do_something
      end
    RUBY
  end

  it 'registers an offense when using ' \
     '`expect(Job).to have_received(:perform_later)`' do
    expect_offense(<<~RUBY)
      it 'enqueues a job' do
        allow(MyJob).to receive(:perform_later)
        do_something
        expect(MyJob).to have_received(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to have_received(:perform_later)`.
      end
    RUBY
  end

  it 'registers an offense when using ' \
     '`expect(Job).to have_received(:perform_later).with(...)`' do
    expect_offense(<<~RUBY)
      it 'enqueues a job with arguments' do
        allow(MyJob).to receive(:perform_later)
        do_something
        expect(MyJob).to have_received(:perform_later).with(user)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to have_received(:perform_later)`.
      end
    RUBY
  end

  it 'registers an offense when using ' \
     '`expect(Job).not_to have_received(:perform_later)`' do
    expect_offense(<<~RUBY)
      it 'does not enqueue a job' do
        allow(MyJob).to receive(:perform_later)
        do_something
        expect(MyJob).not_to have_received(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).not_to have_received(:perform_later)`.
      end
    RUBY
  end

  it 'registers an offense when using ' \
     '`expect(Job).to_not have_received(:perform_later)`' do
    expect_offense(<<~RUBY)
      it 'does not enqueue a job' do
        allow(MyJob).to receive(:perform_later)
        do_something
        expect(MyJob).to_not have_received(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to_not have_received(:perform_later)`.
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`allow(Job).to receive(:perform_later)`' do
    expect_no_offenses(<<~RUBY)
      it 'allows job enqueuing' do
        allow(MyJob).to receive(:perform_later)
        do_something
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`allow(Job).to receive(:perform_later).with(...)`' do
    expect_no_offenses(<<~RUBY)
      it 'allows job enqueuing with args' do
        allow(MyJob).to receive(:perform_later).with(user)
        do_something
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`allow(Job).to receive(:perform_later).and_return(...)`' do
    expect_no_offenses(<<~RUBY)
      it 'allows job enqueuing with return value' do
        allow(MyJob).to receive(:perform_later).and_return(job_instance)
        do_something
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`expect { ... }.to have_enqueued_job(Job)`' do
    expect_no_offenses(<<~RUBY)
      it 'enqueues a job' do
        expect { do_something }.to have_enqueued_job(MyJob)
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`expect { ... }.to have_enqueued_job(Job).with(...)`' do
    expect_no_offenses(<<~RUBY)
      it 'enqueues a job with arguments' do
        expect { do_something }.to have_enqueued_job(MyJob).with(user, order)
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`expect { ... }.to have_enqueued_job(Job)` with chained matchers' do
    expect_no_offenses(<<~RUBY)
      it 'enqueues a job with options' do
        expect { do_something }
          .to have_enqueued_job(MyJob)
          .on_queue('mailers')
          .at(Date.tomorrow.noon)
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`expect { ... }.not_to have_enqueued_job(Job)`' do
    expect_no_offenses(<<~RUBY)
      it 'does not enqueue a job' do
        expect { do_something }.not_to have_enqueued_job(MyJob)
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`expect { ... }.to_not have_enqueued_job(Job)`' do
    expect_no_offenses(<<~RUBY)
      it 'does not enqueue a job' do
        expect { do_something }.to_not have_enqueued_job(MyJob)
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`expect(Job).to receive(:perform_now)`' do
    expect_no_offenses(<<~RUBY)
      it 'performs a job' do
        expect(MyJob).to receive(:perform_now)
        do_something
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`expect(Job).to receive(:other_method)`' do
    expect_no_offenses(<<~RUBY)
      it 'calls some method' do
        expect(MyJob).to receive(:some_method)
        do_something
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`expect(Job).to have_received(:other_method)`' do
    expect_no_offenses(<<~RUBY)
      it 'has received some method' do
        allow(MyJob).to receive(:other_method)
        do_something
        expect(MyJob).to have_received(:other_method)
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`expect(instance).to receive(:perform_later)`' do
    expect_no_offenses(<<~RUBY)
      it 'receives a method' do
        expect(instance).to receive(:perform_later)
        instance.perform_later
      end
    RUBY
  end

  it 'does not register an offense when using ' \
     '`expect(variable).to receive(:perform_later)`' do
    expect_no_offenses(<<~RUBY)
      it 'receives a method on variable' do
        job = MyJob.new
        expect(job).to receive(:perform_later)
        job.perform_later
      end
    RUBY
  end

  it 'registers an offense for namespaced job class' do
    expect_offense(<<~RUBY)
      it 'enqueues a namespaced job' do
        expect(Jobs::MyJob).to receive(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(Jobs::MyJob)` over `expect(Jobs::MyJob).to receive(:perform_later)`.
        do_something
      end
    RUBY
  end

  it 'registers an offense for deeply nested job class' do
    expect_offense(<<~RUBY)
      it 'enqueues a deeply nested job' do
        expect(Company::Jobs::MyJob).to receive(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(Company::Jobs::MyJob)` over `expect(Company::Jobs::MyJob).to receive(:perform_later)`.
        do_something
      end
    RUBY
  end

  it 'does not register an offense when parent is not a send node' do
    expect_no_offenses(<<~RUBY)
      it 'handles non-send parent' do
        receive(:perform_later)
      end
    RUBY
  end

  it 'does not register an offense when to_node receiver is nil' do
    expect_no_offenses(<<~RUBY)
      it 'handles missing receiver' do
        to receive(:perform_later)
      end
    RUBY
  end

  it 'does not register an offense when expect has no arguments' do
    expect_no_offenses(<<~RUBY)
      it 'handles expect without args' do
        expect().to receive(:perform_later)
      end
    RUBY
  end

  it 'does not register an offense when job_class is not a constant' do
    expect_no_offenses(<<~RUBY)
      it 'handles non-constant job class' do
        job_class = MyJob
        expect(job_class).to receive(:perform_later)
      end
    RUBY
  end

  it 'registers an offense with expect and to' do
    expect_offense(<<~RUBY)
      it 'uses expect and to' do
        expect(MyJob).to receive(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
      end
    RUBY
  end

  it 'registers an offense with expect and not_to' do
    expect_offense(<<~RUBY)
      it 'uses expect and not_to' do
        expect(MyJob).not_to receive(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).not_to receive(:perform_later)`.
      end
    RUBY
  end

  it 'registers an offense with expect and to_not' do
    expect_offense(<<~RUBY)
      it 'uses expect and to_not' do
        expect(MyJob).to_not receive(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to_not receive(:perform_later)`.
      end
    RUBY
  end

  it 'registers an offense with allow and have_received' do
    expect_offense(<<~RUBY)
      it 'uses allow and have_received' do
        allow(MyJob).to receive(:perform_later)
        MyJob.perform_later
        expect(MyJob).to have_received(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to have_received(:perform_later)`.
      end
    RUBY
  end

  it 'does not register an offense with allow and receive (no expect)' do
    expect_no_offenses(<<~RUBY)
      it 'uses allow and receive only' do
        allow(MyJob).to receive(:perform_later)
        MyJob.perform_later
      end
    RUBY
  end

  it 'registers offenses for multiple jobs' do
    expect_offense(<<~RUBY)
      it 'enqueues multiple jobs' do
        expect(FirstJob).to receive(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(FirstJob)` over `expect(FirstJob).to receive(:perform_later)`.
        expect(SecondJob).to receive(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(SecondJob)` over `expect(SecondJob).to receive(:perform_later)`.
        do_something
      end
    RUBY
  end

  it 'does not register an offense ' \
     'when no runner node is found' do
    expect_no_offenses(<<~RUBY)
      it 'handles case where no runner is found' do
        SomeClass.method_chain.receive(:perform_later)
      end
    RUBY
  end

  it 'does not register an offense ' \
     'when parent becomes nil in search' do
    expect_no_offenses(<<~RUBY)
      it 'handles nil parent case' do
        receive(:perform_later)
      end
    RUBY
  end

  it 'registers offense for simple case ' \
     'without method chaining' do
    expect_offense(<<~RUBY)
      it 'simple case' do
        expect(MyJob).to receive(:perform_later)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
      end
    RUBY
  end

  it 'registers offense when parent is not send_type' do
    expect_offense(<<~RUBY)
      it 'parent not send type' do
        result = (expect(MyJob).to receive(:perform_later))
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
      end
    RUBY
  end

  it 'registers offense with multi-level method chaining' do
    expect_offense(<<~RUBY)
      it 'multi level chaining' do
        expect(MyJob).to receive(:perform_later).with(arg1).with(arg2).and_return(value)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
      end
    RUBY
  end

  it 'registers offense when assigned to variable' do
    expect_offense(<<~RUBY)
      it 'assignment context' do
        expectation = expect(MyJob).to receive(:perform_later)
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
      end
    RUBY
  end

  it 'registers offense when nested in method call' do
    expect_offense(<<~RUBY)
      it 'tests parent.receiver != current early exit' do
        other_method(expect(MyJob).to receive(:perform_later))
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
      end
    RUBY
  end

  it 'registers offense in begin block with semicolon' do
    expect_offense(<<~RUBY)
      it 'parent not send type in find_offense_node' do
        result = (expect(MyJob).to receive(:perform_later); other_code)
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
      end
    RUBY
  end

  it 'registers offense with chaining after expectation' do
    expect_offense(<<~RUBY)
      it 'chaining after to' do
        result = expect(MyJob).to(receive(:perform_later)).tap { |x| x }
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
      end
    RUBY
  end

  it 'registers offense with deeply nested method chain' do
    # This tests the case where find_offense_range traverses up
    # until it reaches a node whose parent is nil
    expect_offense(<<~RUBY)
      expect(MyJob).to(receive(:perform_later)).foo.bar.baz
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `expect { ... }.to have_enqueued_job(MyJob)` over `expect(MyJob).to receive(:perform_later)`.
    RUBY
  end
end
