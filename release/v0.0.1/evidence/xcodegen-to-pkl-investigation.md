# Vaporize v0.0.1 - XcodeGen To Pkl Investigation

**Status:** release-blocker investigation complete
**Generated:** 2026-06-12T20:58:02Z
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
2. Model the common project shape as `AppleProjectSpec.pkl`.
3. Port Concourse first as a parity specimen.
4. Use a shadow parity bridge only to prove equivalence; do not call that the
   final release path.
5. Add a Swift-owned generator that consumes Pkl-evaluated project data and
   writes `.xcodeproj` world-state with receipts.
6. Add Vaporize generation mode around Pkl evaluation, world-state generation,
   receipt emission, and app build/install composition.
7. Migrate generator/scaffold surfaces before broad fleet conversion.
8. Gate release on all remaining XcodeGen uses being migrated or quarantined.

## Next Concrete Work

- Author `AppleProjectSpec.pkl`.
- Port `wrkstrm-core/private/apple/apps/concourse/project.yml` as the first
  Pkl specimen.
- Define `PklProjectGenerationReceipt`.
- Add a Vaporize enforcement bead that scans for unclassified substrate-owned
  XcodeGen invocations.
- Update `versioned-macos-app-install` workflow refs after Vaporize owns the
  generation lane.
