@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Feature Catalog")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Feature Catalog

This page is the canonical human-readable feature list for Vaporize.

The PRD defines why a feature should exist. CUJs define how users must be able
to exercise it. Tests and release evidence prove the claim. This catalog names
the feature, explains the user problem it addresses, and points reviewers at
the command or documentation surface that currently carries it.

## Implemented v0.0.1 Feature Slices

| Feature | User Problem | Current Surface | Proof / Boundary |
| --- | --- | --- | --- |
| Canonical command identity and release policy | Assistants need one build/install/release gate instead of ad hoc tool choreography. | `vaporize@wrkstrm-core.cli`, `product-definition.md`, `release-gates.md` | Internal-essential release prep only; final v0.0.1 remains blocked on fleet Pkl-backed Xcode world-state parity. |
| SwiftPM CLI lifecycle | Assistants need to build, install, uninstall, test, and run SwiftPM CLI products through a repeatable lane. | `install`, `uninstall`, `build`, `test`, `run --artifact cli` | CUJ-01 and installer tests cover argument construction and lifecycle behavior. |
| SwiftPM CLI resource-bundle installs | Resource-bearing CLI products need `Bundle.module` resources to survive installation into `~/.swiftpm/bin`. | `install` plus SwiftPM `--show-bin-path` bundle carry | CUJ-22 proves a typed simulation proving ground with processed, copied, decoded JSON, byte-count, stale-reinstall, checked-in resource-vault, and legacy product-gate scenarios; see <doc:swiftpm-cli-resource-bundle-installs>. |
| Vaporware product proving grounds | Release reviewers need to know which evidence tracks a product has actually driven before trusting a launch packet. | Typed proving-ground passports and `product-proving-grounds.md` | CUJ-23 proves a Vaporize CLI passport, a Pkl project-generation proving-ground passport, incomplete-passport failure, reusable product-class track defaults, and release-doctor coverage; see <doc:product-proving-grounds>. |
| Apple app lifecycle | Assistants need app build/install/open/uninstall operations to be explicit about product, scheme, destination, DerivedData, and build settings. | `install`, `uninstall`, `run --artifact app` with Xcode project/workspace options | CUJ-02 covers app installer paths and Xcode invocation construction; fleet build parity remains a release blocker. |
| Swift pass-through | Assistants sometimes need a bounded direct tool invocation without losing the Vaporize audit boundary. | `pass -- <tool> <args>` | CUJ-03 covers pass-through request normalization and execution behavior. |
| CommonProcess invocation | Assistants need a common-process style invocation surface with durable receipts. | `use --common-process-spec <spec.json> --receipt-path <receipt.json>` | CUJ-04 proves spec decoding, disk loading, invalid executable rejection, and receipt emission. |
| Xcode-selected Swift toolchain bridge | Assistants need Swift and DocC execution to follow the owned toolchain route without calling native discovery tools directly. | `toolchain -- swift ...`, `toolchain -- docc convert ...`, `--toolchain-bin-path <bin>` | CUJ-05 covers Swift routing, DocC conversion routing, macOS `xcrun` resolution, non-macOS direct tool lookup, explicit toolchain-bin path routing, and receipt metadata. |
| JSON validation | Release packets and schema fixtures need a Vaporize-owned validation route. | `validate-json --path <packet.json>` | CUJ-06 covers valid and invalid JSON; release gates require evidence JSON validation through Vaporize. |
| Vaporware inventory | Vaporware records need a reviewable inventory path and legacy compatibility boundaries. | `status`, `warehouse`, `inventory` | CUJ-07 covers scanner status classification, malformed JSON, missing paths, legacy read-only key handling, and text/JSON rendering. |
| Package graph forwarding | Assistants need package graph discovery behind the Vaporize boundary. | `graph` | CUJ-12 covers the forwarding slice; deeper graph policy remains outside this release slice. |
| Legacy project YAML inspection | Pkl migration needs safe read-only intake of existing XcodeGen `project.yml` files. | `inspect-project-yml` | CUJ-08 plus fleet parse audit prove 155/155 discovered project.yml files parse; this is not generation proof. |
| YAML/Pkl parity comparison | Migration needs to prove a Pkl specimen matches legacy YAML before replacing old generation. | `compare-project-yml-pkl` | CUJ-10 and Concourse receipts prove zero-mismatch specimen comparison. |
| YAML-to-Pkl import | Migration needs a mechanical bridge from legacy YAML into owned Pkl specimens. | `import-project-yml` | CUJ-13 and Creative Selection v0.2 receipts prove import/parity for one app specimen. |
| Pkl-to-YAML transitional generation | Migration needs a transitional way to emit YAML from Pkl while project-generation parity is still landing. | `generate-project-yml` | CUJ-11 proves transitional YAML generation; this is intentionally not `.xcodeproj` world-state proof. |
| Pkl-backed `.xcodeproj` generation | Vaporize needs to own Apple project world-state generation instead of depending on XcodeGen for owned surfaces. | `generate-xcodeproj` | CUJ-14 and Creative Selection v0.2 prove first-slice generation plus framework/app/unit-test graphs, target dependencies, local package products, and shared schemes; fleet build parity and remaining XcodeGen quarantine remain blocked. |
| Project target discovery | Assistants need target, package, scheme, and buildable-candidate facts before choosing build, cache, parity, or migration routes. | `list-targets` | CUJ-18 and the Creative Selection v0.2 target-discovery receipt prove AppleProjectSpec target discovery; build/install/generation and automatic workspace cache discovery remain separate. |
| Shared Xcode workspace product cache | Large workspaces need app installs to reuse one maintained product cache instead of rebuilding per app. | `--xcode-product-cache-workspace`, `--xcode-product-cache-derived-data-path` | CUJ-15 proves paired option validation, cache-first lookup, and shared workspace invocation; automatic workspace product/scheme discovery remains follow-up. |
| Workspace product-cache discovery | Assistants need to know whether a buildable target already has an expected `.app` product in the maintained workspace DerivedData before attempting install/build routing. | `list-targets --xcode-product-cache-workspace --xcode-product-cache-derived-data-path` | CUJ-19 proves candidate-path and warm/missing discovery from AppleProjectSpec target facts; `.xcworkspace` graph membership, cache warming, fleet coverage, and disk-savings measurement remain follow-up. |
| Xcode workspace scheme listing | Assistants need the maintained workspace's live scheme names before routing shared-cache or workspace-build work. | `list-schemes --xcode-workspace <workspace.xcworkspace>` | CUJ-20 proves the Vaporize/CommonProcess `xcodebuild -list -json -workspace` request, parser, input validation, and receipt boundary; large-workspace runtime, product paths, cache warming, and fleet coverage remain follow-up. |
| CUJ-state coverage | Release reviewers need proof that every journey-derived simulated-world state record is covered before trusting CUJ-state tests. | `cuj-state-coverage.json`, `VaporizeCUJStateCoverageGate` | CUJ-21 proves pass/fail coverage manifests, missing-state failure, unknown-state failure, and release-doctor enforcement; Kura/database adapter readiness remains separate. |
| Target feature inspection | App teams need Vaporize to know whether a target has the required release-feature topology. | `inspect-target-features` | CUJ-16 and Hello World Google receipts prove target-level inspection; registry-backed fleet inspection remains follow-up. |
| Runtime samples and benchmark evidence | Engineering and marketing need measured runtime, coverage, build-size, and cache evidence before strong claims. | Kura `vaporize-runtime-samples` series and benchmark/size docs | Series and a backfilled CUJ-09 sample exist; automatic Vaporize sample emission and durable Apple artifact retention remain follow-ups. |
| Feature-scoped test lifecycle | A major tool needs tests grouped by user journey so each feature can be targeted during development and release review. | CUJ-specific SwiftPM test bundles and `feature-test-lifecycle.md` | CUJ-09 enforces the coverage contract; v0.0.1 has 23 implemented CUJ bundles. |
| Pre-code PRD review | Major Vaporize coding slices need Engineering, QA, and Marketing to shape implementation before code starts. | `prd-review-session.md`, `pre-code-prd-review.md` | GATE-31 is codified; v0.0.1 is backfilled as `GO-WITH-NOTES` because work was already in flight. |
| Release doctor | Release packets drift when docs, CUJs, tests, gates, launch review, provenance, and schema fixtures are updated separately. | `release-doctor --path <package-or-release-root>` | CUJ-17 covers CLI parsing, live-spine pass, release-root resolution, missing-gate failure, unresolved-root rejection, unreviewed gate approval failure, follow-up list drift failure, and blocker-disposition drift checks; GATE-33 requires the release-doctor receipt and now enforces CUJ-state coverage plus launch-review/PRD/release-gate follow-up list coherence and launch-review blocker disposition. |
| Engineering DocC publication surface | Reviewers and future operators need durable engineering explanation that can publish to `wrkstrm.com/engineering`. | `vaporize.engineering.docc/` | GATE-30 covers this catalog; release evidence remains the proof corpus. |

## Release Blockers And Follow-Up Features

These features are named, but they are not final v0.0.1 proof claims yet:

- Fleet Pkl-backed `.xcodeproj` world-state generation and build parity.
- Scheme, resource, and local package parity for Pkl project generation.
- Explicit quarantine or migration of remaining substrate-owned XcodeGen
  surfaces.
- Automatic shared workspace product discovery and large-workspace scheme-list
  runtime sampling.
- Vaporize-emitted Kura runtime samples with retained SwiftPM and Apple native
  artifacts.
- Vaporware buddy heartbeat and health samples for runtime/build posture.
- Periodic build-watch checks that know which vaporware buddies should build,
  report failures, and route fixes through modification requests.
- Per-feature-flag build-size cohorts for release and development builds.
- Registry-backed wrkstrm app-minimums inspection across the app fleet.
- `vaporware scaffold feature-request` and sibling scaffold kinds for upstream
  product packets; this belongs to the vaporware scaffold lane, not the
  release-doctor command.
- Public `wrkstrm.com/engineering` projection of the DocC catalog.

## Review Rule

When a new Vaporize feature is proposed, it should appear here only after it has
all of these anchors:

- A product reason in `product-definition.md` or the PRD.
- A user-facing journey in `cuj.md`.
- A command, artifact, or documentation surface.
- A proof boundary in tests, receipts, release gates, or schema fixtures.
- A correct ownership home per <doc:modularity-and-ownership-boundaries>.
- A feature flag, feature status record, or explicit exception per
  <doc:vaporware-modification-request-discipline>.
