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
     # Logger.info("Audit: ##{audit.id}")

      super(*args)
    end

    def before_perform_grab_audit(*args)
      guid = args.pop
      audit = QueueAudit.find_by_enqueued_id(guid)
      args << guid
    end

    def after_perform_complete_audit(*args)
      audit = args.pop
      audit.complete!
    end
  end
end
