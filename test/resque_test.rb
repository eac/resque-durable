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

        it "should stamp its timeout_at with time.now" do
          assert_equal Time.now.to_i,  @audit.timeout_at.to_i
        end

        it "should not be immediately retryable" do
          assert !@audit.retryable?
        end

        it "should be retryable in a minute" do
          Time.stubs(:now).returns(@ts + 1.minutes)
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

        it "should backoff exponentially if it keeps failing" do
        end
      end
    end
  end
end
