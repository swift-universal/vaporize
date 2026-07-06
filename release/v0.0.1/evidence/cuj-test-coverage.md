# Vaporize v0.0.1 - CUJ Test Coverage

**Generated:** 2026-06-14T07:21:25Z
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
| Active CUJs | 23 |
| Deferred CUJs | 1 |
| Required Swift test obligations | 116 |
| Required release evidence checks | 13 |
| Required targetable test obligations | 129 |
| Current executable Swift tests | 160 |

## Targetable Test Bundles

| CUJ | SwiftPM test target | Current tests |
| --- | --- | ---: |
| CUJ-01 | `VaporizeCUJ01SwiftPMCLITests` | 20 |
| CUJ-02 | `VaporizeCUJ02MacAppTests` | 14 |
| CUJ-03 | `VaporizeCUJ03PassThroughTests` | 4 |
| CUJ-04 | `VaporizeCUJ04CommonProcessUseTests` | 4 |
| CUJ-05 | `VaporizeCUJ05ToolchainTests` | 11 |
| CUJ-06 | `VaporizeCUJ06JSONValidationTests` | 8 |
| CUJ-07 | `VaporizeCUJ07VaporInventoryTests` | 18 |
| CUJ-08 | `VaporizeCUJ08ProjectYMLInspectionTests` | 5 |
| CUJ-09 | `VaporizeCUJ09ReleaseReviewTests` | 6 |
| CUJ-10 | `VaporizeCUJ10YMLPklComparisonTests` | 5 |
| CUJ-11 | `VaporizeCUJ11PklYMLGenerationTests` | 3 |
| CUJ-12 | `VaporizeCUJ12PackageGraphTests` | 1 |
| CUJ-13 | `VaporizeCUJ13YMLPklImportTests` | 5 |
| CUJ-14 | `VaporizeCUJ14PklXcodeProjectGenerationTests` | 7 |
| CUJ-15 | `VaporizeCUJ15XcodeProductCacheTests` | 4 |
| CUJ-16 | `VaporizeCUJ16TargetFeaturesTests` | 5 |
| CUJ-17 | `VaporizeCUJ17ReleaseDoctorTests` | 7 |
| CUJ-18 | `VaporizeCUJ18ListTargetsTests` | 5 |
| CUJ-19 | `VaporizeCUJ19WorkspaceCacheDiscoveryTests` | 5 |
| CUJ-20 | `VaporizeCUJ20XcodeWorkspaceSchemesTests` | 5 |
| CUJ-21 | `VaporizeCUJ21CUJStateTests` | 6 |
| CUJ-22 | `VaporizeCUJ22ResourceCLIInstallTests` | 8 |
| CUJ-23 | `VaporizeCUJ23ProductProvingGroundTests` | 4 |

## Coverage By CUJ

| CUJ | PRD refs | Required Swift tests | Current evidence |
| --- | --- | ---: | --- |
| CUJ-01 | FR-001, FR-002, FR-004 | 5 | Command identity, CLI build parsing, CLI installer install/uninstall args, install-state matchers |
| CUJ-02 | FR-003, FR-004, FR-015 | 9 | App install parsing, Xcode invocation, derived data, bundle-name resolution, invalid Xcode config |
| CUJ-03 | FR-005 | 4 | Pass-through parser normalization and receipt shape |
| CUJ-04 | FR-006 | 4 | CommonProcess decode, file load, validation rejection, receipt shape |
| CUJ-05 | FR-010 | 11 | Toolchain parser normalization, swift-toolchain DocC routing, macOS fallback routing, non-macOS direct lookup, unsupported/empty rejection, receipt shape |
| CUJ-06 | FR-011 | 3 | Valid and invalid Swift Universal json-formatter-backed validation plus formatter coverage; validate-json-schema engine expected-pass, expected-fail, expectation-mismatch, remote-$ref rejection, and actionable-failure coverage against workstream-schemas v0.0.4 fixtures |
| CUJ-07 | FR-007, FR-008 | 10 | Scanner status classification, legacy key, malformed JSON, path errors, text/JSON renderer |
| CUJ-08 | FR-015 | 5 | Concourse and multi-target YAML parsing, value/source decoding, read-only bridge evidence |
| CUJ-09 | FR-012, FR-013, FR-014, FR-022, FR-025, FR-026 | 0 | Product definition, PRD, PRD review session, vaporware modification request discipline, CUJ, release gates, launch-review packet, engineering DocC catalog checks |
| CUJ-10 | FR-016 | 5 | Pkl parity comparison, checked-in XcodeGen-to-Pkl parity proving grounds, loader failure, mismatch reporting, script normalization |
| CUJ-11 | FR-017 | 3 | Transitional YAML generation, renderer round-trip, generated YAML/Pkl comparison evidence |
| CUJ-12 | FR-009 | 1 | Graph forwarded argument parsing |
| CUJ-13 | FR-018 | 5 | Legacy YAML import parsing, generated Pkl evaluation, YAML/Pkl comparison, every parity proving-ground import, nested value rendering |
| CUJ-14 | FR-020 | 7 | generate-xcodeproj parsing, Pkl-backed .xcodeproj output, deterministic renderer proof, tool releaseIdentity expected-pass, framework/app/unit-test/package/shared-scheme graph expected-pass, above-parity Pkl generation grounds, unsupported-target expected-fail |
| CUJ-15 | FR-003, FR-021 | 4 | Product-cache option parsing, cache-first app lookup, shared workspace build invocation, paired option validation |
| CUJ-16 | FR-023, FR-024 | 5 | Target feature inspection parsing, inferred target, stale xcconfig detection, generated Swift provenance, CLI parsing |
| CUJ-17 | FR-027 | 7 Swift tests; 1 release evidence check | Release doctor parsing, live-spine pass, release-root resolution, missing-gate failure, unresolved-root rejection, unreviewed gate approval failure, follow-up list drift failure |
| CUJ-18 | FR-028 | 5 Swift tests; 1 release evidence check | list-targets parsing, legacy YAML discovery, Pkl discovery, directory fallback, missing project-spec rejection |
| CUJ-19 | FR-021, FR-029 | 5 Swift tests; 1 release evidence check | list-targets cache option parsing, missing candidate discovery, warm candidate discovery, non-buildable exclusion, incomplete cache-pair rejection |
| CUJ-20 | FR-030 | 5 | list-schemes CLI parsing, xcodebuild argument construction, workspace scheme JSON parsing, non-workspace rejection, receipt boundary |
| CUJ-21 | FR-031 | 6 Swift tests; 1 release evidence check | CUJ-state fixture derivation, source metadata preservation, receipt output, coverage contract validation |
| CUJ-22 | FR-002, FR-032 | 8 | Typed simulation proving-ground manifest, processed text resource, copied resource directory, decoded JSON resource, byte-count resource, stale installed bundle replacement, checked-in resource vault CLI install, legacy resource CLI product-gate capture |
| CUJ-23 | FR-033 | 4 Swift tests; 1 release evidence check | Product proving-ground passport profile, Pkl project-generation proving-ground passport, incomplete-passport failure, reusable product-class track catalog, release-doctor coverage |

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
- `list-schemes` Xcode workspace scheme listing is covered as a first slice; it
  asks Xcode for workspace schemes through `xcodebuild -list -json -workspace`
  and records the scheme-list receipt boundary, but it does not build, install,
  warm caches, prove product paths, or measure large-workspace runtime.
- wrkstrm app-minimums inspection has a target-level first slice; fleet
  registry-level inspection remains a follow-up.
- SwiftPM CLI resource-bundle install coverage proves installed CLI resource
  bundles and metadata sidecars; it does not prove app bundle packaging,
  `Bundle.main.infoDictionary` product metadata, Sparkle appcast generation, or
  update signing.
- Product proving-ground passport coverage proves adoption evidence shape; it
  does not approve releases or replace product-specific proving-ground
  scenarios.

The machine-readable companion is `cuj-test-coverage.json`.
