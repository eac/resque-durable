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
      DEFAULT_DURATION = 10.minutes

      validates_length_of    :payload_before_type_cast, :in => 1..5000

      validates_inclusion_of :duration, :in => 1.minute..3.hours

      named_scope :older_than, lambda { |date|
        { :conditions => [ 'created_at < ?', date ] }
      }

      named_scope :failed, lambda {
        { :conditions => [ 'completed_at is null AND timeout_at < ?', Time.now ] }
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


      def self.initialize_by_klass_and_args(job_klass, args)
        new(:job_klass => job_klass, :payload => args, :enqueued_id => GUID.generate)
      end

      def job_klass
        read_attribute(:job_klass).constantize
      end

      def job_klass=(klass)
        write_attribute(:job_klass, klass.to_s)
      end

      def payload
        ActiveSupport::JSON.decode(super)
      end

      def payload=(value)
        super value.to_json
      end

      def queue
        Resque.queue_from_class(job_klass)
      end

      def enqueue
        job_klass.enqueue(*(payload.push(self)))
      end

      def duration
        job_klass.job_timeout
      end

      def heartbeat!
        update_attribute(:timeout_at, Time.now + duration)
      end

      def fail!
        update_attribute(:timeout_at, Time.now)
      end

      def enqueued!
        self.enqueued_at    = Time.now
        self.timeout_at     = enqueued_at + duration
        self.enqueue_count += 1
        save!
      end

      def complete!
        self.completed_at = Time.now
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
