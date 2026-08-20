# Source and Installed Parity

@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Source and Installed Parity")
  @PageImage(purpose: icon, source: "source-installed-parity-icon", alt: "Two separate artifact identities meet at a comparison gate.")
  @PageImage(purpose: card, source: "source-installed-parity-card", alt: "A source candidate and installed artifact retain independent digests before comparison.")
}

@Image(source: "source-installed-parity-hero", alt: "Source candidate and installed binary travel along separate tracks to a digest comparison gate; no replacement occurs at the gate.")

A source build proves that source can materialize an artifact. An installed
binary proves only the exact bytes currently installed. Neither statement
implies the other.

## The Provider-Loss Pattern

Vaporize normally embeds Swiftly. A prior Release artifact can nevertheless
lack that provider if it was materialized in a feature-reduced configuration.
If the shell `swift` proxy targets that artifact, ordinary Swift invocation
fails even while Xcode's own compiler works.

Diagnose this with identities, never visual similarity or version text alone.

```sh
shasum -a 256 /Users/sonoma/.swiftpm/bin/vaporize.cli@wrkstrm-core.clia.sh
```

Then inspect the candidate artifact's identity separately. A differing digest
is expected for a changed candidate; it does not authorize installation.

## Build a Candidate Without Installation

Vaporize can materialize a candidate through the active Xcode authority while
leaving the installed canonical executable untouched:

```sh
vaporize.cli@wrkstrm-core.clia.sh build xcode \
  --artifact cli \
  --package-path <vaporize-package-path> \
  --product vaporize.cli@wrkstrm-core.clia.sh \
  --configuration release \
  --skip-install
```

This is source-materialization evidence only. It may compile substantial Swift
dependencies on the first invocation. Continue with
<doc:bounded-build-observation> rather than assuming it failed from a quiet
terminal.

## Candidate Capability Check

Run help against the exact candidate path, not the installed path:

```sh
<candidate-vaporize-path> toolchain-selection --help
```

The candidate must report the embedded Swiftly provider. Preserve its digest,
build authority, selected Xcode identity, and output path with the evidence.

## Promotion Is a Separate Step

Do not replace `/Users/sonoma/.swiftpm/bin/vaporize.cli@wrkstrm-core.clia.sh`
merely because a candidate built. Promotion requires all of the following:

1. The candidate's provider capability is exercised.
2. The candidate has its expected test and release proof.
3. The installation is performed through Vaporize's own materialization lane.
4. The installed artifact's digest and capability are checked again.

Failure mode: installing an unreviewed candidate globally can alter the shell
`swift` path and disrupt unrelated projects. This guide intentionally stops
before that authority boundary.
