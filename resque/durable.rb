module Resque
  module Durable
    autoload :GUID,       'resque/durable/guid'
    autoload :QueueAudit, 'resque/durable/queue_audit'

    def enqueue(*args)
      if args.last.is_a?(QueueAudit)
        # the audit-is-re-enqueing case
        audit = args.pop
      else
        audit = QueueAudit.initialize_by_klass_and_args(self, args)
      end

      args << audit.enqueued_id
      audit.enqueued!

      Resque.enqueue(self, *args)
    end

    def audit(args)
      QueueAudit.find_by_enqueued_id(args.last)
    end

    def heartbeat(args)
      audit(args).heartbeat!
    end

    def around_perform_manage_audit(*args)
      a = audit(args)
      a.heartbeat!
      return if a.complete?
      yield
      a.complete!
    end

    def on_failure_set_timeout(exception, *args)
      a = audit(args)
      a.fail!
    end

    def self.extended(base)
      base.class_eval { cattr_accessor :job_timeout }
      base.job_timeout = 10.minutes
    end
  end
end
