ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # S1-G2 — the suite runs single-process by design. The RLS tests connect as
    # app_user and manage context on one shared connection; parallel workers would each
    # need their own database, which app_user cannot create (NOSUPERUSER, no CREATEDB).
    # Forking also crashes on macOS (ObjC fork-safety). Owner-side per-worker DB
    # provisioning is future work if the suite ever needs parallelism.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
