# AppleProjectSpecCore: External `xcrun` Materialization Fix Note

@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("External Xcode Materialization Fix Note")
  @PageImage(purpose: icon, source: "apple-project-spec-core-external-xcrun-fix-note-2026-08-17-icon", alt: "A source declaration becomes a verified external project")
  @PageImage(purpose: card, source: "apple-project-spec-core-external-xcrun-fix-note-2026-08-17-card", alt: "Pkl source, generated project, xcrun execution, and proof remain distinct")
  @Available(macOS, introduced: "0.0.1")
}

@Image(source: "apple-project-spec-core-external-xcrun-fix-note-2026-08-17-hero", alt: "Four separate stations show Pkl source, generated Xcode project, xcrun build proof, and later migration authority")

**Recorded:** 2026-08-17  
**Technical owner:** Wrkstrm CTO  
**Product consulted:** Wrkstrm CPO  
**State:** technical proof recorded; product migration and release remain open.

This is a bounded fix record for Pkl-to-Xcode project materialization. It
documents work in the reusable `AppleProjectSpecCore` generator and gives the
reader a repeatable proof route. The later additive package extraction is
recorded separately; this note does not claim an installed Vaporize runtime,
fleet migration, release readiness, or human approval.

## Why This Matters

Pkl is the editable source of an Apple project; the generated `.xcodeproj` is
the Xcode world-state. That world-state must remain valid when written outside
the source directory. If it silently depends on its output location, then a
project can look correct in a local folder while failing in the release or
review route that materializes it elsewhere.

The correction gives Foundry-style project scaffolding a credible handoff to
the materialization and build layer: one typed Pkl declaration can be rendered
to a generated Xcode project and exercised through the platform's `xcrun`
authority.

## Observed Failure Modes

| Defect | Concrete consequence | Correct owner |
| --- | --- | --- |
| Local Swift package paths were written relative to the generated project | An output project under a temporary directory resolved a source-relative package path from `/tmp`, not from the Pkl source root | `AppleProjectSpecCore` renderer |
| Target `.xcconfig` declarations were not materialized | A Pkl configuration could exist without becoming an Xcode configuration-file reference or target base configuration | `AppleProjectSpecCore` renderer |
| An application with no explicit Info.plist received no generated-plist setting | Xcode could fail late because the application had neither an Info.plist path nor `GENERATE_INFOPLIST_FILE = YES` | `AppleProjectSpecCore` renderer |

The tempting but wrong fix would have been a Vaporize CLI-only path rewrite.
That would leave direct users of the generator with the same output defect.

## Correction Applied

The generator now keeps the Pkl source directory and generated-project output
directory as distinct typed locations. It rebases only typed path fields while
rendering the Xcode project:

- local Swift package locations;
- source-group and source-file references;
- target `.xcconfig` references and their `baseConfigurationReference` links;
- explicit Info.plist paths.

Shell scripts are intentionally not rewritten. They may contain deliberate
variables, URLs, or command syntax and are not typed file locations.

For an application target without an explicit Info.plist path, the generator
now emits `GENERATE_INFOPLIST_FILE = YES` instead of relying on a later Xcode
default.

The permanent fixture is deliberately shaped to expose the old defect:

`tests/proving-grounds/pkl-project-generation/portable-local-package-build-variants/`

It has a local Swift package plus Debug, Dogfood, TestFlight, and Release
configuration files. The test generates the Xcode project outside that Pkl
source root, confirms the Dogfood setting, then builds it with `xcrun`.

## Proof Frontier

| Claim | Evidence recorded | Status |
| --- | --- | --- |
| Reusable generator source changed | `AppleProjectXcodeProjectGenerator.swift` now owns source/output root separation, xcconfig materialization, and generated application plist behavior | recorded |
| Regression contract | A focused Swift Testing target materializes the persistent fixture in an external directory | passed |
| Xcode configuration projection | `xcrun xcodebuild -showBuildSettings` reports `PORTABLE_VARIANT = dogfood` | passed |
| Generated-project build | unsigned macOS `xcrun xcodebuild build` returned `** BUILD SUCCEEDED **` | passed |
| Standalone generator package and `cli-s` | The additive `apple-project-spec` package now exposes `AppleProjectSpecCore` and `apple-project-spec.cli-s`; its focused package proof remains distinct from this historical Vaporize-hosted receipt | extracted separately |
| Canonical Hello World consumer migration | Its historical project remains preserved until the migration Bead completes | open |
| Installed Vaporize behavior | This record runs a source-target test, not an installed executable | not exercised |
| Fleet Pkl parity, release, and human approval | Outside this correction's authority | not claimed |

This frontier is intentional. Passing source and generated-project evidence is
meaningful, but it is not a substitute for the later owner-specific gates.

## Repeatable Technical Receipt

From the `vaporize@wrkstrm-core.cli` package root, the focused proof was
exercised with:

```sh
VAPORIZE_DISABLE_SWIFTLY=1 xcrun swift test --skip-update \
  --filter AppleProjectSpecCoreXcrunMaterializationTests
```

The test result was:

```text
Test "AppleProjectSpecCore materializes an external project that xcrun builds" passed
Test run with 1 test in 0 suites passed
```

The test invokes both of these platform-owned steps itself:

```text
xcrun xcodebuild -showBuildSettings ... -configuration Dogfood
xcrun xcodebuild build ... -sdk macosx CODE_SIGNING_ALLOWED=NO
```

The observed build output contained `PORTABLE_VARIANT = dogfood` and
`** BUILD SUCCEEDED **`.

`VAPORIZE_DISABLE_SWIFTLY=1` is a current source-build test environment
constraint while the package is cohosted with Vaporize's conditional toolchain
dependencies. It keeps the proof bounded to `AppleProjectSpecCore`; it does
not prove that the installed Vaporize product or a separate generator package
has the same behavior. The dedicated package extraction is therefore a
separate open Bead rather than hidden scope.

## Linked Corrective Work

- `bug-apple-project-spec-core-source-root-relative-package-paths-v000-000-001-2026-08-17`
- `feature-apple-project-spec-core-xcconfig-materialization-v000-000-001-2026-08-17`
- `bug-apple-project-spec-core-application-generated-info-plist-v000-000-001-2026-08-17`

The following independently-closeable architectural work remains open:

- `feature-apple-project-spec-core-cli-xcrun-materialization-v000-000-001-2026-08-17`

### Final Command Topology

| Layer | Canonical artifact | Responsibility |
| --- | --- | --- |
| Shared implementation | `AppleProjectSpecCore` library | The one Pkl parser, PBX renderer, and generator-receipt implementation. |
| CLI 1 | `apple-project-spec.cli-s` | Standalone operator and integration-test surface over the shared library. |
| CLI 2 | `foundry.cli-s@wrkstrm-core.clia.sh` | Existing Foundry source-workflow CLI; later links the shared library directly. |

There is no adapter CLI between these two frontends, and Foundry does not shell
out to CLI 1. Both CLIs invoke the same library.

The additive AppleProjectSpecCore **library** and CLI 1 now exist as the
separate `apple-project-spec` package. The standalone tool proves the
library's real request-to-receipt behavior without Foundry; it does not carry
a second renderer.

The next, independently-closeable move is
`feature-foundry-apple-project-spec-library-adoption-v000-000-001-2026-08-17`:
the existing Foundry CLI links the extracted library directly, makes the
source-to-derived request explicit, and retains CLI 1 for independent testing.
Only after that can a consumer migration move through Foundry. The legacy
project and `project.yml` stay preserved until that consumer migration has its
own receipts.

## Review Boundary

This note gives a reviewer a durable route to the source, fixture, proof
command, corrective Beads, and owner roles. The next decision is not whether a
test passed; it is whether the separately scoped extraction and consumer
migration should proceed. Release and human approval remain explicit later
transitions.

See <doc:project-generation-and-migration> for the wider Pkl migration model
and <doc:release-evidence-and-gates> for the gates this note does not satisfy.

The `0.0.1` manifest test scheme is bundled at
`resources/v0.0.1.apple-project-spec-core-external-xcrun-fix-note.manifest-test-scheme.su.json`.
