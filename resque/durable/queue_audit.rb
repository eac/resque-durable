require 'active_record'
require 'active_support/core_ext/class'

module Resque
  module Durable
    class QueueAudit < ActiveRecord::Base
      set_table_name :durable_queue_audits
      # id
      # enqueued_id
      # queue_name
      # payload
      # enqueue_count
      # enqueued_at
      # completed_at
      # timeout_at
      # updated_at
      # created_at
      class_attribute :duration
      self.duration = 10.minutes

      validates_length_of   :payload, :in => 1..5000
      validates_presence_of :enqueued_id, :queue_name, :payload

      validates_inclusion_of :duration, :in => 1.minute..3.hours

      named_scope :older_than, lambda { |date|
        { :conditions => [ 'created_at > ?', date ] }
      }

      named_scope :failed, lambda {
        { :conditions => [ 'completed_at is null AND timeout_at < ?', Time.now.utc ] }
      }

      named_scope :complete, lambda {
        { :conditions => 'completed_at is not null' }
      }

      module Recovery

        def recover
          failed.find_each { |audit| audit.enqueue if audit.retryable? }
        end

        def cleanup(date)
          older_than(date).destroy_all
        end

      end
      extend Recovery

      def self.find_or_initialize_by_args(args)
        params = args.last

        if id = params['id']
          find_by_enqueued_id(id)
        else
          args.last['id'] = GUID.generate
          new(:queue => self, :payload => args)
        end
      end

      def payload
        ActiveSupport::JSON.decode(super)
      end

      def payload=(value)
        self.enqueued_id = value.last['id']
        super value.to_json
      end

      def queue=(klass)
        self.queue_name = klass.name
      end

      def queue
        @queue ||= queue_name.constantize
      end

      def enqueue
        queue.enqueue(*payload)
      end

      def enqueued!
        self.enqueued_at    = Time.now.utc
        self.timeout_at     = enqueued_at + duration
        self.enqueue_count += 1
        save!
      end

      def complete!
        self.completed_at = Time.now.utc
        save!
      end

      def complete?
        completed_at.present?
      end

      def retryable?
        Time.now > (timeout_at + delay)
      end

      # 1, 8, 27, 64, 125, 216, etc. minutes.
      def delay
        (enqueue_count ** 3).minutes
      end

    end
  end
end
