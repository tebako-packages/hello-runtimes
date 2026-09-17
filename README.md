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
  `stage_runtime` / `build` / `boot_smoke` / `registry_default` / the
  installer tools (`fetch_installer_sources`, `install_msi`,
  `install_pkg`).
- `.github/workflows/build-payloads.yml` — plan → per-(app × platform)
  legs (build + smoke against every runtime line) + the installer legs
  (MSI and pkg, lean and fat compositions — build + install-rehearse on
  every trigger, sign + ship on the publish run) → the publish job
  (gated: owner dispatch with `publish: true` on a tag ref — NEVER
  automatic).
- `tpkg-registry.yaml` — this suite's registry, published at the
  default-branch root per the conventions.

## Installers

Every release also ships OS-native installers for `hello-ruby`, in both
compositions a tebako product can take:

| Asset | Composition | Contents | Network |
|---|---|---|---|
| `hello-ruby-setup-<ver>-windows-ucrt64.msi` · `hello-ruby-setup-<ver>-macos-<arch>.pkg` | lean | the tebako toolset + an install-time seed | at install only: the seed registers this suite's registry, installs `hello-ruby`, and prefetches its runtime, so the first run is already offline-ready (an offline install still completes — re-run `bootstrap-seed` later) |
| `hello-ruby-fat-setup-<ver>-macos-<arch>.pkg` | fat (airgap) | one self-contained `hello-ruby` executable — bootstrap + ruby runtime + the app, stitched | none — not at install, not at run |

The fat MSI is gated off for now: a self-contained Windows press against
any current runtime line fails its boot closed on a duplicate
library-alias declaration (tamatebako/tebako#486, open — and the
documented pin-an-older-runtime workaround predates the carried-runtime
wire form, so no client-side pin exists). The Windows fat leg returns
the day the fix ships in a tebako release.

The MSI containers are signed with Azure Trusted Signing; the pkg
containers are signed with a Developer ID Installer certificate,
notarized, and stapled. The binaries inside carry their own signatures
(the tebako release's own for the lean toolset; this org's Developer ID
Application certificate for the fat exe), and every container ships with
the suite's OpenPGP `.asc` beside it.

The installers bind the product repo's parameterized templates
(`templates/installers/` in tamatebako/tebako), fetched at the pinned
tebako release tag and digest-verified file by file — the same files a
client CI binds with *its* identity. The legs build and install-rehearse
both compositions on every PR and push; the containers ship signed
exactly on the owner-dispatched publish run (a disarmed signing plane
rehearses unsigned and ships nothing).

Two carries to know about, both tracked upstream:

- `patches/tebako-wxs-bootstrap-wix5.patch` makes the pinned WiX
  template's web-bootstrapper block compile under the pinned WiX v5
  toolchain (the block is preprocessed out in the product's own
  pipeline, so the compile errors surface only for a client binding
  it — tamatebako/tebako#623). `tools/install_msi` applies it to a
  working copy; the digest-verified template tree is never mutated.
- The Windows fat MSI leg is gated off (its matrix entry carries the
  pointer) until tamatebako/tebako#486 ships: an alias-era runtime line
  makes a self-contained Windows press fail its boot on a duplicate
  library-alias declaration, and no pre-alias runtime line speaks the
  carried-runtime wire form. The macOS fat pkg legs cover the fat
  composition.

## Build your own installer

The same pipeline is the client recipe — everything varies through the
`installers:` block of the Tebakofile and your own signing credentials:

1. **Bind your identity.** Copy the `installers:` block and set
   `product_name`, `org_id` (your reverse-DNS prefix, e.g.
   `org.example`), `manufacturer`, and `install_root`. **Mint your own
   MSI `msi_upgrade_code` GUID and lock it forever** — upgrades pair on
   it, and reusing another product's GUID makes the two products
   upgrade-collide on the same machine.
2. **Point at your payload.** `app:` names the suite app to wrap (the
   fat composition presses it self-contained against the app's first
   listed runtime line); `registry:` is the registry your lean seed
   registers; `warm:` lists the shims dispatched once at install time
   (the runtime prefetch — print-and-exit entrypoints only).
3. **Keep the pins.** The template files come from your pinned tebako
   release tag (`tools.release`), digest-verified by
   `tools/fetch_installer_sources` — bump the digests when you bump the
   toolchain. Never vendor-edit the templates: bind them.
4. **Provision your signing.** Windows: an Azure Trusted Signing
   account + certificate profile, and an Entra app registration whose
   federated credential matches your repo's `windows-signing`
   environment; repo secrets `AZURE_CLIENT_ID` / `AZURE_TENANT_ID` /
   `AZURE_SUBSCRIPTION_ID`, repo variables `AZURE_ENDPOINT` /
   `AZURE_SIGNING_ACCOUNT_NAME` / `AZURE_SIGNING_CERT_PROFILE`, and the
   gate variable `WINDOWS_SIGNING_ENABLED=true`. macOS: **two distinct
   certificates** — Developer ID Application (the fat exe inside) and
   Developer ID Installer (the pkg container; the Application
   certificate cannot productsign) — plus an App Store Connect API key;
   secrets `APPLE_DEVELOPER_ID_P12(+_PASSWORD)`,
   `APPLE_DEVELOPER_ID_INSTALLER_P12(+_PASSWORD)`, `APPLE_ASC_KEY_P8` /
   `APPLE_ASC_KEY_ID` / `APPLE_ASC_ISSUER_ID`, `APPLE_TEAM_ID`, and the
   gate variables `APPLE_SIGNING_ENABLED=true` +
   `APPLE_INSTALLER_SIGNING_ENABLED=true`. Payload/container `.asc`:
   your OpenPGP signing key as `TEBAKO_CI_SIGNING_KEY`, with the
   registry pinning the primary keyid (`signing:` in the Tebakofile).
5. **Fail-closed by construction.** A gate variable set to `true` with a
   secret absent fails the leg with a named error — a signed release
   never silently ships unsigned. Gates off: the legs still build and
   install-rehearse both containers on every run, and the release simply
   carries no installer assets.

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
