# frozen_string_literal: true

require "bundler/gem_tasks"

APP_RAKEFILE = File.expand_path("spec/dummy/Rakefile", __dir__)
load APP_RAKEFILE if File.exist?(APP_RAKEFILE)

task default: :tapioca_dsl

desc "Run tapioca dsl to attempt to reproduce the sig-called-twice error"
task :tapioca_dsl do
  sh "bundle exec tapioca dsl"
end
