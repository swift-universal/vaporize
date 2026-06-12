# Vaporize v0.0.1 - Provenance Artifact

**Generated:** 2026-06-12T22:11:11Z
**Status:** captured for forward Pkl migration
**Subject:** `vaporize@wrkstrm-core.cli` v0.0.1 release prep

This artifact gathers the receipts needed to move forward without relying on
chat memory.

## Proven

- Focused Vaporize tests pass through `vaporize toolchain`: 15 tests.
- Concourse `project.yml` parses into Swift `AppleProjectSpec`.
- Fleet intake audit parsed 155/155 discovered `project.yml` files.
- Old XcodeGen script build and Vaporize app build both pass for Concourse
  after Vaporize derives legacy `WRAPPER_NAME` from `project.yml`.
- Concourse `project.pkl` evaluates through Pkl and matches the Swift-read
  legacy YAML parity signature with zero mismatches.
- Release evidence JSON validates through `vaporize validate-json`.

## Not Proven

- Pkl-backed Apple project generation exists.
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
| `xcodegen-to-pkl-investigation.json` | Migration scope and blockers are captured | BLOCKS-INTERNAL-V0.0.1 |
| `launch-review-packet.json` | Release-prep packet is gathered | VALID-JSON |

## Savepoints

- `DF8697F3-DCED-4FA3-AF36-103D818F23E7` - Swift YAML bridge, release docs,
  tests, Concourse inspection receipt.
- `8D119C0F-65AD-4633-A776-EC15350BA4A5` - fleet parse audit receipt.
- `65A98CBC-F745-4B23-9E41-4361DAECF054` - old/new Concourse build
  comparison and `WRAPPER_NAME` compatibility fix.

## Forward Path

1. Define `PklProjectGenerationReceipt`.
2. Add Vaporize-owned Pkl generation mode.
3. Repeat old tool / Vaporize / Pkl-generation comparisons across more
   specimens before claiming fleet parity.

The machine-readable companion is
`vaporize-v0.0.1-provenance-artifact.json`.
