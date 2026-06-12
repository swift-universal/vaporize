# Vaporize v0.0.1 - Release Gates

**Status:** release-prep draft; blocked pending Pkl-backed Xcode world-state generation
**Updated:** 2026-06-12T23:06:11Z
**Component:** `vaporize@wrkstrm-core.cli`
**Tool classification:** `internal-essential-tool`

## Current Verdict

**BLOCKED-FOR-INTERNAL-ESSENTIAL-RELEASE.**

The CUJ-derived test coverage contract now defines the required floor:
53 Swift test obligations plus 4 release evidence checks across 12 active CUJs.
The Vaporize package tests pass 70 executable Swift tests across 12 targetable
CUJ-specific SwiftPM bundles through Vaporize's owned Xcode-selected toolchain
mode. The approved Swift YAML read bridge,
PklSwift-backed Pkl parity specimen, transitional YAML generation slice, and
major-feature test expansion are landed and receipted. Final internal v0.0.1
release approval is still blocked because substrate-owned Apple project
generation must move off XcodeGen and onto an owned Pkl-backed `.xcodeproj`
world-state path or be explicitly quarantined.

## Gate Table

| Gate | Status | Evidence |
| --- | --- | --- |
| GATE-01 - PRD authored | PASS | `release/v0.0.1/prd.md` |
| GATE-02 - CUJs authored | PASS | `release/v0.0.1/cuj.md` |
| GATE-03 - Release gates authored | PASS | This file |
| GATE-04 - Launch-review packet authored | PASS | `release/v0.0.1/evidence/launch-review-packet.json` |
| GATE-05 - CUJ-derived package tests pass | PASS | `release/v0.0.1/evidence/cuj-test-coverage.json` requires 53 Swift test obligations plus 4 release evidence checks across 12 active CUJs. `vaporize toolchain -- swift test --package-path private/apple/spm/vaporize@wrkstrm-core.cli` passed 70 executable tests across 12 CUJ-specific SwiftPM bundles. |
| GATE-06 - Required toolchain owned by Vaporize | PASS-WITH-NOTE | Bare `swift test` used Swift 6.3.2 and failed because Package.swift requires tools 6.4. Vaporize `toolchain` now owns Xcode-selected Swift via internal `xcrun`. |
| GATE-07 - CLI help reflects release surface | PASS | Vaporize help advertises `use`, `toolchain`, `validate-json`, `inspect-project-yml`, `compare-project-yml-pkl`, `generate-project-yml`, and `--common-process-spec`. |
| GATE-08 - CommonProcess use mode tested | PASS | `VaporizeUseCommonProcessTests.swift` decodes valid spec JSON, loads a spec from disk, and rejects invalid executable refs. |
| GATE-09 - Vapor inventory tests pass | PASS | `VaporizeCUJ07VaporInventoryTests` covers scanner status classification, legacy key handling, malformed JSON, path errors, and text/JSON rendering. |
| GATE-10 - JSON release packet validates | PASS | `vaporize validate-json --path release/v0.0.1/evidence/launch-review-packet.json` passed. |
| GATE-11 - README matches release surface | BLOCKED | README still needs final audit for Swift tools version, `use` mode, and remaining legacy `craze` wording. Existing README was already modified before this release-prep slice, so this gate is tracked rather than silently edited. |
| GATE-12 - Open feature beads dispositioned | BLOCKED | Follow-ups are named in PRD and launch-review packet; the Pkl project-generation bead is a release blocker for internal v0.0.1. |
| GATE-13 - Full repository cleanliness | BLOCKED-BY-EXISTING-TREE | Startup reported 511 diff-files. Release review must use scoped paths, not broad worktree cleanliness. |
| GATE-14 - Pkl project generation for owned Apple surfaces | BLOCKED | Concourse now has PklSwift-backed transitional YAML generation, but final internal release still waits until our XcodeGen-backed owned surfaces move to Pkl-backed `.xcodeproj` world-state generation or are explicitly quarantined as historical/external compatibility. |
| GATE-15 - Swift YAML read bridge | PASS | `inspect-project-yml` parsed `private/apple/apps/concourse/project.yml` into Swift `AppleProjectSpec` data and emitted `release/v0.0.1/evidence/concourse-project-yml-inspection.receipt.json`; fleet audit parsed 155/155 discovered `project.yml` files and emitted `release/v0.0.1/evidence/project-yml-fleet-parse-audit.receipt.json`. This is read-only parity evidence, not release-unblocking generation or build proof. |
| GATE-16 - Old tool / Vaporize build comparison | PASS-WITH-NOTE | Old XcodeGen script build and Vaporize app build both pass for Concourse after Vaporize derives the legacy `WRAPPER_NAME` from `project.yml`. Evidence: `release/v0.0.1/evidence/concourse-old-tool-vaporize-build-comparison.receipt.json`. This proves one specimen, not fleet build parity. |
| GATE-17 - Provenance artifact captured | PASS | `release/v0.0.1/evidence/vaporize-v0.0.1-provenance-artifact.json` and `.md` collect the receipts, validation commands, savepoint events, proven claims, unproven claims, and forward path for the Pkl migration slice. |
| GATE-18 - Concourse Pkl parity specimen | PASS | `private/apple/apps/concourse/project.pkl` amends `Pkl/AppleProjectSpec.pkl`; `compare-project-yml-pkl` uses PklSwift and reports zero mismatches in `release/v0.0.1/evidence/concourse-project-yml-pkl-comparison.receipt.json`. This proves one Pkl parity specimen, not buildable project generation. |
| GATE-19 - Concourse Pkl transitional YAML generation | PASS-WITH-NOTE | `generate-project-yml` uses PklSwift to emit `release/v0.0.1/evidence/generated/concourse.apple-project-spec.generated.yml` plus `release/v0.0.1/evidence/concourse-pkl-project-yml-generation.receipt.json`; `release/v0.0.1/evidence/concourse-generated-yml-pkl-comparison.receipt.json` proves generated YAML still matches Pkl. The receipt explicitly says `.xcodeproj` world-state was not generated. |

## Open Follow-Up Beads

- `FR-VAPORIZE-LIST-TARGETS-substrate-canonical-target-discovery`
- `FR-VAPORIZE-PKL-PROJECT-GENERATION-move-owned-xcodegen-surfaces-to-pkl`
- `FR-VAPORIZE-AUTO-INCREMENT-BUILD-NUMBERS`
- `FR-VAPORIZE-REALIZE-typed-vaporware-unit`
- `FR-VAPORIZE-TOOL-CALL-OBSERVABILITY`
- `FR-VAPORIZE-DRIFT-CATCH-retire-craze-canonical-language`
- `FR-VAPORIZE-PRODUCT-RELEASE-DIR-RENAME-MODE`

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
- Should Vaporize preserve this legacy `WRAPPER_NAME` compatibility only until
  Pkl generation lands, or should it remain as a permanent compatibility bridge
  for quarantined XcodeGen projects?
