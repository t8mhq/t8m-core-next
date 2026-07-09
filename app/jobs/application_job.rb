class ApplicationJob < ActiveJob::Base
  # S1-G1 · I4 — every job carries the RLS scope guard.
  include ScopedJob

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
