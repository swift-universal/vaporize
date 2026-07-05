@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Product And Policy")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Product And Policy

Vaporize exists because assistant-run engineering needs a stable product
boundary, not a pile of remembered shell snippets.

The product claim is narrow: when a build, test, install, toolchain, app,
project-generation, validation, or release-evidence run must become durable
world-state, Vaporize is the owned interface. It wraps lower-level engines with
typed options, receipts, release gates, and policy boundaries.

## What Vaporize Is

Vaporize is:

- A build/test/install/run gate for SwiftPM CLIs and Apple app bundles.
- A toolchain gate for Swift and Swift-DocC commands through environment-owned
  resolver choices.
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

- Use `vaporize toolchain -- swift ...` for Swift runs that need the owned
  toolchain route.
- Use `vaporize toolchain -- swift package generate-documentation ...` for
  Swift package API documentation when a package carries the Swift-DocC Plugin.
- Use `swift-docc-cli@swift-universal.clia.sh export ...` as the canonical
  Swift Universal product route for standalone `.docc` catalog export once that
  product is installed in the runtime environment.
- Use `swift-docc-preview-cli@swift-universal.clia.sh` and
  `swift-docc-validator-cli@swift-universal.clia.sh` for preview and validation
  product surfaces.
- Treat `vaporize toolchain -- docc convert ...` as the lower-level
  Swift-DocC compiler fallback so documentation builds still stay inside the
  Vaporize receipt boundary when the canonical product route is unavailable.
- Let Vaporize choose the Swift-DocC compiler resolver from the environment:
  Swift toolchain `docc` when present, Xcode DocC as macOS fallback, and direct
  `docc` lookup on non-macOS Swift toolchain hosts.
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
