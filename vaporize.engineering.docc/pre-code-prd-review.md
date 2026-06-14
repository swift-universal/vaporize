@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Pre-Code PRD Review")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Pre-Code PRD Review

Major Vaporize feature work starts with a PRD review session, not coding.

The required reviewers are Engineering, QA, and Marketing. Each lane reviews a
different kind of truth before implementation begins.

## Purpose

The session prevents three common failures:

- Engineering builds a feature whose proof surface is unclear.
- QA receives behavior that was never made testable.
- Marketing inherits claims that the product cannot honestly support.

The review happens after the product definition, PRD, and draft CUJs exist, and
before implementation starts.

## Engineering Lane

Engineering reviews:

- system fit
- owning tool boundary
- implementation slice
- reuse of existing substrate surfaces
- receipt, schema, and artifact obligations
- migration and quarantine strategy
- blocked-vs-partial truth

Engineering approves the build path only when the PRD can be implemented as a
bounded proof.

## QA Lane

QA reviews:

- CUJ ownership
- acceptance criteria
- negative cases
- feature-scoped test bundle
- release evidence checks
- fixture and schema mirrors
- focused verification command

QA approves only when the feature can fail visibly and be tested directly.

## Marketing Lane

Marketing reviews:

- user choice argument
- safe claim language
- examples and positioning
- prohibited claims
- benchmark evidence required for stronger claims
- eventual catalog or engineering-site narrative

Marketing approves only when the PRD's promise is honest for the evidence that
will exist at release.

## Output

The session emits one decision:

- `GO`
- `GO-WITH-NOTES`
- `NO-GO`

No major coding slice should begin without that decision recorded in the release
packet. If the decision is `GO-WITH-NOTES`, implementation must stay inside the
named constraints. If the decision is `NO-GO`, implementation waits for a PRD
revision and another review.

For Vaporize v0.0.1, this requirement is backfilled in
`release/v0.0.1/prd-review-session.md` because the release-prep lane was already
in flight. Future coding slices do not get that exception.
