# Vaporize v0.0.1 - Provenance Artifact

**Generated:** 2026-06-14T04:05:00Z
**Status:** captured for forward Pkl migration
**Subject:** `vaporize@wrkstrm-core.cli` v0.0.1 release prep

This artifact gathers the receipts needed to move forward without relying on
chat memory.

## Proven

- CUJ-derived test coverage is explicit: 84 required Swift test obligations
  plus 11 release evidence checks across 19 active CUJs.
- Vaporize package tests pass through `vaporize toolchain`: 102 executable Swift
  tests across 19 implemented CUJ-specific SwiftPM test bundles, including
  CUJ-16 target feature inspection, CUJ-17 release doctor, CUJ-18 project
  target discovery, and CUJ-19 workspace product-cache discovery.
- `product-definition.md` defines Vaporize, primary users, product-level user
  journeys, why users choose it, when not to choose it, and build implications
  before more implementation is accepted.
- `prd-review-session.md` codifies the Engineering, QA, and Marketing PRD
  review session before major coding starts. v0.0.1 is backfilled as
  `GO-WITH-NOTES` because the release-prep lane was already in flight.
- `vaporware-modification-request-discipline.md` codifies that vaporware feature
  requests are product input, while vaporware modification requests are the
  controlled engineering execution unit that needs a feature flag or
  feature-status story, targetable tests, release evidence, and explicit no-flag
  exceptions. The domain-specific request name leaves room for future hardware
  or other material-domain request families.
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
- Creative Selection v0.2 `project.pkl` is discoverable through `list-targets`
  with a `vaporize-project-target-discovery` receipt that names target,
  package, scheme, and buildable-candidate facts.
- Shared Xcode workspace product-cache reuse has a first slice: cache-first app
  lookup, paired option validation, and shared workspace/DerivedData build
  invocation are covered by CUJ-15.
- Workspace product-cache discovery has a first slice: Creative Selection v0.2
  target facts map to one expected shared DerivedData `.app` candidate with
  warm/missing status through CUJ-19.
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
- `vaporize.engineering.docc` exists as the package-local human engineering
  narrative for future `wrkstrm.com/engineering` publication; release evidence
  remains the proof corpus.
- `vaporize.engineering.docc/feature-catalog.md` exists as the canonical
  human-readable feature list and explanation surface for Vaporize.
- `vaporize.engineering.docc/release-doctor.md` exists, and
  `release-doctor` emits a `vaporize-release-doctor` receipt that verifies
  release-spine coherence before assistants trust the packet.
- `vaporize.engineering.docc/modularity-and-ownership-boundaries.md` exists as
  the ownership and modularity rule: Swift Universal primitives belong in
  `swift-universal`, Apple-bounded orchestration belongs in `wrkstrm-core`, and
  Vaporize should not accumulate feature bodies in the CLI router.
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
- Vaporize automatically discovers `.xcworkspace` graph membership for the
  requested product or scheme.
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
| `creative-selection-v0.2-list-targets.receipt.json` | Creative Selection v0.2 Pkl target, package, scheme, and buildable-candidate facts are discoverable | PASS-WITH-NOTE |
| `creative-selection-v0.2-workspace-cache-discovery.receipt.json` | Creative Selection v0.2 workspace product-cache candidate path and warm/missing state are discoverable | PASS-WITH-NOTE |
| `VaporizeCUJ15XcodeProductCacheTests.swift` | Shared workspace product cache lookup and invocation slice is covered | PASS-WITH-NOTE |
| `VaporizeCUJ19WorkspaceCacheDiscoveryTests.swift` | Workspace product-cache candidate discovery is covered | PASS-WITH-NOTE |
| `product-definition.md` | Product definition, primary users, journeys, choice argument, and build implications are defined | PASS |
| `why-vaporize.md` | Positioning, tool comparison, benchmark baseline, and ergonomics are explained | PASS-WITH-NOTE |
| `performance-marketing-claims.md` | Safe performance marketing copy and claim boundaries are defined | PASS-WITH-NOTE |
| `vaporize.engineering.docc` | Human engineering docs exist for future `wrkstrm.com/engineering` projection | PASS-WITH-NOTE |
| `feature-catalog.md` | Major Vaporize features are listed with user problem, current surface, and proof boundary | PASS-WITH-NOTE |
| `modularity-and-ownership-boundaries.md` | Swift Universal versus wrkstrm-core ownership and Vaporize modularity boundaries are defined | PASS-WITH-NOTE |
| `vaporware-modification-request-discipline.md` | Vaporware feature requests are distinguished from vaporware modification requests; release-discipline mechanics are defined | PASS-WITH-NOTE |
| `vaporize-v0.0.1-release-doctor.receipt.json` | Release doctor verifies release-spine agreement before assistants trust the packet | PASS-WITH-NOTE |
| `hello-world-google-target-features-inspection.receipt.json` | Hello World Google target release-feature topology is inspectable by Vaporize | PASS-WITH-NOTE |
| `wrkstrm-app-minimums.md` | wrkstrm app release-feature minimums are defined for target and future fleet inspection | PASS-WITH-NOTE |
| `vaporize-runtime-samples.series.su.json` | Kura-queryable runtime sample series is seeded | PASS-WITH-NOTE |
| `2026-06-14.vaporize-runtime-samples.jsonl` | Backfilled CUJ-09 coverage runtime sample records native SwiftPM coverage artifacts and build-size metrics | PASS-WITH-NOTE |
| `xcodegen-to-pkl-investigation.json` | Migration scope and blockers are captured | BLOCKS-INTERNAL-V0.0.1 |
| `cuj-test-coverage.json` | PRD/CUJ-derived required test floor is captured | PASS |
| `launch-review-packet.json` | Release-prep packet is gathered | VALID-JSON |
| `prd-review-session.md` | Engineering, QA, and Marketing PRD review is required before major coding starts | PASS-WITH-NOTE |
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
3. Use project target discovery and workspace cache candidate receipts to route
   the next build/cache/parity step before attempting automatic `.xcworkspace`
   graph membership discovery.
4. Promote target-fact-derived workspace product-cache candidate discovery into
   `.xcworkspace` graph membership and product/scheme discovery once the
   maintained workspace fleet is known.
5. Implement Vaporize-emitted Kura runtime samples that attach SwiftPM coverage
   JSON/profile data, xUnit output when available, Xcode `.xcresult` bundles,
   result metadata, build logs, diagnostics, DerivedData/product paths,
   product/binary/bundle sizes, coverage/result artifact sizes, cache deltas,
   and per-feature-flag size cohorts.
6. Complete registry-backed wrkstrm app-minimums inspection so Vaporize can
   report whether each app has release-feature manifest, generated xcconfigs,
   generated `ReleaseFeatures.swift`, project wiring, and
   `digikoma-release-features` provenance.
7. Create dedicated benchmark receipts for cold builds, warm cache hits, cache
   misses, and disk usage before making fleet performance or space-saving
   release claims.
8. Project `vaporize.engineering.docc` through the future
   `wrkstrm.com/engineering` pipeline without deriving new claims from prose.
9. Hold the Engineering, QA, and Marketing PRD review session before the next
   major Vaporize coding slice begins.
10. Promote approved performance marketing claims only after attaching the
   relevant benchmark receipt.
11. Quarantine or migrate remaining substrate-owned XcodeGen surfaces.
12. Add periodic vaporware buddy heartbeat and build-watch checks so Vaporize
    can report health and route failing buddies into modification requests.

The machine-readable companion is
`vaporize-v0.0.1-provenance-artifact.json`.
