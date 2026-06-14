@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Feature Test Lifecycle")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Feature Test Lifecycle

Every major Vaporize feature should have a targetable SwiftPM test bundle.

The purpose is not just organization. Feature bundles let assistants run proof
for the feature they are changing, migrate old broad tests into precise
coverage, and keep release review tied to CUJs rather than raw test count.

## Rule

For a major feature:

1. Draft or update the product definition, PRD, and CUJ.
2. Hold the Engineering, QA, and Marketing PRD review session and record a
   `GO`, `GO-WITH-NOTES`, or `NO-GO` decision.
3. Add a targetable SwiftPM test bundle for that feature.
4. Add tests to the feature bundle before changing or deleting older coverage.
5. Run the feature bundle directly through Vaporize's toolchain route.
6. Update the CUJ coverage artifact and release packet counts.
7. Delete or retire older duplicate tests only after the replacement bundle,
   receipt, and CUJ count name the behavior being migrated.

The replacement proof must exist before deletion. Test deletion is allowed as
coverage migration, not as cleanup detached from release evidence.

## Command Shape

```sh
vaporize toolchain -- swift test \
  --package-path private/universal/substrate/collectives/wrkstrm-core/private/apple/spm/vaporize@wrkstrm-core.cli \
  --filter <FeatureBundleName>
```

The full package suite still matters before release, but feature work should
start with the focused bundle. That keeps the proof local and keeps failures
understandable.

## Current Bundle Map

The v0.0.1 release packet currently names 17 active CUJ-specific bundles. CUJ-16
is the target-feature inspection bundle and CUJ-17 is the release-doctor bundle:

```text
VaporizeCUJ16TargetFeaturesTests
VaporizeCUJ17ReleaseDoctorTests
```

Those bundles prove target-feature receipt shape, target inference, stale
xcconfig detection, generated Swift provenance detection, release-spine
coherence, missing-gate failure, unresolved-root rejection, and CLI parsing.

## Release Review

Release review should compare the current executable tests against the
CUJ-derived obligation floor. If the suite has more tests than required, that is
healthy but not self-justifying. The requirement comes from PRD and CUJ coverage,
not from whatever number the package currently happens to contain.
