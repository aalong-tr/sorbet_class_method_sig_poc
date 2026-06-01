# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_record/railtie"
require "action_controller/railtie"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.1

    # Disable eager loading so that autoload resolves lazily during tapioca dsl
    config.eager_load = false

    # Point Rails root at the dummy directory
    config.root = File.expand_path("..", __dir__)
  end
end
