@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Package Supply And Build Intelligence")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Package Supply And Build Intelligence

Vaporize will own the package-supply decision above SwiftPM: what logical
dependency is requested, whether the current build should consume maintained
source or an admitted product, which contextual resolution is valid, where a
large payload lives, and what evidence the operation contributes to fleet build
intelligence.

This is a requirements contract. The lane is
`requirements-defined; implementation-pending`. It does not claim that the
resolver, provisioner, depot adapter, schemas, or analytics projector exist.

## Responsibilities

| Layer | Authority |
| --- | --- |
| Package-supply policy declaration | Declares logical identity, Calendar-Origin `from:`, representation, and canonical local/permitted remote repository endpoints; prepares one effective SwiftPM input. |
| `Package.swift` | Contains the one effective path or remote coordinate that SwiftPM can resolve for this invocation. It does not natively express route alternatives. |
| Vaporize | Supplies build context, selects representation and freshness policy, orchestrates provision/admission, and emits receipts. |
| SwiftPM | Resolves the dependency graph, writes the current `Package.resolved`, and performs source/package compilation. |
| Git `pro` repository | Records admitted temporal resolutions and build metadata available to permitted clients. |
| Artifact depot | Stores optional large payload bytes referenced by an admitted Git record. |
| Build intelligence | Projects durable observations into coverage and performance summaries outside the build's critical path. |

The depot is intentionally not a fourth route beside canonical local source and
permitted remote Git. It is the payload data plane for a provisioned product
selected through Git.

SwiftPM's current PackageDescription surface cannot declare a first-class
logical dependency with alternate local and remote routes. The policy
declaration is therefore compiled or prepared into exactly one effective
SwiftPM input before resolution. That limitation does not create a second
logical identity, and it does not make the depot a peer package source.

## Visibility Projections

- `pri` owns producer-private source and build machinery.
- `pro` owns ACL-controlled, client-facing manifests and provisioned products.
- `pub` owns deliberately public projections.

`pro` mirrors the relevant relative structure of `pri` so a Package manifest
can select the appropriate projection without leaking the private source tree.
The projections share a logical product identity; visibility is not a new
dependency identity.

## Context And Resolution

A build context contains at least:

- product
- platform
- architecture
- configuration, derived from parsed SwiftPM/Vaporize build parameters
- Swift toolchain
- release channel such as developer, dogfood, TestFlight, or App Store
- source or product dependency representation

The context also selects the best admitted carrier for the platform rather
than forcing a lowest-common-denominator archive. One logical dependency and
one temporal requirement may resolve to an Apple XCFramework, a Linux or
Windows target-triple artifact, or an Android carrier keyed by SDK, NDK, API,
and architecture. Carrier selection is contextual and receipted. If no
compatible carrier is admitted, policy must select an explicit source fallback
or return typed `ProvisioningRequired`; it must never borrow a similar platform
artifact silently.

The policy declaration expresses the logical requirement; `Package.swift`
receives the prepared effective route. Vaporize supplies this context. SwiftPM
computes the resolution. Vaporize captures the resulting
`Package.resolved` as a contextual artifact and admits trusted records.

The root `Package.resolved` is the current working projection. It is not the
authority for every platform and configuration. Distinct contexts must remain
distinct artifacts so a Windows product-first build cannot silently replace a
macOS source-release resolution, or vice versa.

## Temporal Selection

Calendar-Origin versions use `Major.YYMM.DDHHR`. A dependency `from:` selects
an admitted coordinate in `[from, nextMajor(from))`: the lower bound is
inclusive and compatibility remains inside that major, matching SwiftPM's
existing `.upToNextMajor(from:)` model.

Git revisions and payload digests remain evidence:

- the Git record proves which admitted source and build produced the selection;
- the digest proves the selected payload has not changed;
- neither replaces the temporal version as the ordinary dependency contract.

Freshness is explicit:

| Policy | Behavior |
| --- | --- |
| `locked` | Reuse the admitted contextual selection. |
| `refresh` | Discover and report compatible candidates without adoption. |
| `update-compatible` | Explicitly adopt a compatible candidate and update the contextual resolution. |
| `offline` | Use only locally available admitted records and payloads. |

Vaporize fetches or inspects refs; it does not pull into a maintainer's working
tree. The direct-local route instead uses the canonical in-place checkout and a
graph-receipt gate verifies that its actual coordinate equals the consumer's
selected dependency coordinate. Discovery, selection, and adoption are
separately receipted states.

## Vaporize Integration Seam

The first implementation slice is feature-gated. Vaporize's one-turn CLI
application composes `CommonFeatureFlags` at launch and injects a
`PolicyEvaluatorService` into the workflow selector. A compiled-disabled flag
selects the unchanged legacy workflow by default; an explicit enabled policy
selects a separate library-product workflow. The slice proves one actual host
carrier and a typed build/test receipt. It does not claim that this carrier is
universal or that the broader depot-backed provisioner is complete.

The feature is governed by a Beads v0.0.3 parent/child graph. The current
library-only Bead remains the implementation-problem child, and the existing
`feature-gated-cli-dependency-experiment` supplies the specialized execution
workflow. The graph requires impact analysis and product-document deltas before
implementation, then experiment receipts, analytics, a human decision, flag and
dead-branch removal, and closure validation in that order. Analytics must exist
before the decision; cleanup is mandatory after it.

The planned lookup runs immediately after `coreExecutionPlan(for:)` has parsed
the command and build parameters, including configuration, and before the
existing i18n and SwiftUI source gates. It returns the selected effective
package/materialization and a selection receipt; subsequent gates then inspect
the selected representation.

The existing maintainer path configures mirrors, snapshots `Package.resolved`,
performs its legacy `swift package edit` preparation, runs SwiftPM, and restores
the snapshot. The new canonical-local and provisioned-product routes are not
that editable-checkout mechanism: they use direct canonical paths or the
Git-selected admitted record, and have their own preparation and receipt gates.
Configuration remains command context, never a conditional dependency
declaration.

## Product-First And Source-Release Policy

During development, the active package builds from source and its dependencies
prefer admitted products. A product hit avoids recompiling that dependency. A
client miss returns `ProvisioningRequired`.

An authorized producer may respond to the same miss by building from source,
verifying, admitting the contextual resolution and product, then retrying once.
Client authority never silently expands into producer authority.

Large release products rebuild their full dependency closure from admitted
source. A fast product-first development build cannot satisfy that source-closure
release gate.

## Payload And Privacy Admission

Artifacts at or above 100 MiB never enter Git. An admitted Git record may point
to a depot payload with size and integrity evidence. Smaller important payloads
may be embedded only through explicit policy.

Before `pro` admission, Vaporize blocks:

- producer source paths and usernames
- environment values and secrets
- private repository or network topology
- raw logs and internal receipts
- signing material
- prohibited debug symbols or unstripped private metadata

The privacy receipt records finding categories without reproducing sensitive
values.

## Observable State Machine

```text
requested
  -> discovering-resolutions
  -> resolution-selected
  -> artifact-lookup
  -> product-hit -----------------------------> completed
  -> product-miss -> building -> verifying -> admitted -> completed
                                                 \-> failed
```

Every transition carries one correlation identity through CommonLog, Service
Context, Distributed Tracing, typed events, and the final receipt. A durable
local outbox records observations before asynchronous projection. Remote
analytics can be unavailable without making a build fail. A release policy may
separately require an acknowledged release receipt.

The current `VaporizeCoreExecutionRecorder` phases—core command, dependency
preparation, dependency restoration, and process execution—are the starting
execution evidence. Package supply adds typed resolution, artifact lookup,
verification, and admission states rather than attempting to infer them from
console text.

## Build Intelligence

The canonical evidence chain is:

```text
BuildResolutionRequest
  -> Package.resolved
  -> BuildResolutionArtifact
  -> ProvisioningPlan
  -> AdmittedBuildRecord
```

An `AdmittedBuildRecord` carries the selected temporal coordinate,
representation, and contextual dimensions, plus either an embedded Git payload
or a depot locator. The record's digest is receipt-level integrity evidence
after selection; it is not a request identity or cache-selection key.

The projector distinguishes three coverage planes:

- requested: the context someone attempted to build;
- resolved: a valid contextual graph exists;
- provisioned: a compatible admitted product is available.

That produces honest X-of-Y coverage rather than a single success count. Useful
projections include product-hit rate, source/product ratio, missing contexts,
stale resolutions, build duration, and freshness posture. Every summary cell
must drill back to durable receipts.

## Required Schema Universal Contracts

- `PackageResolutionContextModel`
- `PackageResolutionRequestModel`
- `PackageResolutionArtifactModel`
- `PackageResolutionReceiptModel`
- `BuildRunEventModel`
- `BuildRunReceiptModel`
- `BuildArtifactObservationModel`
- `BuildArtifactAdmissionModel`
- `BuildPortfolioProjectionModel`
- `BuildCoverageCellModel`
- `BuildPerformanceSummaryModel`
- `BuildFreshnessSummaryModel`

The feature-gated library-product slice also requires a Schema Universal-owned
build/test receipt capable of distinguishing the selected workflow and SwiftPM
product kind. Until the schema family establishes whether this is an extension
of `BuildRunReceiptModel` or another owned contract, Vaporize must not create an
app-local substitute.

These belong in Schema Universal before the architecture can be called complete.
Logs may render the same state, but log text is not the schema contract.

## Platform And Service Rules

Package discovery, resolution, provision, admission, and observation are
cross-platform service contracts. Different operating systems receive separate
test suites and policy-selected manifests. Service implementations do not use
compile-time platform branches to merge different behavior, and process
execution uses CommonProcess exclusively.

## Product Requirements And Journeys

The canonical PRD requirements are FR-036 through FR-048 in
`release/v0.0.1/prd.md`. The canonical journeys are CUJ-28 through CUJ-39 in
`release/v0.0.1/cuj.md`. They remain outside the active v0.0.1 proof floor until
pre-code review assigns targetable tests, schemas, and receipts.
