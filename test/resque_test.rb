require File.join(File.dirname(__FILE__), 'test_helper')
require 'resque'

module Resque::Durable
  class ResqueTest < MiniTest::Unit::TestCase

    describe 'Resque' do
      it 'is compatible' do
        assert Resque::Plugin.lint(Resque::Durable)
      end
    end

    describe 'A sample job' do
      it "should work" do
        MailQueueJob.enqueue(:one, :two)
        work_queue(:test_queue)
        assert($mail_queue_job_results)
      end
    end


  end
end
