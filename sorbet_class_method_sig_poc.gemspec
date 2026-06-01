# frozen_string_literal: true

require_relative "lib/sorbet_class_method_sig_poc/version"

Gem::Specification.new do |spec|
  spec.name = "sorbet_class_method_sig_poc"
  spec.version = SorbetClassMethodSigPoc::VERSION
  spec.authors = ["Drew Long"]
  spec.email = ["48696687+aalong-tr@users.noreply.github.com"]

  spec.summary = "POC reproducing sorbet-runtime 'sig called twice' error with tapioca dsl"
  spec.description = <<~DESC
    Demonstrates a bug where sorbet-runtime raises
    'You called sig twice without declaring a method in between'
    when running `tapioca dsl` against a Rails engine that defines
    consecutive class-method sigs on an ApplicationRecord subclass.
  DESC

  spec.files = Dir["{app,config,db,lib}/**/*", "Rakefile"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0.0"

  spec.add_dependency "rails", "~> 7.1"
  spec.add_dependency "sorbet-runtime"
end
