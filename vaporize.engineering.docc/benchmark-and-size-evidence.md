@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Benchmark And Size Evidence")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Benchmark And Size Evidence

Vaporize's performance story is evidence-gated. The current release packet
contains local baseline measurements, but those measurements are not yet fleet
benchmark claims.

The engineering position is simple: strong claims require retained runtime
samples and artifact receipts.

## Current Claims

Current measured claims are limited:

- JSON validation is fast on the local launch-review packet baseline.
- `vaporize toolchain -- swift --version` adds small wrapper overhead compared
  to bare `swift --version` on this host.
- Focused CUJ-15 SwiftPM tests measured the same through bare Swift and
  Vaporize's toolchain route once warm.
- The full Vaporize test suite has passed through the Vaporize toolchain route
  with 97 executable tests.

The current product claim is not "Vaporize compiles faster than Swift." The
claim is that Vaporize makes the route stable, reviewable, policy-compliant,
and connected to receipts.

## Runtime Sample Series

Queryable benchmark evidence belongs in a Kura series, not in ad hoc timing
text. The release packet names the intended series:

```text
private/universal/substrate/collectives/wrkstrm/private/universal/kura-spaces/series/vaporize-runtime-samples/
```

Future Vaporize modes should be able to emit runtime samples that include:

- command identity
- toolchain identity
- package, project, workspace, target, scheme, and product identity
- wall-clock timing
- exit status
- build logs or references
- SwiftPM coverage artifacts
- `.xcresult` bundle references when present
- DerivedData and product paths
- product-cache hit or miss state
- build-size metrics

## Build Size

Build size is a first-class engineering metric. App-facing samples should track
at least:

- build output size
- product bundle size
- executable binary size
- coverage artifact size
- result bundle size
- shared cache delta
- per-feature-flag size deltas when feature flags exist

Development and release sizes should both be tracked. A debug-only growth spike
can still indicate future release risk, and release-only shrinkage can hide
developer-machine cost.

## Prohibited Claims

Until receipts exist, do not claim:

- fleet-wide build speed improvement
- fleet-wide disk-space savings
- universal cache-hit rates
- parity with every owned Apple project
- automatic workspace product-cache discovery
- replacement of Xcode or Swift

The right next engineering step is to make Vaporize emit runtime samples as a
first-class receipt path, then let the engineering site publish claims directly
from retained evidence.
