@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("CUJ State Testing Methodology")
  @Available(platform: macOS, introduced: "0.0.1")
}

# CUJ State Testing Methodology

Vaporize tests should increasingly be organized around CUJ state: the reusable
state implied by complete critical user journeys.

This is a testing architecture, not a fixture naming trick. A critical user
journey names an actor, an intent, the preconditions that make the journey
meaningful, the actions the actor takes, and the outcomes that decide whether
the product worked. CUJ state is the structured state derived from that journey.
It is the state a test needs in order to simulate the product world without
first choosing a database engine, a sync service, or an app-specific fixture
format.

The immediate CUJ-21 slice proves the first form of this architecture. It adds
`VaporizeCUJStateHarness`, `VaporizeCUJStateSpec`,
`VaporizeCUJStateDocument`, `VaporizeCUJStateRecord`, and
`VaporizeCUJStateReceipt` in `VaporizeTestSupport`. The harness writes
`cujs.json`, `cuj-state.json`, and `cuj-state.receipt.json`, then the focused
`VaporizeCUJ21CUJStateTests` bundle proves derivation, receipt independence
from database engines, and Codable round-tripping.

## Why This Exists

The old testing instinct was to begin with infrastructure. If a product will
eventually use Kura, Turso, libSQL, CloudKit, files, SQLite, or some other
state layer, it is tempting to design the test harness around that layer first.
That produces tests that are technically plausible but architecturally early.
They prove we can make a data container. They do not necessarily prove the user
world the product must serve.

CUJ state reverses the starting point. We begin with the user journey and derive
the minimum world state needed for spawn, modification, and release proof. The
storehouse family can still appear in the receipt as implementation context.
For this slice, `storehouseFamily: kura-org` is allowed metadata. But the
testing abstraction remains `stateFamily: cuj-state`.

That distinction matters because Vaporize is not trying to become a database
test runner. Vaporize is the proof lane that turns software intent into
reviewable world-state. When the intent is vaporware spawn or vaporware
modification, the durable question is: what user journey state are we trying to
make true?

## Architectural Layers

CUJ-state testing has five layers.

The first layer is the source CUJ. It is not a loose test title. It carries the
actor, intent, preconditions, actions, outcomes, tags, and metadata that define
the product world. If the journey is incomplete, the test should not compensate
by inventing hidden fixture assumptions.

The second layer is the normalized CUJ state document. Vaporize maps each CUJ
to a `VaporizeCUJStateRecord`. The record preserves the CUJ semantics, assigns
a stable state id, and writes those records into `cuj-state.json`. This file is
the portable simulated world for the focused test.

The third layer is the receipt. `VaporizeCUJStateReceipt` names the harness,
state family, optional storehouse family, state path, CUJ manifest path, record
count, source kind, metadata, and timestamp. The receipt is the review bridge.
It lets a workflow, board packet, launch review, or future release doctor point
to what was actually materialized.

The fourth layer is the focused Swift Testing bundle. CUJ-state tests live in a
targetable bundle, currently `VaporizeCUJ21CUJStateTests`. This lets engineers
run the proof through Vaporize without sweeping the whole package while they are
changing the harness.

The fifth layer is the typed workstream. CUJ-state testing is not an isolated
library detail. It is bound to `vaporware-cuj-state-workstream`, the steward
role, the component-home bead, and the board milestone packet. Those records
make the testing methodology durable as process, not just code.

## Test Flow

The flow is intentionally small:

1. Author or select complete CUJs for the product slice.
2. Build a `VaporizeCUJStateSpec` with a state slug, state title, CUJs, and
   metadata.
3. Prepare the state with `VaporizeCUJStateHarness`.
4. Read back the generated files and assert the state document and receipt.
5. Keep database-engine, network, and storehouse-specific claims out of the
   receipt unless the test is explicitly proving that integration layer.
6. Run the focused target through `vaporize.cli@wrkstrm-core.clia.sh test`.
7. Link the command receipt to the relevant workflow instance, bead, board
   packet, or release packet.

The current proof command is:

```sh
vaporize.cli@wrkstrm-core.clia.sh test \
  --package-path private/universal/substrate/collectives/wrkstrm-core/private/apple/spm/vaporize@wrkstrm-core.cli \
  --configuration debug \
  -- \
  --filter VaporizeCUJ21CUJStateTests
```

The point is not the command syntax by itself. The point is that Vaporize owns
the assistant-facing proof boundary. Swift and Xcode remain native engines
underneath, but the reviewable lane is Vaporize.

## What The CUJ-21 Tests Prove

The first CUJ-21 test proves derivation. Two CUJs for the SCM product suite are
converted into CUJ-state records. The test verifies that actor, intent,
outcomes, tags, metadata, and source CUJ slugs survive the transformation. This
guards against the most common fixture failure: a test that contains the shape
of the data but loses the semantics of the journey.

The second test proves abstraction hygiene. It prepares a minimal CUJ state
without a storehouse family and asserts that the receipt does not expose
`turso`, `libsql`, `databaseURL`, `database-engine`, or `kura-world`. This is
the architectural guardrail. If a future test needs a database or Kura adapter,
that test should say so explicitly in a different integration slice. The
CUJ-state harness itself should not teach engineers that infrastructure is the
primary abstraction.

The third test proves receipt portability. `VaporizeCUJStateReceipt` round-trips
through Codable so receipts can be persisted, linked, and read later by release
or workflow tooling.

## How This Supports Spawn And Modification

Spawn and modification share the same state problem.

For vaporware spawn, CUJ state describes the world the new product must create
or observe. A spawn request should be able to say: these CUJs imply this state,
and this new tool exists to make that state executable for users.

For vaporware modification, CUJ state describes the before and after world. A
modification request should be able to say: this CUJ state is current, this
delta is expected, and this focused proof shows the delta without changing the
wrong layer.

That shared state model is why the active workstream is not named as a database
harness. A database harness can be useful later. It is not the common unit. The
common unit is the state implied by user journeys.

## Kura And Database Boundaries

Kura-org remains relevant. It is the storehouse and data-engine family context
for work that needs storage, sync, or durable state services. CUJ-state testing
does not erase that ownership. It prevents Kura, Turso, libSQL, or any other
engine from becoming the default test abstraction before the journey state is
known.

Use these boundaries:

- Use `stateFamily: cuj-state` when the test proves journey-derived state.
- Use `storehouseFamily: kura-org` only when the state may later belong to Kura
  or when the test needs to name that implementation family as context.
- Use database engine fields only in an explicit adapter or integration test.
- Do not describe CUJ-state tests as database support, Turso support, or Kura
  world support in board or release materials.

This keeps board materials honest. A CUJ-state milestone means we can derive
and prove user-world state. It does not mean we have shipped a production
database adapter.

## Engineering Rules

CUJ-state tests should follow these rules:

- Start from complete CUJs, not from a storage technology.
- Preserve user semantics in generated state records.
- Write receipts as first-class review artifacts.
- Keep the focused test target runnable through Vaporize.
- Keep storehouse and database claims subordinate unless the test is explicitly
  proving that layer.
- Link the proof back to the typed workstream, bead, or release packet.
- Treat public-consumption claims as blocked until chief-office and board
  review approve the milestone.

These rules are intentionally stricter than ordinary fixture practice. The goal
is not merely to make tests pass. The goal is to make tests explain which part
of the product world became reviewable.

## Failure Modes

The main failure mode is infrastructure-first testing. A test that starts by
making a database URL or migration fixture can accidentally bypass the question
of what user-world state is needed. That may be a valid integration test, but it
is not a CUJ-state test.

The second failure mode is prose-only capture. A board packet or proposal can
say that CUJs drive simulation, but the architecture is not durable until a
test-support model, focused test target, receipt, and typed workflow record all
exist.

The third failure mode is stale naming. Superseded names such as database
harness, Turso-like harness, or Kura-world seed-state may remain in historical
beads. Active tests, docs, board packets, and receipts should use CUJ state.

The fourth failure mode is overclaiming release readiness. A passing CUJ-state
test proves the state-derivation slice. It does not prove production Kura
integration, network sync, database migration safety, or public availability.

## Release And Review Implications

Release review should treat CUJ-state tests as proof of a state-derivation
capability. The expected evidence is:

- the source CUJ or CUJs
- the generated `cujs.json`
- the generated `cuj-state.json`
- the generated `cuj-state.receipt.json`
- the Vaporize command receipt
- the workflow, bead, board packet, or release packet that consumes the proof

When those surfaces agree, the methodology is healthy. When any surface drifts,
the review should fail the slice or mark it blocked. The engineering document
is the narrative, but the receipt and tests are the proof.

## Future Work

The next useful step is typed receipt standardization. Today the CUJ-state
receipt is a Swift Codable shape in test support. A future Vaporize receipt
schema should make this portable outside the test bundle.

The second step is release-doctor awareness. Release doctor should eventually
know that CUJ-state architecture exists and should check that active docs,
board packets, receipts, and tests do not regress to database-first wording.

The third step is Kura adapter proof. Once a product slice truly needs Kura
storage or sync, a separate integration harness should consume CUJ state and
prove the Kura adapter boundary. That harness should not replace CUJ state. It
should depend on it.
