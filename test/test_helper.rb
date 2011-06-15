require 'rubygems'
require 'bundler/setup'
Bundler.require(:test)
require 'minitest/autorun'

require File.join(File.dirname(__FILE__), '../resque/durable')
require 'active_record'
ActiveRecord::Base.establish_connection(YAML.load_file(File.join(File.dirname(__FILE__),'database.yml'))['test'])
ActiveRecord::Base.establish_connection(YAML.load_file(File.join(File.dirname(__FILE__),'database.yml'))['test'])
require File.join(File.dirname(__FILE__), 'schema')

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

    class MailQueueJob
      extend Resque::Durable
      @queue = :test_queue
      def self.perform(one, two, audit)
        $mail_queue_job_results = true
      end
    end
  end
end

def work_queue(name)
  job = Resque.reserve(name)
  job.perform
end


