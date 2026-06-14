# Vaporize Performance Marketing Claims

**Status:** release-prep claim matrix
**Updated:** 2026-06-14T00:34:28Z
**Component:** `vaporize@wrkstrm-core.cli`
**Companions:** `product-definition.md`, `why-vaporize.md`

## Claim Rule

Every performance claim must say which kind of proof backs it:

- **Measured:** backed by a captured local timing or receipt.
- **Behavioral:** backed by tests that prove the behavior, but not yet a fleet
  time or disk measurement.
- **Theoretical:** true by design, but still needs benchmark receipts before it
  can become a quantified release claim.

Do not market theoretical claims as measured outcomes.

Every claim must also trace to `product-definition.md`: a primary user,
product-level journey, or reason users choose Vaporize. If a claim cannot be
tied to that product contract, it is not release-ready copy.

For runtime claims, "measured" should mean "captured as a Vaporize runtime
sample in the Kura series with Swift/Apple native artifacts and size metrics
attached or referenced." Manual terminal timings may seed provisional
release-prep baselines, but they are not enough for strong performance,
coverage, build-size, or disk-space claims.

Internal positioning: Vaporize provides engineering pedigree. The tool should
make assistants fight over the best engineering standards by default: native
artifacts, typed records, queryable samples, and gates before claims.

## Approved Claims

| Claim | Type | Safe wording | Evidence |
| --- | --- | --- | --- |
| Vaporize provides engineering pedigree for assistant-run build work | Behavioral | "Engineering pedigree for assistant-run builds." | `product-definition.md`; runtime sample series; release gates |
| Vaporize does not replace Swift; it wraps the same engine with policy and evidence | Measured/behavioral | "Same Swift engine, owned proof surface." | `why-vaporize.md`; focused CUJ-15 bare Swift and Vaporize both measured `6.80s` warm |
| Vaporize wrapper overhead was not visible at focused SwiftPM test scale in the current warm baseline | Measured | "In our warm CUJ-15 baseline, Vaporize matched direct Swift at second-level timing." | `why-vaporize.md` benchmark table |
| Vaporize keeps performance proof inside release evidence | Behavioral | "Build proof you can review later." | PRD, CUJ-09, launch-review packet, provenance artifact |
| Vaporize can run SwiftPM coverage on the owned toolchain route | Provisional measured | "Coverage stays on the owned route." | Backfilled Kura runtime sample; SwiftPM code coverage JSON/profile data and build-size metrics verified |
| Vaporize avoids direct `xcodebuild` and `xcrun` choreography for assistants | Behavioral | "One command surface instead of native-tool choreography." | CUJ-02, CUJ-05, CUJ-15 |
| Shared workspace product-cache reuse can skip a local rebuild when the requested `.app` already exists in the warm workspace DerivedData | Behavioral | "Install from the warm workspace product when it already exists." | CUJ-15 cache-first lookup test |
| Shared workspace DerivedData is designed to reduce duplicate per-project build caches | Theoretical | "Designed to consolidate build products into the maintained workspace cache." | CUJ-15; disk-savings formula in `why-vaporize.md` |
| Vaporize names cache misses and builds through the shared workspace path instead of falling back to ad hoc local commands | Behavioral | "Cache miss stays on the owned route." | CUJ-15 shared workspace invocation test |

## Example Copy

Short internal positioning:

> Vaporize is not a faster compiler. It is the owned build lane that lets
> assistants use Swift and Xcode without losing policy, receipts, install
> semantics, or cache discipline.

Engineering-pedigree version:

> Vaporize gives assistant-run builds engineering pedigree: native artifacts,
> typed records, queryable samples, and release gates before claims.

Performance-safe headline:

> Same Swift engine. Better build discipline.

Cache-safe headline:

> Use the warm workspace product before rebuilding locally.

Release-note version:

> Vaporize v0.0.1 now has a shared Xcode workspace product-cache slice. If the
> requested app product is already present in the maintained workspace
> DerivedData, Vaporize can install that product before trying local outputs; on
> cache miss, it builds through the same shared workspace and DerivedData path.

Assistant ergonomics version:

> Instead of hand-composing `swift`, `xcodebuild`, `xcrun`, app lookup, install
> paths, and JSON validation, assistants use one Vaporize command surface with
> receipts and CUJ coverage.

Benchmark version:

> In the current warm local baseline, focused CUJ-15 testing measured `6.80s`
> through direct Swift and `6.80s` through `vaporize toolchain`. That supports
> the claim that Vaporize preserves the Swift engine while adding policy and
> evidence; it does not support a claim that Vaporize is faster than Swift.

Build-space version:

> The shared workspace cache is designed to retire duplicate per-project
> DerivedData products by making the maintained workspace DerivedData the first
> place Vaporize looks for app bundles.

## Before And After Examples

Before, assistant runbooks had to remember every native-tool detail:

```bash
xcodebuild \
  -workspace /path/to/Huge/Huge.xcworkspace \
  -scheme MyApp \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /path/to/Huge/.derived-data \
  CODE_SIGNING_ALLOWED=NO \
  build
open /Applications/MyApp.app
```

After, the intent is one Vaporize app install:

```bash
vaporize install \
  --artifact app \
  --package-path /path/to/app/root \
  --product MyApp \
  --configuration debug \
  --destination /Applications \
  --xcode-project /path/to/app/MyApp.xcodeproj \
  --scheme MyApp \
  --xcode-product-cache-workspace /path/to/Huge/Huge.xcworkspace \
  --xcode-product-cache-derived-data-path /path/to/Huge/.derived-data \
  --xcode-destination 'platform=macOS,arch=arm64' \
  --xcode-build-setting CODE_SIGNING_ALLOWED=NO \
  --force
```

Before, a package proof can be just a terminal event:

```bash
swift test --filter VaporizeCUJ15XcodeProductCacheTests
```

After, the proof stays inside the release-owned route:

```bash
vaporize toolchain -- swift test --filter VaporizeCUJ15XcodeProductCacheTests
```

## Claims Not Yet Allowed

Do not say:

- "Vaporize is faster than Swift."
- "Vaporize makes Xcode builds 2x faster."
- "Vaporize saves N GB of disk space."
- "Vaporize automatically discovers every product in the huge workspace."
- "Vaporize proves fleet build parity."
- "The shared workspace cache is warm for every app."

Allowed replacement wording:

- "Vaporize matched direct Swift in the current warm focused CUJ-15 baseline."
- "Vaporize is designed to avoid local app rebuilds when the warm workspace
  product already exists."
- "Disk-space savings are expected from cache consolidation, but need a
  dedicated disk benchmark receipt."
- "Runtime samples should attach Swift/Apple native artifacts such as SwiftPM
  coverage JSON/profile data, xUnit output when available, `.xcresult` bundles,
  result metadata, build logs, diagnostics, and DerivedData/product paths."
- "Build-size claims should include product, binary, bundle, coverage artifact,
  result bundle, cache-delta, and per-feature-flag size metrics where
  applicable."
- "App-facing build/config claims should link to the wrkstrm-core
  `xcode-project` registry record, identifier app description,
  app-artifacts audit/export receipt, and release-feature or xcconfig source."
- "Workspace product/scheme discovery remains a follow-up."
- "Fleet parity remains a release blocker."

## Benchmark Receipts Needed For Stronger Claims

| Future claim | Required benchmark |
| --- | --- |
| "Warm cache install avoids rebuild time" | Time app install with existing shared `.app` product vs local rebuild path |
| "Cold cache builds through the shared workspace without extra local cache growth" | Time and disk measurement before/after cache miss build |
| "Vaporize reduces DerivedData footprint" | Disk usage of per-project DerivedData roots before and after consolidation |
| "Vaporize improves fleet build throughput" | Repeated fleet run across owned Apple app surfaces with old path, local Vaporize path, and shared-cache Vaporize path |
| "Workspace discovery removes manual scheme lookup" | Product/scheme discovery receipt from the maintained workspace |
| "Vaporize coverage/performance samples are queryable" | Vaporize-emitted Kura runtime samples with retained SwiftPM coverage JSON/profile data and Xcode result artifacts where applicable |
| "Feature flag X changes app size by N MB" | Paired runtime samples for each feature-flag cohort with product/binary/bundle size metrics and retained native build artifacts |
| "Vaporize knows which app config and feature cohort it built" | Runtime sample joining a wrkstrm-core `xcode-project` record, identifier app description, app-artifacts receipt, and release-feature/xcconfig source |

## Reviewer Checklist

- Does the claim distinguish measured, behavioral, and theoretical evidence?
- Does the copy avoid saying Vaporize is a faster compiler?
- Does the copy name shared workspace cache as conditional on the product
  already existing or being built through the shared workspace?
- Does the copy keep fleet parity and disk savings marked unproven unless a
  benchmark receipt is attached?
- Does every runtime claim point at a Kura runtime sample and native Swift/Apple
  artifacts instead of manual timing alone?
- Does every build-size or feature-flag size claim point at a Kura sample with
  explicit size metrics and the flag set used for that build?
- For app-facing claims, does the sample prove which wrkstrm-core registry,
  identifier, app-artifacts, and release-feature/xcconfig sources supplied the
  build configuration?
