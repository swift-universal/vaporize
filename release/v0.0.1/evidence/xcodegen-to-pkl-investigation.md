# Vaporize v0.0.1 - XcodeGen To Pkl Investigation

**Status:** release-blocker investigation complete
**Generated:** 2026-06-12T20:58:02Z
**Updated:** 2026-06-12T22:11:11Z
**Component:** `vaporize@wrkstrm-core.cli`
**Tool classification:** `internal-essential-tool`

## Verdict

Vaporize v0.0.1 should stay blocked for internal release until
substrate-owned Apple project-generation truth moves off XcodeGen and onto a
Pkl-backed owned path.

The important distinction:

- Pkl is the forward source-of-truth surface.
- Vaporize is the assistant-facing internal essential gate.
- XcodeGen may remain as historical or external compatibility, but should not
  be the forward release horizon for our own apps.

## Completed Approved Slice

The first approved migration-prep slice is now landed:

- `AppleProjectSpecCore` reads legacy XcodeGen `project.yml` into Swift
  `AppleProjectSpec` data.
- `vaporize inspect-project-yml` emits a read-only
  `vaporize-apple-project-yml-inspection` receipt.
- `AppleProjectYMLReaderTests.swift` covers the real Concourse spec and a
  multi-target fixture.
- `concourse-project-yml-inspection.receipt.json` records the Concourse intake
  proof for release review.
- `project-yml-fleet-parse-audit.receipt.json` records that 155/155 discovered
  `project.yml` files under `private/universal/substrate/collectives` parsed
  through `inspect-project-yml`.
- `concourse-old-tool-vaporize-build-comparison.receipt.json` records that the
  old XcodeGen script build and the Vaporize app build both pass for Concourse
  after Vaporize derives `WRAPPER_NAME` from the legacy YAML.
- `vaporize-v0.0.1-provenance-artifact.json` collects the release-prep
  receipts, validation commands, savepoints, proven claims, unproven claims,
  and forward Pkl migration path.
- `Pkl/AppleProjectSpec.pkl` plus Concourse `project.pkl` are the first Pkl
  parity specimen.
- `concourse-project-yml-pkl-comparison.receipt.json` records that
  `compare-project-yml-pkl` found zero mismatches between Concourse YAML and
  Pkl-evaluated project data.

This does not unblock v0.0.1 by itself. It gives the Pkl migration a tested
Swift intake surface so the next slice can compare Pkl-evaluated project data
against the legacy YAML shape before generating project world-state. The fleet
audit proves read compatibility, and the Concourse build comparison proves one
specimen, not that every project builds.

## Live Inventory

Scoped scan findings:

| Surface | Count |
| --- | ---: |
| `project.yml` files | 155 |
| checked-in `.xcodeproj/project.pbxproj` files | 185 |
| Pkl-ish files | 9 |

Project specs by largest owner:

| Collective | `project.yml` count |
| --- | ---: |
| `wrkstrm-components` | 45 |
| `wrkstrm-app` | 45 |
| `wrkstrm-research` | 18 |
| `clia-app-org` | 11 |
| `wrkstrm-core` | 7 |

Existing Pkl is not yet an Apple project-generation lane. The Pkl surfaces I
found are org-prefix and digikoma-adjacent evidence, not a project model for
Xcode targets, packages, schemes, Info.plist, scripts, or pbxproj generation.

## Representative Shape

The common `project.yml` surface maps well to a Pkl model:

- `options.minimumXcodeGenVersion`
- `settings.base`
- `packages`
- `targets`
- target `sources`, `info`, `settings`, `dependencies`, `postBuildScripts`
- `schemes`
- macOS, iOS, Catalyst, helper/status-app, and embedded-target variants

Concourse is a useful first specimen because it carries the release-relevant
bits: Swift 6.4, install path, app category metadata, debug/release bundle
identity, package dependencies, wrapper names, display names, and a deploy
script.

## Direct XcodeGen Runners

The migration is not only file format conversion. These live runner surfaces
invoke XcodeGen directly:

- `clia-org/.../scaffold-app-from-web-cli/.../BuildAndInstall.swift`
- `wrkstrm-app/.../WrkstrmAppScaffold/.../AppScaffoldEngine.swift`
- `wrkstrm-core/.../app-artifacts/.../PatchInstallPathCommand.swift`
- `wrkstrm-core/private/apple/apps/shared/scripts/build_and_run_xcode_app.sh`
- `wrkstrm-app/private/apple/apps/shared/scripts/build_and_run_xcode_app.sh`
- `kura-org/private/apple/shared/scripts/build_and_run_xcode_app.sh`
- `slate-org/private/apple/apps/shared/scripts/build_and_run_xcode_app.sh`
- `spaces-universal/.../versioned-macos-app-install.workflow.su.json`

Those must eventually route through Vaporize/Pkl generation rather than
directly through `xcodegen generate`.

## Migration Plan

1. Freeze new debt: no new substrate-owned `project.yml` surfaces unless
   explicitly tagged legacy compatibility.
2. Use `inspect-project-yml` as the read-only Swift intake surface for legacy
   parity evidence.
3. Model the common project shape as `AppleProjectSpec.pkl`.
4. Port Concourse first as a parity specimen.
5. Use a shadow parity bridge only to prove equivalence; do not call that the
   final release path.
6. Add a Swift-owned generator that consumes Pkl-evaluated project data and
   writes `.xcodeproj` world-state with receipts.
7. Add Vaporize generation mode around Pkl evaluation, world-state generation,
   receipt emission, and app build/install composition.
8. Migrate generator/scaffold surfaces before broad fleet conversion.
9. Gate release on all remaining XcodeGen uses being migrated or quarantined.

## Next Concrete Work

- Define `PklProjectGenerationReceipt`.
- Add a Vaporize enforcement bead that scans for unclassified substrate-owned
  XcodeGen invocations.
- Update `versioned-macos-app-install` workflow refs after Vaporize owns the
  generation lane.
