---
applyTo: "**/*job.rb,**/queue*.rb,**/solid_queue*.rb,**/recurring.yml"
---
# Solid Queue Guidelines

## Core Concepts
- Solid Queue is a DB-based queuing backend for Active Job in Rails 8
- Uses SQL databases SQLite for job persistence
- Leverages `FOR UPDATE SKIP LOCKED` for non-blocking job polling
- Provides priority queues, concurrency controls, and recurring jobs

## Configuration Best Practices
- Define queues and workers in `config/queue.yml` according to job priorities
- Configure recurring tasks in `config/recurring.yml` for scheduled operations
- Use separate database for queue in production for better performance
- Configure appropriate polling intervals based on job urgency and volume
- Set proper thread counts based on job characteristics and database capacity
- Make sure to add "config.solid_queue.connects_to = { database: { writing: :queue } }" to the development environment
- Ensure that the database.yml file has a separate database for the queue, e.g., "queue: <<: *default database: storage/development_queue.sqlite3 migrations_paths: db/queue_migrate"
- Make sure that "plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"] || Rails.env.development?" is added to the puma configuration files

## Worker Configuration Example
```yaml
# config/queue.yml
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
      concurrency_maintenance_interval: 300
  workers:
    - queues: "*"
      threads: 3
      polling_interval: 2
    - queues: [ real_time, background ]
      threads: 5
      polling_interval: 0.1
      processes: 3
```

## Queue Organization
- Design queues based on job priorities and processing requirements
- Prioritize jobs using both queue order and job priority values
- Use lower priority values for more important jobs (0 is highest priority)
- Specify exact queue names rather than wildcards for optimal performance
- Configure dedicated workers for high-priority queues with lower polling intervals

## Concurrency Controls
- Use `limits_concurrency` to prevent too many jobs of same type from running simultaneously
- Define concurrency scopes with the `key` parameter to group related jobs
- Set appropriate concurrency limits with the `to` parameter (defaults to 1)
- Configure `duration` parameter to automatically release locks after timeout
- Group jobs across classes using the `group` parameter when necessary

```ruby
class MyJob < ApplicationJob
  limits_concurrency to: 2, key: ->(record) { record }, duration: 5.minutes

  def perform(record)
    # Job implementation
  end
end
```

## Recurring Tasks Configuration Example
```yaml
# config/recurring.yml
production:
  daily_cleanup:
    class: CleanupJob
    args: [{ older_than_days: 30 }]
    schedule: every day at 2am
  hourly_report:
    class: GenerateReportJob
    schedule: every hour
  database_maintenance:
    command: "DatabaseMaintenance.run"
    schedule: every sunday at 1am
```

## Job Processing
- Use `bin/jobs` to start the supervisor that manages workers and dispatchers
- Consider the Puma plugin for integrated worker management in production
- Configure appropriate number of worker processes based on server resources
- Set thread count based on database connection pool size (threads ≤ pool_size - 2)
- Monitor job execution through lifecycle hooks for better observability

## Error Handling
- Configure error reporting on your jobs through ApplicationJob
- Use Active Job's `retry_on` and `discard_on` for retrying and discarding jobs
- Implement custom error reporting through rescue_from in ApplicationJob
- Inspect failed jobs through the SolidQueue::FailedExecution model
- Consider mission_control-jobs gem for job monitoring dashboard

## Database Configuration Example
```ruby
# config/database.yml
production:
  primary:
    <<: *default
    database: app_production
    username: app
    password: <%= ENV["APP_DATABASE_PASSWORD"] %>
  queue:
    <<: *default
    database: app_production_queue
    migrations_paths: db/queue_migrate
```

## Performance Optimization
- Use exact queue names instead of wildcards for better polling performance
- Set appropriate batch sizes in dispatchers for efficient job dispatching
- Configure polling intervals based on queue urgency and job volume
- Ensure database indexes are properly maintained
- Set up appropriate connection pool sizes in database.yml

## Lifecycle Hooks
```ruby
# config/initializers/solid_queue.rb
SolidQueue.on_start do |supervisor|
  # Report metrics about supervisor start
end

SolidQueue.on_worker_start do |worker|
  # Configure logging or metrics for worker
  Rails.logger.info "Worker started: #{worker.name} for queues #{worker.queues.join(', ')}"
end
```

## Transactional Integrity
- Be mindful of transactional boundaries when enqueuing jobs
- Use `enqueue_after_transaction_commit = true` for jobs that need data committed first
- Consider keeping Solid Queue in a separate database for clear separation
- Use `after_commit` callbacks for enqueuing jobs that depend on database state
- Understand the implications of moving between queue adapters or databases

## Cleanup and Maintenance
- Set appropriate values for `preserve_finished_jobs` and `clear_finished_jobs_after`
- Create recurring task to clean up finished jobs using `SolidQueue::Job.clear_finished_in_batches`
- Monitor database size and performance, especially for high-volume queues
- Schedule regular maintenance tasks for database optimization
- Configure appropriate retention periods for job history

## Commands

Here are some common commands:
- SolidQueue::Job.count
- SolidQueue::ReadyExecution.count
- SolidQueue::ScheduledExecution.count
- SolidQueue::ClaimedExecution.count
- SolidQueue::FailedExecution.count
- SolidQueue::Job.finished.count
- SolidQueue::FailedExecution.all.map { |fe| { job_id: fe.job_id, error: fe.error, job_class: fe.job.class_name, arguments: fe.job.arguments } }
- SolidQueue::Job.find_by(active_job_id: "your-active-job-id")
