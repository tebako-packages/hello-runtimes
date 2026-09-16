#!/usr/bin/env ruby
# frozen_string_literal: true

# hello-ruby — the tebako sample app on the ruby runtime. Stdlib only:
# the runtime edge is a version RANGE (pure-language law), never an ABI
# line, so one payload rides every compatible ruby line.
puts "Hello from tebako (ruby #{RUBY_VERSION}, #{RUBY_PLATFORM})"

# Extension slices (the manifest's declared extension point, spec 03
# §2.8): each attached slice mounts a mini GEM_HOME below the point at
# /flavors.d/<name>; the VFS materializes the boundary dir itself (spec
# 17 §1), so plain Dir enumeration sees the mounted homes. Put each on
# GEM_PATH and require the slice-named gem — a flavor registers itself
# on require (here: its tag joins the greeting). A failing require is a
# broken slice — the LoadError surfaces as-is. Zero slices attached =
# the glob is empty.
flavors = "/flavors.d"
if File.directory?(flavors)
  Dir[File.join(flavors, "*")].sort.each do |home|
    next unless File.directory?(home)
    Gem.paths = { "GEM_PATH" => (Gem.path + [home]).join(File::PATH_SEPARATOR) }
    require File.basename(home)
  end
end

puts "… + #{HelloFlavor::TAG}" if defined?(HelloFlavor)
