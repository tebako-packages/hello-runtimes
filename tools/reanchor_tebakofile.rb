#!/usr/bin/env ruby
# frozen_string_literal: true

# reanchor_hello.rb — re-anchor the hello-runtimes suite recipe against a
# tebako release, in the shape the file actually has today.
#
#   ruby reanchor_hello.rb <Tebakofile> <version> [--check]
#
# The shape this reads (NOT the runtime factories' `tools.sha256.tfs.*`):
#
#   tools:
#     release: "vX.Y.Z"
#     sha256:
#       <platform>:
#         tebako: "<sha>"
#         tfs:    "<sha>"
#         shim:   "<sha>"
#         pkg:    "<sha>"
#
# Every value comes from the release: the four tool rows per platform out
# of SHA256SUMS (windows rows carry `.exe`). Nothing is typed by hand, and
# the file is edited LINE-WISE so comments and spacing survive.
#
# Exit 0 = in sync or written; 1 = --check found drift; 2 = a named failure.

require "net/http"
require "uri"

file = ARGV[0] or abort "usage: ruby reanchor_hello.rb <Tebakofile> <version> [--check]"
version = ARGV[1] or abort "usage: ruby reanchor_hello.rb <Tebakofile> <version> [--check]"
check = ARGV.include?("--check")
BASE = "https://github.com/tamatebako/tebako/releases/download/v#{version}"

def die(msg) = (warn "reanchor_hello: #{msg}"; exit 2)

def get(url, redirects = 5)
  die "too many redirects for #{url}" if redirects.zero?
  res = Net::HTTP.get_response(URI(url))
  case res
  when Net::HTTPSuccess then res.body
  when Net::HTTPRedirection then get(res["location"], redirects - 1)
  else die "#{url} answered #{res.code}"
  end
end

sums = {}
get("#{BASE}/SHA256SUMS").each_line do |line|
  sha, name = line.strip.split(/\s+/, 2)
  sums[name] = sha if sha && name
end

EXE = ->(p) { p.start_with?("windows") ? ".exe" : "" }

# key => the asset name the row must come from
ROW = {
  "tebako" => ->(p) { "tebako-#{version}-#{p}#{EXE.call(p)}" },
  "tfs" => ->(p) { "tfs-#{version}-#{p}#{EXE.call(p)}" },
  "shim" => ->(p) { "tebako-shim-#{version}-#{p}#{EXE.call(p)}" },
  "pkg" => ->(p) { "tebako-pkg-#{version}-#{p}#{EXE.call(p)}" }
}.freeze

section = nil
platform = nil
moves = []
out = File.readlines(file).map do |line|
  if line =~ /^(\w+):\s*$/
    section = Regexp.last_match(1)
    platform = nil
    next line
  end
  if section == "tools" && line =~ /^  release: "v[\d.]+"(\s*#.*)?\n$/
    old = line[/v[\d.]+/]
    tail = line[/\s*#.*(?=\n$)/] || ""
    moves << ["tools.release", old, "v#{version}"] if old != "v#{version}"
    next %(  release: "v#{version}"#{tail}\n)
  end
  if section == "tools" && line =~ /^    ([a-z0-9_-]+):\s*$/
    platform = Regexp.last_match(1)
    next line
  end
  if section == "tools" && platform && line =~ /^      (\w+):\s+"([0-9a-f]{64})"\s*$/
    key = Regexp.last_match(1)
    old = Regexp.last_match(2)
    resolver = ROW[key]
    next line unless resolver
    name = resolver.call(platform)
    want = sums[name] or die "the release has no #{name} row in SHA256SUMS"
    moves << ["tools.sha256.#{platform}.#{key}", old, want] if old != want
    next %(      #{key}:    "#{want}"\n)
  end
  line
end.join

if check
  if moves.empty?
    puts "reanchor_hello: #{file} is in sync with v#{version}"
    exit 0
  end
  puts "reanchor_hello: #{moves.length} of #{moves.length} pins DRIFT from v#{version} (--check: nothing written)"
  moves.each { |path, old, want| puts "  #{path}: #{old} -> #{want}" }
  exit 1
end

File.write(file, out)
# The verification pass: re-run in --check mode, which must be drift-free.
system(RbConfig.ruby, __FILE__, file, version, "--check") or exit 2
puts "reanchor_hello: #{moves.length} pins re-anchored to v#{version}; verified 0 drift"
