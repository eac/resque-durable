require 'test_helper'


module Resque::Durable
  class QueueAuditTest < MiniTest::Unit::TestCase

    describe 'Queue Audit' do
      after do
        QueueAudit.delete_all
      end

      before do
        @queue = MailQueue
        @queue.data = []

        @audit = QueueAudit.new.tap do |audit|
          audit.queue       = @queue
          audit.payload     = [ 'hello', { 'id' => Time.now.to_f } ]
        end
      end

      describe 'find_or_initialize_by_args' do

        it 'finds the audit when the enqueued id is available' do
          @audit.save!
          assert @audit.enqueued_id
          audit = QueueAudit.find_or_initialize_by_args(@audit.payload)

          assert_equal @audit, audit
        end

        it 'builds an audit when no enqueued id is available' do
          GUID.expects(:generate).returns('1/2/3')
          audit = QueueAudit.find_or_initialize_by_args([ 'new', {} ])
          assert audit.new_record?
          assert_equal '1/2/3', audit.enqueued_id
          audit.save!
        end

      end

      describe 'complete!' do

        it 'destroys the audit' do
          @audit.save!
          assert !@audit.destroyed?
          assert !@audit.complete?
          @audit.complete!

          assert_equal true, @audit.complete?
          assert_equal true, @audit.destroyed?
        end

      end

      describe 'older than' do
        before do
          Timecop.freeze(24.hours.ago) do
            @audit.save!
          end
        end

        it 'provides audits older than the given date' do
          assert_equal [ @audit ], QueueAudit.older_than(25.hours.ago)
        end

        it 'does not provide audits newer than the given date' do
          assert_equal [], QueueAudit.older_than(23.hours.ago)
        end

      end

      describe 'failed' do
        before do
          @audit.enqueued!
        end

        it 'provides audits enqueued for more than than the expected run duration' do
          Timecop.freeze(@audit.duration.from_now + 1.second) do
            assert_equal [ @audit ], QueueAudit.failed
          end
        end

        it 'does not provides audits enqueued less than the expected run duration' do
          Timecop.freeze(@audit.duration.from_now - 1.second) do
            assert_equal [], QueueAudit.failed
          end
        end

      end

      describe 'enqueue' do

        it 'sends the payload to the queue' do
          assert_equal nil, @queue.pop
          @audit.enqueue
          assert_equal @audit.payload, @queue.pop
        end

      end

      describe 'enqueued!' do

        it 'increments the enqueue count' do
          assert_equal 0, @audit.enqueue_count
          @audit.enqueued!
          assert_equal 1, @audit.enqueue_count
        end

        it 'updates the enqueued timestamp' do
          an_hour_ago = 1.hour.ago
          Timecop.freeze(an_hour_ago) do
            @audit.enqueued!
          end

          assert_equal an_hour_ago, @audit.enqueued_at
        end

      end

      describe 'retryable?' do

        it 'checks if the expected run duration with delay is exceeded' do
          @audit.enqueued!
          assert_equal 1.minute,   @audit.delay
          assert_equal 10.minutes, @audit.duration
          assert_equal false, @audit.retryable?

          Timecop.freeze(Time.now + 10.minutes) do
            assert_equal false, @audit.retryable?
          end

          Timecop.freeze(Time.now + 11.minutes) do
            assert_equal true, @audit.retryable?
          end

          Timecop.freeze(1.year.from_now) do
            assert_equal true, @audit.retryable?
          end
        end

      end

      describe 'queue' do

        it 'is the queue name converted into a constant' do
          audit = QueueAudit.new(:queue_name => MailQueue.name)
          assert_equal MailQueue, audit.queue
        end

      end

      it 'has an exponential delay based on enqueue attempts' do
        @audit.enqueued!
        assert_equal 1.minute,   @audit.delay

        @audit.enqueued!
        assert_equal 8.minutes,  @audit.delay

        @audit.enqueued!
        assert_equal 27.minutes, @audit.delay
      end

    end

  end
end
