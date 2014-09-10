Iso::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Other caching
  config.cache_store = :dalli_store
  config.action_controller.perform_caching = true
  config.action_dispatch.rack_cache = {
    metastore: Dalli::Client.new,
    entitystore: Dalli::Client.new,
    allow_reload: false
  }
  config.static_cache_control = "public, max-age=2592000"

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: "localhost:5000" }
  config.action_mailer.asset_host = 'http://localhost:5000'
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  config.assets.debug = true
  config.serve_static_assets = true
end
