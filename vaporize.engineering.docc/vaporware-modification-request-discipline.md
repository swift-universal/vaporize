@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Vaporware Modification Request Discipline")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Vaporware Modification Request Discipline

A vaporware modification request is release work.

A feature request and a vaporware modification request are related, but they are
not the same thing.

A feature request is product input: a user, reviewer, or operator wants a new
capability, behavior, workflow, or claim. It belongs in product definition, PRD,
CUJs, creative selection, competitor framing, and marketing claim work.

A vaporware modification request is engineering execution: the substrate agrees
to modify a vaporware unit. It belongs in implementation, feature flags,
feature-status records, tests, receipts, schema fixtures, release gates, and
savepoints.

Feature requests can justify or spawn vaporware modification requests. Vaporware modification requests are what assistants execute.

## Required Shape

Every Vaporize vaporware modification request must do the following before it is
treated as release-ready:

- Create or attach to a named feature flag, feature status record, or
  release-feature cohort.
- Add or update targetable tests for the changed behavior.
- Run the smallest feature-scoped test bundle that proves the behavior.
- Update release evidence when the behavior affects release claims, receipts,
  launch review, schema fixtures, or app/build output.
- Update the CUJ coverage contract when the change adds, removes, or migrates a
  required test or release evidence obligation.
- Record any exception explicitly in the PRD, CUJ, release gate, or receipt
  surface.

## Feature Flag Rule

A true vaporware modification request should introduce a controlled flag or
feature-status surface unless the change is purely documentation, fixture
mirroring, or release-evidence bookkeeping.

If a flag is not created, the release evidence must say why:

- The request is documentation-only.
- The request only mirrors already-approved evidence.
- The request is a test-only or refactor-only change with no behavior exposure.
- The request attaches to an existing named feature flag or release-feature
  cohort.

Silent "no flag needed" is not release discipline.

## Test Rule

Tests are part of the modification request, not a later cleanup lane.

The expected test shape is:

- Feature behavior gets a feature-scoped or CUJ-scoped test bundle.
- Release evidence behavior gets CUJ-09 release-review assertions.
- Schema-backed evidence gets schema-universal fixture tests.
- App target feature behavior gets target/app fixture tests and a receipt.
- Replacing old coverage is allowed only when the replacement test bundle and
  coverage artifact name the behavior being migrated.

## Release Evidence Rule

The release packet must be updated when the modification changes any of these:

- user-visible feature list
- PRD requirements
- CUJs or required test counts
- release gates
- launch-review packet fields
- provenance claims or receipts
- schema-universal fixtures
- benchmark, build-size, cache, or feature-flag claims
- wrkstrm app minimums, release-feature manifests, or generated build configs

If release evidence is unchanged, the implementation notes or receipt should
state why the modification does not affect release review.

## Vaporize Enforcement

For Vaporize, this discipline is enforced through:

- `release/v0.0.1/prd.md`
- `release/v0.0.1/cuj.md`
- `release/v0.0.1/evidence/cuj-test-coverage.json`
- `release/v0.0.1/release-gates.md`
- `release/v0.0.1/evidence/launch-review-packet.json`
- `release/v0.0.1/evidence/vaporize-v0.0.1-provenance-artifact.json`
- CUJ-specific SwiftPM test bundles
- schema-universal fixtures when evidence becomes schema-backed

The practical rule for assistants is simple: do not call a behavior-changing
vaporware modification complete until its feature flag or feature-status story,
tests, and release evidence are all accounted for.
