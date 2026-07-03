# Vaporize Product Definition

**Status:** release-prep product contract
**Updated:** 2026-06-14T00:34:28Z
**Component:** `vaporize@wrkstrm-core.cli`
**Release target:** internal essential substrate CLI

## Product Definition

Vaporize is the substrate-owned build, install, run, validation,
project-migration, cache-reuse, and proof gate for assistants working on Swift
and Apple software.

It wraps Swift and Xcode engines with a stable assistant-facing command
contract, release evidence, receipts, and restricted native-tool boundaries.
The product is not a faster compiler or a replacement build system. It is the
owned route that turns software intent into reviewable world-state.

Internally, Vaporize provides engineering pedigree. It forces build, test,
coverage, cache, and release claims to compete on the best engineering
standards available: native Apple/Swift artifacts first, typed records instead
of chat summaries, Kura-queryable samples instead of one-off timing anecdotes,
and release gates that keep unproven claims blocked.

## Primary Users

- Commissioned assistants building, installing, launching, validating, or
  migrating substrate software.
- Release reviewers deciding whether v0.0.1 is internally releasable.
- Apple project migration maintainers moving owned apps from XcodeGen-era YAML
  toward Pkl-backed project world-state.
- rismay as founder, chairman, and operator checking whether the product has a
  coherent reason to exist before more implementation lands.

## Product-Level User Journeys

1. Assistant builds, installs, or runs a SwiftPM CLI/app without composing shell
   choreography. Covered by CUJ-01 and CUJ-02.
2. Assistant validates release JSON without direct `jq`. Covered by CUJ-06.
3. Assistant uses Xcode-selected Swift without direct `xcrun`. Covered by
   CUJ-05.
4. Assistant emits receipts for CommonProcess command execution. Covered by
   CUJ-03 and CUJ-04.
5. Assistant inventories vaporware state from substrate records. Covered by
   CUJ-07.
6. Assistant migrates Apple project generation from legacy `project.yml` toward
   Pkl-backed truth with receipts at every boundary. Covered by CUJ-08, CUJ-10,
   CUJ-11, CUJ-13, and CUJ-14.
7. Assistant reuses a warm Xcode workspace product cache instead of rebuilding
   locally when the shared product already exists. Covered by CUJ-15.
8. Release reviewer evaluates product definition, user journeys, choice
   argument, evidence, gates, and blockers without relying on chat memory.
   Covered by CUJ-09.

## Why Users Choose Vaporize

Choose Vaporize when the work is assistant-run, release-facing, app-facing,
receipt-bearing, toolchain-sensitive, project-migration, or shared-cache work.

Users choose Vaporize because it provides:

- Engineering pedigree: the assistant-facing route fights for proof quality and
  makes the best available engineering standard the default path.
- One recognizable assistant-facing command family for build, install, run,
  validation, inventory, toolchain, CommonProcess, and Apple project migration.
- A policy boundary around native tools: assistants use Vaporize while Vaporize
  may call Swift, Xcode, and JSON parsers internally.
- Evidence that can be reviewed later: release packet references, receipts,
  CUJ coverage, gate results, schema-universal fixtures, and Kura-queryable
  runtime samples backed by Swift/Apple native artifacts.
- A path for owning Apple project generation instead of leaving XcodeGen as the
  forward source of truth.
- A cache-reuse route for large Xcode workspaces that are already kept warm.

## When Not To Choose Vaporize

Do not choose Vaporize as the primary interface when:

- A human is running a one-off local Swift command for private experimentation.
- A task needs a public release or App Store claim; v0.0.1 is internal-only.
- A benchmark claim needs fleet speed or disk-space proof that has not been
  receipted.
- A feature needs unsupported Xcode project-generation parity and should remain
  blocked rather than smoothed into a false green path.

## Build Implications

Future Vaporize features must trace to this product definition, a named
product-level user journey, and a reason users would choose Vaporize over the
raw underlying tool.

Release review must reject feature work that only adds implementation surface
without updating the product definition, PRD, CUJs, evidence, and tests that
make the user value and choice argument inspectable.

Before coding starts, major feature work must pass a PRD review session with
Engineering, QA, and Marketing. Engineering reviews buildability and proof
surface, QA reviews testability and acceptance criteria, and Marketing reviews
claim language and prohibited promises. The durable session record for this
release lane is `release/v0.0.1/prd-review-session.md`; future major coding
slices must record that review before implementation begins.

Runtime, performance, and build-size work must leverage the evidence Apple and
Swift already provide before inventing parallel measurement formats. Code
coverage JSON, profile data, xUnit output when available, `.xcresult` bundles,
result-bundle metadata, build logs, diagnostics, DerivedData/product paths,
product/binary/bundle sizes, cache storage deltas, and per-feature-flag build
size deltas should become Vaporize runtime samples in a Kura series.

App-facing build/config status work must also leverage the wrkstrm-core build
tools that already exist. Hello World-style `xcode-project.tool.json` records
come from `tool-registry@wrkstrm-core.cli`; app variant names, bundle IDs,
application paths, and DerivedData paths come from `identifier@wrkstrm-core.cli`;
bundle audits, install-path patching, Xcode build/export receipts, and flat
`.app` artifacts come from `app-artifacts@wrkstrm-core.cli`. Vaporize should
orchestrate, sample, and receipt those sources instead of creating a second
build-config truth surface.

Vaporize also needs a wrkstrm app-minimums lens. The v0.0.1 target-level slice
is `inspect-target-features --path <project.yml> --target <target>`, which
knows whether a target has declared release tiers, `Config/release-features.json`,
generated `Config/xcconfigs/*.xcconfig`, project `configFiles` wiring,
generated `Sources/ReleaseFeatures.swift`, and `digikoma-release-features`
provenance. Registry-backed fleet inspection remains a follow-up. The release
contract is captured in `release/v0.0.1/wrkstrm-app-minimums.md`.

## Release Proof Obligation

For v0.0.1, the PRD, CUJs, PRD review session, release gates,
launch-review packet, why explainer, performance claim matrix, public brochure,
public changelog, CUJ coverage artifact, engineering DocC catalog, and CUJ-09
release-review tests must all acknowledge this product definition.
