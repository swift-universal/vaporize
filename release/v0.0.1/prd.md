# Vaporize v0.0.1 - PRD

**Status:** release-prep draft; blocked pending Pkl-backed Xcode world-state generation
**Updated:** 2026-06-12T23:06:11Z
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

The release classification is `internal-essential-tool`: an internal-only tool
whose absence blocks assistants from completing build, install, launch, release
packet validation, and Apple toolchain proof workflows. This is not a public
distribution release. Final v0.0.1 internal release is blocked until
substrate-owned Apple project generation moves off XcodeGen and onto a
Pkl-backed owned generation path, or any remaining XcodeGen surfaces are
explicitly quarantined as historical/external compatibility.

## Goals

- Ship one canonical CLI name: `vaporize@wrkstrm-core.cli`.
- Classify Vaporize as an internal essential tool for assistant build,
  install, launch, and release-proof workflows.
- Support SwiftPM CLI build, install, uninstall, and run flows.
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
- Provide `status` and `warehouse` inventory modes for
  `x-vaporize-collapse-path` records, with legacy `x-craze-collapse-path`
  read-only fallback.
- Preserve graph analysis through the `graph` forwarder.
- Block final internal v0.0.1 release until substrate-owned XcodeGen project
  generation is replaced by a Pkl-backed owned path.
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
- Do not block this release on `list-targets`, `realize`, auto-incremented
  build numbers, or full tool-call observability; those remain tracked release
  follow-ups.
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
| FR-011 | JSON validation route | `validate-json --path <json>` validates JSON with Foundation and can emit a receipt. |
| FR-012 | Release packet | PRD, CUJs, release gates, and launch-review packet exist under `release/v0.0.1/`. |
| FR-013 | Internal essential tool classification | Release evidence names Vaporize as `internal-essential-tool` and records which assistant workflows it blocks when absent. |
| FR-014 | Pkl project-generation release gate | Final internal v0.0.1 release is blocked until substrate-owned XcodeGen-managed Apple surfaces move to a Pkl-backed generation path or are explicitly quarantined. |
| FR-015 | Swift YAML read bridge | `inspect-project-yml --path <project.yml>` parses legacy XcodeGen project YAML into Swift `AppleProjectSpec` data and emits an inspection receipt without rewriting YAML, invoking XcodeGen, or generating an Xcode project. |
| FR-016 | Pkl parity specimen comparison | `compare-project-yml-pkl --path <project.yml> --pkl-path <project.pkl>` evaluates Pkl through PklSwift, decodes both inputs into Swift `AppleProjectSpec`, compares parity signatures, and emits a comparison receipt. |
| FR-017 | Pkl transitional YAML generation | `generate-project-yml --pkl-path <project.pkl> --output-path <generated.yml>` evaluates Pkl through PklSwift, writes transitional `AppleProjectSpec` YAML, and emits a `vaporize-pkl-project-yml-generation` receipt that explicitly marks `.xcodeproj` world-state generation as not performed. |

## Release Criteria

- Vaporize's package test suite passes with the Swift 6.4 toolchain:
  `vaporize toolchain -- swift test --package-path private/apple/spm/vaporize@wrkstrm-core.cli`.
  Current proof: the CUJ-derived coverage floor requires 53 Swift test
  obligations plus 4 release evidence checks, all targetable by CUJ-specific
  SwiftPM test bundles; the executable suite passes 70 tests across 12 CUJ
  targets.
- CUJ test coverage is recorded in
  `release/v0.0.1/evidence/cuj-test-coverage.json`.
- CLI help advertises `use`, `toolchain`, `validate-json`,
  `inspect-project-yml`, and `--common-process-spec`.
- Release packet JSON validates with
  `vaporize validate-json --path release/v0.0.1/evidence/launch-review-packet.json`.
- Concourse legacy project inspection receipt validates with
  `vaporize validate-json --path release/v0.0.1/evidence/concourse-project-yml-inspection.receipt.json`.
- Concourse YAML/Pkl comparison receipt validates with
  `vaporize validate-json --path release/v0.0.1/evidence/concourse-project-yml-pkl-comparison.receipt.json`.
- Concourse Pkl transitional YAML generation receipt validates with
  `vaporize validate-json --path release/v0.0.1/evidence/concourse-pkl-project-yml-generation.receipt.json`.
- Concourse generated YAML/Pkl comparison receipt validates with
  `vaporize validate-json --path release/v0.0.1/evidence/concourse-generated-yml-pkl-comparison.receipt.json`.
- Release evidence classifies Vaporize as an internal essential tool rather
  than a public release artifact.
- Pkl-backed `.xcodeproj` world-state generation for substrate-owned Apple
  surfaces is complete or remaining XcodeGen surfaces are explicitly
  quarantined outside the v0.0.1 internal release path.
- Release gates honestly mark open follow-ups and drift rather than smoothing
  them into a false green state.
- Documentation drift is either repaired before final release or marked as an
  explicit blocker in release gates.

## Known Release Follow-Ups

- `FR-VAPORIZE-LIST-TARGETS-substrate-canonical-target-discovery`
- `FR-VAPORIZE-PKL-PROJECT-GENERATION-move-owned-xcodegen-surfaces-to-pkl`
- `FR-VAPORIZE-AUTO-INCREMENT-BUILD-NUMBERS`
- `FR-VAPORIZE-REALIZE-typed-vaporware-unit`
- `FR-VAPORIZE-TOOL-CALL-OBSERVABILITY`
- `FR-VAPORIZE-DRIFT-CATCH-retire-craze-canonical-language`
