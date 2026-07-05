@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Release Evidence And Gates")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Release Evidence And Gates

Vaporize release review is evidence-first. The release packet defines product
intent, CUJs, test obligations, launch-review state, provenance, benchmark
claims, and open blockers.

The engineering docs explain the product. The release packet proves the product.

## Evidence Stack

The v0.0.1 evidence stack is:

- Product definition before implementation.
- Engineering, QA, and Marketing PRD review before coding.
- PRD requirements.
- CUJs derived from the PRD.
- CUJ-specific SwiftPM test bundles.
- CUJ-state coverage evidence for journey-derived simulated-world state.
- Release gates that name each proof and blocker.
- Launch-review packet JSON.
- Provenance artifact JSON and Markdown.
- Public brochures with required audience packets and user manuals.
- Schema-universal schemas, fixtures, and Swift model tests.

This shape prevents the release from becoming "the code seems to work." The
release must answer what was promised, which user journeys matter, what proof
exists, and which claims are still prohibited.

## Current Test Contract

The current CUJ-derived floor is:

- 23 active CUJs
- 113 required Swift test obligations
- 13 release evidence checks
- 126 required targetable obligations
- 147 executable Swift tests across 23 CUJ-specific bundles

The executable suite may exceed the floor, but the floor comes from PRD and CUJ
obligations. Test count alone is not a product argument.

## Release Gate Status

The current release verdict is blocked for internal essential release. Machine
evidence already covers command surface, JSON validation, release packet shape,
schema extraction, project migration first slices, project target discovery
first slice, workspace product-cache discovery first slice, Xcode workspace
scheme-listing first slice, shared workspace cache first slice, target feature
inspection first slice, CUJ-state coverage, SwiftPM CLI resource-bundle install
preservation, product proving-ground passports, release-doctor spine audit,
pre-code PRD review policy, and
package test execution through Vaporize's owned toolchain route.

That evidence does not pass a gate by itself. Gate approval requires a
gate-level human review record. Until that exists, supported gates remain
`EVIDENCE-READY-PENDING-HUMAN-REVIEW`.

The blocking gates remain focused on full Apple project generation parity and
strong benchmark/runtime sample evidence.

## Schema Boundary

Vaporize evidence is not complete until schema-universal can validate and model
the key receipts. The current schema family is:

```text
schema-universal/private/universal/domain/tooling/schema-families/vaporize-schemas/v0.0.1
```

New release evidence should add or update:

- JSON schema
- canonical fixture
- Swift model
- model decode/round-trip tests
- Vaporize JSON validation evidence

That is what lets engineering docs link to artifacts that a reviewer can
actually validate.

## Brochure Companion Contract

Any Vaporize brochure must have two companions before the release packet can
present it as publication-shaped:

- An audience packet that names the readers, trust posture, must-see facts,
  must-not-see facts, and prohibited claims.
- A user manual beside the brochure that explains how to operate or review the
  advertised surface.

Release doctor enforces this for the v0.0.1 public brochure through
`public-brochure.html`, `evidence/audience-packet.su.json`, and
`user-manual.md`.
