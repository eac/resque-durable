require 'test_helper'

module Resque::Durable
  class DurableTest < MiniTest::Unit::TestCase

    class DurableQueue < MailQueue
      extend Resque::Durable

    end

    describe 'Durable queue' do
      before do
        QueueAudit.delete_all
        DurableQueue.data = []
      end

      describe 'enqueue' do

        it 'audits the enqueue' do
          GUID.expects(:generate).returns('abc/1/12345')
          DurableQueue.enqueue('hello', {})
          audit = QueueAudit.find_by_enqueued_id('abc/1/12345')

          assert_equal 'abc/1/12345', audit.enqueued_id
          assert_equal [ 'hello', { 'id' => 'abc/1/12345' } ], DurableQueue.pop
        end

      end

      describe 'after perform' do

        it 'completes the audit' do
          GUID.expects(:generate).returns('abc/1/12345')
          DurableQueue.enqueue('hello', {})
          audit = QueueAudit.find_by_enqueued_id('abc/1/12345')
          assert !audit.complete?

          DurableQueue.after_perform_complete_audit('hello', { 'id' => 'abc/1/12345' })
          assert_equal nil, QueueAudit.find_by_enqueued_id('abc/1/12345')
        end

      end

    end

  end
end
