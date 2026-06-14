# Vaporize v0.0.1 - PRD Review Session

**Status:** required pre-code gate, backfilled for current in-flight release prep
**Updated:** 2026-06-14T02:12:00Z
**Component:** `vaporize@wrkstrm-core.cli`
**Review lanes:** Engineering, QA, Marketing

## Rule

No major Vaporize feature slice should enter coding until the PRD has been
reviewed by Engineering, QA, and Marketing.

This is a product gate, not a ceremony. The session exists to make the product
promise, proof obligations, acceptance criteria, and claim boundaries explicit
before implementation starts.

## Current Release Boundary

Vaporize v0.0.1 was already in release-prep implementation before this gate was
codified. This artifact is therefore a backfilled process correction for the
current release lane, and a hard requirement for future coding slices.

Future changes that add major feature surface, user-facing claims, release
gates, benchmark claims, or app/build behavior must have this PRD review session
recorded before implementation begins.

## Required Inputs

- Product definition and choice argument.
- PRD requirements.
- CUJ map and draft acceptance paths.
- Proposed release gates.
- Proposed test bundle or evidence strategy.
- Proposed marketing, positioning, benchmark, and prohibited claims.
- Known dependencies, migration risks, and non-goals.

## Engineering Review

Engineering signs that the PRD is buildable and bounded.

Required questions:

- Does the feature belong in Vaporize rather than another tool?
- Which existing substrate surfaces must be reused before new ones are added?
- Which command, receipt, schema, or artifact boundary proves the feature?
- What is the smallest implementation slice that still proves the product
  claim?
- Which migrations, compatibility surfaces, or quarantines are required?
- Which failure modes must remain visible in release review?

Engineering output:

- Technical scope decision.
- Required proof surfaces.
- Implementation boundary.
- Known blockers and deferred work.

## QA Review

QA signs that the PRD is testable and release-reviewable.

Required questions:

- Which CUJ owns the behavior?
- Which targetable SwiftPM test bundle proves the feature?
- Which negative cases are required?
- Which release evidence checks are required beyond executable tests?
- Which fixtures, receipts, or schema-universal mirrors must be updated?
- What makes the feature blocked rather than partially accepted?

QA output:

- Test obligations.
- Evidence obligations.
- Acceptance and rejection criteria.
- Regression risk and focused test command.

## Marketing Review

Marketing signs that the product promise and claims are honest.

Required questions:

- Why would a user choose this feature?
- What is the safe one-sentence claim?
- Which examples can be shown before stronger benchmark evidence exists?
- Which claims are prohibited until receipts exist?
- Does the feature change the eventual catalog, engineering-site, release-store,
  or App Store style promise?

Marketing output:

- Approved claim language.
- Prohibited claim language.
- Required benchmark or evidence receipts for stronger claims.
- External-facing narrative boundary.

## Session Output

The session must produce one of these decisions:

- `GO`: PRD, CUJs, proof obligations, and claims are aligned; coding may start.
- `GO-WITH-NOTES`: coding may start only inside named constraints.
- `NO-GO`: coding is blocked until the PRD changes and the session reruns.

The durable output must name:

- reviewers or reviewing roles
- decision
- approved scope
- required tests
- required release evidence
- approved and prohibited claims
- open blockers

## v0.0.1 Backfilled Decision

Decision: `GO-WITH-NOTES`.

Rationale: the current release-prep lane already contains product definition,
PRD, CUJs, release gates, performance claim boundaries, engineering DocC, typed
fixtures, and CUJ-specific test bundles. The correction is accepted for the
current lane only because those artifacts now exist and are cross-checked by
CUJ-09 and schema-universal tests.

Notes:

- This does not prove that the pre-code session occurred before earlier coding.
- It does make the pre-code PRD review session mandatory for the next major
  Vaporize coding slice.
- Any future slice that bypasses this gate should be treated as release review
  failure, even if the code compiles.
