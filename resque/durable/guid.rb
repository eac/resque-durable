module Resque
  module Durable
    module GUID

      def self.generate
        [ hostname, Process.pid, Time.now.to_f ].join('/')
      end

      def self.hostname
        @hostname ||= `hostname`.chomp
      end

    end
  end
end
