# Vaporize v0.0.1 Public Brochure

**Status:** public-disclosure draft; not approved for publication
**Audience:** external technical evaluators, future customers, board-approved public readers
**Component:** `vaporize@wrkstrm-core.cli`
**Disclosure boundary:** This brochure is the external public disclosure surface. It is claim-limited by `performance-marketing-claims.md`, release-gated by `release-gates.md`, and blocked from publication until the release packet is approved for public consumption.

## What Vaporize Is

Vaporize is the owned build, install, launch, and release-proof lane for assistant-run software work. It wraps native Swift and Apple tooling with typed receipts, explicit toolchain policy, release evidence, and CUJ-derived proof gates.

Vaporize is not a faster compiler claim. It is an engineering-pedigree claim: assistants should use the same native engines humans trust, but with durable proof that says which command ran, which artifact was inspected or produced, which route owned the toolchain, and which release gate the result satisfies.

## Feature Brochure

| Feature | Public-safe description | Proof boundary |
| --- | --- | --- |
| Owned SwiftPM lifecycle | Runs package build and test work through the Vaporize command surface so assistant actions can produce consistent receipts. | Proved by CUJ SwiftPM tests; does not claim faster compilation. |
| Xcode-selected Swift toolchain | Uses the Xcode-selected Swift route for assistant-controlled toolchain execution. | Proves route ownership; host PATH drift can still exist outside Vaporize. |
| JSON release packet validation | Validates release evidence and typed packets through a dedicated command instead of ad hoc terminal parsing. | Proves JSON parseability; schema maturity remains per packet family. |
| CommonProcess use mode | Executes CommonProcess specs through a typed Vaporize surface with receipt support. | Proves invocation discipline; higher-level product wrappers remain separate. |
| Apple project migration intake | Reads legacy project YAML and Pkl-backed AppleProjectSpec records for migration and comparison work. | Proves read, comparison, import, and first-slice generation paths; fleet build parity remains blocked. |
| Pkl-backed Xcode project generation first slice | Generates a first-slice `.xcodeproj` world-state specimen from an owned Pkl record. | Proves one Creative Selection v0.2 specimen; does not prove fleet parity. |
| Project target discovery | Lists buildable targets, package facts, candidate schemes, and proof boundaries from AppleProjectSpec records. | Proves target-fact discovery; does not prove build/install success. |
| Shared workspace product-cache discovery | Maps target facts to expected shared DerivedData `.app` candidates and reports warm or missing status. | Proves candidate path and status reporting; does not prove cache warmth, disk savings, or fleet coverage. |
| Xcode workspace scheme listing | Delegates live workspace scheme discovery to `xcodebuild -list -json -workspace` through Vaporize/CommonProcess. | Proves command and parser boundary; large-workspace runtime samples remain follow-up evidence. |
| Target feature inspection | Inspects release-feature manifests, generated xcconfigs, generated `ReleaseFeatures.swift`, project wiring, and provenance for an app target. | Proves target-level app minimums for the reference specimen; registry-backed fleet inspection remains follow-up work. |
| Release doctor | Audits the release spine for required docs, JSON evidence, launch-review references, provenance, CUJ coverage, and CUJ-state coverage. | Proves release-spine coherence; does not approve final release. |
| CUJ-state coverage | Requires journey-derived CUJ-state records to have explicit proof entries. | Proves the named CUJ-state coverage fixture; does not claim Kura adapter, Turso, sync, migration, or public release readiness. |

## Why It Matters

Assistant-run engineering fails when the runtime can do work but cannot prove the right work happened. Vaporize addresses that by turning build, install, migration, validation, and release-review actions into typed surfaces with receipts and gates.

The public value proposition is:

- Native engines remain the source of execution truth.
- Vaporize owns the assistant-facing command route.
- Release evidence records what was proven and what remains blocked.
- Claims are limited until receipts support stronger language.
- Public disclosure is separated from internal PRD, CUJ, and launch-review packets.

## Proof-Backed Claims

These statements are safe for this draft:

- Vaporize gives assistant-run builds an owned proof surface.
- Vaporize wraps Swift and Xcode workflows with release evidence and typed receipts.
- Vaporize can validate JSON release evidence, inspect Apple project records, and audit its own release spine.
- Vaporize has first-slice support for Pkl-backed Apple project generation, target discovery, workspace product-cache candidate discovery, and Xcode workspace scheme listing.
- Vaporize keeps public claims constrained by measured, behavioral, or theoretical proof status.

## Claims Not Yet Allowed

Do not publish claims that Vaporize is faster than Swift, makes Xcode builds 2x faster, saves a fixed amount of disk space, automatically discovers every workspace product, proves fleet build parity, or is approved for public release.

The current v0.0.1 packet remains blocked for internal-essential release until the Pkl-backed Apple project world-state path has fleet build parity and remaining XcodeGen surfaces are explicitly quarantined or migrated.

## Evidence Map

- Product contract: `release/v0.0.1/product-definition.md`
- Internal PRD: `release/v0.0.1/prd.md`
- Critical user journeys: `release/v0.0.1/cuj.md`
- Release gates: `release/v0.0.1/release-gates.md`
- Claim matrix: `release/v0.0.1/performance-marketing-claims.md`
- Launch-review packet: `release/v0.0.1/evidence/launch-review-packet.json`
- Release doctor receipt: `release/v0.0.1/evidence/vaporize-v0.0.1-release-doctor.receipt.json`
- Public changelog companion: `release/v0.0.1/public-changelog.md`
