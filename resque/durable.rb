module Resque
  module Durable
    autoload :GUID,       'resque/durable/guid'
    autoload :QueueAudit, 'resque/durable/queue_audit'

    def enqueue(*args)
      audit = QueueAudit.find_or_initialize_by_args(args)
      audit.enqueued!
     # Logger.info("Audit: ##{audit.id}")

      super
    end

    def after_perform_complete_audit(*args)
      enqueued_id = args.last['id']
      audit       = QueueAudit.find_by_enqueued_id(enqueued_id)

      audit.complete!
     # Logger.info("Audit: complete ##{audit.id}")
    end

  end
end
