require 'test_helper'

class MonitorTest < MiniTest::Unit::TestCase

  class TestMonitor
    include Resque::Durable::Monitor

    def slept?
      !@sleep.nil?
    end

    def sleep(duration)
      @sleep = duration
    end

    def sleep_duration
      @sleep
    end

  end

  class FakeAudit

    def self.recover
    end

    def self.cleanup(duration)
    end

  end

  describe 'Monitor' do
    before do
      @monitor = TestMonitor.new(FakeAudit.dup)
      @monitor.expiration = 3.days
    end

    describe 'watch' do

      it 'recovers audits' do
        auditor = @monitor.auditor
        auditor.expects(:recover)
        @monitor.watch
      end

      it 'cleans up expired audits' do
        auditor = @monitor.auditor
        auditor.expects(:cleanup)
        @monitor.watch
      end

    end

    describe 'run' do

      it 'watches audits until stopped' do
        @monitor.stop
        @monitor.expects(:watch)
        @monitor.run
        assert @monitor.slept?
      end

    end

    it 'has a configurable wait duration' do
      @monitor.wait
      assert_equal(1, @monitor.sleep_duration)

      @monitor.wait_duration = 30
      @monitor.wait
      assert_equal(30, @monitor.sleep_duration)
    end

  end

end
