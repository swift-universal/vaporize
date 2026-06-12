# Vaporize v0.0.1 - Provenance Artifact

**Generated:** 2026-06-12T22:43:14Z
**Status:** captured for forward Pkl migration
**Subject:** `vaporize@wrkstrm-core.cli` v0.0.1 release prep

This artifact gathers the receipts needed to move forward without relying on
chat memory.

## Proven

- Focused Vaporize tests pass through `vaporize toolchain`: 17 tests.
- Concourse `project.yml` parses into Swift `AppleProjectSpec`.
- Fleet intake audit parsed 155/155 discovered `project.yml` files.
- Old XcodeGen script build and Vaporize app build both pass for Concourse
  after Vaporize derives legacy `WRAPPER_NAME` from `project.yml`.
- Concourse `project.pkl` evaluates through PklSwift and matches the Swift-read
  legacy YAML parity signature with zero mismatches.
- Concourse `project.pkl` generates transitional `AppleProjectSpec` YAML
  through PklSwift, and the generated YAML compares back to Pkl with zero
  mismatches.
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
| `xcodegen-to-pkl-investigation.json` | Migration scope and blockers are captured | BLOCKS-INTERNAL-V0.0.1 |
| `launch-review-packet.json` | Release-prep packet is gathered | VALID-JSON |

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

## Forward Path

1. Add Pkl-backed `.xcodeproj` world-state generation.
2. Repeat old tool / Vaporize / Pkl-generation comparisons across more
   specimens before claiming fleet parity.
3. Quarantine or migrate remaining substrate-owned XcodeGen surfaces.

The machine-readable companion is
`vaporize-v0.0.1-provenance-artifact.json`.
