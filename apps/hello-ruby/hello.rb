#!/usr/bin/env ruby
# frozen_string_literal: true

# hello-ruby — the tebako sample app on the ruby runtime. Stdlib only:
# the runtime edge is a version RANGE (pure-language law), never an ABI
# line, so one payload rides every compatible ruby line.
puts "Hello from tebako (ruby #{RUBY_VERSION}, #{RUBY_PLATFORM})"
