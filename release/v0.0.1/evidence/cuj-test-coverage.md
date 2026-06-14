# Vaporize v0.0.1 - CUJ Test Coverage

**Generated:** 2026-06-14T04:05:00Z
**Status:** active CUJ coverage floor defined
**Component:** `vaporize@wrkstrm-core.cli`
**Schema:** `vaporize-schemas v0.0.1` / `VaporizeCUJTestCoverageModel`

## Rule

The required test count is derived from PRD requirements through active draft
CUJs. The executable Swift suite may exceed the required floor, but release
review must compare actual tests against the CUJ-derived requirement rather
than treating the current test count as self-justifying.

## Feature-Scoped Test Lifecycle

Each major Vaporize feature should have a targetable SwiftPM test bundle. New
feature work first adds tests to the feature bundle, then runs that bundle
directly with `vaporize toolchain -- swift test --filter <FeatureBundle>`.
After the feature bundle proves the behavior and the coverage artifact is
updated, duplicate older/general tests may be deleted in the same change. Test
deletion is allowed only as coverage migration: the replacement bundle, receipt,
and CUJ count must already name the behavior being retired from the old location.

## Counts

| Metric | Count |
| --- | ---: |
| Active CUJs | 19 |
| Deferred CUJs | 1 |
| Required Swift test obligations | 84 |
| Required release evidence checks | 11 |
| Required targetable test obligations | 95 |
| Current executable Swift tests | 102 |

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
| CUJ-16 | `VaporizeCUJ16TargetFeaturesTests` | 5 |
| CUJ-17 | `VaporizeCUJ17ReleaseDoctorTests` | 5 |
| CUJ-18 | `VaporizeCUJ18ListTargetsTests` | 5 |
| CUJ-19 | `VaporizeCUJ19WorkspaceCacheDiscoveryTests` | 5 |

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
| CUJ-09 | FR-012, FR-013, FR-014, FR-022, FR-025, FR-026 | 0 | Product definition, PRD, PRD review session, vaporware modification request discipline, CUJ, release gates, launch-review packet, engineering DocC catalog checks |
| CUJ-10 | FR-016 | 4 | Pkl parity comparison, loader failure, mismatch reporting, script normalization |
| CUJ-11 | FR-017 | 3 | Transitional YAML generation, renderer round-trip, generated YAML/Pkl comparison evidence |
| CUJ-12 | FR-009 | 1 | Graph forwarded argument parsing |
| CUJ-13 | FR-018 | 4 | Legacy YAML import parsing, generated Pkl evaluation, YAML/Pkl comparison, nested value rendering |
| CUJ-14 | FR-020 | 3 | generate-xcodeproj parsing, Pkl-backed .xcodeproj output, deterministic renderer proof |
| CUJ-15 | FR-003, FR-021 | 4 | Product-cache option parsing, cache-first app lookup, shared workspace build invocation, paired option validation |
| CUJ-16 | FR-023, FR-024 | 5 | Target feature inspection parsing, inferred target, stale xcconfig detection, generated Swift provenance, CLI parsing |
| CUJ-17 | FR-027 | 5 Swift tests; 1 release evidence check | Release doctor parsing, live-spine pass, release-root resolution, missing-gate failure, unresolved-root rejection |
| CUJ-18 | FR-028 | 5 Swift tests; 1 release evidence check | list-targets parsing, legacy YAML discovery, Pkl discovery, directory fallback, missing project-spec rejection |
| CUJ-19 | FR-021, FR-029 | 5 Swift tests; 1 release evidence check | list-targets cache option parsing, missing candidate discovery, warm candidate discovery, non-buildable exclusion, incomplete cache-pair rejection |

## Deferred Coverage

- Fleet Pkl-backed `.xcodeproj` build parity and XcodeGen quarantine
  disposition remain deferred and release blocking.
- Workspace product-cache candidate discovery is covered as a first slice; CUJ-15
  covers cache-first lookup and shared workspace invocation when the scheme is
  already known, CUJ-18 supplies target/scheme discovery facts, and CUJ-19 maps
  buildable target facts to warm/missing shared DerivedData product candidates.
- `list-targets` project target discovery is covered as a first slice; it does
  not build, install, generate `.xcodeproj` world-state, parse `.xcworkspace`
  graph membership, warm the cache, prove fleet cache coverage, or measure disk
  savings.
- wrkstrm app-minimums inspection has a target-level first slice; fleet
  registry-level inspection remains a follow-up.

The machine-readable companion is `cuj-test-coverage.json`.
