# Vaporize v0.0.1 - Provenance Artifact

**Generated:** 2026-06-14T00:34:28Z
**Status:** captured for forward Pkl migration
**Subject:** `vaporize@wrkstrm-core.cli` v0.0.1 release prep

This artifact gathers the receipts needed to move forward without relying on
chat memory.

## Proven

- CUJ-derived test coverage is explicit: 69 required Swift test obligations
  plus 6 release evidence checks across 16 active CUJs.
- Vaporize package tests pass through `vaporize toolchain`: 87 executable Swift
  tests across 16 implemented CUJ-specific SwiftPM test bundles, including
  CUJ-16 target feature inspection.
- `product-definition.md` defines Vaporize, primary users, product-level user
  journeys, why users choose it, when not to choose it, and build implications
  before more implementation is accepted.
- Concourse `project.yml` parses into Swift `AppleProjectSpec`.
- Fleet intake audit parsed 155/155 discovered `project.yml` files.
- Old XcodeGen script build and Vaporize app build both pass for Concourse
  after Vaporize derives legacy `WRAPPER_NAME` from `project.yml`.
- Concourse `project.pkl` evaluates through PklSwift and matches the Swift-read
  legacy YAML parity signature with zero mismatches.
- Concourse `project.pkl` generates transitional `AppleProjectSpec` YAML
  through PklSwift, and the generated YAML compares back to Pkl with zero
  mismatches.
- Creative Selection v0.2 `project.yml` imports into a generated `project.pkl`
  parity specimen, and the generated Pkl compares back to YAML with zero
  mismatches.
- Creative Selection v0.2 `project.pkl` generates first-slice `.xcodeproj`
  world-state through `generate-xcodeproj`.
- Shared Xcode workspace product-cache reuse has a first slice: cache-first app
  lookup, paired option validation, and shared workspace/DerivedData build
  invocation are covered by CUJ-15.
- Hello World Google target feature inspection passes through
  `inspect-target-features`, proving project configs, release tiers,
  `configFiles` wiring, generated xcconfigs, generated `ReleaseFeatures.swift`,
  and `digikoma-release-features` provenance for the reference target.
- `why-vaporize.md` explains the value proposition, Swift/xcodebuild/xcrun
  comparison, current local benchmark baselines, build-space savings theory,
  user ergonomics, and benchmark gaps.
- `performance-marketing-claims.md` defines approved measured, behavioral, and
  theoretical performance claim language, example copy, prohibited claims, and
  required future benchmark receipts.
- `vaporize-runtime-samples` Kura series is seeded, with a backfilled CUJ-09
  coverage sample that verifies SwiftPM code coverage JSON, raw `.profraw`
  files, merged `default.profdata`, build-output size, product size, codecov
  artifact size, and binary size from a Vaporize toolchain run.
- Initial schema-universal extraction exists as `vaporize-schemas v0.0.1` for
  CUJ coverage, provenance, launch-review specialization, and Apple project
  YAML/Pkl receipts.
- Release evidence JSON validates through `vaporize validate-json`.

## Not Proven

- The full fleet builds through Vaporize.
- Pkl-backed `.xcodeproj` generation covers scheme/resource/package feature
  parity across the required fleet.
- Vaporize automatically discovers the requested product or scheme from the
  shared Xcode workspace cache.
- Fleet-wide performance or disk-space savings have been measured.
- Vaporize automatically emits Kura runtime samples, retains Apple/Swift native
  artifacts as durable release evidence, or compares per-feature-flag build-size
  cohorts.
- Vaporize performs registry-backed app-minimums inspection across the full
  wrkstrm app fleet.
- Remaining XcodeGen surfaces are migrated or quarantined.
- Vaporize v0.0.1 is ready for final internal-essential release.

## Receipt Index

| Receipt | Claim | Result |
| --- | --- | --- |
| `concourse-project-yml-inspection.receipt.json` | Concourse YAML reads into Swift project data | PASS |
| `project-yml-fleet-parse-audit.receipt.json` | 155 discovered `project.yml` files parse | PASS |
| `concourse-old-tool-vaporize-build-comparison.receipt.json` | Old tool and Vaporize agree on Concourse build | PASS-WITH-NOTE |
| `concourse-project-yml-pkl-comparison.receipt.json` | Concourse Pkl specimen matches legacy YAML | PASS |
| `concourse-pkl-project-yml-generation.receipt.json` | Concourse Pkl emits transitional YAML | PASS-WITH-NOTE |
| `concourse-generated-yml-pkl-comparison.receipt.json` | Generated YAML matches Concourse Pkl | PASS |
| `creative-selection-v0.2-project-yml-pkl-import.receipt.json` | Creative Selection v0.2 YAML imports into Pkl | PASS-WITH-NOTE |
| `creative-selection-v0.2-project-yml-pkl-comparison.receipt.json` | Imported Creative Selection v0.2 Pkl matches YAML | PASS |
| `creative-selection-v0.2-pkl-xcodeproj-generation.receipt.json` | Creative Selection v0.2 Pkl emits first-slice `.xcodeproj` world-state | PASS-WITH-NOTE |
| `VaporizeCUJ15XcodeProductCacheTests.swift` | Shared workspace product cache lookup and invocation slice is covered | PASS-WITH-NOTE |
| `product-definition.md` | Product definition, primary users, journeys, choice argument, and build implications are defined | PASS |
| `why-vaporize.md` | Positioning, tool comparison, benchmark baseline, and ergonomics are explained | PASS-WITH-NOTE |
| `performance-marketing-claims.md` | Safe performance marketing copy and claim boundaries are defined | PASS-WITH-NOTE |
| `hello-world-google-target-features-inspection.receipt.json` | Hello World Google target release-feature topology is inspectable by Vaporize | PASS-WITH-NOTE |
| `wrkstrm-app-minimums.md` | wrkstrm app release-feature minimums are defined for target and future fleet inspection | PASS-WITH-NOTE |
| `vaporize-runtime-samples.series.su.json` | Kura-queryable runtime sample series is seeded | PASS-WITH-NOTE |
| `2026-06-14.vaporize-runtime-samples.jsonl` | Backfilled CUJ-09 coverage runtime sample records native SwiftPM coverage artifacts and build-size metrics | PASS-WITH-NOTE |
| `xcodegen-to-pkl-investigation.json` | Migration scope and blockers are captured | BLOCKS-INTERNAL-V0.0.1 |
| `cuj-test-coverage.json` | PRD/CUJ-derived required test floor is captured | PASS |
| `launch-review-packet.json` | Release-prep packet is gathered | VALID-JSON |
| `vaporize-schemas v0.0.1` | Initial schema-universal extraction is captured | PASS-WITH-NOTE |

## Savepoints

- `DF8697F3-DCED-4FA3-AF36-103D818F23E7` - Swift YAML bridge, release docs,
  tests, Concourse inspection receipt.
- `8D119C0F-65AD-4633-A776-EC15350BA4A5` - fleet parse audit receipt.
- `65A98CBC-F745-4B23-9E41-4361DAECF054` - old/new Concourse build
  comparison and `WRAPPER_NAME` compatibility fix.
- `A1FC2C04-AD43-448E-8B72-291E226AB429` - Pkl schema, Concourse Pkl parity
  specimen, `compare-project-yml-pkl` mode, and zero-mismatch comparison
  receipt.
- `CFC7AE2A-1E63-4358-BE75-4C514A6CCC87` - PklSwift dependency,
  `generate-project-yml`, transitional Concourse YAML artifact, generation and
  comparison receipts, release packet updates, and blocker-bead progress.
- `D4FABA98-0FF1-44EA-920A-80CE08517921` - Apple project test-suite split and
  focused CLI coverage expansion before the CUJ-derived coverage contract.

## Forward Path

1. Expand Pkl-backed `.xcodeproj` world-state generation beyond the first
   Creative Selection v0.2 slice.
2. Repeat old tool / Vaporize / Pkl-generation comparisons beyond Concourse and
   Creative Selection v0.2 before claiming fleet parity.
3. Promote shared workspace product-cache reuse into workspace product/scheme
   discovery once the maintained workspace fleet is known.
4. Implement Vaporize-emitted Kura runtime samples that attach SwiftPM coverage
   JSON/profile data, xUnit output when available, Xcode `.xcresult` bundles,
   result metadata, build logs, diagnostics, DerivedData/product paths,
   product/binary/bundle sizes, coverage/result artifact sizes, cache deltas,
   and per-feature-flag size cohorts.
5. Complete registry-backed wrkstrm app-minimums inspection so Vaporize can
   report whether each app has release-feature manifest, generated xcconfigs,
   generated `ReleaseFeatures.swift`, project wiring, and
   `digikoma-release-features` provenance.
6. Create dedicated benchmark receipts for cold builds, warm cache hits, cache
   misses, and disk usage before making fleet performance or space-saving
   release claims.
7. Promote approved performance marketing claims only after attaching the
   relevant benchmark receipt.
8. Quarantine or migrate remaining substrate-owned XcodeGen surfaces.

The machine-readable companion is
`vaporize-v0.0.1-provenance-artifact.json`.
