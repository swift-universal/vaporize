# Swiftly Light-Fork Implementation

@Metadata {
  @PageKind(article)
  @PageColor(orange)
  @TitleHeading("First governed light-fork fixture")
  @PageImage(purpose: icon, source: "swiftly-light-fork-implementation-icon", alt: "Swiftly light-fork implementation icon")
  @PageImage(purpose: card, source: "swiftly-light-fork-implementation-card", alt: "Swiftly light-fork implementation card")
  @Available(platform: macOS, introduced: "0.0.1")
}

Swiftly is the first fixture because its current candidate demonstrates useful,
bounded upstream modification without yet carrying a false completion claim.

@Image(source: "swiftly-light-fork-implementation-hero", alt: "A bounded Swiftly branch exposes hosted commands and remains connected to upstream")

## Current Candidate

The current checkout is based on
`d0795a223706ab274c0f361be38a5cef14c8d296`. Its tracked candidate changes
separate a `SwiftlyCommands` library from a thin executable, introduce an async
host entry point, and apply task-local hosted invocation context. The working
tree also contains untracked executable, test, and Bead evidence surfaces.

This design treats those facts as observations. It does not infer admission,
approval, or verification from their presence.

The recorded base is an observation, not a permanent anchor. Swiftly tracks
the newest eligible upstream channel continuously. Vaporize fetches that
channel and attempts the hosted-command patch series in a separate candidate
branch or worktree, preserving the current dirty candidate until the new rebase
is proven recoverable.

## First Package Record

The Swiftly record should declare:

- identity `swiftly`;
- canonical upstream `https://github.com/swiftlang/swiftly.git`;
- maintainer-relative checkout path;
- admitted upstream base;
- upstream tracking channel and freshness service level;
- `Manual.LightFork` update mechanism;
- Vaporize as the primary direct consumer;
- allowed library/executable split and hosted-context paths;
- prohibited Vaporize product policy, UI, receipts, and orchestration;
- patch budget and explicit exit condition;
- verification state `incomplete` until evidence exists.

The existing specimen JSON is an input to migration, not the final package
record schema. Migration must preserve its honest `working-tree-candidate` and
`proposed` status.

## Patch Materialization

The candidate becomes an operable light fork only after:

1. tracked and intentional untracked source changes are separated from
   generated Bead evidence;
2. an exact upstream base is fetchable;
3. the local series has a fork head or deterministic exported patches;
4. the package record hashes or references the patch material;
5. standalone and hosted verification receipts exist;
6. the parent gitlink references a published or otherwise recoverable fork
   revision.

Until then, Vaporize reports the candidate as incomplete and refuses an
advance or rebase operation.

## Verification Matrix

The initial fixture must prove:

- upstream standalone command parity;
- hosted parse, help, version, selection, proxy, and error behavior;
- task-local isolation under concurrent hosted invocations;
- Vaporize integration against the embedded library;
- macOS and supported non-macOS behavior;
- clean reapplication onto a selected upstream advance;
- freshness age and the delta from the newest eligible upstream revision;
- reconciliation of generated source-enforcement findings.

Each row records a command specification, environment, exit status, evidence
path, and source/fork revisions. A green aggregate without row-level evidence
does not admit the fork.

## Exit Test

The fork exits when upstream exposes an equivalent embeddable command boundary
or Vaporize no longer embeds Swiftly. It escalates to a first-party fork if the
patch owns toolchain semantics, stable product policy, or a public API that can
no longer plausibly converge upstream.
