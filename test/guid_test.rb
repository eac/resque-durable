require File.join(File.dirname(__FILE__), 'test_helper')

module Resque::Durable
  class GUIDTest < MiniTest::Unit::TestCase

    describe 'GUID generate' do

      it 'has the hostname, process id and current time' do
        hostname     = `hostname`.chomp
        current_time = Time.now
        process_id   = Process.pid

        Timecop.freeze(current_time) do
          assert_equal "#{hostname}/#{process_id}/#{current_time.to_f}", GUID.generate
        end

      end

    end

  end
end
