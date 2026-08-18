# Temporal Candidate And Explicit Release Request

@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Temporal Candidate Materialization")
  @PageImage(purpose: icon, source: "temporal-candidate-and-explicit-release-request-v001-2608-18050-icon", alt: "A source coordinate becomes a candidate, then an explicitly requested release")
  @PageImage(purpose: card, source: "temporal-candidate-and-explicit-release-request-v001-2608-18050-card", alt: "A temporal source coordinate flowing through separate candidate and release-request decisions")
  @Available(platform: macOS, introduced: "0.0.1")
}

@Image(source: "temporal-candidate-and-explicit-release-request-v001-2608-18050-hero", alt: "A temporal source coordinate flows into a default candidate lane and an explicit release-request lane while refusals stop before mutation")

## PRD

Vaporize must materialize a temporally named candidate by default when it is
given a Foundry temporal handoff. A release build is a separate, explicit
request. Neither outcome is publication, storefront delivery, or human
approval.

The candidate carries a forward source coordinate `vMMM_YYMM_DDHHr`, its
source digest, and the governing coordinate-policy identity. The filesystem
artifact identity ends in `-vMMM-YYMM-DDHHr`. A release-build request adds one
full version, `Major.YYMM.DDHHr+BuildMMSS`, whose first three fields must equal
the source coordinate. `BuildMMSS` never enters the source identity or SwiftPM
precedence.

## Command Boundary

The new temporal flags are distinct from Vaporize's existing
`--product-version`, `--product-build`, and `--auto-increment-build` app
metadata features. Those configure bundle marketing/build values; they do not
prove a Calendar-Origin candidate or release request.

Temporal validation runs before `prepareAppBuildNumberIdentity(for:)`, before
Pkl mutation, before SwiftPM/Xcode build, and before installation. A refusal
therefore cannot advance an app build number or create a mutable output.

## Intended Outcomes

| Input | Intent | Required result |
| --- | --- | --- |
| Valid coordinate + digest, no full release | candidate | Candidate materialization receipt; no release claim. |
| Valid coordinate + digest + matching full release | release-request | Release-request materialization receipt; no publication/approval claim. |
| Missing/malformed/mismatched temporal data | refusal | Typed refusal before source/build/install mutation. |

## Required Receipt

The dedicated receipt records intent, decision, source coordinate, filesystem
artifact identity, source digest, policy identity, optional full release, and
the pre-mutation check boundary. It must be represented by a
Schema Universal schema and fixture before Vaporize's dispatcher consumes it.

## Premortem

- **Failure mode:** a normal build is displayed as a release merely because it
  carries a version. **Cost:** release/publication authority leaks into a local
  build. **Guard:** intent and explicit non-claims remain in the typed receipt.
- **Failure mode:** validation occurs after Pkl auto-increment. **Cost:** a
  rejected request changes source and consumes a build number. **Guard:** run
  temporal validation before `prepareAppBuildNumberIdentity(for:)`.
- **Failure mode:** Vaporize reimplements Foundry's coordinate arithmetic.
  **Cost:** the same handoff succeeds in one tool and fails in another.
  **Guard:** both import the shared Calendar-Origin coordinate component.

## Claim Boundary

This PRD is source intent only. It does not prove dispatcher integration,
schema validation, materialization, installation, release, publication, or
human approval.
