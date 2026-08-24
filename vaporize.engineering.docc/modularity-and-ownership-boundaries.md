@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Modularity And Ownership Boundaries")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Modularity And Ownership Boundaries

Vaporize is allowed to grow only if its ownership boundaries stay clear.

The rule is simple:

- Capabilities that are genuinely Swift Universal belong in `swift-universal`.
- Capabilities that are Apple-bounded, Xcode-bounded, app-bounded, or
  release-orchestration-bounded belong in `wrkstrm-core`.
- Vaporize should compose with extracted primitives rather than copying them
  into its own command tree.
- Vaporize should add feature modules, receipts, and CUJ bundles as major
  feature families land; it should not concentrate feature logic in one CLI
  file.

## Ownership Classification

| Capability Kind | Canonical Home | Vaporize Rule |
| --- | --- | --- |
| Swift-only process, shell, package, data, or schema primitive with no Apple or wrkstrm release coupling | `swift-universal` | Depend on the package. Do not duplicate the primitive in Vaporize. |
| Xcode project, Xcode workspace, DerivedData, `.app` bundle, Apple build setting, scheme, target, or release-feature topology | `wrkstrm-core` | Keep the owning implementation in Vaporize or another wrkstrm-core Apple module. |
| wrkstrm release evidence, launch review, vaporware economics, Kura sample emission, or internal-essential tooling policy | `wrkstrm-core` | Keep the release policy and receipt boundary in Vaporize; extract only policy-neutral primitives. |
| Shared Apple implementation used by multiple wrkstrm-core tools | `wrkstrm-core` shared module | Extract inside wrkstrm-core before copying logic between tools. |
| General Swift implementation useful outside Apple and outside Vaporize | `swift-universal` package | Promote upstream, then depend on it from Vaporize. |

## Current Package Boundary

The current v0.0.1 shape is:

- `XcodeProjectDefinitionCore`: Apple project modeling, YAML/Pkl parity, Pkl-backed
  project generation, and target feature inspection. This is Apple/Xcode
  bounded and should remain in `wrkstrm-core`.
- `SwiftAppInstaller`: Apple app install/build/open/uninstall orchestration,
  Xcode project/workspace invocation, DerivedData lookup, and shared workspace
  product-cache behavior. This is Apple-bounded and should remain in
  `wrkstrm-core`.
- `SwiftCLIInstaller`: SwiftPM CLI install/uninstall argument construction.
  This is the main extraction candidate. It remains in Vaporize while it carries
  Vaporize install policy, but any policy-neutral SwiftPM installer primitive
  should move to `swift-universal`.
- `VaporizeCLI`: command parsing, dispatch, receipts, release boundaries, and
  feature-family orchestration. This target should stay thin. New feature
  bodies should not accumulate here when they can live in a feature module.
- `VaporInventory`: vaporware inventory scanning and rendering. This remains
  wrkstrm-core while it encodes Vaporize/vaporware release economics.
- `CommonProcess` and `CommonShell`: Swift Universal dependencies. Vaporize
  should use these packages rather than reimplementing process or shell
  primitives.

## Extraction Triggers

Move code out of Vaporize when any of these are true:

- The code is reusable Swift infrastructure with no Apple, Xcode, Vaporize,
  vaporware, or release-review dependency.
- The same primitive is needed by another package outside wrkstrm-core.
- A feature implementation starts as a helper inside `VaporizeCLI` but becomes a
  durable command family with its own receipts and tests.
- Two wrkstrm-core tools need the same Apple-bounded implementation.

Keep code in Vaporize or wrkstrm-core when any of these are true:

- The code knows about Xcode projects, workspaces, schemes, build settings,
  DerivedData, `.app` bundles, or Apple feature topology.
- The code is part of Vaporize's command, receipt, launch-review, or
  internal-essential-tool policy boundary.
- The code composes wrkstrm app minimums, build configs, release features, or
  Kura runtime samples into release evidence.

## Feature Growth Rule

Each new major Vaporize feature should land with:

- A feature-family home outside `main.swift` when implementation logic exceeds
  parser/dispatch glue.
- A feature flag, feature status record, or explicit exception per
  <doc:vaporware-modification-request-discipline>.
- A CUJ-specific test bundle or an extension to the existing feature's CUJ
  bundle.
- A receipt or evidence shape before release-ready status.
- A schema-universal fixture when the feature's evidence becomes durable
  release-review data.
- A release-gate update naming whether the feature is proven, blocked, or
  follow-up only.

## Current Consolidation Backlog

- Split `VaporizeCLI` command-family implementations out of `main.swift` so the
  executable target becomes a router plus small command adapters.
- Decide whether the policy-neutral part of `SwiftCLIInstaller` belongs in a
  Swift Universal package.
- Keep Apple project generation and target-feature inspection in
  `XcodeProjectDefinitionCore` until there is a stronger wrkstrm-core Apple project
  module boundary.
- Avoid adding new project-generation, workspace-cache, benchmark, or
  app-minimums feature bodies directly to the CLI router.
