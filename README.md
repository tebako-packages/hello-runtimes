# hello-runtimes — one hello-world app per tebako runtime

The sample suite and client-product reference for the tebako v2
ecosystem: minimal app payloads, each riding its own runtime, built and
smoked on every platform the runtime ships, then signed and published as
both payload images and OS-native installers.

| Payload | Rides | Runtime edge | Platforms |
|---|---|---|---|
| `hello-ruby` | tebako-runtime-ruby | `>= 3.3, < 5.0` (range — pure-language) | linux-gnu ×2, macOS ×2, windows-ucrt |
| `hello-python` | tebako-runtime-python | `>= 3.13, < 4.0` | linux-gnu ×2, macOS ×2 (windows waits on the factory's mount tier) |
| `hello-java` | tebako-runtime-openjdk | `>= 21`, flavor-pinned to `temurin` | linux-gnu x86_64, macOS arm64, windows-ucrt (the factory's three) |
| `hello-jruby` | tebako-runtime-jruby | `>= 10, < 11`, implementation-pinned to `jruby` | linux-gnu x86_64, macOS arm64 (the factory's two) |
| `hello-truffleruby` | tebako-runtime-truffleruby | `>= 34, < 35`, implementation-pinned to `truffleruby` | linux-gnu x86_64, macOS arm64 (jvm mode) |

## Why this suite exists

A client product (the packed-mn class) is a composition: bootstrap +
runtime(s) + payload(s) + an installer carrying the client's own signing
identity. Each app here is ~20 lines — the point is never the app, it's
that the **whole path** runs: registry resolution → runtime co-mount →
entrypoint dispatch → signed payload → signed installer.

Every app honors the same contract — `hello-<engine>` prints
`Hello from tebako (<engine> <version>, <platform>)` — so the suite is
also the ecosystem's acceptance matrix: a red leg means a runtime, a
dispatch path, or a signing surface regressed.

## What the suite demonstrates (deliberately)

- **Pure-language runtime edges.** No app here has native extensions, so
  every entrypoint carries a version RANGE (spec 05 §5's ABI line applies
  only to native extensions — see the xml2rfc feedstock for that shape).
  One `hello-ruby` payload rides ruby 3.3 and 4.0 alike; the legs stage
  both published lines and smoke the same bytes against each.
- **Nothing tebako-side compiles.** The apps are copied verbatim — the
  one exception is the java app, whose OWN source compiles to a jar with
  the runner's hosted JDK (audience law 3: a runnable-payload developer
  compiles only their own code; the openjdk runtime is a JRE, so the jar
  with `args_default: ["-jar"]` is the payload form — spec 29 §1's own
  example shape). No tebako machinery ever compiles here.
- **Shard-model runtime staging.** `tools/stage_runtime` consumes the
  factories' per-leg shard releases (manifest shards + per-asset
  sidecars + `.asc`), verifies every staged byte three ways, and derives
  the trimmed mirror index consumer-side. Repeated stagings into one
  mirror ACCUMULATE — the derived index spans every shard the mirror
  carries, so a composition mirror (a depending line + its owner line)
  builds naturally.
- **Runtime-on-runtime composition.** `hello-jruby` and
  `hello-truffleruby` ride wrappers that compose onto the openjdk owner
  at dispatch: the owner's exe runs, the depending runtime's env image
  co-mounts at its declared `/__runners__/<name>` point, and the payload
  mounts at `/`. The legs stage both lines into one mirror and smoke the
  full handoff — the owner's interpreter, the depending runtime's
  template, the app's greeting.
- **Signed publish.** On a tag, the publish job signs every payload with
  the tamatebako CI signing subkey and lands the registry by bot PR
  (main is protected).

## Layout

- `apps/<name>/` — the app sources (copied verbatim into the image).
- `manifests/<name>.yaml` — the in-image manifest templates
  (`@@…@@` filled by `tools/build`).
- `Tebakofile` — the SSOT: suite version, tool pins (digest-pinned
  against the release's own SHA256SUMS), per-app runtime lines,
  platforms, CI hosts, signing keyid.
- `tools/` — `pins.rb` (recipe → CI matrix/env/payload-args) /
  `stage_runtime` / `build` / `boot_smoke`.
- `.github/workflows/build-payloads.yml` — plan → per-(app × platform)
  legs (build + smoke against every runtime line) → the publish job
  (gated: owner dispatch with `publish: true` on a tag ref — NEVER
  automatic).
- `tpkg-registry.yaml` — this suite's registry, published at the
  default-branch root per the conventions.

## Installers

The installer legs (MSI + pkg, fat and lean shapes) consume the product
repo's parameterized templates (`templates/installers/` in
tamatebako/tebako) with this org's own identity — the same files a
client CI binds with *its* identity. They land in this repo's workflow
as the signing credentials arrive (see the repo's open tracking issue).

## Try a published payload

Requires tebako > v2.8.2. One-time setup — register this suite's registry:

```sh
tebako add-registry tfs:github:tebako-packages/hello-runtimes
```

Then per engine (each runtime arrives once per machine, into the shared
cache):

- **ruby — zero-config.** The product's default channel hosts ruby
  runtimes; nothing else to register:

  ```sh
  tebako install hello-ruby
  hello-ruby        # Hello from tebako (ruby 4.0.6, arm64-darwin23)
  ```

- **java — register the factory registry once.** The openjdk factory
  publishes two flavors of `engine: java`; `hello-java` pins the default
  flavor (`temurin`, spec 28 §8's implementation axis), so every machine
  resolves the same runtime:

  ```sh
  tebako add-registry tfs:github:tamatebako/tebako-runtime-openjdk
  tebako install hello-java
  hello-java        # Hello from tebako (java 21.0.12, Mac OS X/aarch64)
  ```

  To ride the graalvm flavor instead, the manifest edge names
  `implementation: graalvm` — a one-line change and a rebuild; the
  factory registry serves both flavors.

- **python — pin the source once (the factory registry lands with
  tebako-runtime-python's registry renderer).** Add to
  `~/.tebako/config.yaml`:

  ```yaml
  runtimes:
    python:
      version: "3.14.7"
      tebako: "0.2.0"
      source: "https://github.com/tamatebako/tebako-runtime-python/releases/download"
  ```

  then `tebako install hello-python && hello-python`.
