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
- PRD requirements.
- CUJs derived from the PRD.
- CUJ-specific SwiftPM test bundles.
- Release gates that name each proof and blocker.
- Launch-review packet JSON.
- Provenance artifact JSON and Markdown.
- Schema-universal schemas, fixtures, and Swift model tests.

This shape prevents the release from becoming "the code seems to work." The
release must answer what was promised, which user journeys matter, what proof
exists, and which claims are still prohibited.

## Current Test Contract

The current CUJ-derived floor is:

- 16 active CUJs
- 69 required Swift test obligations
- 6 release evidence checks
- 75 required targetable obligations
- 87 executable Swift tests across 16 CUJ-specific bundles

The executable suite may exceed the floor, but the floor comes from PRD and CUJ
obligations. Test count alone is not a product argument.

## Release Gate Status

The current release verdict is blocked for internal essential release. Passing
gates already cover command surface, JSON validation, release packet shape,
schema extraction, project migration first slices, shared workspace cache first
slice, target feature inspection first slice, and package test execution through
Vaporize's owned toolchain route.

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
