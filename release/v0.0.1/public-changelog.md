# Vaporize v0.0.1 Public Changelog

**Status:** public-disclosure draft; not approved for publication
**Audience:** external technical evaluators, future customers, board-approved public readers
**Component:** `vaporize@wrkstrm-core.cli`
**Public gate owner:** Carrie CMO (`cmo-chief-marketing-officer@wrkstrm.jobs.org`)
**Disclosure boundary:** This changelog is the external release-note companion to `public-brochure.html`, `public-brochure.md`, `user-manual.md`, and `evidence/audience-packet.su.json`. Carrie CMO owns the consumer-facing publication gate; wrkstrm-core owns the Vaporize implementation evidence and release-doctor mechanics. It is safe to review as a draft public surface, but it is not a publication approval and cannot override blocked release gates.

## v0.0.1 Release-Prep Highlights

Vaporize v0.0.1 has matured from a command wrapper into a release-spine tool for assistant-run build work. The release now carries internal product definition, PRD, CUJs, release gates, claim controls, engineering documentation, launch-review evidence, and a public-disclosure draft surface.

### Added

- Adjacent `swift` and `xcode` authorities for macOS `install`, `build`,
  `test`, and `run`, with naturally collapsed pure-Swift commands on hosts
  without Xcode.
- Immediate core-command phase output, `studio.laussat.vaporize` signposts,
  typed timing fields, and exact sibling retry commands.
- Static marketing-site brochure at `public-brochure.html`, with a Markdown companion at `public-brochure.md`, for external disclosure review.
- Audience packet at `evidence/audience-packet.su.json` for the brochure's technical evaluator, future customer, board-approved public reader, operator, and adversarial reviewer profiles.
- User manual at `user-manual.md` so the brochure sits beside an operational review path.
- Release doctor checks for public-disclosure docs and launch-review references.
- ReleaseIdentity-facing public copy for Pkl-backed app, framework, tool, unit-test, local package, and shared-scheme generation, including Sparkle Info.plist key projection boundaries.
- CUJ-state coverage evidence for journey-derived state proof.
- Project target discovery from AppleProjectSpec records.
- Shared workspace product-cache candidate discovery from target facts.
- Xcode workspace scheme-listing through Vaporize/CommonProcess.
- Target-level app minimums inspection for release-feature topology.
- Engineering DocC catalog with feature, modularity, command/artifact, release evidence, benchmark, feature-test, CUJ-state, and release-doctor narratives.

### Changed

- Public-facing claims now route through the claim matrix before they can appear in marketing-site, brochure, or changelog copy.
- The release packet now distinguishes internal PRD/CUJ surfaces from external public disclosure surfaces.
- Release Doctor now treats the public brochure marketing site, audience packet, user manual, Markdown brochure, and changelog as required release artifacts.
- Launch review now carries an explicit public-disclosure surface gate owned by Carrie CMO without recording publication signoff.

### Proof

- `release-doctor` audits required artifacts, JSON evidence, launch-review references, provenance, CUJ coverage, CUJ-state coverage, and public-disclosure references.
- CUJ-09 release-review tests require the public brochure marketing site, audience packet, user manual, Markdown brochure, public changelog, and public-disclosure launch-review gate.
- CUJ-17 release-doctor tests require the live release spine and fixture release spine to include the public-disclosure gate.
- The launch-review packet records `GATE-38-public-disclosure-surfaces`.
- Release Doctor checks the Carrie CMO owner token, `cmo-chief-marketing-officer@wrkstrm.jobs.org`, across the public-disclosure packet.

### Blocked

- Public publication remains blocked until approval follows the full review path.
- Carrie CMO ownership is assigned but not signed off; founder/board publication approvals remain absent.
- Internal v0.0.1 release remains blocked by fleet Pkl-backed Xcode world-state parity and remaining XcodeGen quarantine or migration disposition.
- Strong speed, disk-space, cache-warmth, and fleet-parity claims remain blocked until dedicated benchmark and runtime-sample receipts exist.

### Not Publicly Claimed

This changelog does not claim that Vaporize is faster than Swift, saves a fixed amount of disk space, automatically discovers every app product, proves every workspace graph, or is approved for public distribution.

## Evidence Map

- Public brochure marketing site: `release/v0.0.1/public-brochure.html`
- Audience packet: `release/v0.0.1/evidence/audience-packet.su.json`
- User manual: `release/v0.0.1/user-manual.md`
- Public brochure Markdown companion: `release/v0.0.1/public-brochure.md`
- Release gates: `release/v0.0.1/release-gates.md`
- Claim matrix: `release/v0.0.1/performance-marketing-claims.md`
- Launch-review packet: `release/v0.0.1/evidence/launch-review-packet.json`
- Release doctor source: `sources/vaporize-cli/ReleaseDoctor.swift`
- Release review tests: `tests/cuj-09-release-review/VaporizeCUJ09ReleaseReviewTests.swift`
- Release doctor tests: `tests/cuj-17-release-doctor/VaporizeCUJ17ReleaseDoctorTests.swift`
