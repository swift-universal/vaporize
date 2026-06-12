# Vaporize v0.0.1 - Release Gates

**Status:** release-prep draft; blocked pending Pkl project-generation migration
**Updated:** 2026-06-12T21:16:27Z
**Component:** `vaporize@wrkstrm-core.cli`
**Tool classification:** `internal-essential-tool`

## Current Verdict

**BLOCKED-FOR-INTERNAL-ESSENTIAL-RELEASE.**

The focused Vaporize CLI tests pass through Vaporize's owned Xcode-selected
toolchain mode, and the current help surface advertises the release's
implemented modes including `use`, `toolchain`, `validate-json`, and
`inspect-project-yml`. The approved Swift YAML read bridge is now landed and
receipted for Concourse. Final internal v0.0.1 release approval is still
blocked because substrate-owned Apple project generation must move off XcodeGen
and onto a Pkl-backed owned path.

## Gate Table

| Gate | Status | Evidence |
| --- | --- | --- |
| GATE-01 - PRD authored | PASS | `release/v0.0.1/prd.md` |
| GATE-02 - CUJs authored | PASS | `release/v0.0.1/cuj.md` |
| GATE-03 - Release gates authored | PASS | This file |
| GATE-04 - Launch-review packet authored | PASS | `release/v0.0.1/evidence/launch-review-packet.json` |
| GATE-05 - Focused tests pass | PASS | `vaporize toolchain -- swift test --package-path private/apple/spm/vaporize@wrkstrm-core.cli --filter VaporizeCLITests` passed 15 tests. |
| GATE-06 - Required toolchain owned by Vaporize | PASS-WITH-NOTE | Bare `swift test` used Swift 6.3.2 and failed because Package.swift requires tools 6.4. Vaporize `toolchain` now owns Xcode-selected Swift via internal `xcrun`. |
| GATE-07 - CLI help reflects release surface | PASS | Vaporize help advertises `use`, `toolchain`, `validate-json`, `inspect-project-yml`, and `--common-process-spec`. |
| GATE-08 - CommonProcess use mode tested | PASS | `VaporizeUseCommonProcessTests.swift` decodes valid spec JSON and rejects invalid executable refs. |
| GATE-09 - Vapor inventory tests pass | PASS | Existing `VaporizeVaporInventoryScannerTests.swift` ran inside the 15-test target. |
| GATE-10 - JSON release packet validates | PASS | `vaporize validate-json --path release/v0.0.1/evidence/launch-review-packet.json` passed. |
| GATE-11 - README matches release surface | BLOCKED | README still needs final audit for Swift tools version, `use` mode, and remaining legacy `craze` wording. Existing README was already modified before this release-prep slice, so this gate is tracked rather than silently edited. |
| GATE-12 - Open feature beads dispositioned | BLOCKED | Follow-ups are named in PRD and launch-review packet; the Pkl project-generation bead is a release blocker for internal v0.0.1. |
| GATE-13 - Full repository cleanliness | BLOCKED-BY-EXISTING-TREE | Startup reported 511 diff-files. Release review must use scoped paths, not broad worktree cleanliness. |
| GATE-14 - Pkl project generation for owned Apple surfaces | BLOCKED | Final internal release waits until our XcodeGen-backed owned surfaces move to Pkl or are explicitly quarantined as historical/external compatibility. |
| GATE-15 - Swift YAML read bridge | PASS | `inspect-project-yml` parsed `private/apple/apps/concourse/project.yml` into Swift `AppleProjectSpec` data and emitted `release/v0.0.1/evidence/concourse-project-yml-inspection.receipt.json`; fleet audit parsed 155/155 discovered `project.yml` files and emitted `release/v0.0.1/evidence/project-yml-fleet-parse-audit.receipt.json`. This is read-only parity evidence, not release-unblocking generation or build proof. |
| GATE-16 - Old tool / Vaporize build comparison | PASS-WITH-NOTE | Old XcodeGen script build and Vaporize app build both pass for Concourse after Vaporize derives the legacy `WRAPPER_NAME` from `project.yml`. Evidence: `release/v0.0.1/evidence/concourse-old-tool-vaporize-build-comparison.receipt.json`. This proves one specimen, not fleet build parity. |

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
- Is the read-only `inspect-project-yml` bridge enough intake surface for the
  first Pkl parity specimen, or should the next slice add a typed comparison
  receipt before project generation?
- Should Vaporize preserve this legacy `WRAPPER_NAME` compatibility only until
  Pkl generation lands, or should it remain as a permanent compatibility bridge
  for quarantined XcodeGen projects?
