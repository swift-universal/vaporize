# Bounded Build Observation

@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Bounded Build Observation")
  @PageImage(purpose: icon, source: "bounded-build-observation-icon", alt: "A bounded timeline with measured observation markers.")
  @PageImage(purpose: card, source: "bounded-build-observation-card", alt: "A build timeline distinguishes advancing work from a stable no-progress interval.")
}

@Image(source: "bounded-build-observation-hero", alt: "A transparent time axis carries four sampled observations, differentiating active compiler work from a bounded no-progress interval.")

An initial Release build can compile large dependencies such as SwiftSyntax.
Silence alone is not a failure signal. Observe a build before deciding whether
to keep waiting, stop it, or escalate it.

## What to Observe

Record:

- the Vaporize operation, authority, package path, configuration, and product;
- the selected Xcode path and Swift version;
- elapsed time;
- active compiler child process and CPU state;
- newest materialization output timestamp;
- terminal outcome and exit code.

Use short observations spaced far enough apart to show change. An active
`swift-frontend` process consuming CPU or producing newer outputs means the
build is advancing, even if the parent process is waiting silently.

## Bounded Stop Conditions

Stop and preserve evidence when all of the following hold across repeated
observations:

1. No compiler child is using meaningful CPU.
2. No build output or dependency state has changed.
3. No dependency fetch, prompt, or reported diagnostic explains the wait.

Do not terminate a build merely because the first dependency compile is slow.
Conversely, do not wait indefinitely after a stable no-progress interval.

## Distinguish the Outcomes

| Outcome | Evidence | Interpretation |
| --- | --- | --- |
| Candidate binary appears and responds | artifact digest plus command output | Source materialization succeeded. |
| Compiler reports a diagnostic | compiler output and nonzero exit | Source/dependency compatibility failure. |
| Active compiler continues consuming CPU | repeated process samples | Build is in progress. |
| No process/output progress across the bound | repeated samples and timestamps | Stalled or blocked build; prepare escalation. |

No one of these proves that an installed Vaporize artifact changed. After a
successful candidate build, return to <doc:source-installed-parity>.
