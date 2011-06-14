require File.join(File.dirname(__FILE__), 'test_helper')
require 'resque'

module Resque::Durable
  class ResqueTest < MiniTest::Unit::TestCase

    describe 'Resque' do
      it 'is compatible' do
        assert Resque::Plugin.lint(Resque::Durable)
      end
    end

  end
end
