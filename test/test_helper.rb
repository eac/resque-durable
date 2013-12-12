require 'rubygems'
require 'bundler/setup'
Bundler.require(:test)
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))                      # test
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../lib'))) # lib

require 'minitest/autorun'
require 'active_record'
require 'resque/durable'

database_config = YAML.load_file(File.join(File.dirname(__FILE__), 'database.yml'))
ActiveRecord::Base.establish_connection(database_config['test'])
ActiveRecord::Base.default_timezone = :utc
require 'schema'

I18n.enforce_available_locales = true

MiniTest::Unit::TestCase.add_teardown_hook { Resque::Durable::QueueAudit.delete_all }
MiniTest::Unit::TestCase.add_teardown_hook do
  Mocha::Mockery.instance.teardown
  Mocha::Mockery.reset_instance
end

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
        raise Exception, "Failing Job!" if self.fail
      end

      cattr_accessor :fail
    end
  end
end

def work_queue(name)
  worker = Resque::Worker.new(name)
  worker.process
end

