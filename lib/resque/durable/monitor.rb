module Resque
  module Durable
    module Monitor

      attr_accessor :audit, :expiration

      def initialize(audit)
        @audit = audit
      end

      def watch
        audit.recover
        audit.cleanup(expiration.ago)
      end

      def run
        install_signal_handlers

        loop do
          watch
          wait
          break if @stopped
        end
      end

      def wait
        sleep(1)
      end

      def install_signal_handlers
        trap('TERM') { stop }
        trap('INT')  { stop }
      end

      def stop
        puts 'Stopping...'
        @stopped = true
      end

    end

  end
end
