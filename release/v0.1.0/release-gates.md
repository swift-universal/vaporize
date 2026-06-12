# Vaporize v0.1.0 - Release Gates

**Status:** release-prep draft  
**Updated:** 2026-06-12T20:26:28Z  
**Component:** `vaporize@wrkstrm-core.cli`

## Current Verdict

**CONDITIONAL-READY-FOR-RELEASE-REVIEW.**

The focused Vaporize CLI tests pass under the required Swift 6.4 toolchain, and
the current help surface advertises the release's implemented modes including
`use`. Final release approval is still gated by documentation cleanup, release
packet validation, and explicit disposition of open feature beads.

## Gate Table

| Gate | Status | Evidence |
| --- | --- | --- |
| GATE-01 - PRD authored | PASS | `release/v0.1.0/prd.md` |
| GATE-02 - CUJs authored | PASS | `release/v0.1.0/cuj.md` |
| GATE-03 - Release gates authored | PASS | This file |
| GATE-04 - Launch-review packet authored | PASS | `release/v0.1.0/evidence/launch-review-packet.json` |
| GATE-05 - Focused tests pass | PASS | `xcrun swift test --package-path private/apple/spm/vaporize@wrkstrm-core.cli --filter VaporizeCLITests` passed 9 tests. |
| GATE-06 - Required toolchain identified | PASS-WITH-NOTE | Bare `swift test` used Swift 6.3.2 and failed because Package.swift requires tools 6.4. `xcrun swift` is Swift 6.4 and passed. |
| GATE-07 - CLI help reflects release surface | PASS | `xcrun swift run --package-path ... vaporize@wrkstrm-core.cli --help` advertises `use` and `--common-process-spec`. |
| GATE-08 - CommonProcess use mode tested | PASS | `VaporizeUseCommonProcessTests.swift` decodes valid spec JSON and rejects invalid executable refs. |
| GATE-09 - Vapor inventory tests pass | PASS | Existing `VaporizeVaporInventoryScannerTests.swift` ran inside the 9-test target. |
| GATE-10 - JSON release packet validates | PASS | `jq -e . release/v0.1.0/evidence/launch-review-packet.json` passed. |
| GATE-11 - README matches release surface | BLOCKED | README still needs final audit for Swift tools version, `use` mode, and remaining legacy `craze` wording. Existing README was already modified before this release-prep slice, so this gate is tracked rather than silently edited. |
| GATE-12 - Open feature beads dispositioned | CONDITIONAL-PASS | Follow-ups are named in PRD and launch-review packet; they do not block an internal v0.1.0 release unless founder/Launch Review upgrades one to blocker. |
| GATE-13 - Full repository cleanliness | BLOCKED-BY-EXISTING-TREE | Startup reported 511 diff-files. Release review must use scoped paths, not broad worktree cleanliness. |

## Open Follow-Up Beads

- `FR-VAPORIZE-LIST-TARGETS-substrate-canonical-target-discovery`
- `FR-VAPORIZE-XCODEGEN-INTEGRATION-substrate-canonical-xcodegen-aware-build`
- `FR-VAPORIZE-AUTO-INCREMENT-BUILD-NUMBERS`
- `FR-VAPORIZE-REALIZE-typed-vaporware-unit`
- `FR-VAPORIZE-TOOL-CALL-OBSERVABILITY`
- `FR-VAPORIZE-DRIFT-CATCH-retire-craze-canonical-language`
- `FR-VAPORIZE-PRODUCT-RELEASE-DIR-RENAME-MODE`

## Release Review Questions

- Is v0.1.0 allowed to ship as an internal CLI release with target discovery
  deferred?
- Is `use --common-process-spec` enough for the first CommonProcess-style
  invocation surface, or must a higher-level typed wrapper land before release?
- Should README drift be fixed in this release branch before launch review, or
  carried as a blocking release-docs bead?
