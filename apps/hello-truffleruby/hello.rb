#!/usr/bin/env ruby
# frozen_string_literal: true

# hello-truffleruby — the tebako sample app on the truffleruby runtime
# (jvm mode). Stdlib only: the runtime edge is a version RANGE on the
# implementation's own line (pure-language law), pinned to the
# truffleruby implementation — the wrapper composes it onto the graalvm
# owner at dispatch (runtime-on-runtime).
puts "Hello from tebako (truffleruby #{TruffleRuby::VERSION}, ruby #{RUBY_VERSION} compat, #{RUBY_PLATFORM})"
