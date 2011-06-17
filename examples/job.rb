class ImportantJob
  extend Resque
  extend Resque::Durable

  # How long to wait before the monitor consideres this job failed. Default is 10 minutes.
  self.job_timeout = 20.minutes

  # A custom auditor class. By default it's Resque::Durable::QueueAudit.
  self.auditor = ImportantJobAudit

  # All durable jobs need to have the queue audit as their last argument.
  def self.perform(account_id, audit)
    do_some_expensive_work

    # Need some more time. Update the audit to keep alive for another 20 minutes.
    audit.heartbeat!

    do_more_espensive_work
  end

end
