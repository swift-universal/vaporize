@Metadata {
  @TechnologyRoot
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Vaporize Engineering")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Vaporize Engineering

Vaporize is the wrkstrm-core build, test, install, run, project-migration, and
artifact-evidence gate for Swift and Apple app work.

This DocC catalog is the engineering source intended for eventual publication
under a `wrkstrm.com/engineering` route. It is not marketing copy, and it is not
a replacement for the release packet. It explains the system, names its proof
surfaces, and points to receipts that release review can validate.

## Contract

Assistants and automation use Vaporize when build or toolchain work must become
reviewable world-state. Raw Swift, Xcode, and Apple tools remain the underlying
engines, but Vaporize owns the assistant-facing command boundary, receipt
boundary, and release evidence boundary.

The v0.0.1 release is still an internal essential-tool release candidate, not a
public performance claim. Current release review is blocked on full fleet
Pkl-backed Xcode world-state parity, scheme/resource/package feature coverage,
and explicit disposition of remaining XcodeGen surfaces.

## Engineering Topics

- <doc:product-and-policy>
- <doc:feature-catalog>
- <doc:modularity-and-ownership-boundaries>
- <doc:vaporware-modification-request-discipline>
- <doc:command-and-artifact-architecture>
- <doc:project-generation-and-migration>
- <doc:release-evidence-and-gates>
- <doc:pre-code-prd-review>
- <doc:benchmark-and-size-evidence>
- <doc:target-feature-inspection>
- <doc:feature-test-lifecycle>
- <doc:release-doctor>

## Source Of Truth

The package-local engineering catalog explains the system. The release packet
proves it.

Primary release surfaces:

- `release/v0.0.1/product-definition.md`
- `release/v0.0.1/prd.md`
- `release/v0.0.1/cuj.md`
- `release/v0.0.1/release-gates.md`
- `release/v0.0.1/why-vaporize.md`
- `release/v0.0.1/performance-marketing-claims.md`
- `release/v0.0.1/evidence/launch-review-packet.json`
- `release/v0.0.1/evidence/cuj-test-coverage.json`
- `release/v0.0.1/evidence/vaporize-v0.0.1-provenance-artifact.json`
- `release/v0.0.1/evidence/vaporize-v0.0.1-release-doctor.receipt.json`

Primary schema surface:

- `schema-universal/private/universal/domain/tooling/schema-families/vaporize-schemas/v0.0.1`

## Publication Boundary

A future `wrkstrm.com/engineering` pipeline should treat this catalog as the
human engineering narrative and the release evidence directory as the linked
proof corpus. The pipeline should not invent claims from prose. Publishable
claims must be backed by a current receipt, schema fixture, test bundle, or
release gate entry.
