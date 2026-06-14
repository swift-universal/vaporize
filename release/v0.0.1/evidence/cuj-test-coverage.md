# Vaporize v0.0.1 - CUJ Test Coverage

**Generated:** 2026-06-14T00:34:28Z
**Status:** active CUJ coverage floor defined
**Component:** `vaporize@wrkstrm-core.cli`
**Schema:** `vaporize-schemas v0.0.1` / `VaporizeCUJTestCoverageModel`

## Rule

The required test count is derived from PRD requirements through active draft
CUJs. The executable Swift suite may exceed the required floor, but release
review must compare actual tests against the CUJ-derived requirement rather
than treating the current test count as self-justifying.

## Counts

| Metric | Count |
| --- | ---: |
| Active CUJs | 15 |
| Deferred CUJs | 2 |
| Required Swift test obligations | 64 |
| Required release evidence checks | 5 |
| Required targetable test obligations | 69 |
| Current executable Swift tests | 82 |

## Targetable Test Bundles

| CUJ | SwiftPM test target | Current tests |
| --- | --- | ---: |
| CUJ-01 | `VaporizeCUJ01SwiftPMCLITests` | 7 |
| CUJ-02 | `VaporizeCUJ02MacAppTests` | 14 |
| CUJ-03 | `VaporizeCUJ03PassThroughTests` | 4 |
| CUJ-04 | `VaporizeCUJ04CommonProcessUseTests` | 4 |
| CUJ-05 | `VaporizeCUJ05ToolchainTests` | 6 |
| CUJ-06 | `VaporizeCUJ06JSONValidationTests` | 2 |
| CUJ-07 | `VaporizeCUJ07VaporInventoryTests` | 16 |
| CUJ-08 | `VaporizeCUJ08ProjectYMLInspectionTests` | 5 |
| CUJ-09 | `VaporizeCUJ09ReleaseReviewTests` | 5 |
| CUJ-10 | `VaporizeCUJ10YMLPklComparisonTests` | 4 |
| CUJ-11 | `VaporizeCUJ11PklYMLGenerationTests` | 3 |
| CUJ-12 | `VaporizeCUJ12PackageGraphTests` | 1 |
| CUJ-13 | `VaporizeCUJ13YMLPklImportTests` | 4 |
| CUJ-14 | `VaporizeCUJ14PklXcodeProjectGenerationTests` | 3 |
| CUJ-15 | `VaporizeCUJ15XcodeProductCacheTests` | 4 |

## Coverage By CUJ

| CUJ | PRD refs | Required Swift tests | Current evidence |
| --- | --- | ---: | --- |
| CUJ-01 | FR-001, FR-002, FR-004 | 5 | Command identity, CLI build parsing, CLI installer install/uninstall args, install-state matchers |
| CUJ-02 | FR-003, FR-004, FR-015 | 9 | App install parsing, Xcode invocation, derived data, bundle-name resolution, invalid Xcode config |
| CUJ-03 | FR-005 | 4 | Pass-through parser normalization and receipt shape |
| CUJ-04 | FR-006 | 4 | CommonProcess decode, file load, validation rejection, receipt shape |
| CUJ-05 | FR-010 | 6 | Toolchain parser normalization, unsupported/empty rejection, receipt shape |
| CUJ-06 | FR-011 | 2 | Valid and invalid Foundation JSON validation |
| CUJ-07 | FR-007, FR-008 | 10 | Scanner status classification, legacy key, malformed JSON, path errors, text/JSON renderer |
| CUJ-08 | FR-015 | 5 | Concourse and multi-target YAML parsing, value/source decoding, read-only bridge evidence |
| CUJ-09 | FR-012, FR-013, FR-014, FR-022 | 0 | Product definition, PRD, CUJ, release gates, launch-review packet checks |
| CUJ-10 | FR-016 | 4 | Pkl parity comparison, loader failure, mismatch reporting, script normalization |
| CUJ-11 | FR-017 | 3 | Transitional YAML generation, renderer round-trip, generated YAML/Pkl comparison evidence |
| CUJ-12 | FR-009 | 1 | Graph forwarded argument parsing |
| CUJ-13 | FR-018 | 4 | Legacy YAML import parsing, generated Pkl evaluation, YAML/Pkl comparison, nested value rendering |
| CUJ-14 | FR-020 | 3 | generate-xcodeproj parsing, Pkl-backed .xcodeproj output, deterministic renderer proof |
| CUJ-15 | FR-003, FR-021 | 4 | Product-cache option parsing, cache-first app lookup, shared workspace build invocation, paired option validation |

## Deferred Coverage

- Fleet Pkl-backed `.xcodeproj` build parity and XcodeGen quarantine
  disposition remain deferred and release blocking.
- Automatic shared-workspace scheme/product discovery remains deferred; CUJ-15
  covers cache-first lookup and shared workspace invocation when the scheme is
  already known.
- `list-targets` target discovery remains deferred and outside the current
  v0.0.1 green path.

The machine-readable companion is `cuj-test-coverage.json`.
