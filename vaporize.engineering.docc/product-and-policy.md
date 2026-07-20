@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Product And Policy")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Product And Policy

Vaporize exists because assistant-run engineering needs a stable product
boundary, not a pile of remembered shell snippets.

The product claim is narrow: when a build, test, install, toolchain selection, app,
project-generation, validation, or release-evidence run must become durable
world-state, Vaporize is the owned interface. It wraps lower-level engines with
typed options, receipts, release gates, and policy boundaries.

## What Vaporize Is

Vaporize is:

- A build/test/install/run gate for SwiftPM CLIs and Apple app bundles.
- A selection gate for the default Swift and, on macOS, the independently
  selected Xcode developer directory.
- A JSON validation gate for release packets and schema fixtures.
- A CommonProcess-style invocation gate through `use`.
- A project migration gate for `project.yml`, Pkl, generated YAML, and
  Pkl-backed `.xcodeproj` output.
- A release evidence gate that connects commands to PRD, CUJ, launch-review,
  provenance, benchmark, and schema surfaces.

Vaporize is not:

- A replacement for Swift.
- A replacement for Xcode's build system.
- A generic bypass for native tools.
- A public performance-claim surface before benchmark receipts exist.

## Policy Boundary

Assistants should prefer Vaporize for release-facing work because it keeps
native tool invocation inside a first-party command surface.

The current policy boundary is:

- Use `vaporize toolchain-selection swift -- use ...` only to report or change
  the default Swift selection.
- On macOS, use `vaporize toolchain-selection xcode -- select ...` only to
  report or change the Xcode developer-directory selection. This selection is
  independent from default Swift.
- Use `install`, `build`, `test`, or `run` for artifact-aware Swift execution.
  On macOS, choose its adjacent `swift` or `xcode` authority explicitly. On
  hosts without Xcode, omit the authority and the command collapses to Swift.
- Use `vaporize pass -- swift package generate-documentation ...` for generic
  Swift package API documentation invocation when a package carries the
  Swift-DocC Plugin.
- Use `docc.cli@swift-universal.clia.sh export ...` as the canonical
  Swift Universal product route for standalone `.docc` catalog export once that
  product is installed in the runtime environment.
- Use `docc-preview.cli@swift-universal.clia.sh` and
  `docc-validator.cli@swift-universal.clia.sh` for preview and validation
  product surfaces.
- Treat `vaporize pass -- docc convert ...` as the lower-level Swift-DocC
  compiler fallback when the canonical product route is unavailable.
- Do not add toolchain acquisition, lifecycle, inspection, or execution to
  `toolchain-selection`; those behaviors require their own operation owners.
- Use `vaporize validate-json --path <file>` for JSON validation in this lane.
- Use Vaporize's app/project/workspace options instead of direct `xcodebuild`
  choreography in release runbooks.
- Let Vaporize invoke Apple tooling internally when the mode owns that
  behavior.

The important engineering distinction is not that Vaporize is faster than Swift
or Xcode. The distinction is that Vaporize makes the route repeatable,
reviewable, policy-compliant, and connected to receipts.

## Why Users Choose It

An engineer or assistant chooses Vaporize when the work needs:

- A command that future agents can run without reinterpreting local context.
- A receipt for launch review, provenance, or benchmark analysis.
- Stable app install/uninstall/run behavior.
- Explicit toolchain selection.
- Explicit project/workspace/DerivedData inputs.
- Project-generation migration evidence.
- Feature-scoped tests tied to CUJs.

Direct Swift remains acceptable for a human one-off local experiment. Vaporize
is the internal route when the result must be part of the product's engineering
record.
