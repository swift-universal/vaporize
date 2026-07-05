# Vaporize v0.0.1 - PRD

**Status:** release-prep draft; blocked pending fleet Pkl-backed Xcode world-state parity
**Updated:** 2026-06-14T07:21:25Z
**Component:** `vaporize@wrkstrm-core.cli`
**Release target:** internal essential substrate CLI
**Tool classification:** `internal-essential-tool`

## Summary

Vaporize is the substrate-canonical vaporware-collapse gate for Swift and Apple
product work. It turns typed or operator-selected buildable intent into
world-state: CLIs installed, app bundles built and launched, CommonProcess
commands executed, vaporware inventories emitted, and receipts captured.

This release prepares Vaporize v0.0.1 as a usable internal command surface for
assistants. It should reduce direct shell and direct `xcodebuild` choreography by
putting build, install, run, open, pass-through, CommonProcess invocation,
Xcode-selected Swift execution, JSON validation, warehouse inventory, read-only
legacy Apple project YAML inspection, and package graph access behind one
recognizable gate.

The approved migration-prep slice adds a Swift YAML read bridge for legacy
XcodeGen `project.yml` files. That bridge is deliberately read-only: it lets
Vaporize inspect and receipt existing project shape as Swift data while Pkl
becomes the forward project-generation source of truth.

The next parity slice adds a Pkl schema plus the first Concourse `project.pkl`
specimen, then compares PklSwift-evaluated data against the Swift-read legacy
YAML signature before any project-generation code is attempted.

The current generation slice imports Apple's `pkl-swift` package and adds
`generate-project-yml`. That mode evaluates Concourse `project.pkl` through
PklSwift, emits transitional `AppleProjectSpec` YAML, and receipts the
generation boundary. This is useful migration evidence, but it is not the final
owned `.xcodeproj` world-state generator.

The current import slice adds `import-project-yml`. That mode reads legacy
XcodeGen YAML, emits an evaluable `project.pkl` parity specimen, and receipts
the boundary that no `.xcodeproj` world-state was generated. Creative Selection
v0.2 is the first newly generated specimen in addition to the hand-authored
Concourse parity specimen.

The current product-cache slice adds shared Xcode workspace cache reuse for app
builds. When a large workspace is kept warm, callers can pass
`--xcode-product-cache-workspace` with
`--xcode-product-cache-derived-data-path`; Vaporize searches the shared
`Build/Products/<Configuration>/<app>.app` cache before local DerivedData and
builds through the shared workspace/DerivedData pair on cache miss. This is a
cache-first workspace reuse slice. The next discovery slice lets `list-targets`
report expected product-cache candidate paths and warm/missing status from
AppleProjectSpec target facts. That is still not full `.xcworkspace` graph
membership proof.

The current workspace scheme-listing slice adds `list-schemes`. That mode asks
Xcode for the live scheme list of a maintained `.xcworkspace` through
`xcodebuild -list -json -workspace`, parses the result, and can emit a
`vaporize-xcode-workspace-scheme-list` receipt. This is the bridge between our
owned XcodeGen/Pkl project-generation flow and Xcode's own workspace graph. It
does not build, install, warm caches, prove fleet membership, or replace
AppleProjectSpec target discovery.

The current SwiftPM CLI resource slice keeps `experimental-install` as the
executable install primitive, then carries SwiftPM resource bundles from the
SwiftPM-reported build products directory into `~/.swiftpm/bin` so installed
CLIs using `Bundle.module` keep working away from `.build`. Product version and
build metadata live in Vaporize's CLI metadata sidecar, not in
`Bundle.main.infoDictionary`.

The release classification is `internal-essential-tool`: an internal-only tool
whose absence blocks assistants from completing build, install, launch, release
packet validation, and Apple toolchain proof workflows. This is not a public
distribution release. Final v0.0.1 internal release is blocked until
substrate-owned Apple project generation moves off XcodeGen and onto a
Pkl-backed owned generation path, or any remaining XcodeGen surfaces are
explicitly quarantined as historical/external compatibility.

The current release-doctor slice adds a self-audit mode for the release packet.
`release-doctor` checks that the release spine is coherent across documents,
JSON evidence, launch-review references, provenance, and CUJ coverage before
assistants trust the packet. It is a consistency gate, not a release approval
gate.

## Product Definition, User Journeys, And Choice Argument

`release/v0.0.1/product-definition.md` is the release-prep product contract for
Vaporize. It defines the product, primary users, product-level journeys, why
users choose Vaporize, when not to choose Vaporize, and the build implication
that new feature work must trace back to user value before implementation is
accepted.

This PRD consumes that contract rather than replacing it. Requirements below
must stay aligned with the product definition and CUJ map, so release review can
answer "why should a user choose Vaporize?" before accepting another feature
slice.

Major feature coding also requires a pre-code PRD review session with
Engineering, QA, and Marketing. Engineering reviews buildability and proof
surface, QA reviews testability and acceptance criteria, and Marketing reviews
claim language and prohibited promises before implementation starts. The current
v0.0.1 lane records the backfilled correction in
`release/v0.0.1/prd-review-session.md`; future major Vaporize coding slices do
not get a backfill exception.

Vaporware modification requests are release work. A request that changes
executable behavior, product behavior, build behavior, release behavior, or
user-visible capability must create or attach to a feature flag, feature status
record, or release-feature cohort; add or update targetable tests; and update
release evidence when release claims, receipts, schema fixtures, launch review,
or app/build output are affected. Vaporware feature requests are product input;
vaporware modification requests are the controlled engineering execution unit
that may be spawned from that input. The domain-specific name leaves room for
future hardware or other material-domain request families.

## Goals

- Ship one canonical CLI name: `vaporize@wrkstrm-core.cli`.
- Define the product, primary users, product-level user journeys, and why users
  choose Vaporize before more build work is accepted.
- Require an Engineering, QA, and Marketing PRD review session before major
  feature coding starts.
- Require vaporware modification requests to carry an owning bead, a feature
  flag or feature-status story, targetable tests, and release evidence before
  they are treated as release-ready.
- Classify Vaporize as an internal essential tool for assistant build,
  install, launch, and release-proof workflows.
- Support SwiftPM CLI build, install, uninstall, and run flows.
- Preserve SwiftPM CLI target resource bundles during install without turning
  CLIs into app bundles.
- Support Apple app build, install, uninstall, and launch flows for SwiftPM,
  Xcode project, and Xcode workspace homes.
- Keep direct `xcodebuild` use inside Vaporize as an implementation detail.
- Provide analyzable `pass` execution for Swift commands through CommonProcess.
- Provide `use` execution for caller-supplied CommonProcess `CommandSpec` JSON.
- Provide `toolchain` execution for Xcode-selected Swift through Vaporize-owned
  `xcrun` invocation.
- Provide `validate-json` so release packets validate through Vaporize rather
  than direct `jq`.
- Provide `inspect-project-yml` so legacy XcodeGen project specs can be parsed
  into Swift project data and receipted without rewriting or regenerating
  anything.
- Provide `compare-project-yml-pkl` so a legacy `project.yml` and Pkl parity
  specimen can be evaluated into the same Swift model and receipted before
  project world-state generation.
- Provide `generate-project-yml` so a Pkl specimen can emit transitional
  `AppleProjectSpec` YAML with a generation receipt, without rewriting checked
  in legacy YAML or generating `.xcodeproj` world-state.
- Provide `import-project-yml` so a legacy XcodeGen `project.yml` can be
  rendered into an evaluable Pkl parity specimen with a receipt, without
  treating YAML as the forward source of truth.
- Provide `generate-xcodeproj` so an evaluated AppleProjectSpec Pkl specimen can
  emit first-slice `.xcodeproj` world-state with a receipt.
- Provide `list-targets` so an assistant can discover Apple project targets,
  buildable candidates, packages, and schemes from AppleProjectSpec Pkl or
  legacy `project.yml` before routing Pkl parity, build, install, or cache work.
- Provide workspace product-cache discovery through `list-targets` so an
  assistant can see expected shared DerivedData `.app` product candidates and
  warm/missing status before attempting install/build routing.
- Provide `list-schemes` so an assistant can ask Xcode for live schemes in a
  maintained `.xcworkspace` before routing workspace build/cache work.
- Provide shared Xcode workspace product-cache reuse so a warm large workspace
  DerivedData product can satisfy app installs before local rebuilds.
- Define a Kura-queryable runtime sample series and Apple/Swift native artifact
  ingestion follow-up so performance, coverage, and build-space claims are
  based on durable samples rather than manual terminal timing.
- Compose app-facing build/config status with existing wrkstrm-core build
  tools: `tool-registry@wrkstrm-core.cli` for `xcode-project` records such as
  the Hello World demos, `identifier@wrkstrm-core.cli` for canonical app
  variant names/paths, and `app-artifacts@wrkstrm-core.cli` for bundle audits,
  install paths, Xcode build/export receipts, and flat application artifacts.
- Define wrkstrm app minimums so Vaporize can tell whether an app has the
  release-feature manifest, generated conditional-compilation xcconfigs,
  generated `ReleaseFeatures.swift`, and project wiring required before strong
  app-facing claims are allowed.
- Provide `release-doctor` so Vaporize can audit its own release spine for
  agreement across product definition, PRD, CUJs, gates, launch-review packet,
  provenance, CUJ coverage, feature catalog, and engineering DocC before
  assistants trust the packet.
- Provide `status` and `warehouse` inventory modes for
  `x-vaporize-collapse-path` records, with legacy `x-craze-collapse-path`
  read-only fallback.
- Preserve graph analysis through the `graph` forwarder.
- Block final internal v0.0.1 release until substrate-owned XcodeGen project
  generation is replaced by a Pkl-backed owned path across the required fleet
  or remaining surfaces are explicitly quarantined.
- Produce a release packet with PRD, CUJs, release gates, and launch-review
  evidence.

## Non-Goals

- Do not claim public or App Store distribution readiness; this is an internal
  substrate CLI release.
- Do not complete schema-universal integration for typed vaporware units in this
  release.
- Do not make XcodeGen integration the forward canonical path for
  substrate-owned apps. XcodeGen may remain as legacy compatibility, but the
  internal release path moves our owned generation surfaces to Pkl.
- Do not block this release on `realize`, auto-incremented build numbers, or
  full tool-call observability; those remain tracked release follow-ups.
- Do not remove historical compatibility understanding for legacy `craze`
  records; this release can classify legacy annotation keys while naming
  Vaporize as the forward canonical surface.

## Audience

Primary audience:

- Commissioned assistants that need to build, install, run, launch, inspect, or
  prove substrate software without improvising shell choreography.

Supporting audiences:

- rismay as founder and chairman reviewing whether Vaporize is coherent enough
  to be the internal release gate.
- Launch Review engineering and audience approvers reviewing proof quality.
- Warehouse and schema-universal maintainers who will consume future typed
  collapse and tool-call receipts.

## Requirements

| ID | Requirement | Acceptance |
| --- | --- | --- |
| FR-001 | Canonical command identity | CLI help and release docs name `vaporize@wrkstrm-core.cli` as the canonical surface. |
| FR-002 | SwiftPM CLI operations | `install`, `uninstall`, `build`, and `run` support `--artifact cli`, `--package-path`, `--product`, and release/debug configuration. |
| FR-003 | Apple app operations | `install`, `uninstall`, and `run` support `--artifact app`, app bundle naming, destination, launch, Xcode project/workspace, scheme, derived data, destination, SDK, result bundle, and build settings. |
| FR-004 | Restricted native tool boundary | Assistant-facing docs route app build/install/open/run through Vaporize; direct `xcodebuild` is an implementation detail. |
| FR-005 | CommonProcess pass-through | `pass` runs Swift commands through CommonProcess, preserves stdout/stderr/exit code, and can emit a JSON receipt with `--analyze` or `--receipt-path`. |
| FR-006 | CommonProcess use invocation | `use --common-process-spec <path-or->` decodes a CommonProcess `CommandSpec`, validates it, executes it through `RunnerControllerFactory`, preserves stdout/stderr/exit code, and emits a receipt when requested. |
| FR-007 | Vaporware inventory | `status` and `warehouse` scan JSON records for `x-vaporize-collapse-path`, classify vapor state, and emit text or JSON receipts. |
| FR-008 | Compatibility inventory | Legacy `x-craze-collapse-path` annotations remain readable for classification only. |
| FR-009 | Package graph forwarder | `graph` forwards to `package-graph@wrkstrm.cli` from the same canonical Vaporize surface. |
| FR-010 | Xcode-selected toolchain route | `toolchain -- swift <args>` invokes `xcrun swift <args>` inside Vaporize and rejects unsupported tools. |
| FR-011 | JSON validation route | `validate-json --path <json>` validates JSON through the Swift Universal json-formatter package and can emit a receipt. |
| FR-012 | Release packet | PRD, CUJs, release gates, and launch-review packet exist under `release/v0.0.1/`. |
| FR-013 | Internal essential tool classification | Release evidence names Vaporize as `internal-essential-tool` and records which assistant workflows it blocks when absent. |
| FR-014 | Pkl project-generation release gate | Final internal v0.0.1 release is blocked until substrate-owned XcodeGen-managed Apple surfaces move to a Pkl-backed generation path or are explicitly quarantined. |
| FR-015 | Swift YAML read bridge | `inspect-project-yml --path <project.yml>` parses legacy XcodeGen project YAML into Swift `AppleProjectSpec` data and emits an inspection receipt without rewriting YAML, invoking XcodeGen, or generating an Xcode project. |
| FR-016 | Pkl parity specimen comparison | `compare-project-yml-pkl --path <project.yml> --pkl-path <project.pkl>` evaluates Pkl through PklSwift, decodes both inputs into Swift `AppleProjectSpec`, compares parity signatures, and emits a comparison receipt. |
| FR-017 | Pkl transitional YAML generation | `generate-project-yml --pkl-path <project.pkl> --output-path <generated.yml>` evaluates Pkl through PklSwift, writes transitional `AppleProjectSpec` YAML, and emits a `vaporize-pkl-project-yml-generation` receipt that explicitly marks `.xcodeproj` world-state generation as not performed. |
| FR-018 | Legacy YAML to Pkl import | `import-project-yml --path <project.yml> --output-path <project.pkl>` parses legacy XcodeGen YAML, renders an AppleProjectSpec Pkl specimen that amends `AppleProjectSpec.pkl`, and emits a `vaporize-apple-project-yml-pkl-import` receipt that explicitly marks `.xcodeproj` world-state generation as not performed. |
| FR-019 | Schema-universal evidence extraction | Vaporize release evidence and durable receipts have initial JSON schemas in `schema-universal/private/universal/domain/tooling/schema-families/vaporize-schemas/v0.0.1`, with fixtures extracted from the v0.0.1 release packet. |
| FR-020 | Pkl to Xcode project generation | `generate-xcodeproj --pkl-path <project.pkl> --output-path <generated.xcodeproj>` evaluates Pkl through PklSwift, writes first-slice `.xcodeproj` world-state, and emits a `vaporize-pkl-xcodeproj-generation` receipt that explicitly records project world-state generation. |
| FR-021 | Shared Xcode workspace product cache | App install/build accepts paired `--xcode-product-cache-workspace` and `--xcode-product-cache-derived-data-path`, searches the shared DerivedData product path before local outputs, and uses the shared workspace/DerivedData pair for the Xcode build invocation on cache miss. |
| FR-022 | Pre-development product definition and choice argument | `release/v0.0.1/product-definition.md` defines the product, primary users, product-level user journeys, why users choose Vaporize, when not to choose Vaporize, and build implications; PRD, CUJs, why explainer, release gates, launch-review packet, CUJ coverage, and release-review tests reference it. |
| FR-023 | Existing wrkstrm-core app/build config composition | App-facing runtime samples and future feature-status inspection must consume existing wrkstrm-core build surfaces before inventing parallel records: `tool-registry@wrkstrm-core.cli discover-apps` / `xcode-project.tool.json` records for `project.yml` ownership, `identifier@wrkstrm-core.cli app describe` for app variant names/paths, and `app-artifacts@wrkstrm-core.cli` for bundle validation, install-path patching, Xcode build/export receipts, and flat application artifacts. |
| FR-024 | wrkstrm app minimums inspection | `inspect-target-features --path <project.yml> --target <target>` reports target-level release-feature topology: project spec, declared build configurations, tier declarations, `Config/release-features.json`, generated `Config/xcconfigs/*.xcconfig`, project `configFiles` or Pkl equivalent wiring, generated `Sources/ReleaseFeatures.swift`, and `digikoma-release-features` provenance. Registry-backed fleet inspection remains a follow-up. Missing, stale, or unknown minimums block strong feature-cohort, launch-readiness, and per-feature-size claims. |
| FR-025 | Pre-code PRD review session | Major feature work must record an Engineering, QA, and Marketing PRD review session before coding starts. The session must decide `GO`, `GO-WITH-NOTES`, or `NO-GO`, and must name approved scope, required tests, required release evidence, approved claims, prohibited claims, and blockers. |
| FR-026 | Vaporware modification request release discipline | Behavior-changing vaporware modification requests create or attach to a feature flag, feature status record, or release-feature cohort; add or update targetable tests; run the smallest feature-scoped proof; update release evidence and schema fixtures when affected; and record any no-flag exception explicitly. |
| FR-027 | Release doctor spine audit | `release-doctor --path <package-or-release-root>` emits a `vaporize-release-doctor` receipt that verifies required release artifacts exist, evidence JSON parses, PRD/CUJ/gate/catalog surfaces name the release-doctor slice, launch-review references the gate and receipt, provenance inventories the receipt, and CUJ coverage counts CUJ-17. The command audits coherence; it does not approve final release. |
| FR-028 | Project target discovery | `list-targets --pkl-path <project.pkl>` or `list-targets --package-path <project-dir>` emits a `vaporize-project-target-discovery` receipt that names target, package, scheme, and buildable-candidate facts from AppleProjectSpec. The command discovers routing facts; it does not build, install, generate `.xcodeproj` world-state, or prove fleet parity. |
| FR-029 | Workspace product-cache discovery | `list-targets` accepts `--xcode-product-cache-workspace`, `--xcode-product-cache-derived-data-path`, and `--configuration`; when present, the target-discovery receipt includes expected shared DerivedData `.app` candidates and warm/missing status for buildable AppleProjectSpec targets. The command does not parse `.xcworkspace` membership, build, install, warm the cache, or prove fleet cache coverage. |
| FR-030 | Xcode workspace scheme listing | `list-schemes --xcode-workspace <workspace.xcworkspace>` executes `xcodebuild -list -json -workspace` through Vaporize/CommonProcess, parses the workspace scheme list, and can emit a `vaporize-xcode-workspace-scheme-list` receipt. The command lists schemes only; it does not build, install, warm caches, prove product paths, or prove fleet-wide workspace membership. |
| FR-031 | CUJ-state coverage gate | CUJ-state coverage evidence names every required journey-derived CUJ-state id, attaches a proof entry for each id, records empty uncovered/unknown/duplicate lists, and is checked by release doctor before release review trusts simulated world state. This proves CUJ-state coverage only; it does not prove Kura, Turso, libSQL, sync, migration, or public release readiness. |
| FR-032 | SwiftPM CLI resource-bundle install preservation | `install --artifact cli` preserves SwiftPM target resource bundles required by `Bundle.module` for installed CLIs by using SwiftPM `experimental-install` for the executable, asking SwiftPM for the build products directory with `swift build --show-bin-path`, and copying direct `.bundle` siblings into the installed CLI bin directory. Vaporize also writes product version/build facts to the CLI metadata sidecar. This does not turn the CLI into an app bundle, does not make `Bundle.main.infoDictionary` carry product metadata, and does not prove Sparkle appcast generation or update signing. |

## Release Criteria

- Vaporize's package test suite passes with the Swift 6.4 toolchain:
  `vaporize toolchain -- swift test --package-path private/apple/spm/vaporize@wrkstrm-core.cli`.
  Current proof: the CUJ-derived coverage floor requires 105 Swift test
  obligations plus 12 release evidence checks; the executable suite passes 139
  tests across 22 implemented CUJ targets, including the CUJ-16
  `inspect-target-features` first slice, CUJ-17 `release-doctor` first slice,
  CUJ-18 `list-targets` first slice, CUJ-19 workspace cache discovery first
  slice, CUJ-20 `list-schemes` first slice, CUJ-21 CUJ-state coverage gate, and
  CUJ-22 SwiftPM CLI resource-bundle install preservation.
- `release/v0.0.1/product-definition.md` defines the product, primary users,
  product-level user journeys, choice argument, non-choice cases, and build
  implications before additional feature work is accepted.
- `release/v0.0.1/prd-review-session.md` records the Engineering, QA, and
  Marketing PRD review session requirement and the v0.0.1 backfilled
  `GO-WITH-NOTES` decision. Future major coding slices require this review
  before implementation begins.
- `vaporize.engineering.docc/vaporware-modification-request-discipline.md`
  records the vaporware modification request rule: behavior-changing slices need
  a feature flag or feature-status story, targetable tests, and release evidence
  before release-ready status.
- CUJ test coverage is recorded in
  `release/v0.0.1/evidence/cuj-test-coverage.json`.
- CLI help advertises `use`, `toolchain`, `validate-json`,
  `inspect-project-yml`, `compare-project-yml-pkl`, `import-project-yml`,
  `generate-project-yml`, `generate-xcodeproj`, `inspect-target-features`,
  `list-targets`, `list-schemes`, `release-doctor`, `--common-process-spec`,
  `--xcode-product-cache-workspace`, and `--xcode-product-cache-derived-data-path`.
- Release packet JSON validates with
  `vaporize validate-json --path release/v0.0.1/evidence/launch-review-packet.json`.
- `release/v0.0.1/why-vaporize.md` explains the value proposition,
  Swift/xcodebuild/xcrun comparison, current benchmark baseline, build-space
  savings theory, ergonomics, and remaining benchmark gaps without claiming
  unmeasured fleet performance.
- `release/v0.0.1/performance-marketing-claims.md` defines approved claim
  language, example copy, prohibited claims, and the benchmark receipts required
  before stronger speed or disk-space claims are allowed.
- Vaporize release evidence schemas validate as JSON under
  `schema-universal/private/universal/domain/tooling/schema-families/vaporize-schemas/v0.0.1`.
- `release-doctor --path private/apple/spm/vaporize@wrkstrm-core.cli` emits
  `release/v0.0.1/evidence/vaporize-v0.0.1-release-doctor.receipt.json` and
  passes while preserving the final release blocker truth.
- Runtime benchmark claims beyond provisional release-prep baselines require
  Vaporize-emitted Kura runtime samples that retain or reference Swift/Apple
  native artifacts such as code coverage JSON, profile data, xUnit output when
  available, `.xcresult` bundles, result metadata, build logs, diagnostics, and
  DerivedData/product paths. Build-size claims require product, binary, bundle,
  build-output, coverage artifact, result-bundle, cache-delta, and
  per-feature-flag size metrics where applicable. Current series contract:
  `private/universal/substrate/collectives/wrkstrm/private/universal/kura-spaces/series/vaporize-runtime-samples/vaporize-runtime-samples.series.su.json`.
- App-facing runtime samples and feature/config status claims must link the
  sample back to the existing wrkstrm-core build source: the `xcode-project`
  tool record, the identifier app description, the app-artifacts audit/export
  receipt, and any release-feature manifest or generated `.xcconfig` files
  present in the project.
- wrkstrm app minimums are defined in
  `release/v0.0.1/wrkstrm-app-minimums.md`; the target-level
  `inspect-target-features` slice is implemented, while registry-backed fleet
  awareness remains a blocking follow-up before Vaporize can claim fleet-wide
  app-minimum awareness.
- Concourse legacy project inspection receipt validates with
  `vaporize validate-json --path release/v0.0.1/evidence/concourse-project-yml-inspection.receipt.json`.
- Concourse YAML/Pkl comparison receipt validates with
  `vaporize validate-json --path release/v0.0.1/evidence/concourse-project-yml-pkl-comparison.receipt.json`.
- Concourse Pkl transitional YAML generation receipt validates with
  `vaporize validate-json --path release/v0.0.1/evidence/concourse-pkl-project-yml-generation.receipt.json`.
- Concourse generated YAML/Pkl comparison receipt validates with
  `vaporize validate-json --path release/v0.0.1/evidence/concourse-generated-yml-pkl-comparison.receipt.json`.
- Creative Selection v0.2 YAML-to-Pkl import receipt validates with
  `vaporize validate-json --path release/v0.0.1/evidence/creative-selection-v0.2-project-yml-pkl-import.receipt.json`.
- Creative Selection v0.2 YAML/Pkl comparison receipt validates with
  `vaporize validate-json --path release/v0.0.1/evidence/creative-selection-v0.2-project-yml-pkl-comparison.receipt.json`.
- Creative Selection v0.2 Pkl `.xcodeproj` generation receipt validates with
  `vaporize validate-json --path release/v0.0.1/evidence/creative-selection-v0.2-pkl-xcodeproj-generation.receipt.json`.
- Creative Selection v0.2 target discovery receipt validates with
  `vaporize validate-json --path release/v0.0.1/evidence/creative-selection-v0.2-list-targets.receipt.json`.
- CUJ-state coverage evidence validates with
  `vaporize validate-json --path release/v0.0.1/evidence/cuj-state-coverage.json`.
- Release evidence classifies Vaporize as an internal essential tool rather
  than a public release artifact.
- Pkl-backed `.xcodeproj` world-state generation has fleet build parity for
  substrate-owned Apple surfaces or remaining XcodeGen surfaces are explicitly
  quarantined outside the v0.0.1 internal release path.
- Release gates honestly mark open follow-ups and drift rather than smoothing
  them into a false green state.
- Documentation drift is either repaired before final release or marked as an
  explicit blocker in release gates.

## Known Release Follow-Ups

- `FR-VAPORIZE-PKL-PROJECT-GENERATION-move-owned-xcodegen-surfaces-to-pkl`
- `FR-VAPORIZE-AUTO-INCREMENT-BUILD-NUMBERS`
- `FR-VAPORIZE-REALIZE-typed-vaporware-unit`
- `FR-VAPORIZE-TOOL-CALL-OBSERVABILITY`
- `FR-VAPORIZE-DRIFT-CATCH-retire-craze-canonical-language`
- `FR-VAPORIZE-XCODE-WORKSPACE-GRAPH-MEMBERSHIP-DISCOVERY`
- `FR-VAPORIZE-RUNTIME-SAMPLE-SERIES-APPLE-ARTIFACT-INGESTION`
- `FR-VAPORIZE-WRKSTRM-CORE-BUILD-CONFIG-COMPOSITION`
- `FR-VAPORIZE-WRKSTRM-APP-MINIMUMS-INSPECTION`
- `FR-VAPORIZE-PRD-REVIEW-SESSION-BEFORE-CODING`
