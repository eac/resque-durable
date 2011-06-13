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
      # duration
      # enqueue_count
      # enqueued_at
      # updated_at
      # created_at
      class_attribute :default_duration
      self.default_duration = 10.minutes

      validates_length_of   :payload, :in => 1..5000
      validates_presence_of :enqueued_id, :queue_name, :payload

      validates_inclusion_of :duration, :in => 1.minute..1.day

      named_scope :older_than, lambda { |date|
        { :conditions => [ 'created_at > ?', date ] }
      }

      named_scope :failed, lambda {
        { :conditions => [ 'enqueued_at < ?', default_duration.ago.utc ] }
      }

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
        queue.enqueue(payload)
      end

      def enqueued!
        self.enqueued_at    = Time.now.utc
        self.enqueue_count += 1
        save!
      end

      def complete!
        destroy
      end

      def complete?
        destroyed?
      end

      def duration
        super || self.duration = default_duration
      end

      def retryable?
        Time.now > (timeout_at + delay)
      end

      def timeout_at
        enqueued_at + duration
      end

      # 1, 8, 27, 64, 125, 216, etc. minutes.
      def delay
        (enqueue_count ** 3).minutes
      end

    end
  end
end
