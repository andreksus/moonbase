require_relative "boot"

require "rails/all"
require './app/middleware/opensea_stream_api'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Moonbase
  class Application < Rails::Application
    config.middleware.use Rack::Brotli
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.assets.paths << Rails.root.join("app", "assets", "fonts")

    config.active_job.queue_adapter = :shoryuken
    config.active_job.queue_name = if ENV['BACKGROUND_WORKER_NUMBER'] == 'second'
                                     'awseb-e-3eka3gpvup-stack-AWSEBWorkerQueue-ZESyQr4BpRB1'
                                   elsif ENV['BACKGROUND_WORKER_NUMBER'] == 'third'
                                     'MoonbaseListingsWorker'
                                   else
                                     'awseb-e-xpk2xpwnks-stack-AWSEBWorkerQueue-1PDFAO0R4PSAY'
                                   end
    # config.middleware.use OpenseaStreamApi
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
