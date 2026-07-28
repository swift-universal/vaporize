# Engineering Decision: Govern Third-Party Source as a Package Depot

@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("EDR-0001")
  @PageImage(purpose: icon, source: "engineering-decision-icon", alt: "Engineering decision icon")
  @PageImage(purpose: card, source: "engineering-decision-card", alt: "Engineering decision card")
  @Available(platform: macOS, introduced: "0.0.1")
}

The substrate accepts package-level third-party source governance, with
Vaporize as operator, Swift Subprocess as the north-star package, and Swiftly
as the first bounded light-fork specimen.

@Image(source: "engineering-decision-hero", alt: "A selected engineering path separates package governance from the recursive dependency graph")

## Status

Accepted on 2026-07-22. This decision authorizes design and incremental
implementation. It does not admit or publish Swiftly's current uncommitted
candidate. It authorizes automatic upstream fetch and safe candidate refresh;
it does not authorize automatic adoption by consumers.

## Context

The former maintainer-profile model confused people, organizations, packages,
and resolver edges. A real source-governance system needs a stable answer to a
different set of questions: which package is admitted, where its accepted
source lives, which revision and local modifications are active, which leaf
products consume it, and how it advances or retires.

SwiftPM lockfiles answer leaf-resolution questions. They do not establish
fleet-wide source authority, and a library's lockfile does not bind downstream
products. The system therefore needs package governance above leaf lockfiles
without replacing SwiftPM below them.

## Decision

- `maintainers/` is the governed third-party source depot.
- Upstream organization directories are provenance groups.
- Package directories and package records are atomic governance units.
- Admission is affirmative and does not follow transitive closure.
- Every governed package tracks a declared upstream channel as freshly as its
  freshness service level requires.
- Candidate revision and admitted revision are separate state. Refreshing the
  former never silently advances the latter.
- Vaporize owns inventory, diagnostics, compatibility cohorts, advancement,
  patch-rebase proof, and retirement proof.
- Local modifications are explicit light forks while they remain bounded.
- Multiple versions are typed exceptions attached to incompatible cohorts.
- Consumer-affecting mutation workflows are review-gated and receipt-producing.
- Candidate refresh may be automated only when it can preserve local dirt and
  recover the prior candidate exactly.

## North Star: Swift Subprocess

`swiftlang/swift-subprocess` is the reference package against which the depot
contract is judged. It is official upstream source, operationally consumed,
shared across package boundaries, and expected to remain pristine. Vaporize
must keep its latest-stable candidate current, detect every URL or identity collision,
enumerate direct and transitive consumers, and prove adoption separately for
each affected leaf graph.

Swiftly remains the light-fork fixture. It tests the exceptional patch path;
Swift Subprocess defines the normal maintainer path. A design that works only
for the locally modified fixture has missed the depot's center.

## Alternatives Rejected

### Social Maintainer Profiles

People and organizations are not dependency identities. This model obscures
package-level license, revision, patch, consumer, and retirement boundaries.

### Recursive Graph Mirroring

Importing every transitive edge produces unbounded homes and false ownership.
Resolver reachability remains inventory evidence, not automatic admission.

### Lockfiles as Global Authority

Lockfiles are leaf artifacts and may legitimately differ. Treating one as
global authority would mistake one product's resolution for fleet policy.

### Unrecorded Working-Tree Forks

Hidden divergence is cheap only until the next update. Exact bases, patch
budgets, verification, and exits make the actual maintenance cost visible.

## Consequences

The system gains more metadata and review work at admission time. In exchange,
dependency authority, local divergence, consumer impact, and retirement become
inspectable before failure. Vaporize must remain conservative: read-only truth
comes before mutation, and a missing receipt cannot be replaced by prose.

## Failure Premortem

The most likely failure is that light forks become permanent product branches.
The cost is growing rebase work and ownership ambiguity. The control is a typed
patch budget, a named exit condition, and escalation when product policy enters
upstream source.

The second failure is inventory or upstream-freshness drift. The cost is
confident but false diagnostics and integrations built on unnecessarily stale
source. The control is scheduled fetch, an explicit freshness service level,
and mechanically derived checkout, manifest, workspace, and lockfile
observations that remain distinct from declared policy.
