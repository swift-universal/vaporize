# Vaporize v0.0.1 - Provenance Artifact

**Generated:** 2026-06-13T08:18:07Z
**Status:** captured for forward Pkl migration
**Subject:** `vaporize@wrkstrm-core.cli` v0.0.1 release prep

This artifact gathers the receipts needed to move forward without relying on
chat memory.

## Proven

- CUJ-derived test coverage is explicit: 57 required Swift test obligations
  plus 4 release evidence checks across 13 active CUJs.
- Vaporize package tests pass through `vaporize toolchain`: 74 executable Swift
  tests across 13 CUJ-specific SwiftPM test bundles.
- Concourse `project.yml` parses into Swift `AppleProjectSpec`.
- Fleet intake audit parsed 155/155 discovered `project.yml` files.
- Old XcodeGen script build and Vaporize app build both pass for Concourse
  after Vaporize derives legacy `WRAPPER_NAME` from `project.yml`.
- Concourse `project.pkl` evaluates through PklSwift and matches the Swift-read
  legacy YAML parity signature with zero mismatches.
- Concourse `project.pkl` generates transitional `AppleProjectSpec` YAML
  through PklSwift, and the generated YAML compares back to Pkl with zero
  mismatches.
- Creative Selection v0.2 `project.yml` imports into a generated `project.pkl`
  parity specimen, and the generated Pkl compares back to YAML with zero
  mismatches.
- Initial schema-universal extraction exists as `vaporize-schemas v0.0.1` for
  CUJ coverage, provenance, launch-review specialization, and Apple project
  YAML/Pkl receipts.
- Release evidence JSON validates through `vaporize validate-json`.

## Not Proven

- Pkl-backed `.xcodeproj` world-state generation exists.
- The full fleet builds through Vaporize.
- Remaining XcodeGen surfaces are migrated or quarantined.
- Vaporize v0.0.1 is ready for final internal-essential release.

## Receipt Index

| Receipt | Claim | Result |
| --- | --- | --- |
| `concourse-project-yml-inspection.receipt.json` | Concourse YAML reads into Swift project data | PASS |
| `project-yml-fleet-parse-audit.receipt.json` | 155 discovered `project.yml` files parse | PASS |
| `concourse-old-tool-vaporize-build-comparison.receipt.json` | Old tool and Vaporize agree on Concourse build | PASS-WITH-NOTE |
| `concourse-project-yml-pkl-comparison.receipt.json` | Concourse Pkl specimen matches legacy YAML | PASS |
| `concourse-pkl-project-yml-generation.receipt.json` | Concourse Pkl emits transitional YAML | PASS-WITH-NOTE |
| `concourse-generated-yml-pkl-comparison.receipt.json` | Generated YAML matches Concourse Pkl | PASS |
| `creative-selection-v0.2-project-yml-pkl-import.receipt.json` | Creative Selection v0.2 YAML imports into Pkl | PASS-WITH-NOTE |
| `creative-selection-v0.2-project-yml-pkl-comparison.receipt.json` | Imported Creative Selection v0.2 Pkl matches YAML | PASS |
| `xcodegen-to-pkl-investigation.json` | Migration scope and blockers are captured | BLOCKS-INTERNAL-V0.0.1 |
| `cuj-test-coverage.json` | PRD/CUJ-derived required test floor is captured | PASS |
| `launch-review-packet.json` | Release-prep packet is gathered | VALID-JSON |
| `vaporize-schemas v0.0.1` | Initial schema-universal extraction is captured | PASS-WITH-NOTE |

## Savepoints

- `DF8697F3-DCED-4FA3-AF36-103D818F23E7` - Swift YAML bridge, release docs,
  tests, Concourse inspection receipt.
- `8D119C0F-65AD-4633-A776-EC15350BA4A5` - fleet parse audit receipt.
- `65A98CBC-F745-4B23-9E41-4361DAECF054` - old/new Concourse build
  comparison and `WRAPPER_NAME` compatibility fix.
- `A1FC2C04-AD43-448E-8B72-291E226AB429` - Pkl schema, Concourse Pkl parity
  specimen, `compare-project-yml-pkl` mode, and zero-mismatch comparison
  receipt.
- `CFC7AE2A-1E63-4358-BE75-4C514A6CCC87` - PklSwift dependency,
  `generate-project-yml`, transitional Concourse YAML artifact, generation and
  comparison receipts, release packet updates, and blocker-bead progress.
- `D4FABA98-0FF1-44EA-920A-80CE08517921` - Apple project test-suite split and
  focused CLI coverage expansion before the CUJ-derived coverage contract.

## Forward Path

1. Add Pkl-backed `.xcodeproj` world-state generation.
2. Repeat old tool / Vaporize / Pkl-generation comparisons beyond Concourse and
   Creative Selection v0.2 before claiming fleet parity.
3. Quarantine or migrate remaining substrate-owned XcodeGen surfaces.

The machine-readable companion is
`vaporize-v0.0.1-provenance-artifact.json`.
