# Vaporize v0.0.1 - Release Gates

**Status:** release-prep draft; blocked pending fleet Pkl-backed Xcode world-state parity
**Updated:** 2026-06-13T21:28:11Z
**Component:** `vaporize@wrkstrm-core.cli`
**Tool classification:** `internal-essential-tool`

## Current Verdict

**BLOCKED-FOR-INTERNAL-ESSENTIAL-RELEASE.**

The CUJ-derived test coverage contract now defines the required floor:
64 Swift test obligations plus 4 release evidence checks across 15 active CUJs.
The Vaporize package tests pass 81 executable Swift tests across 15 targetable
CUJ-specific SwiftPM bundles through Vaporize's owned Xcode-selected toolchain
mode. The approved Swift YAML read bridge,
PklSwift-backed Pkl parity specimen, transitional YAML generation slice,
legacy-YAML-to-Pkl import slice, and major-feature test expansion are landed
and receipted. The first Pkl-backed `.xcodeproj` world-state generation slice is
also landed for Creative Selection v0.2. The shared Xcode workspace product
cache first slice is landed for cache-first app lookup and shared workspace
build invocation. The initial
schema-universal extraction for Vaporize evidence is also landed as
`vaporize-schemas v0.0.1`. Final internal v0.0.1 release approval is still
blocked because substrate-owned Apple project generation still needs fleet build
parity, scheme/resource/package feature coverage, and explicit quarantine
disposition for any remaining XcodeGen surfaces.

## Gate Table

| Gate | Status | Evidence |
| --- | --- | --- |
| GATE-01 - PRD authored | PASS | `release/v0.0.1/prd.md` |
| GATE-02 - CUJs authored | PASS | `release/v0.0.1/cuj.md` |
| GATE-03 - Release gates authored | PASS | This file |
| GATE-04 - Launch-review packet authored | PASS | `release/v0.0.1/evidence/launch-review-packet.json` |
| GATE-05 - CUJ-derived package tests pass | PASS | `release/v0.0.1/evidence/cuj-test-coverage.json` requires 64 Swift test obligations plus 4 release evidence checks across 15 active CUJs. `vaporize toolchain -- swift test --package-path private/apple/spm/vaporize@wrkstrm-core.cli` passed 81 executable tests across 15 CUJ-specific SwiftPM bundles. |
| GATE-06 - Required toolchain owned by Vaporize | PASS-WITH-NOTE | Current host check at 2026-06-13T21:39:03Z found bare `swift` and `vaporize toolchain -- swift` both reporting Apple Swift 6.4, and focused CUJ-15 took `6.80s` through both routes once warm. Earlier release-prep runs observed bare Swift drift. Vaporize remains the owned route because it stabilizes toolchain policy and release evidence even when host PATH happens to be correct. |
| GATE-07 - CLI help reflects release surface | PASS | Vaporize help advertises `use`, `toolchain`, `validate-json`, `inspect-project-yml`, `compare-project-yml-pkl`, `import-project-yml`, `generate-project-yml`, `generate-xcodeproj`, `--common-process-spec`, `--xcode-product-cache-workspace`, and `--xcode-product-cache-derived-data-path`. |
| GATE-08 - CommonProcess use mode tested | PASS | `VaporizeUseCommonProcessTests.swift` decodes valid spec JSON, loads a spec from disk, and rejects invalid executable refs. |
| GATE-09 - Vapor inventory tests pass | PASS | `VaporizeCUJ07VaporInventoryTests` covers scanner status classification, legacy key handling, malformed JSON, path errors, and text/JSON rendering. |
| GATE-10 - JSON release packet validates | PASS | `vaporize validate-json --path release/v0.0.1/evidence/launch-review-packet.json` passed. |
| GATE-11 - README matches release surface | PASS | README names Swift tools 6.4, `use`, `toolchain`, `validate-json`, Apple project migration commands, and shared Xcode workspace product-cache flags. Historical `x-craze-collapse-path` remains documented only as read-only compatibility. |
| GATE-12 - Open feature beads dispositioned | BLOCKED | Follow-ups are named in PRD and launch-review packet; the Pkl project-generation bead is a release blocker for internal v0.0.1. |
| GATE-13 - Full repository cleanliness | BLOCKED-BY-EXISTING-TREE | Startup reported 511 diff-files. Release review must use scoped paths, not broad worktree cleanliness. |
| GATE-14 - Pkl project generation for owned Apple surfaces | BLOCKED | Creative Selection v0.2 now proves first-slice Pkl-backed `.xcodeproj` world-state generation. Final internal release still waits for fleet build parity, scheme/resource/package feature coverage, and explicit quarantine disposition for any remaining XcodeGen-backed owned surfaces. |
| GATE-15 - Swift YAML read bridge | PASS | `inspect-project-yml` parsed `private/apple/apps/concourse/project.yml` into Swift `AppleProjectSpec` data and emitted `release/v0.0.1/evidence/concourse-project-yml-inspection.receipt.json`; fleet audit parsed 155/155 discovered `project.yml` files and emitted `release/v0.0.1/evidence/project-yml-fleet-parse-audit.receipt.json`. This is read-only parity evidence, not release-unblocking generation or build proof. |
| GATE-16 - Old tool / Vaporize build comparison | PASS-WITH-NOTE | Old XcodeGen script build and Vaporize app build both pass for Concourse after Vaporize derives the legacy `WRAPPER_NAME` from `project.yml`. Evidence: `release/v0.0.1/evidence/concourse-old-tool-vaporize-build-comparison.receipt.json`. This proves one specimen, not fleet build parity. |
| GATE-17 - Provenance artifact captured | PASS | `release/v0.0.1/evidence/vaporize-v0.0.1-provenance-artifact.json` and `.md` collect the receipts, validation commands, savepoint events, proven claims, unproven claims, and forward path for the Pkl migration slice. |
| GATE-18 - Concourse Pkl parity specimen | PASS | `private/apple/apps/concourse/project.pkl` amends `Pkl/AppleProjectSpec.pkl`; `compare-project-yml-pkl` uses PklSwift and reports zero mismatches in `release/v0.0.1/evidence/concourse-project-yml-pkl-comparison.receipt.json`. This proves one Pkl parity specimen, not buildable project generation. |
| GATE-19 - Concourse Pkl transitional YAML generation | PASS-WITH-NOTE | `generate-project-yml` uses PklSwift to emit `release/v0.0.1/evidence/generated/concourse.apple-project-spec.generated.yml` plus `release/v0.0.1/evidence/concourse-pkl-project-yml-generation.receipt.json`; `release/v0.0.1/evidence/concourse-generated-yml-pkl-comparison.receipt.json` proves generated YAML still matches Pkl. The receipt explicitly says `.xcodeproj` world-state was not generated. |
| GATE-20 - Schema-universal extraction | PASS-WITH-NOTE | Initial `vaporize-schemas v0.0.1` JSON schemas, fixtures, and fixture-backed Swift model package landed under `schema-universal/private/universal/domain/tooling/schema-families/vaporize-schemas/v0.0.1`. The schema files and fixtures validate as JSON through Vaporize, and `schema-tighten audit` reports 0 safe-to-migrate hits for the slice. |
| GATE-21 - Legacy YAML to Pkl import | PASS-WITH-NOTE | `import-project-yml` generated `private/apple/apps/creative-selection-v0.2/project.pkl` from the v0.2 app's legacy `project.yml`; `creative-selection-v0.2-project-yml-pkl-import.receipt.json` records the import and `creative-selection-v0.2-project-yml-pkl-comparison.receipt.json` reports zero mismatches. The receipt explicitly says `.xcodeproj` world-state was not generated. |
| GATE-22 - Pkl Xcode project generation first slice | PASS-WITH-NOTE | `generate-xcodeproj` generated `/tmp/vaporize-creative-selection-v02-generated.xcodeproj` from `private/apple/apps/creative-selection-v0.2/project.pkl`; `creative-selection-v0.2-pkl-xcodeproj-generation.receipt.json` records `buildableWorldStateGenerated=true`, `xcodeProjectGenerated=true`, 1 target, and 4 source files. This proves first-slice world-state generation, not fleet build parity. |
| GATE-23 - Shared Xcode workspace product cache first slice | PASS-WITH-NOTE | CUJ-15 covers product-cache option parsing, paired option validation, cache-first app lookup before local DerivedData, and Xcode build invocation through the shared workspace/DerivedData pair. This proves the invocation/cache-order slice, not automatic workspace scheme discovery or fleet cache warmth. |
| GATE-24 - Positioning and benchmark explainer | PASS-WITH-NOTE | `release/v0.0.1/why-vaporize.md` explains why Vaporize exists, what problems it solves, how it compares to Swift, xcodebuild, and xcrun, current local benchmark numbers, build-space savings theory, user ergonomics, and the benchmark evidence still required before final release claims. |

## Open Follow-Up Beads

- `FR-VAPORIZE-LIST-TARGETS-substrate-canonical-target-discovery`
- `FR-VAPORIZE-PKL-PROJECT-GENERATION-move-owned-xcodegen-surfaces-to-pkl`
- `FR-VAPORIZE-AUTO-INCREMENT-BUILD-NUMBERS`
- `FR-VAPORIZE-REALIZE-typed-vaporware-unit`
- `FR-VAPORIZE-TOOL-CALL-OBSERVABILITY`
- `FR-VAPORIZE-DRIFT-CATCH-retire-craze-canonical-language`
- `FR-VAPORIZE-PRODUCT-RELEASE-DIR-RENAME-MODE`
- `FR-VAPORIZE-XCODE-WORKSPACE-PRODUCT-CACHE-DISCOVERY`

## Release Review Questions

- Which substrate-owned XcodeGen-backed Apple surfaces must migrate to Pkl
  before internal v0.0.1 can release?
- Is `use --common-process-spec` enough for the first CommonProcess-style
  invocation surface, or must a higher-level typed wrapper land before release?
- Should README drift be fixed in this release branch before launch review, or
  carried as a blocking release-docs bead?
- Should the transitional `generate-project-yml` bridge remain as migration
  evidence after the owned `.xcodeproj` generator exists, or be quarantined as
  a temporary parity tool?
- Should the transitional `import-project-yml` bridge remain available after
  the owned `.xcodeproj` generator exists, or become an explicit legacy-only
  migration utility?
- Should Vaporize preserve this legacy `WRAPPER_NAME` compatibility only until
  Pkl generation lands, or should it remain as a permanent compatibility bridge
  for quarantined XcodeGen projects?
- Which project feature slice should follow the first `generate-xcodeproj`
  landing: schemes, resources, local Swift packages, or fleet build parity?
- Should shared workspace cache discovery live under `list-targets`, or should
  Vaporize grow a dedicated workspace product query mode?
- Which benchmark fixture should become the canonical release benchmark:
  Concourse, Creative Selection v0.2, or the maintained huge workspace?
