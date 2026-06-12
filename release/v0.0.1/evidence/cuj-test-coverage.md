# Vaporize v0.0.1 - CUJ Test Coverage

**Generated:** 2026-06-12T23:06:11Z
**Status:** active CUJ coverage floor defined
**Component:** `vaporize@wrkstrm-core.cli`

## Rule

The required test count is derived from PRD requirements through active draft
CUJs. The executable Swift suite may exceed the required floor, but release
review must compare actual tests against the CUJ-derived requirement rather
than treating the current test count as self-justifying.

## Counts

| Metric | Count |
| --- | ---: |
| Active CUJs | 12 |
| Deferred CUJs | 2 |
| Required Swift test obligations | 53 |
| Required release evidence checks | 4 |
| Current executable Swift tests | 64 |

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
| CUJ-09 | FR-012, FR-013, FR-014 | 0 | PRD, CUJ, release gates, launch-review packet checks |
| CUJ-10 | FR-016 | 4 | Pkl parity comparison, loader failure, mismatch reporting, script normalization |
| CUJ-11 | FR-017 | 3 | Transitional YAML generation, renderer round-trip, generated YAML/Pkl comparison evidence |
| CUJ-12 | FR-009 | 1 | Graph forwarded argument parsing |

## Deferred Coverage

- Pkl-backed `.xcodeproj` world-state generation remains deferred and release
  blocking.
- `list-targets` target discovery remains deferred and outside the current
  v0.0.1 green path.

The machine-readable companion is `cuj-test-coverage.json`.
