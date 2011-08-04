module Resque
  module Durable
    autoload :GUID,       'resque/durable/guid'
    autoload :Monitor,    'resque/durable/monitor'
    autoload :QueueAudit, 'resque/durable/queue_audit'

    def self.extended(base)
      base.cattr_accessor :job_timeout
      base.job_timeout = 10.minutes

      base.cattr_accessor :auditor
      base.auditor = QueueAudit
    end

    def enqueue(*args)
      if args.last.is_a?(auditor)
        # the audit-is-re-enqueing case
        audit = args.pop
      else
        audit = build_audit(args)
      end

      args << audit.enqueued_id
      begin
        audit.enqueued!
      rescue Exception => e
        audit_failed(e)
      end

      Resque.enqueue(self, *args)
    rescue Exception => e
      enqueue_failed(e)
    end

    def audit(args)
      audit = auditor.find_by_enqueued_id(args.last)
      audit_failed(ArgumentError.new("Could not find audit: #{args.last}")) if audit.nil?
      audit
    end

    def heartbeat(args)
      if a = audit(args)
        a.heartbeat!
      end
    end

    def around_perform_manage_audit(*args)
      if a = audit(args)
        a.heartbeat!
        return if a.complete?
        yield
        a.complete!
      else
        yield
      end
    end

    def on_failure_set_timeout(exception, *args)
      if a = audit(args)
        a.fail!
      end
    end

    def build_audit(args)
      auditor.initialize_by_klass_and_args(self, args)
    end

    def audit_failed(e)
      raise e
    end

    def enqueue_failed(e)
      raise e
    end

  end
end
