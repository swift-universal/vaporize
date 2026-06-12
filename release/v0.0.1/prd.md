# Vaporize v0.0.1 - PRD

**Status:** release-prep draft
**Updated:** 2026-06-12T20:26:28Z
**Component:** `vaporize@wrkstrm-core.cli`
**Release target:** internal substrate CLI

## Summary

Vaporize is the substrate-canonical vaporware-collapse gate for Swift and Apple
product work. It turns typed or operator-selected buildable intent into
world-state: CLIs installed, app bundles built and launched, CommonProcess
commands executed, vaporware inventories emitted, and receipts captured.

This release prepares Vaporize v0.0.1 as a usable internal command surface for
assistants. It should reduce direct shell and direct `xcodebuild` choreography by
putting build, install, run, open, pass-through, CommonProcess invocation,
Xcode-selected Swift execution, JSON validation, warehouse inventory, and
package graph access behind one recognizable gate.

## Goals

- Ship one canonical CLI name: `vaporize@wrkstrm-core.cli`.
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
- Provide `status` and `warehouse` inventory modes for
  `x-vaporize-collapse-path` records, with legacy `x-craze-collapse-path`
  read-only fallback.
- Preserve graph analysis through the `graph` forwarder.
- Produce a release packet with PRD, CUJs, release gates, and launch-review
  evidence.

## Non-Goals

- Do not claim public or App Store distribution readiness; this is an internal
  substrate CLI release.
- Do not complete schema-universal integration for typed vaporware units in this
  release.
- Do not block this release on `list-targets`, `realize`, XcodeGen integration,
  auto-incremented build numbers, or full tool-call observability; those remain
  tracked release follow-ups.
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

## Release Criteria

- Focused Vaporize CLI test target passes with the Swift 6.4 toolchain:
  `vaporize toolchain -- swift test --package-path private/apple/spm/vaporize@wrkstrm-core.cli --filter VaporizeCLITests`.
- CLI help advertises `use`, `toolchain`, `validate-json`, and
  `--common-process-spec`.
- Release packet JSON validates with
  `vaporize validate-json --path release/v0.0.1/evidence/launch-review-packet.json`.
- Release gates honestly mark open follow-ups and drift rather than smoothing
  them into a false green state.
- Documentation drift is either repaired before final release or marked as an
  explicit blocker in release gates.

## Known Release Follow-Ups

- `FR-VAPORIZE-LIST-TARGETS-substrate-canonical-target-discovery`
- `FR-VAPORIZE-XCODEGEN-INTEGRATION-substrate-canonical-xcodegen-aware-build`
- `FR-VAPORIZE-AUTO-INCREMENT-BUILD-NUMBERS`
- `FR-VAPORIZE-REALIZE-typed-vaporware-unit`
- `FR-VAPORIZE-TOOL-CALL-OBSERVABILITY`
- `FR-VAPORIZE-DRIFT-CATCH-retire-craze-canonical-language`
