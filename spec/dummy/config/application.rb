# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_record/railtie"
require "action_controller/railtie"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.1

    # Enable eager loading so tapioca dsl discovers all engine models
    config.eager_load = true

    # Point Rails root at the dummy directory
    config.root = File.expand_path("..", __dir__)
  end
end
