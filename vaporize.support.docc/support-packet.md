# Support Packet

@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Support Packet")
  @PageImage(purpose: icon, source: "support-packet-icon", alt: "A five-field evidence packet with a protected, non-secret boundary.")
  @PageImage(purpose: card, source: "support-packet-card", alt: "A support packet composes machine observations without implying a selection or approval.")
}

@Image(source: "support-packet-hero", alt: "Five evidence fields enter a single support packet envelope while secrets, installation, and approval remain outside the boundary.")

Escalate an evidence packet, not a reconstructed story. The packet must let a
maintainer distinguish Xcode state, source behavior, installed behavior, and
any selection change.

## Required Observations

Capture the output of these read-only checks:

```sh
xcode-select -p
xcodebuild -version
xcrun swift --version
vaporize.cli@wrkstrm-core.clia.sh --version
vaporize.cli@wrkstrm-core.clia.sh toolchain-selection --help
command -v swift
ls -l "$(command -v swift)"
readlink "$(command -v swift)"
```

Add the exact Vaporize command invoked, its authority (`swift` or `xcode`),
its package path, configuration, product, start/end time, exit code, and every
candidate or installed artifact digest that the investigation compares.

## Required Classification

State one current classification:

- `xcode-unavailable` — Xcode or its Swift compiler cannot be resolved.
- `installed-provider-omitted` — canonical Vaporize lacks a promised provider.
- `source-installed-drift` — a source candidate differs from installed bytes.
- `selection-unset` — a provider exists but no desired Swift selection is
  active.
- `active-build` — bounded observation shows active work.
- `stalled-build` — bounded observation shows no explainable progress.

## Do Not Include

- passwords, Keychain material, signing keys, or Apple account tokens;
- an assertion that a Board or Launch Review approved the change;
- an installation request disguised as diagnostic evidence;
- a claim that a source build is already installed.

## Routing

Attach the packet to the owning Bead. A runtime capability defect belongs with
the Vaporize owner; a third-party source incompatibility belongs with the
dependency owner as a linked, separately closeable Bead. Human review occurs
only after the technical packet is complete.
