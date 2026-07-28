# Third-Party Depot Engineering

@Metadata {
  @TechnologyRoot
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Third-party source governance in Vaporize")
  @PageImage(purpose: icon, source: "index-icon", alt: "Third-party depot engineering icon")
  @PageImage(purpose: card, source: "index-card", alt: "Third-party depot engineering card")
  @Available(platform: macOS, introduced: "0.0.1")
}

Vaporize turns the substrate's governed third-party source doctrine into typed,
inspectable, and receipt-producing engineering operations.

The operating rule is **fresh source, gated adoption**: maintainers track the
newest eligible upstream candidate, while consumer pins move only after proof.

@Image(source: "index-hero", alt: "Package records pass through Vaporize into verified consumer cohorts")

## System Contract

The filesystem remains the durable source surface. Vaporize is the operational
membrane that reads package records, compares them with checkout and resolver
truth, explains conflicts, and proposes bounded state transitions.

The first implementation establishes read-only inventory, then safe automated
candidate refresh. It must prove that the system can describe current state and
fetch upstream without overwriting dirt or mutating admitted revisions,
consumer manifests, lockfiles, or parent gitlinks. Admission and advancement
commands follow only after discrepancies are typed and reviewable.

## Engineering Decision

<doc:engineering-decision> records the accepted boundary and rejected
alternatives. Its typed companion is:

`engineering/decisions/edr-0001-govern-third-party-source-as-a-package-depot.decision-summary.su.json`

## North Star

Swift Subprocess is the normal-path reference implementation. It must remain
pristine, track the official latest stable release, converge all consumers on one source
identity, and separate a fresh candidate from every admitted consumer pin.
Swiftly follows as the exceptional light-fork fixture.

## Design Topics

- <doc:governed-package-model>
- <doc:vaporize-depot-operator>
- <doc:swiftly-light-fork-implementation>
- <doc:implementation-sequence>

## Non-Goals

- Mirroring every transitive dependency into `maintainers/`.
- Replacing SwiftPM's resolver or one-version-per-identity leaf semantics.
- Treating upstream organizations as single package approval boundaries.
- Hiding local modifications inside dirty checkouts.
- Allowing inventory to mutate repositories merely to make diagnostics clean.
- Equating a freshly fetched candidate with an admitted consumer revision.

## Definition of Done

The design becomes an implementation only when Vaporize can emit a stable
typed inventory, explain every mismatch against filesystem and SwiftPM truth,
exercise Swiftly as a light-fork fixture, and produce reviewable receipts for
each later mutation workflow.
