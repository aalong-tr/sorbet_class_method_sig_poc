# frozen_string_literal: true

# This file is used by tapioca to load the application environment before
# generating DSL RBI files. It points at the spec/dummy app which mounts
# the engine, making all engine models (e.g. Foo::Bar) visible to tapioca.
require_relative "../spec/dummy/config/environment"
