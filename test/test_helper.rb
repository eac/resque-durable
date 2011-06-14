require 'rubygems'
require 'bundler/setup'
Bundler.require(:test)
require 'minitest/autorun'

require 'resque/durable'
require 'active_record'
ActiveRecord::Base.establish_connection(YAML.load_file('test/database.yml')['test'])
require 'test/schema'

module Resque
  module Durable

    class MailQueue

      class << self
        def data=(data)
          @data = data
        end

        def data
          @data
        end

        def pop
          @data.pop
        end

        def enqueue(*payload)
          @data.push(payload)
        end
      end

    end
    class AbstractResqueJob
      def self.enqueue(*args)
        MailQueue.enqueue(*args)
      end
    end

    class MailQueueJob < AbstractResqueJob
      extend Resque::Durable
    end
  end
end


