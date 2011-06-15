require File.join(File.dirname(__FILE__), 'test_helper')

module Resque::Durable
  class DurableTest < MiniTest::Unit::TestCase

    describe 'Durable queue' do
      before do
        QueueAudit.delete_all
        GUID.expects(:generate).returns('abc/1/12345')
        Resque.expects(:enqueue).with(Resque::Durable::MailQueueJob, :foo, :bar, 'abc/1/12345')
        MailQueueJob.enqueue(:foo, :bar)
      end

      describe 'enqueue' do
        it 'creates an audit' do
          audit = QueueAudit.find_by_enqueued_id('abc/1/12345')

          assert_equal 'abc/1/12345', audit.enqueued_id
        end

      end

      describe 'around perform' do
        it 'completes the audit' do
          audit = QueueAudit.find_by_enqueued_id('abc/1/12345')
          assert !audit.complete?

          MailQueueJob.around_perform_manage_audit('hello', "foo", 'abc/1/12345') {}

          audit = QueueAudit.find_by_enqueued_id('abc/1/12345')
          assert audit.complete?
        end

        it 'should not complete on failure' do
          audit = QueueAudit.find_by_enqueued_id('abc/1/12345')
          assert !audit.complete?

          MailQueueJob.around_perform_manage_audit('hello', "foo", 'abc/1/12345') { raise } rescue nil

          audit.reload
          assert !audit.complete?
        end

        it 'should be retryable the first minute after failure' do
          audit = QueueAudit.find_by_enqueued_id('abc/1/12345')
          assert !audit.complete?

          ts = 1.hour.ago
          Timecop.freeze(ts) do
            MailQueueJob.around_perform_manage_audit('hello', "foo", 'abc/1/12345') { raise } rescue nil
          end

          audit.reload
          assert_equal ts, audit.timeout_at

          Timecop.freeze(ts - 5.minutes) do
            assert audit.retryable?
          end
        end
      end
    end
  end
end
