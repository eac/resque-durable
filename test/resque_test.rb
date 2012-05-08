require File.join(File.dirname(__FILE__), 'test_helper')
require 'resque'

module Resque::Durable
  class ResqueTest < MiniTest::Unit::TestCase
    describe 'With Resque' do
      before do
        $mail_queue_job_results = nil
        MailQueueJob.fail = false
        Resque.redis.del "queue:test_queue"
        QueueAudit.delete_all
      end

      it 'is compatible' do
        assert Resque::Plugin.lint(Resque::Durable)
      end

      describe 'A successful job' do
        it "should work" do
          MailQueueJob.enqueue(:one, :two)
          work_queue(:test_queue)
        end
      end

      describe 'An completed job that is re-enqueued' do
        before do
          Resque::Durable::GUID.stubs(:generate).returns('12345')
          MailQueueJob.enqueue(:one, :two)
        end

        it 'does not get tried again' do
          worked_at = 1.day.ago
          Time.stubs(:now).returns(worked_at)
          work_queue(:test_queue)

          audit = QueueAudit.find_by_enqueued_id('12345')
          assert audit.complete?
          assert_equal worked_at.to_i, audit.completed_at.to_i

          audit.enqueue
          Time.stubs(:now).returns(worked_at + 1.hour)
          work_queue(:test_queue)
          assert_equal worked_at.to_i, audit.reload.completed_at.to_i
        end

      end

      describe 'A failing job' do
        before do
          @ts = 1.hour.ago
          Time.stubs(:now).returns(@ts)
          MailQueueJob.fail = true
          MailQueueJob.enqueue(123, 456)
          work_queue(:test_queue)
          @audit = QueueAudit.find(:all).detect { |j| j.payload == [123, 456] }
        end

        it "should have enqueued a job" do
          assert @audit
        end

        it "should not complete" do
          assert !@audit.complete?
        end

        it "should not be immediately retryable" do
          assert !@audit.retryable?
        end

        it "should eventually be retryable" do
          Time.stubs(:now).returns(@ts + 1.hour)
          assert @audit.retryable?
        end

        describe 'retrying the job' do
          describe 'job succeeding' do
            before do
              MailQueueJob.fail = false
              @audit.enqueue
              work_queue(:test_queue)
              @audit.reload
            end
            it "should be marked as complete" do
              assert @audit.complete?
            end
          end
        end

      end
    end
  end
end
