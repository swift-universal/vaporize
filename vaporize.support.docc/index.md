# Vaporize Support

@Metadata {
  @TechnologyRoot
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Vaporize Support")
  @PageImage(purpose: icon, source: "index-icon", alt: "Four connected evidence stations: inspect, identify, bound, and escalate.")
  @PageImage(purpose: card, source: "index-card", alt: "An evidence path that moves from observation to a contained escalation packet.")
}

@Image(source: "index-hero", alt: "Four transparent stations in sequence: authority observation, artifact identity, bounded build observation, and support packet escalation.")

Vaporize support begins by identifying the exact artifact and authority in
play. A selected Xcode, a source-built candidate, an installed Vaporize
executable, a `swift` proxy, and a Board or Launch Review decision are
different states with different proofs.

This guide is for the operator who sees a failed build, a missing toolchain
provider, a long first build, or a `swift` command that does not behave as
expected. It favors small observations before any mutation.

## Start Here

- <doc:toolchain-triage>
- <doc:source-installed-parity>
- <doc:bounded-build-observation>
- <doc:support-packet>

## Operating Contract

Vaporize owns the assistant-facing materialization boundary for build, test,
install, and run operations. It does not make Xcode selection, Temper-owned
Swift selection, installed-runtime proof, release readiness, and human approval
the same claim.

On macOS, ownership remains explicit:

- `toolchain-selection xcode -- select <xcode-select-options>` owns the active
  Xcode developer-directory selection.
- `temper swift use <selector>` owns Swift toolchain selection and lifecycle.

Use the smallest provider that owns the state you need to inspect or change.
Do not silently replace the global `swift` path to solve an Xcode-selection
question.

## Support Boundaries

This catalog helps an operator observe and prepare evidence. It does not grant
authority to:

- install a candidate under a canonical executable name;
- select a global compiler without an explicit scope;
- claim a source artifact is installed runtime;
- claim Launch Review or Board approval.

Those actions need their own typed receipt and, where required, their own
review authority.

## Current Incident Pattern

When source behavior differs from the installed Vaporize artifact, compare the
two exact binaries and their receipts before promotion. Vaporize is no longer a
Swift proxy; a broken ordinary `swift` command belongs to Temper or the selected
toolchain boundary. <doc:source-installed-parity> shows how to prove source and
installed identity without replacing the installed tool during diagnosis.
