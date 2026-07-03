# Vaporize v0.0.1 Public Changelog

**Status:** public-disclosure draft; not approved for publication
**Audience:** external technical evaluators, future customers, board-approved public readers
**Component:** `vaporize@wrkstrm-core.cli`
**Disclosure boundary:** This changelog is the external release-note companion to `public-brochure.md`. It is safe to review as a draft public surface, but it is not a publication approval and cannot override blocked release gates.

## v0.0.1 Release-Prep Highlights

Vaporize v0.0.1 has matured from a command wrapper into a release-spine tool for assistant-run build work. The release now carries internal product definition, PRD, CUJs, release gates, claim controls, engineering documentation, launch-review evidence, and a public-disclosure draft surface.

### Added

- Public brochure and public changelog surfaces for external disclosure review.
- Release doctor checks for public-disclosure docs and launch-review references.
- CUJ-state coverage evidence for journey-derived state proof.
- Project target discovery from AppleProjectSpec records.
- Shared workspace product-cache candidate discovery from target facts.
- Xcode workspace scheme-listing through Vaporize/CommonProcess.
- Target-level app minimums inspection for release-feature topology.
- Engineering DocC catalog with feature, modularity, command/artifact, release evidence, benchmark, feature-test, CUJ-state, and release-doctor narratives.

### Changed

- Public-facing claims now route through the claim matrix before they can appear in brochure or changelog copy.
- The release packet now distinguishes internal PRD/CUJ surfaces from external public disclosure surfaces.
- Release Doctor now treats the public brochure and changelog as required release artifacts.
- Launch review now carries an explicit public-disclosure surface gate.

### Proof

- `release-doctor` audits required artifacts, JSON evidence, launch-review references, provenance, CUJ coverage, CUJ-state coverage, and public-disclosure references.
- CUJ-09 release-review tests require the public brochure, public changelog, and public-disclosure launch-review gate.
- CUJ-17 release-doctor tests require the live release spine and fixture release spine to include the public-disclosure gate.
- The launch-review packet records `GATE-38-public-disclosure-surfaces`.

### Blocked

- Public publication remains blocked until approval follows the full review path.
- Internal v0.0.1 release remains blocked by fleet Pkl-backed Xcode world-state parity and remaining XcodeGen quarantine or migration disposition.
- Strong speed, disk-space, cache-warmth, and fleet-parity claims remain blocked until dedicated benchmark and runtime-sample receipts exist.

### Not Publicly Claimed

This changelog does not claim that Vaporize is faster than Swift, saves a fixed amount of disk space, automatically discovers every app product, proves every workspace graph, or is approved for public distribution.

## Evidence Map

- Public brochure: `release/v0.0.1/public-brochure.md`
- Release gates: `release/v0.0.1/release-gates.md`
- Claim matrix: `release/v0.0.1/performance-marketing-claims.md`
- Launch-review packet: `release/v0.0.1/evidence/launch-review-packet.json`
- Release doctor source: `sources/vaporize-cli/ReleaseDoctor.swift`
- Release review tests: `tests/cuj-09-release-review/VaporizeCUJ09ReleaseReviewTests.swift`
- Release doctor tests: `tests/cuj-17-release-doctor/VaporizeCUJ17ReleaseDoctorTests.swift`
