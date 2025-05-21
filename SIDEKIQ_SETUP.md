# Sidekiq Setup

This document explains how Sidekiq has been set up for background job processing.

## What's Been Installed

- **Sidekiq gem (v6.5.x)**: For background job processing
- **Redis (v5.0.x)**: Required for Sidekiq to store job data

## Configuration Files

1. **config/initializers/sidekiq.rb**: Configures Sidekiq client and server
2. **config/sidekiq.yml**: Specifies Sidekiq queue settings and concurrency
3. **app/jobs/sample_job.rb**: A simple test job for Sidekiq
4. **app/jobs/sample_active_job.rb**: A sample ActiveJob that utilizes Sidekiq

## How to Use

### Starting Services

1. **Start Redis first**:
   ```
   Start-Process -FilePath ".\redis-5.0\redis-server.exe"
   ```

2. **Start Sidekiq worker**:
   ```
   bundle exec sidekiq
   ```

3. **Start Rails server**:
   ```
   bundle exec rails server
   ```

### Accessing the Dashboard

The Sidekiq web dashboard is available at `/sidekiq`.
In development mode, it's accessible without authentication.
In production, it uses HTTP Basic Auth with username "admin" and password "password".

### Testing Jobs

You can enqueue a test job with:

```ruby
SampleJob.perform_async('test_parameter', 123)
# or using ActiveJob
SampleActiveJob.perform_later('test_parameter', 123)
```

## Compatibility Notes

- We're using Sidekiq 6.5.x with Redis 5.0.x for compatibility.
- Sidekiq 7.x requires Redis 6.0+ with HELLO command support.
- On Windows, Redis 5.0.x is the most recent stable version.

## Troubleshooting

1. **Connection issues**: Ensure Redis is running (`.\redis-5.0\redis-cli ping` should return "PONG")
2. **Version compatibility**: Verify Redis version using `.\redis-5.0\redis-cli info server`
3. **Web UI errors**: Check Rails log for route or authentication issues
4. **If needed**, restart both Redis and Sidekiq:
   ```
   # Stop all Redis servers
   Get-Process -Name redis-server -ErrorAction SilentlyContinue | Stop-Process -Force
   
   # Start Redis 5.0
   Start-Process -FilePath ".\redis-5.0\redis-server.exe"
   
   # Restart Sidekiq
   bundle exec sidekiq
   ```

## Next Steps

1. Implement business logic for floorplan processing jobs
2. Create job classes specific to your floorplan processing needs
3. Set up monitoring for long-running jobs
4. Configure job retries and failure handling 