@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Release Doctor")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Release Doctor

`release-doctor` is Vaporize's first release-spine self-audit command.

It does not approve a release. It checks whether the product definition, PRD,
CUJs, release gates, launch-review packet, provenance artifact, CUJ coverage,
CUJ-state coverage, public brochure companions, feature catalog, and
engineering DocC surface agree with each other before assistants trust the
packet.

## Command

```bash
vaporize@wrkstrm-core.cli release-doctor \
  --path private/apple/spm/vaporize@wrkstrm-core.cli \
  --format json \
  --receipt-path release/v0.0.1/evidence/vaporize-v0.0.1-release-doctor.receipt.json
```

The command accepts either the package root or `release/v0.0.1` root. The JSON
receipt is `vaporize-release-doctor`.

## First Slice

The v0.0.1 first slice checks:

- required release and engineering artifacts exist
- release evidence JSON parses through Foundation
- PRD, CUJs, release gates, and feature catalog name the release-doctor slice
- the public brochure has the required audience packet and user manual
- vaporware scaffold vocabulary exists in the modification-request discipline
- launch-review packet references the release-doctor gate and receipt
- launch-review gate statuses distinguish machine evidence from human approval:
  machine-supported gates use `EVIDENCE-READY-PENDING-HUMAN-REVIEW`, while
  `PASS`, `PASS-WITH-NOTE`, `APPROVED`, and `APPROVED-WITH-NOTE` require a
  gate-level human review record with `reviewerKind=human`
- provenance inventory names the release-doctor receipt
- CUJ coverage counts CUJ-17 and its targetable test bundle
- CUJ-state coverage names every required state id, proves each id, and leaves
  uncovered, unknown, and duplicate proof lists empty

## Boundaries

Release doctor is the key consistency gate, not a release approval or a
replacement for the other work.

- It can pass while v0.0.1 remains blocked on fleet Pkl-backed Xcode project
  generation.
- It does not run the full test suite yet; CUJ-specific bundles still own
  behavioral proof.
- It does not let automated proof approve a gate. A gate approval without a
  human review record is a blocking release-doctor failure.
- It does not perform periodic build health or buddy heartbeat checks yet.
- It does not own Engineering/QA/Marketing review or competitor reports; those
  belong with the future review/scaffold lane.

## Relationship To Vaporware Scaffold

`vaporware scaffold` is the future umbrella surface for creating upstream
vaporware work packets. `feature-request` is one scaffold kind under that
umbrella, not the umbrella itself.

Release doctor sits later in the lifecycle. It verifies that a vaporware unit's
release packet stayed coherent after the feature request, modification request,
implementation, tests, and evidence updates have all touched the same spine.
