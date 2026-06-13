# Vaporize v0.0.1 - XcodeGen To Pkl Investigation

**Status:** release-blocker investigation complete
**Generated:** 2026-06-12T20:58:02Z
**Updated:** 2026-06-13T08:18:07Z
**Component:** `vaporize@wrkstrm-core.cli`
**Tool classification:** `internal-essential-tool`

## Verdict

Vaporize v0.0.1 should stay blocked for internal release until
substrate-owned Apple project-generation truth moves off XcodeGen and onto a
Pkl-backed owned `.xcodeproj` world-state path, or remaining XcodeGen surfaces
are explicitly quarantined.

The important distinction:

- Pkl is the forward source-of-truth surface.
- Vaporize is the assistant-facing internal essential gate.
- PklSwift-backed transitional YAML generation is migration evidence, not final
  buildable project generation.
- PklSwift-backed YAML-to-Pkl import is migration evidence, not final buildable
  project generation.
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
- `AppleProjectPklTests.swift` covers PklSwift parity comparison and
  transitional YAML generation from Concourse `project.pkl`.
- `AppleProjectSpecComparatorTests.swift`,
  `AppleProjectAppBundleNameResolverTests.swift`, and
  `AppleProjectValueTests.swift` cover mismatch reporting, script
  normalization, bundle-name expansion/failure, scalar decoding, source
  shorthand, and renderer round-trip behavior.
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
  `compare-project-yml-pkl` uses PklSwift and found zero mismatches between
  Concourse YAML and Pkl-evaluated project data.
- `generate-project-yml` imports PklSwift-backed project data and emits
  transitional `AppleProjectSpec` YAML.
- `concourse-pkl-project-yml-generation.receipt.json` records the generation
  boundary: transitional YAML was emitted; `.xcodeproj` world-state was not.
- `concourse-generated-yml-pkl-comparison.receipt.json` records that generated
  YAML still matches Concourse Pkl with zero mismatches.
- `import-project-yml` renders legacy YAML into a Pkl parity specimen.
- Creative Selection v0.2 now has a generated `project.pkl` with zero
  mismatches against its source `project.yml`.
- `generate-xcodeproj` generates first-slice `.xcodeproj` world-state from
  Creative Selection v0.2 `project.pkl`.
- The CUJ-derived coverage floor now requires 60 Swift test obligations plus
  4 release evidence checks, all targetable by CUJ-specific SwiftPM bundles;
  the full Vaporize package test suite passes 77 executable Swift tests through
  `vaporize toolchain`.

This does not unblock v0.0.1 by itself. It gives the Pkl migration a tested
Swift intake surface plus a first owned `.xcodeproj` generation slice. The
fleet audit proves read compatibility, the Concourse build comparison proves
one legacy-build specimen, and the Creative Selection v0.2 generation receipt
proves one Pkl world-state specimen, not fleet build parity.

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

Existing Pkl is now an Apple project parity lane for Concourse and a generated
import lane for Creative Selection v0.2:
`AppleProjectSpec.pkl`, `private/apple/apps/concourse/project.pkl`, and
`private/apple/apps/creative-selection-v0.2/project.pkl`. Vaporize imports
PklSwift and can emit transitional YAML from Pkl or import legacy YAML into Pkl.
It is not yet a `.xcodeproj` world-state generation lane for Xcode targets,
packages, schemes, Info.plist, scripts, or pbxproj generation.

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
5. Use shadow parity bridges only to prove equivalence; Concourse now has the
   Pkl-to-YAML bridge and Creative Selection v0.2 now has the YAML-to-Pkl
   import bridge, but neither is the final release path.
6. Add a Swift-owned generator that consumes Pkl-evaluated project data and
   writes `.xcodeproj` world-state with receipts.
7. Add Vaporize generation mode around Pkl evaluation, world-state generation,
   receipt emission, and app build/install composition.
8. Migrate generator/scaffold surfaces before broad fleet conversion.
9. Gate release on all remaining XcodeGen uses being migrated or quarantined.

## Next Concrete Work

- Add a Pkl-backed `.xcodeproj` world-state generator and receipt.
- Add a Vaporize enforcement bead that scans for unclassified substrate-owned
  XcodeGen invocations.
- Update `versioned-macos-app-install` workflow refs after Vaporize owns the
  generation lane.
