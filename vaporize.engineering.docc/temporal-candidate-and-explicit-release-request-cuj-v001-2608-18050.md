@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Temporal Materialization CUJs")
  @PageImage(purpose: icon, source: "temporal-candidate-and-explicit-release-request-cuj-v001-2608-18050-icon", alt: "A validated handoff routes to candidate, release-request, or safe refusal")
  @PageImage(purpose: card, source: "temporal-candidate-and-explicit-release-request-cuj-v001-2608-18050-card", alt: "Three bounded temporal materialization journeys branching from one validated handoff")
  @Available(platform: macOS, introduced: "0.0.1")
}

# CUJ: Materialize A Temporal Candidate

@Image(source: "temporal-candidate-and-explicit-release-request-cuj-v001-2608-18050-hero", alt: "A validated temporal handoff branches into candidate, explicit release-request, and no-mutation refusal journeys")

1. A product owner receives a Foundry handoff containing
   `v001_2608_18050`, a source digest, and policy identity.
2. They invoke Vaporize in candidate intent without a release version.
3. Vaporize validates the coordinate and digest before build-number mutation,
   build, installation, or publication.
4. Vaporize returns a candidate materialization receipt naming
   `<stable-name>-v001-2608-18050` and explicitly states that it is not a
   release.

# CUJ: Request A Versioned Release Build

1. The owner supplies the same candidate handoff plus
   `1.2608.18050+0010456`.
2. Vaporize verifies that the major, month, day-hour-revision fields equal the
   source coordinate, and that BuildMMSS remains receipt-only provenance.
3. Vaporize materializes the requested build and records a release-request
   receipt.
4. The receipt remains technical evidence only; release review, publication,
   and human sign-off are separate work.

# CUJ: Receive A Safe Refusal

1. The owner supplies a four-segment coordinate, a mismatched full version, a
   missing digest, or a stale handoff digest.
2. Vaporize returns a typed refusal with the failing invariant.
3. Pkl source, build-number source, build output, installation, and release
   state remain unchanged.

## Test Map

| CUJ | Test target | Required assertion |
| --- | --- | --- |
| Candidate | Temporal materialization core tests | Valid coordinate/digest returns candidate intent and no full release. |
| Release request | Temporal materialization core tests | Full version projection must match exactly. |
| Refusal | Temporal materialization core tests | No mutation callback is reached for every invalid input. |
| Dispatcher order | Vaporize CLI integration tests | Temporal gate precedes build-number preparation. |

No release, publication, or approval test follows from this CUJ alone.
