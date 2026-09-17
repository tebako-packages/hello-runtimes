#!/usr/bin/env ruby
# frozen_string_literal: true

# hello-jruby — the tebako sample app on the jruby runtime. Stdlib only:
# the runtime edge is a version RANGE on the implementation's own line
# (pure-language law), pinned to the jruby implementation — the wrapper
# composes it onto the openjdk owner at dispatch (runtime-on-runtime).
puts "Hello from tebako (#{RUBY_ENGINE} #{RUBY_ENGINE_VERSION}, ruby #{RUBY_VERSION} compat, #{RUBY_PLATFORM})"
