ActiveRecord::Schema.define(:version => 1) do

  create_table(:durable_queue_audits) do |t|
    t.string   :enqueued_id, :null => false
    t.string   :job_klass,  :null => false
    t.string   :payload,     :null => false
    t.integer  :enqueue_count, :default => 0
    t.datetime :enqueued_at
    t.datetime :completed_at
    t.datetime :timeout_at
    t.timestamps
  end rescue nil
  add_index(:durable_queue_audits, :enqueued_id, :unique => true) rescue nil

end
