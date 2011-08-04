require File.join(File.dirname(__FILE__), 'test_helper')

module Resque::Durable
  class DurableTest < MiniTest::Unit::TestCase

    describe 'Durable queue' do
      before do
        QueueAudit.delete_all
        GUID.stubs(:generate).returns('abc/1/12345')
        Resque.expects(:enqueue).with(Resque::Durable::MailQueueJob, :foo, :bar, 'abc/1/12345')
        MailQueueJob.enqueue(:foo, :bar)
      end

      describe 'enqueue' do
        it 'creates an audit' do
          audit = QueueAudit.find_by_enqueued_id('abc/1/12345')

          assert_equal 'abc/1/12345', audit.enqueued_id
        end

      end

      describe 'enqueue failure' do
        before do
          QueueAudit.delete_all
          Resque.expects(:enqueue).raises(ArgumentError.new)
        end

        it 'raises an error by default' do
          assert_raises(ArgumentError) do
            MailQueueJob.enqueue(:ka, :boom)
          end
        end

        it 'has overridable exception handling' do
          @queue = MailQueueJob.clone
          def @queue.enqueue_failed(exception)
            @enqueue_failed = true
          end

          def @queue.enqueue_failed?
            @enqueue_failed == true
          end

          @queue.enqueue(:ka, :boom)
          assert @queue.enqueue_failed?
        end

        it 'creates an audit' do
          assert_raises(ArgumentError) do
            MailQueueJob.enqueue(:ka, :boom)
          end
          audit = QueueAudit.find_by_enqueued_id('abc/1/12345')

          assert_equal 'abc/1/12345', audit.enqueued_id
        end

      end

      describe 'a missing audit' do

        it 'is reported with an exception' do
          audit = QueueAudit.find_by_enqueued_id('abc/1/12345')
          audit.destroy
          assert_raises(ArgumentError) do
            MailQueueJob.around_perform_manage_audit('hello', "foo", 'abc/1/12345') {}
          end
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

        it 'does not perform when the audit is already complete' do
          audit = QueueAudit.find_by_enqueued_id('abc/1/12345')
          assert !audit.complete?
          MailQueueJob.around_perform_manage_audit('hello', "foo", 'abc/1/12345') {}
          assert audit.reload.complete?

          MailQueueJob.around_perform_manage_audit('hello', "foo", 'abc/1/12345') do
            assert false, 'Should not have been executed'
          end
        end

      end
    end
  end
end
