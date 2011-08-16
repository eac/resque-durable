module Resque
  module Durable
    module GUID

      def self.generate
        [ hostname,
          Process.pid,
          Time.now.to_i,
          increment_counter
        ].join('/')
      end

      def self.hostname
        @hostname ||= `hostname`.chomp
      end

      def self.increment_counter
        @counter ||= 0
        @counter += 1
      end

    end
  end
end
