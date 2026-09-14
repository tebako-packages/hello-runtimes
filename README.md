# hello-runtimes — one hello-world app per tebako runtime

The sample suite and client-product reference for the tebako v2
ecosystem: three minimal app payloads, each riding its own runtime,
built and smoked on every platform, then signed and published as both
payload images and OS-native installers.

| Payload | Rides | Runtime edge | Platforms |
|---|---|---|---|
| `hello-ruby` | tebako-runtime-ruby | `>= 3.3, < 5.0` (range — pure-language) | linux-gnu ×2, macOS ×2, windows-ucrt |
| `hello-python` | tebako-runtime-python | `>= 3.13, < 4.0` | linux-gnu ×2, macOS ×2 (windows waits on the factory's mount tier) |
| `hello-java` | tebako-runtime-openjdk | `>= 21` | linux-gnu ×2, macOS ×2, windows-ucrt |

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
- **Nothing compiles.** The apps are copied verbatim (the java app
  launches from source — java 11+ single-file source-code programs), so
  no toolchain ever runs here — audiences 1–3 by construction.
- **Shard-model runtime staging.** `tools/stage_runtime` consumes the
  factories' per-leg shard releases (manifest shards + per-asset
  sidecars + `.asc`), verifies every staged byte three ways, and derives
  the trimmed mirror index consumer-side.
- **Signed publish.** On a tag, the publish job signs every payload with
  the tamatebako CI signing subkey and lands the registry by bot PR
  (main is protected).

## Layout

- `apps/<name>/` — the app sources (copied verbatim into the image).
- `manifests/<name>.yaml` — the in-image manifest templates
  (`@@…@@` filled by `tools/build`).
- `recipe.yml` — the SSOT: suite version, tool pins (digest-pinned
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

```sh
tebako add-registry tfs:github:tebako-packages/hello-runtimes
tebako install hello-ruby
hello-ruby        # Hello from tebako (ruby 4.0.6, arm64-darwin)
```
