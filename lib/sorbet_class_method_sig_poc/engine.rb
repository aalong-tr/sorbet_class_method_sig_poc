# frozen_string_literal: true

module SorbetClassMethodSigPoc
  class Engine < ::Rails::Engine
    isolate_namespace Foo
  end
end
