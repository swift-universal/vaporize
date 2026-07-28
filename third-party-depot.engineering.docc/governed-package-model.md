# Governed Package Model

@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Package-level source governance")
  @PageImage(purpose: icon, source: "governed-package-model-icon", alt: "Governed package model icon")
  @PageImage(purpose: card, source: "governed-package-model-card", alt: "Governed package model card")
  @Available(platform: macOS, introduced: "0.0.1")
}

One typed package record joins declared governance policy to observed checkout,
resolver, consumer, patch, and lifecycle truth.

@Image(source: "governed-package-model-hero", alt: "A governed package record separates declared policy from observed source and consumer state")

## Aggregate Boundary

`GovernedPackageRecord` is the aggregate root. Organization metadata may
provide defaults or grouping, but it cannot replace a package record. The
record has a stable substrate identifier independent of path layout and a
canonical package identity used for resolver comparison.

The initial model should contain:

```swift
struct GovernedPackageRecord: Codable, Sendable, Hashable {
  let schemaVersion: String
  let identifier: String
  let identity: String
  let upstream: UpstreamSource
  let tracking: UpstreamTrackingPolicy
  let checkout: CheckoutAuthority
  let governance: GovernancePolicy
  let consumers: [ConsumerDeclaration]
  let localModification: LocalModificationPolicy
  let contribution: UpstreamContributionPolicy?
  let lifecycle: PackageLifecycle
}
```

## Declared Policy

Declared fields express intended authority:

- canonical and accepted original URLs;
- maintainer-relative checkout path;
- upstream channel: `defaultBranch`, `latestStable`, `latestPrerelease`, or a
  named custom ref;
- freshness service level and last successful fetch requirement;
- newest observed candidate revision;
- exact admitted revision and optional release tag;
- update mechanism;
- owner and review authority;
- license and security classification;
- direct consumer declarations;
- local-modification policy and patch-series reference;
- lifecycle state and retirement condition;
- compatibility-cohort or multiple-version exception references.

Policy is not proof. A declared revision does not mean the checkout currently
matches it, and a declared consumer does not mean its leaf graph resolves
through the admitted authority.

## Fresh Candidate, Gated Adoption

`UpstreamTrackingPolicy` answers what “latest” means for a package. It records
the channel, eligible tag or ref rules, prerelease policy, freshness service
level, and whether a pristine candidate checkout may fast-forward
automatically. Observed state records `candidateRevision`, `admittedRevision`,
`lastFetchedAt`, and the upstream ref from which the candidate was derived.

The candidate revision should converge on the newest eligible upstream commit.
The admitted revision moves only after the affected compatibility cohorts pass
their verification matrix and an advancement receipt is approved. This keeps
source acquisition aggressive without turning every upstream commit into an
unreviewed product dependency change.

A dirty checkout is never reset, cleaned, or overwritten to meet freshness.
Vaporize instead refreshes refs and prepares a separate candidate worktree or
reports the dirt as the reason the checkout projection could not move.

Swift Subprocess is the canonical example: track `swiftlang/swift-subprocess`
`latestStable`, keep the maintainer candidate at its newest fetched release, require
`LocalModificationPolicy.none`, and retain an independently verified admitted
revision for each compatible consumer cohort.

## Upstream Contribution Policy

A locally modified governed package may reference an
`UpstreamContributorProfile`. The profile binds a real contributor identity to
one upstream repository, expected fork remote, permitted patch scope,
contribution guide, verification gates, and credential boundary. It is not a
maintainer-persona record and does not claim upstream membership.

Profiles never contain credentials. A profile remains `proposed` or `standby`
until Vaporize verifies the fork remote and the package-specific proof matrix.
Substrate-only orchestration and receipts are prohibited from upstream patches.

## Observed State

Vaporize derives observations without rewriting policy:

- checkout existence, current revision, remotes, and dirt classification;
- upstream channel head, candidate revision, admitted revision, last fetch,
  and freshness age;
- package identity and products from the manifest;
- mirror configuration and accepted originals;
- workspace-state location and edit status;
- leaf `Package.resolved` pins;
- direct, transitive, build-only, test-only, and rejected consumers;
- local diff footprint and patch-series availability;
- source-location and identity collisions.

Each observation carries its source path and collection time. Diagnostics
compare observations with policy and never silently promote an observation
into policy.

## Light-Fork Model

`LocalModificationPolicy` has explicit cases:

- `none`
- `integrationOnly`
- `lightFork`
- `firstPartyFork`

A light fork requires an exact upstream base, fork head or exported patch
series, purpose, allowed paths, prohibited concerns, patch budget, verification
requirements, review trigger, and exit condition. Missing values make the
record incomplete; they do not default to approval.

## Compatibility Cohorts

A cohort groups leaf graphs that can use one admitted revision with the same
relevant traits. Cohorts are derived from complete leaf constraints and then
named in policy. They do not correspond automatically to repositories,
workspaces, organizations, or teams.

A multiple-version exception contains at least two cohorts, the revision
assigned to each cohort, approval authority, review trigger, retirement owner,
and whether the exception is temporary. A single leaf graph remains unable to
load two versions of one SwiftPM identity.

## Invariants

- Package identifiers and accepted original URLs are unique.
- Every active package has a fetchable upstream and exact admitted revision.
- Every active package has a declared tracking channel and freshness service
  level.
- Candidate refresh never changes an admitted revision or consumer pin.
- Candidate refresh never discards or overwrites local modifications.
- Every local source modification has an explicit policy case.
- Every light fork has a base, budget, verification matrix, and exit.
- Every declared direct consumer is either observed or reported stale.
- Every observed governed consumer is declared or reported undeclared.
- Multiple-version exceptions cannot exist without named cohorts.
- Read-only inventory never changes checkout, manifest, workspace, or lockfile
  state.
