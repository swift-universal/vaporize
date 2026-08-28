@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Canonical Pkl Definition Bundling")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Canonical Pkl Definition Bundling And Short Project References

The Pkl code-generation application must bundle the exact canonical project
definition that it evaluates and emits references to. A generated `project.pkl`
must not depend on the depth or continued existence of a source checkout.

This is a future-improvement contract. It records the desired ownership and
distribution boundary without authorizing immediate removal of existing
compatibility paths.

## Current Problem

The project model is split across three surfaces:

- The canonical Swift read model and generator live in wrkstrm-core's
  `xcode-project-definition` package.
- The canonical Pkl definition also lives in that package, but is not bundled
  as a production SwiftPM resource.
- Most current declarations still amend a separately authored Vaporize-local
  `XcodeProjectDefinition.pkl` or its `AppleProjectSpec.pkl` compatibility shim.

Generated declarations therefore contain repository-relative references such
as:

```pkl
amends "../../../../Pkl/XcodeProjectDefinition.pkl"
```

That line provides useful inheritance, but the path is an accidental topology
contract. Moving the project, installing the CLI without its source checkout,
or reorganizing the repository can make an otherwise valid declaration
unevaluable.

## Ownership Rule

The code-generation product owns one indivisible compatibility unit:

1. The canonical Pkl project definition.
2. The Swift type that receives evaluated Pkl.
3. The importer that emits project declarations.
4. The adapters that project the declaration into platform world-state.
5. The resource resolver that makes the bundled definition available at
   runtime.

Those parts must version, test, and ship together. An executable must never
emit a declaration against a schema newer or older than the Swift model it is
using.

Vaporize may consume this product, but it must not independently author another
full copy of the schema.

## Definition Layers

The canonical contract should distinguish universal project intent from
platform and generator details.

### Project fundamentals

The universal layer should define stable intent and conventions:

- product identity and display name
- application, library, command-line tool, and service product kinds
- source, test, and resource roots
- dependencies and product relationships
- configurations and variants
- signing and release identity intent
- installation and launch intent
- supported platform declarations
- shared naming and path conventions

### Platform adapters

Adapter-owned extensions should contain implementation-specific facts:

- Xcode schemes, build phases, SDK dependencies, and deployment targets
- macOS bundle generation and signing projection
- Windows executable naming, resource staging, installation, and signing
- platform-specific build settings and generator compatibility fields

Fields such as `minimumXcodeGenVersion` are migration compatibility, not
universal project fundamentals.

## Short Project References

Bundled fundamentals and convention-bearing adapter definitions should let a
project describe only what makes it different. The desired authoring shape is
closer to:

```pkl
amends "<stable bundled application definition>"

name = "vault-approval"

identity {
  displayName = "Vault Approval"
  bundleIdentifier = "com.kura.collective.vault-approval"
}

platforms {
  ["macos"] {}
  ["windows"] {}
}
```

The macOS adapter can project that intent into `Vault Approval.app` and an
Xcode project. The Windows adapter can project the same intent into
`Vault Approval.exe` and the WCode application layout. Project authors should
not repeat default source roots, standard configurations, scheme boilerplate,
or repository-relative schema paths.

Short declarations are not achieved by making fields untyped. They come from
typed defaults, conventions, reusable definition layers, and explicit
platform override points.

## Bundling Contract

The `xcode-project-definition` code-generation package should include the
canonical Pkl module as a production SwiftPM resource and expose it through a
small typed service. The service should provide:

- the bundled definition URL
- the definition's temporal release identity
- a content digest for receipts and compatibility checks
- a safe materialization operation when a declaration needs a colocated module
- a diagnostic that explains missing, mismatched, or unreadable resources

The application must resolve this service through `Bundle.module` or the
cross-platform equivalent selected by the package. Compile-time `#filePath`,
the process current directory, and guessed repository roots are not installed
runtime contracts.

## Portable Amendment Strategy

The final amendment form must survive moving a project between machines and
between macOS and Windows. Accepted implementation strategies include a
versioned Pkl package reference or a versioned schema materialized beside the
generated declaration. The selected strategy must preserve:

- deterministic resolution without network access during ordinary generation
- temporal compatibility between generator, Swift model, and Pkl definition
- readable declarations suitable for source control
- an explicit upgrade path
- receipt evidence identifying the exact definition used

An absolute path into an installed bundle is not a portable declaration. A
deep relative path back into a monorepo is not a portable declaration either.

## Migration Sequence

1. Package the canonical Pkl definition with the canonical code generator.
2. Add the typed definition-resource service and focused package tests.
3. Make import and upgrade commands use that service rather than `#filePath`
   discovery.
4. Introduce the portable amendment strategy and record definition identity in
   receipts.
5. Convert the Vaporize-local full schema into a compatibility forwarder.
6. Retarget tracked declarations incrementally and repair broken amendment
   edges.
7. Prove installed-CLI operation outside every source checkout on macOS and
   Windows.
8. Remove compatibility files only after an auditable zero-edge check.
9. Evolve universal fundamentals and platform adapters so concrete project
   declarations become convention-sized.

## Required Tests

The future product is incomplete until tests prove:

- the production executable bundle contains the expected Pkl definition
- the bundled definition and Swift read model accept the same modeled fields
- an installed executable can import, evaluate, and generate outside a checkout
- a generated declaration can be moved and evaluated without rewriting paths
- a definition/model mismatch fails with a clear diagnosis and next step
- macOS and Windows adapters consume the same universal declaration
- legacy amendment paths remain functional during their declared migration
  window
- the compatibility path is removed only after the edge count reaches zero

## Non-Goals

Bundling the definition does not make Xcode concepts universal. It does not
move `Package.swift` compilation ownership into Pkl, and it does not authorize
deleting current project declarations. The work establishes a portable,
version-coherent authoring boundary on which later Foundry project experiences
can build.
