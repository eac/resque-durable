require 'resque/durable'

# This process will run in a loop re-enqueuing and removing old audits.
# This is a very lightweight dispatcher. Don't run more than one of these or failed jobs will be double-enqueued.
class DurableMonitor
  include Resque::Durable::Monitor
end

monitor = DurableMonitor.new(Resque::Durable::QueueAudit)

# How long to keep an audit around before it's removed.
monitor.expiration = 3.days
monitor.run
