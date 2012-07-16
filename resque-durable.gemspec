Gem::Specification.new do |s|
  s.name     = 'resque-durable'
  s.version  = '1.0.1'
  s.authors  = [ 'Eric Chapweske', 'Ben Osheroff' ]
  s.summary  = 'Resque queue backed by database audits, with automatic retry'
  s.files    = [
    'lib/resque/durable.rb',
    'lib/resque/durable/guid.rb',
    'lib/resque/durable/monitor.rb',
    'lib/resque/durable/queue_audit.rb'
  ]
end
