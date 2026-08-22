@Metadata {
  @PageKind(article)
  @PageColor(orange)
  @TitleHeading("Vaporize and WCode Service Topology Engineering Design")
}

# Vaporize and WCode Service Topology Engineering Design

## Document Control

| Field | Value |
| --- | --- |
| Status | Drafted implementation contract. The service direction is affirmed; this document is not a release or approval record. |
| Product line | Vaporize, WCode, and cross-platform application lifecycle execution. |
| Product owner | Wrkstrm CPO. |
| Engineering owner | Wrkstrm CTO. |
| Primary feature Bead | `FR-VAPORIZE-WCODE-SERVICE-TOPOLOGY-2026-08-21` |
| Service doctrine | `service-universal/.docc/index.md` and `common-process-service/CommonProcessService.docc/MinimumAPIDesign.md`. |
| Canonical Vaporize history | `wrkstrm-core/private/apple/spm/vaporize@wrkstrm-core.cli`. |

This page is the engineering decision record for moving platform behavior out
of Vaporize and into injected services. It does not create a new Vaporize,
rename an existing repository, move a canonical checkout, or grant release
authority.

## Executive Summary

Vaporize currently owns too much concrete platform behavior. Windows WCode
logic, Apple Xcode logic, direct CommonProcess execution, self-update mechanics,
and operating-system imports have accumulated in shared package and CLI code.
The resulting conditional compilation is evidence that backend behavior has
crossed the facade boundary.

The substrate already has the architecture needed to correct this:

- `service-universal` owns portable service protocols and no SDK
  implementations.
- `schema-universal` owns versioned request, result, receipt, and capability
  vocabulary.
- Concrete adapters live beside the SDK or host dependency they use.
- `common-service-context` registers implementations and evaluates readiness.
- Product facades select and orchestrate a service exactly once.

Vaporize will become that facade. `swift-win` will remain the raw Swift and
`Package.swift` lane and will reject application lifecycle work with an exact
WCode next-step command. WCode will implement Windows application build, run,
and installation. An Xcode adapter will implement the corresponding Apple app
lifecycle. Neither implementation will live in Vaporize's shared command body.

## Decision

Adopt the service-universal composition pattern for application lifecycle and
process execution:

```text
schema-universal
  application lifecycle request / support / receipt models
        |
        v
service-universal
  protocol-only application lifecycle contract
        |
        +-----------------------------+
        |                             |
        v                             v
WCode adapter                    Xcode adapter
Windows app lifecycle            Apple app lifecycle
beside Windows tooling           beside Apple tooling
        |                             |
        +--------------+--------------+
                       v
common-service-context
  host-bootstrap registration and readiness
                       |
                       v
Vaporize facade
  parse -> validate authority -> resolve -> perform once -> receipt
```

The command grammar continues to name explicit authorities. The authority name
selects a registered service; it does not open a platform implementation branch
inside Vaporize.

## Problem and Context

The first Windows upgrade slice correctly established the product distinction:
SwiftPM alone does not own an application. Apps need resources, packaging,
installation, runtime configuration, and potentially Visual Studio or other
custom tooling. That made WCode the correct Windows app authority.

The initial implementation placed that distinction directly into Vaporize with
`#if os(Windows)`, WCode-specific options, PowerShell environment construction,
and local execution fallback. Continuing in that direction would make
Vaporize a collection of operating-system implementations rather than a stable
artifact facade.

The repository already demonstrates the intended split. `CommonProcessService`
owns only the execution protocol and capability descriptor. Foundation and
swift-subprocess implementations live in separate packages in
swift-universal. `ServiceContext` injects typed implementations by stable
identifier and evaluates whether required capabilities are available at the
correct activation phase.

The correction is therefore architectural, not cosmetic. Moving the same
`#if` blocks into helper functions would preserve the responsibility leak.

## Minimum API Anatomy

### Purpose

Provide one portable application lifecycle contract that Vaporize can invoke
without importing platform SDKs or implementing platform behavior.

### Restraints

- The contract does not select an implementation implicitly.
- Vaporize does not manufacture an app backend when the requested service is
  missing.
- WCode does not accept CLI or TUI artifact ownership.
- `swift-win` does not build, install, package, or run an app as an app.
- An adapter does not grant signing, distribution, or release authority.
- A service implementation does not call back into the Vaporize facade.

### Known Limitations

- WCode app testing has no accepted contract yet.
- No canonical WCode implementation package has been identified in the current
  checkout; its historical home must be located before new implementation code
  is created.
- `CommonProcessService` currently consumes common-process schema v0.0.1 while
  the active CommonProcess package consumes v0.0.3.
- Windows CLI self-replacement is a separate executable-installation problem;
  it is not automatically part of the app lifecycle contract.

### Known Problems

- Vaporize directly imports `CommonProcess` and `CommonProcessExecutionKit`.
- Platform selection and backend execution are interleaved in the flat CLI.
- The current WCode prototype transports lifecycle behavior through a generic
  PowerShell script option rather than a typed service implementation.
- Portable CommonProcess source exposes Unix `pid_t`.
- Existing runner adapters contain Unix path and executable assumptions.

### Previous Bugs

- Vaporize was temporarily treated as a new tool instead of preserving its
  long wrkstrm-core history.
- A duplicate Vaporize tree was created in swift-universal rather than changing
  the canonical product.
- Local dependency assumptions caused unrelated package failures to be
  misclassified as Windows app failures.
- Repeated conditional imports allowed compilation progress while obscuring
  the missing service boundary.

### Future Conditions

The contract may grow only when a new operation cannot be represented by the
existing request and support result, has an owner, has negative tests, and does
not absorb an adjacent service such as signing or distribution.

### Expectations

Callers can rely on explicit support checks, deterministic missing-service and
unsupported-operation failures, one selected implementation per invocation,
and a receipt that identifies the implementation and artifact involved.

## Goals

1. Make Vaporize a platform-independent orchestration facade.
2. Preserve `swift-win` as the Package.swift-only Windows lane.
3. Make WCode the concrete Windows app build, run, and install service.
4. Model Xcode as the Apple app lifecycle implementation of the same portable
   capability.
5. Register services through `common-service-context` at host bootstrap.
6. Keep platform SDK imports and conditional compilation inside concrete
   adapter targets.
7. Preserve canonical repository locations and long-path-compatible dependency
   topology.
8. Produce focused contract, adapter, facade, and installed-runtime evidence
   without collapsing those proof levels.

## Non-Goals

- Moving or renaming repositories to make relative paths easier.
- Replacing WCode with a generic PowerShell script runner.
- Making SwiftPM responsible for Windows or Apple app installation.
- Treating CommonProcess as an application lifecycle service.
- Solving signing, notarization, distribution, or store submission in this
  contract.
- Claiming Windows fleet parity from one pilot app.
- Adding WCode app testing before build, run, and install are stable.
- Rewriting all historical Vaporize commands during the first migration slice.

## Requirements and Constraints

| ID | Requirement | Observable proof |
| --- | --- | --- |
| `service-contract-home` | Portable protocols live in service-universal and import no platform SDK. | Package source and dependency audit. |
| `schema-home` | Cross-package request, support, result, and receipt vocabulary is versioned in schema-universal. | Schema fixtures and round-trip tests. |
| `implementation-home` | WCode and Xcode implementations live beside their tooling, outside service-universal and Vaporize shared code. | Package topology and import audit. |
| `explicit-authority` | `swift-win`, `wcode`, and `xcode` remain explicit authority tokens. | Parser and routing tests. |
| `swift-win-refusal` | Every app operation presented to `swift-win` fails before execution with the matching WCode next step on Windows. | Negative facade tests. |
| `wcode-artifact-boundary` | WCode refuses CLI and TUI artifacts with a `swift-win` pointer. | Negative adapter and facade tests. |
| `single-orchestration` | Vaporize resolves one service and performs one operation without backend recursion or retry siblings. | Spy-service invocation-count tests. |
| `readiness` | A selected required service must be registered at host bootstrap. | ServiceContext readiness tests. |
| `path-stability` | Canonical repositories and declared dependency paths are not moved as a repair technique. | Git topology receipt and exact pointer review. |
| `bounded-evidence` | Build, run, install, signing, and release remain distinct proof claims. | Typed receipts and release-gate review. |

## Proposed System

### Contract Layers

| Layer | Owner | Responsibility | Must not do |
| --- | --- | --- | --- |
| Application lifecycle schemas | schema-universal | Version request, support, output, diagnostic, and receipt models. | Import WCode, Xcode, SwiftPM, PowerShell, or platform SDKs. |
| Application lifecycle service | service-universal | Define the minimum protocol and descriptors. | Run a process, select a backend, or contain an SDK implementation. |
| WCode adapter | canonical WCode home | Implement Windows app build, run, install, resource staging, packaging, and declared custom tooling. | Accept CLI/TUI ownership or call Vaporize recursively. |
| Xcode adapter | Apple tooling home | Implement Apple app project/workspace build, test where contracted, run, and install/materialization operations. | Become the general SwiftPM lane or leak Xcode types into the service contract. |
| Swift package lane | swift-win plus process/build services | Build and run raw Package.swift CLI/TUI products. | Claim application lifecycle or installation. |
| Service composition | common-service-context | Register concrete services and report required capability readiness. | Construct hidden fallback implementations. |
| Product facade | Vaporize | Parse intent, enforce artifact authority, resolve one service, invoke it once, and emit bounded evidence. | Implement platform lifecycle steps. |

### Minimum Contract Shape

The exact versioned names are finalized with the schema package, but the
minimum behavior is:

```swift
public protocol ApplicationLifecycleService: Sendable {
  var descriptor: ApplicationLifecycleServiceDescriptor { get }

  func support(
    for request: ApplicationLifecycleRequest
  ) -> ApplicationLifecycleSupport

  func perform(
    _ request: ApplicationLifecycleRequest
  ) async throws -> ApplicationLifecycleReceipt
}
```

The descriptor identifies the implementation, version, platforms, operations,
artifact kinds, and declared limitations. `support(for:)` is deterministic and
side-effect free. `perform(_:)` may execute only after support and service
readiness succeed.

The request model carries only portable intent: operation, artifact identity,
configuration, destination, arguments, environment, lifecycle flags, and
references to declared project inputs. It does not carry an Xcode object,
PowerShell process, Visual Studio object, or backend closure.

### Service Identifiers

The initial composition uses stable capability identifiers:

| Identifier | Meaning |
| --- | --- |
| `build.application-lifecycle.wcode` | Windows app lifecycle implementation. |
| `build.application-lifecycle.xcode` | Apple app lifecycle implementation. |
| `build.swift-package.swift-win` | Raw Windows Swift/Package.swift execution lane. |

Vaporize derives the required service from the explicit command authority after
parsing. A missing selected service is a blocking host-bootstrap diagnostic. It
is not permission to try another authority.

### Routing Invariants

1. Artifact validation occurs before service lookup or process execution.
2. `swift-win + app` always refuses with a WCode command.
3. `wcode + cli/tui` always refuses with a swift-win command.
4. `wcode + app + test` remains unsupported until a versioned test contract is
   accepted.
5. `xcode` is never available merely because the host is macOS; its service
   must be registered and ready.
6. An adapter may use lower-level command execution services internally, but it
   cannot call Vaporize or reset authority selection.
7. A generated command cannot re-enter application lifecycle selection.
8. One receipt names one selected implementation and one operation.

### Conditional Compilation Boundary

Conditional compilation is allowed only where a package must bind a concrete
platform API or omit an unavailable adapter target. Shared schemas, service
protocols, authority validation, and Vaporize orchestration compile without
platform behavior branches.

For example, the WCode adapter may import Windows SDK modules and the Xcode
adapter may import Apple frameworks. Vaporize imports the service contract and
ServiceContext, not either SDK.

### Process Service Integration

Vaporize will stop importing runner implementation packages directly. Typed
command execution flows through `CommandExecutionService`. Foundation and
swift-subprocess remain adapters, and a Windows-capable adapter must own Windows
PATH, executable-extension, exit-status, and process semantics.

Before that migration, the common-process schema v0.0.1/v0.0.3 mismatch must be
resolved by a versioned contract or an explicit adapter. The mismatch must not
be hidden by type aliases or copied models.

### Self-Update Boundary

Feed parsing and signature verification are portable capabilities. Replacing a
running executable and relaunching it are installation capabilities with
different Unix and Windows semantics. They will use a separate executable
installation/relaunch service rather than expanding the application lifecycle
contract or assigning CLI replacement to WCode automatically.

## Data and State Invariants

1. The authority token and artifact kind are immutable after routing begins.
2. The selected service identifier is recorded before side effects.
3. A missing or unsupported service leaves no partial application artifact at
   the requested destination.
4. Custom tooling is declared as project input and executed only by the owning
   adapter.
5. Environment overrides are typed request data, not ambient mutation in the
   Vaporize process.
6. Build output, installed output, and launched process identity remain
   separate receipt facts.
7. Service registration never changes an active invocation's implementation.
8. Canonical paths remain stable; long path support is a host prerequisite, not
   a reason to shorten or relocate repositories.

## Error and Next-Step Contract

Every refusal names the owner and the next valid command when one exists:

```text
swift-win cannot install an app.
next: vaporize install wcode --artifact app ...

wcode cannot build a cli artifact.
next: vaporize build swift-win --artifact cli ...

WCode application lifecycle service is not registered.
next: install or configure the canonical WCode adapter, then rerun the same command.
```

Messages must not suggest moving the repository, changing a canonical path, or
using an unrelated installed Vaporize binary as a fallback.

## Testing and Evaluation

| Lane | Subject | Required proof | Does not prove |
| --- | --- | --- | --- |
| Contract | schema and service packages | Models round-trip; protocols compile without SDK imports; support results are deterministic. | A real backend works. |
| Adapter | WCode or Xcode package | Supported operations call only owned tooling; unsupported artifacts refuse; receipts identify the adapter. | Vaporize routing or installation. |
| Facade | Vaporize with spies | Exact authority resolves exactly one service; missing services and invalid artifact combinations fail before invocation. | Real SDK behavior. |
| Process | command execution adapter | Windows executable discovery, environment, output, exit status, and cancellation behave correctly. | App packaging or install. |
| Pilot build | one Windows app | WCode creates the expected app artifact from the declared source. | Run, install, signing, or fleet parity. |
| Pilot run | same Windows app | WCode launches the exact built artifact with declared arguments and environment. | Installation or release. |
| Pilot install | same Windows app | WCode places and verifies the exact app at the declared destination. | Signing, distribution, or release. |

Tests use injected spy services for routing and focused real adapters for
platform behavior. Tests do not compile different expectations for each OS in
the shared facade suite.

## Rollout and Migration

### Phase 0: Record the Decision

Commit this engineering design and its Bead in the historical wrkstrm-core
Vaporize tree. Treat the current direct WCode implementation as a prototype and
source of routing tests, not as the final architecture.

### Phase 1: Reconcile Existing Service Contracts

Inventory `CommonProcessService`, its schemas, the current CommonProcess v0.0.3
surface, existing runner adapters, and ServiceContext identifiers. Resolve the
schema-version mismatch explicitly before changing Vaporize imports.

### Phase 2: Create Portable Lifecycle Vocabulary and Contract

Add the versioned schema package and the minimum service protocol. Prove the
contract has no platform SDK imports and document its restraints and known
limitations.

### Phase 3: Locate and Implement Canonical Adapters

Locate WCode's historical repository and canonical path before creating code.
Implement the WCode service there. Implement or extract the Xcode service beside
Apple tooling. Do not move either product to simplify dependency paths.

### Phase 4: Compose Vaporize Through ServiceContext

Register services at host bootstrap, replace direct backend imports with
contracts, and reduce platform branches in the shared CLI. Preserve explicit
authority grammar and actionable refusal messages.

### Phase 5: Extract Adjacent Platform Capabilities

Move executable replacement/relaunch and Windows command execution behind their
own service boundaries. Remove compatibility conditionals only after focused
service tests replace them.

### Phase 6: Prove One Windows App

Build, run, and install one pilot app through WCode with separate receipts.
Repeat the exact sequence before changing Swift, the Windows SDK, backend,
packaging, or destination.

### Phase 7: Expand Deliberately

Add one platform variable or app at a time. WCode app testing receives a new
contract and Bead only after build, run, and install evidence is stable.

## Alternatives Considered

### Continue Adding `#if os(...)` to Vaporize

Rejected. It makes the facade own implementations and repeats routing policy in
every command.

### Hide Platform Branches in Vaporize Helper Types

Rejected. Moving code without moving ownership preserves the same architecture
failure.

### Treat WCode as a Script Flag

Rejected. A script path has no typed capabilities, readiness, descriptor,
support result, or receipt contract. WCode is an application lifecycle service,
not a callback.

### Route Everything Through CommonProcess

Rejected. CommonProcess executes commands; it does not own application
resources, packaging, install destinations, or app identity.

### Let SwiftPM Build and Install Apps

Rejected. Package.swift does not carry the complete application lifecycle.
`swift-win` remains intentionally smaller.

### Move Repositories to Shorter Paths

Rejected. Path movement breaks topology and history. Windows long-path support
and long-path-capable tooling are prerequisites.

### Create a New Vaporize or WCode Repository

Rejected. Historical identity is part of the product contract. The existing
homes must be found and advanced.

## Risks and Mitigations

| Risk | Cost | Mitigation |
| --- | --- | --- |
| Contract becomes a generic build system. | It absorbs signing, distribution, process, and project generation. | Enforce minimum API anatomy and operation-specific support tests. |
| WCode history is not located first. | A duplicate product is created again. | Make history/path discovery a Phase 3 entry gate. |
| Vaporize retains hidden fallback execution. | Receipts name one authority while another performs work. | Spy invocation counts and no-retry routing tests. |
| Schema migration is skipped. | Service and runner packages exchange similar but incompatible models. | Version or adapt v0.0.1/v0.0.3 explicitly. |
| Platform tests are conditionally omitted. | Shared policy appears green without being exercised. | Keep facade tests platform-neutral and adapters independently testable. |
| Pilot success is overclaimed. | One app is treated as Windows platform parity. | Separate contract, adapter, build, run, install, and fleet evidence. |
| Paths are changed during dependency repair. | Canonical topology and submodule pointers break. | Record exact paths and use long-path tooling; prohibit opportunistic moves. |

## Success Criteria

This design succeeds when a reviewer can trace a Vaporize command from explicit
authority and artifact intent to one ServiceContext requirement, one registered
service, one adapter operation, and one bounded receipt.

Shared Vaporize code must compile without implementing Windows or Apple app
lifecycle behavior. `swift-win` must reject apps with a useful WCode pointer.
WCode must own real Windows app build, run, and install proof. Xcode must remain
an independently injected Apple implementation. Missing services must fail
before side effects, and no migration may depend on moving canonical paths.

## Ownership and Review

The CPO owns product authority, command meaning, and later release decisions.
The CTO owns the service contract, implementation boundaries, dependency
topology, and machine-proof strategy. WCode and Xcode adapter maintainers own
their SDK behavior. Vaporize owns orchestration and receipts, not backend
implementation.

This document commissions implementation planning. It does not approve a
release, installation fleet, signing identity, or public Windows support claim.

## Open Decisions

1. Where is the historical canonical WCode source, and what package should vend
   `WCodeApplicationLifecycleService` without moving that source?
2. What is the first version and exact home of the application lifecycle schema
   family and service contract?
3. Does the Xcode adapter live in wrkstrm-core Apple tooling or an existing
   swift-universal Apple adapter package?
4. Is adapter selection represented by individual ServiceContext identifiers
   or a registered application-lifecycle service catalog?
5. Which receipt schema owns build, run, and install facts without granting
   signing or release authority?
6. How will CommonProcessService advance from schema v0.0.1 to the active v0.0.3
   vocabulary without breaking pinned consumers?
7. What independent service owns Windows CLI executable replacement and
   relaunch?
8. What evidence must exist before `test wcode --artifact app` is designed?

## Related Material

- <doc:command-ownership-map>
- <doc:command-and-artifact-architecture>
- <doc:modularity-and-ownership-boundaries>
- <doc:release-evidence-and-gates>
- `service-universal/.docc/index.md`
- `service-universal/private/universal/domain/process/spm/common-process-service/CommonProcessService.docc/MinimumAPIDesign.md`
- `service-universal/private/universal/domain/runtime/spm/common-service-context/CommonServiceContext.docc/index.md`
- `swift-universal/private/universal/spm/domain/system/common-process-foundation-runner`
- `swift-universal/private/universal/spm/domain/system/common-process-subprocess-runner`
