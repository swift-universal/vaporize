# Vaporize v0.0.1 User Manual

**Status:** public-disclosure draft companion; not approved for publication
**Audience:** release reviewers, external technical evaluators, future customers
**Component:** `vaporize@wrkstrm-core.cli`
**Companion brochure:** `release/v0.0.1/public-brochure.html`
**Audience packet:** `release/v0.0.1/evidence/audience-packet.su.json`
**Public gate owner:** Carrie CMO (`cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org`)
**Disclosure boundary:** This manual explains how to operate the current
Vaporize surfaces in the release packet. Carrie CMO owns the consumer-facing
publication gate; wrkstrm-core owns the implementation evidence and
release-doctor mechanics. This manual does not approve public release, claim
fleet parity, or prove Sparkle appcast generation, update signing, or public
update delivery.

## Brochure Companion Contract

Every Vaporize brochure must sit beside:

- A user manual that explains how to operate or review the advertised surface.
- An audience packet that names readers, trust posture, must-see facts,
  must-not-see facts, and prohibited claims.
- Release evidence that proves the brochure, manual, and audience packet are
  required by `release-doctor`.
- A Carrie CMO publication-readiness owner reference before the surface leaves
  draft state.

The brochure earns attention. The manual earns operational trust. The audience
packet keeps both pointed at the right reader.

## Quick Start

From the `wrkstrm-core` checkout:

```bash
/Users/sonoma/.swiftpm/bin/vaporize.cli@wrkstrm-core.clia.sh --version
```

Run the release-spine audit:

```bash
/Users/sonoma/.swiftpm/bin/vaporize.cli@wrkstrm-core.clia.sh release-doctor \
  --path private/apple/spm/vaporize@wrkstrm-core.cli \
  --format json \
  --receipt-path private/apple/spm/vaporize@wrkstrm-core.cli/release/v0.0.1/evidence/vaporize-v0.0.1-release-doctor.receipt.json
```

Open the brochure directly from the release packet:

```bash
open private/apple/spm/vaporize@wrkstrm-core.cli/release/v0.0.1/public-brochure.html
```

## Core Commands

### Build or test a SwiftPM package

```bash
/Users/sonoma/.swiftpm/bin/vaporize.cli@wrkstrm-core.clia.sh test \
  --package-path private/apple/spm/vaporize@wrkstrm-core.cli \
  --configuration debug
```

Focused proof runs can pass Swift Testing filters after `--`:

```bash
/Users/sonoma/.swiftpm/bin/vaporize.cli@wrkstrm-core.clia.sh test \
  --package-path private/apple/spm/vaporize@wrkstrm-core.cli \
  --configuration debug \
  -- --filter CUJ-09
```

### Validate release JSON

```bash
/Users/sonoma/.swiftpm/bin/vaporize.cli@wrkstrm-core.clia.sh validate-json \
  --path private/apple/spm/vaporize@wrkstrm-core.cli/release/v0.0.1/evidence/launch-review-packet.json
```

### Inspect Apple project targets

```bash
/Users/sonoma/.swiftpm/bin/vaporize.cli@wrkstrm-core.clia.sh list-targets \
  --pkl-path private/apple/apps/creative-selection-v0.2/project.pkl \
  --format json
```

### Generate first-slice Xcode project world-state

```bash
/Users/sonoma/.swiftpm/bin/vaporize.cli@wrkstrm-core.clia.sh generate-xcodeproj \
  --pkl-path private/apple/apps/creative-selection-v0.2/project.pkl \
  --output-path /tmp/vaporize-creative-selection-v02-generated.xcodeproj
```

## ReleaseIdentity And Sparkle Boundary

`releaseIdentity` can project bundle id, marketing version, build number,
generated Info.plist keys, Vaporize build metadata, and Sparkle feed/signing
keys into generated Xcode project settings.

This proves project setting generation only. It does not prove Sparkle appcast
generation, update signing, update hosting, or runtime update delivery.

## Review Checklist

Before trusting the brochure:

- Confirm `public-brochure.html` is present.
- Confirm `user-manual.md` is present beside the brochure.
- Confirm `evidence/audience-packet.su.json` is present.
- Confirm `release-doctor` reports all three as required release artifacts.
- Confirm the launch-review packet references the brochure, user manual, and
  audience packet.
- Confirm the release gates and launch-review packet name Carrie CMO
  (`cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org`) as the
  consumer-facing gate owner without recording publication signoff.
- Confirm blocked claims remain blocked in `performance-marketing-claims.md`
  and `release-gates.md`.

## Troubleshooting

If `release-doctor` fails, inspect the failing check names in
`release/v0.0.1/evidence/vaporize-v0.0.1-release-doctor.receipt.json`.

If the brochure opens but proof links are missing, check the evidence map in
`public-brochure.html` and the launch-review evidence refs.

If a claim sounds stronger than the release packet allows, treat
`performance-marketing-claims.md` and `release-gates.md` as authoritative until
new evidence lands.
