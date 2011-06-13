require 'rubygems'
require 'bundler/setup'
Bundler.require(:test)
require 'minitest/autorun'

require 'resque/durable'
require 'active_record'
ActiveRecord::Base.establish_connection(YAML.load_file('test/database.yml')['test'])
#require 'schema'

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

  end
end
