require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CoreNext
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks middleware])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # S1-G1 · I1 — resolve + set RLS context per request, with a guaranteed reset on
    # release. Required (not autoloaded, see lib ignore above) so the class exists while
    # the middleware stack is still mutable here.
    require_relative "../lib/middleware/rls_context_resolver"
    require_relative "../lib/middleware/rls_context_middleware"
    config.middleware.use RlsContextMiddleware

    # S1-G1 — RLS policies and SQL functions are not representable in Ruby schema.rb.
    # Use structure.sql so ENABLE/FORCE RLS, policies, and app_* functions round-trip
    # through db:schema:load. This is a correctness requirement, not a preference.
    config.active_record.schema_format = :sql

    # S1-G0 · D1/D3 — packs live under packs/{name}. Each pack's app/* directories
    # (models, services, public, ...) are Zeitwerk roots, so packs/catalog/app/public/
    # catalog/api.rb resolves to Catalog::Api. Packwerk enforces which of these are
    # reachable across pack boundaries (only app/public/ is).
    Dir.glob(root.join("packs/*/app/*")).each do |dir|
      config.paths.add(dir.delete_prefix("#{root}/"), eager_load: true)
    end
  end
end
