# Implementation Sequence

@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Read-only truth before governed mutation")
  @PageImage(purpose: icon, source: "implementation-sequence-icon", alt: "Implementation sequence icon")
  @PageImage(purpose: card, source: "implementation-sequence-card", alt: "Implementation sequence card")
  @Available(platform: macOS, introduced: "0.0.1")
}

Implementation advances in proof-bearing slices, beginning with typed read-only
truth and ending with separately authorized lifecycle transitions.

@Image(source: "implementation-sequence-hero", alt: "Six implementation gates advance from schema through inventory, refresh, Swiftly proof, cohorts, and adoption")

## Slice One: Schema and Fixtures

- Define `GovernedPackageRecord` and supporting schema types.
- Add canonical, negative, and Swiftly candidate fixtures.
- Validate uniqueness, lifecycle, light-fork, and exception invariants.
- Generate or maintain Swift models through schema-universal conventions.

Exit: fixtures round-trip through typed models and invalid records fail with
stable diagnostic codes.

## Slice Two: Read-Only Inventory

- Extract current authority decoding and path validation into a depot core.
- Observe checkout, manifest, revision, remotes, dirt, workspace, and lockfile.
- Emit deterministic text and JSON inventory.
- Preserve bytes and timestamps of inspected mutable files.

Exit: repeated inventory is byte-stable and produces no repository or SwiftPM
state changes.

## Slice Three: Swift Subprocess North Star

- Materialize the governed Swift Subprocess package record and consumer map.
- Resolve its `latestStable` channel to the newest eligible release revision.
- Fetch on schedule and report freshness against the declared service level.
- Detect URL, package-identity, mirror, and checkout collisions.
- Fast-forward only pristine candidate projections.
- Prove that refresh does not change admitted revisions, consumer pins, dirty
  worktrees, or parent gitlinks.

Exit: Swift Subprocess stays current from official upstream, resolves through
one canonical local authority, exposes its complete consumer blast radius, and
leaves every consumer-affecting surface byte-stable.

## Slice Four: Swiftly Fixture

- Migrate the specimen into the governed package schema.
- Classify the live checkout without sweeping generated evidence.
- Materialize a recoverable patch head or patch series.
- Use recoverable candidate refs or worktrees for light-fork rebases.
- Execute standalone, hosted, concurrency, platform, and Vaporize integration
  checks.

Exit: Swiftly is either admitted with complete receipts or remains an explicit
candidate with typed blockers. Incompleteness is an acceptable outcome;
manufactured completion is not.

## Slice Five: Cohorts and Conflicts

- Discover complete leaf constraints and relevant traits.
- Calculate compatibility intersections by identity.
- Name cohorts and report incompatible leaves.
- Add typed, review-bounded multiple-version exceptions.

Exit: known conflicting identities are explained by a compatible cohort,
approved exception, or blocking diagnostic.

## Slice Six: Lifecycle Operations

- Add proposal-first admission, advancement, patch rebase, and retirement.
- Require explicit review references for state-changing execution.
- Emit operation and verification receipts.
- Preserve recovery references before moving source or parent pins.

Exit: every mutation has a preview, approval, exact operation list, resulting
state, proof matrix, and recovery path.

## Test Strategy

- Swift Testing for schema invariants and deterministic renderers.
- Temporary fixture depots for filesystem observations.
- Synthetic SwiftPM workspace and lockfile fixtures for conflict cases.
- Real Swiftly integration tests only after fixture-level behavior is stable.
- Real Swift Subprocess freshness and identity-convergence tests as the primary
  end-to-end depot acceptance suite.
- Snapshot comparisons for human text and typed JSON inventory.
- Mutation tests that prove read-only commands preserve file content and
  modification times.
- Refresh tests that prove dirty trees and admitted pins remain unchanged while
  remote candidate refs advance.

## Rollout Risk

The highest-risk mistake is adding admission or advance commands before
inventory can distinguish policy from observation. That would automate drift.
The cost is moved checkouts and rewritten resolver state based on incomplete
truth. The gate is categorical: no mutation slice begins until read-only
inventory passes preservation tests across representative depots.
