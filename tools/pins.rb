#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/pins.rb — Tebakofile → CI glue. Modes:
#   --matrix              the GHA include list: one entry per
#                         (app × platform) leg; each entry carries the
#                         app's runtime line(s) as a JSON list — the
#                         payload bytes are runtime-independent
#                         (pure-language law), so a leg builds ONCE and
#                         smokes against EVERY line the recipe names
#                         (hello-ruby proves 3.3 and 4.0 alike)
#   --env APP TRIPLET     the leg's env (KEY=value lines for GITHUB_ENV)
#   --runtimes APP        "<version> <tebako> <release>" per line (the
#                         leg's stage+smoke loop)
#   --payload-args        the publish step's --payload pairs
#
# Tebakofile is the SSOT; this tool carries no version literals.

require "json"
require "yaml"

# Native windows ruby terminates text-mode lines with CRLF and bash's
# `read` keeps the \r — a tainted field malforms every consumer (the
# release tag becomes "v0.16.23\r" and gh answers "release not found").
$stdout.binmode

RECIPE = YAML.load_file(File.join(__dir__, "..", "Tebakofile")).freeze

# triplet → factory host_id (Platform::HOST_IDS) — asserted identical in
# name form only where the factories agree; a divergence fails loudly.
TRIPLET_HOST = {
  "x86_64-linux-gnu" => "linux-gnu-x86_64",
  "aarch64-linux-gnu" => "linux-gnu-arm64",
  "x86_64-macos" => "macos-x86_64",
  "aarch64-macos" => "macos-arm64",
  "x86_64-windows-ucrt" => "windows-ucrt64"
}.freeze

def legs
  RECIPE.fetch("apps").flat_map do |app, spec|
    spec.fetch("platforms").map do |triplet|
      {
        "app" => app,
        "engine" => spec.fetch("engine"),
        "factory" => spec.fetch("factory"),
        "runtimes" => spec.fetch("runtimes"),
        "triplet" => triplet,
        "host_id" => TRIPLET_HOST.fetch(triplet),
        "runner" => RECIPE.fetch("ci").fetch("hosts").fetch(triplet)
      }
    end
  end
end

def tool_env(triplet)
  host = TRIPLET_HOST.fetch(triplet)
  pins = RECIPE.fetch("tools")
  dig = pins.fetch("sha256").fetch(host)
  suffix = triplet.include?("windows") ? ".exe" : ""
  ver = pins.fetch("release").sub(/^v/, "")
  {
    "TEBAKO_RELEASE" => pins.fetch("release"),
    "TEBAKO_ASSET" => "tebako-#{ver}-#{host}#{suffix}",
    "TEBAKO_SHA256" => dig.fetch("tebako"),
    "TFS_ASSET" => "tfs-#{ver}-#{host}#{suffix}",
    "TFS_SHA256" => dig.fetch("tfs"),
    # The publish verify installs the payload — the dispatcher binary
    # must sit beside the CLI (shims point at it).
    "SHIM_ASSET" => "tebako-shim-#{ver}-#{host}#{suffix}",
    "SHIM_SHA256" => dig.fetch("shim")
  }
end

case ARGV[0]
when "--matrix"
  puts JSON.generate({ "include" => legs })
when "--env"
  leg = legs.find { |l| l["app"] == ARGV[1] && l["triplet"] == ARGV[2] } or
    abort("pins: no leg for app=#{ARGV[1]} triplet=#{ARGV[2]}")
  (tool_env(ARGV[2]).to_a + [
    ["APP", leg["app"]], ["ENGINE", leg["engine"]], ["FACTORY_REPO", leg["factory"]],
    ["TRIPLET", leg["triplet"]], ["HOST_ID", leg["host_id"]],
    ["PKG_VERSION", RECIPE.fetch("version")],
    ["SIGNING_KEYID", RECIPE.dig("signing", "keyid").to_s]
  ]).each { |k, v| puts "#{k}=#{v}" }
when "--runtimes"
  spec = RECIPE.fetch("apps").fetch(ARGV[1])
  # "<version> <tebako> <release>" per line; a runtime line carrying an
  # `owner` facet (the runtime-on-runtime composition — jruby/truffleruby
  # on openjdk) appends "<owner_factory> <owner_version> <owner_tebako>
  # <owner_release>" so the leg stages the owner line beside it.
  spec.fetch("runtimes").each do |rt|
    fields = [rt.fetch("version"), rt.fetch("tebako"), rt.fetch("release")]
    if (owner = rt["owner"])
      fields += [owner.fetch("factory"), owner.fetch("version"), owner.fetch("tebako"), owner.fetch("release")]
    end
    puts fields.join(" ")
  end
when "--payload-args"
  # tebako publish's grammar is --payload <triplet>=<path> (identity rides
  # --name + the manifest); one pair per leg of the named app.
  app = ARGV[1] or abort "usage: ruby tools/pins.rb --payload-args APP"
  legs.select { |l| l["app"] == app }.map do |l|
    "--payload #{l["triplet"]}=out/#{l["triplet"]}/#{app}-#{RECIPE.fetch("version")}-#{l["host_id"]}.tfs"
  end.each { |a| puts a }
else
  abort "usage: ruby tools/pins.rb [--matrix | --env APP TRIPLET | --runtimes APP | --payload-args APP]"
end
