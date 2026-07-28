# Vaporize Depot Operator

@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Inventory, diagnosis, and governed transitions")
  @PageImage(purpose: icon, source: "vaporize-depot-operator-icon", alt: "Vaporize depot operator icon")
  @PageImage(purpose: card, source: "vaporize-depot-operator-card", alt: "Vaporize depot operator card")
  @Available(platform: macOS, introduced: "0.0.1")
}

Vaporize observes the depot, keeps eligible upstream candidates fresh, explains
discrepancies, and gates consumer adoption behind verification and review.

@Image(source: "vaporize-depot-operator-hero", alt: "Vaporize transforms declared and observed package state into diagnostics and receipts")

## Existing Foundation

`MaintainerSwiftPMConfiguration` already:

- loads `maintainers/swiftpm-authorities.json`;
- rejects duplicate identities and original URLs;
- verifies local checkout manifests;
- materializes SwiftPM mirror configuration;
- detects incorrect edited and filesystem dependency paths;
- preserves leaf lockfile bytes while preparing authority;
- emits authority receipts.

The implementation should extract these concepts into a reusable depot core
without changing current command behavior. The existing registry becomes a
projection of richer package records, not a competing source of truth.

## North-Star Acceptance Case

Swift Subprocess is the first end-to-end acceptance case for `depot inventory`,
`status --freshness`, `refresh`, and `advance`. Given its canonical
`swiftlang/swift-subprocess` URL, Vaporize must converge alternate source
spellings on one identity, refresh the `latestStable` candidate, reject unexpected
local modifications, report every affected SwiftPM leaf, and leave admitted
pins byte-stable until an advance is approved.

The acceptance case fails if a remote fetch creates an identity conflict, if a
resolver substitutes a second checkout, if a dirty tree is overwritten, or if
candidate refresh changes a consumer graph. Those are north-star failures, not
package-specific exceptions.

## Command Surface

The first public family is read-only:

```text
vaporize depot inventory [--root <substrate>] [--format text|json]
vaporize depot diagnose [--package <identifier>] [--leaf <path>]
vaporize depot show <identifier> [--observations] [--format text|json]
vaporize depot status --freshness [--package <identifier>]
```

Candidate refresh is a normal automatable operation:

```text
vaporize depot refresh [<identifier>|--all] [--channel <channel>] [--dry-run]
```

Consumer-affecting mutation commands are separate and explicit:

```text
vaporize depot admit --proposal <record>
vaporize depot advance <identifier> --candidate <revision> --review <approval>
vaporize depot rebase-patches <identifier> --onto <revision> --review <approval>
vaporize depot retire <identifier> --review <approval>
```

Refresh fetches upstream refs and resolves the newest revision eligible under
the package tracking policy. A pristine candidate projection may fast-forward.
A light fork receives a separate candidate branch or worktree rebased onto the
new upstream base. Refresh never cleans a dirty tree, changes the admitted
revision, rewrites a consumer manifest or lockfile, or advances a parent
gitlink. It records the prior and resulting candidate refs so the operation is
recoverable.

No command should hide a fetch, checkout move, manifest rewrite, workspace
edit, lockfile change, or parent gitlink change. Plans enumerate each operation
before execution.

## Read-Only Pipeline

1. Discover package records under the depot root.
2. Decode and validate declared policy.
3. Inspect checkout, manifest, remote, revision, and dirt.
4. Discover leaf consumers and classify their relationship.
5. Read workspace and lockfile state without preparing or resolving packages.
6. Compare observed state with declared policy.
7. Emit typed inventory and diagnostics.

Warm resolution or build probes are separate opt-in evidence operations because
they can change `.build` state. Their receipts name every mutated cache or
workspace surface.

## Diagnostics

Diagnostics are stable typed codes, not prose-only warnings. Initial codes:

- `DEPOT001` missing package record
- `DEPOT002` missing checkout
- `DEPOT003` checkout revision mismatch
- `DEPOT004` duplicate package identity
- `DEPOT005` duplicate accepted original URL
- `DEPOT006` wrong edited dependency path
- `DEPOT007` wrong filesystem dependency path
- `DEPOT008` undeclared governed consumer
- `DEPOT009` stale declared consumer
- `DEPOT010` unclassified local modification
- `DEPOT011` light-fork budget exceeded
- `DEPOT012` missing light-fork exit condition
- `DEPOT013` incompatible cohort without exception
- `DEPOT014` expired multiple-version exception
- `DEPOT015` candidate exceeds its freshness service level
- `DEPOT016` upstream channel is unreachable
- `DEPOT017` candidate projection blocked by local dirt
- `DEPOT018` admitted revision trails a verified candidate

Each diagnostic records severity, package, leaf when relevant, policy source,
observation source, expected value, actual value, and suggested next operation.

## Logging Contract

Vaporize uses CommonLog with an explicit CLI exposure threshold:

```text
--log-level trace|debug|info|notice|warning|error|critical
```

Command results and machine-readable payloads remain on stdout. Logs always use
stderr, so enabling diagnostics cannot corrupt JSON inventory. The default is
`info`; high-frequency phase boundaries are `trace` and phase durations are
`debug`. Normal operation boundaries are `info`, significant state changes are
`notice`, recoverable drift is `warning`, failed operations are `error`, and
data-loss or invariant-loss conditions are `critical`.

Every depot log event should include stable keys where applicable: operation,
package identifier, leaf, diagnostic code, authority, resolver, request ID, and
receipt path. Secrets, credentials, environment dumps, and unrestricted command
arguments are prohibited. Typed receipts remain the durable proof surface;
logs are operational telemetry and never substitute for them.

## Receipt Boundary

Inventory output is evidence but not mutation approval. Transition receipts
record the input record hash, prior observations, approved plan, executed
operations, resulting revisions, affected consumers, verification matrix,
remaining diagnostics, reviewer reference, and rollback or recovery reference.

An operation that changes source state without a receipt is incomplete even if
the resulting build passes.
