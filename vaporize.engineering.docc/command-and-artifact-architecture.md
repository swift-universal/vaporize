@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Command And Artifact Architecture")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Command And Artifact Architecture

Vaporize turns software intent into an explicit command request, an artifact
operation, and optionally a receipt.

The architectural unit is not "run a command." The unit is a bounded
engineering operation with named inputs, predictable outputs, and evidence that
can be referenced later.

## CLI Application Lifecycle And Feature Selection

Vaporize is an application even though its interface is a CLI. Each invocation
has one bounded lifecycle:

```text
launch
  -> compose services
  -> activate policy
  -> select workflow
  -> execute
  -> emit receipt
  -> terminate
```

Experimental behavior is selected at the composition root before either
workflow executes. `CommonFeatureFlags` is the canonical flag service.
Vaporize's composition root must declare the feature in
`ReleaseFlagSnapshot.compiledFeatures`, construct
`OverridableFeatureFlagService`, and inject its `PolicyEvaluatorService` into a
workflow selector. The compiled and runtime default for the SwiftPM
library-product feature is OFF.

The selector hands one typed request to one of two sibling services:

- the existing legacy SwiftPM executable workflow, unchanged; or
- the new SwiftPM library-product build/test workflow.

Neither workflow reads ambient feature state. Policy selection happens once,
before execution. With the flag OFF—or with no new feature input—the complete
legacy plan remains the production plan: no depot lookup, no network probe, no
product-carrier selection, no resolution change, and no new receipt shape. The
new service does not extend or reinterpret the legacy artifact enum/path.

The current WarehouseKit `FeatureFlagIntegrationAudit` supplies four mechanical
integration gates: a `Package.swift` `CommonFeatureFlags` dependency, a
`PolicyEvaluatorService` injection point, a
`ReleaseFlagSnapshot.compiledFeatures` declaration, and an
`OverridableFeatureFlagService` instantiation. Those checks are necessary but
not sufficient; targetable flag-off equivalence, flag-on behavior, typed
receipts, and launch-review documentation remain separate validation gates.

## Feature Bead Graph Gate

This feature is represented by a Beads v0.0.3 parent feature and a dependency
graph whose readiness can be computed. Before implementation, the graph must
define at least:

- CUJ, PRD, and design references;
- legacy and experimental sibling workflow service references;
- `CommonFeatureFlags`, `ReleaseFlagModel`, flag default, and policy evaluator;
- Schema Universal request, result, and receipt dependencies;
- platform, runtime, toolchain, and carrier scope;
- acceptance and validation gates;
- rollout, rollback, mandatory flag removal, dead-branch cleanup, and closure
  validation; and
- child bead and child workstream references.

The existing
`FR-VAPORIZE-BUILD-TEST-LIBRARY-ONLY-PRODUCT-2026-07-08` bead is the observed
implementation-problem child, not a second feature. The already-defined
`feature-gated-cli-dependency-experiment` is the specialized execution workflow
for the Vaporize experiment; its stages must be reused rather than copied into
the feature graph.

The required lifecycle tail is not optional backlog:

```text
flagged implementation
  -> experiment plan and run
  -> analytics receipts
  -> human decision
  -> remove flag and dead branch
  -> closure validation
```

Analytics receipts are required evidence for the human decision. Whether the
candidate is promoted or rejected, the temporary flag and losing branch must be
removed. The parent feature cannot close until closure validation proves that
cleanup and the final unflagged behavior.

## Command Families

The current v0.0.1 command surface includes these families:

- `install`, `uninstall`, `build`, `test`, and `run` for CLI and app artifacts.
- `pass` and `use` for bounded command invocation.
- `toolchain-selection` for independent Swift and macOS Xcode selection state.
- `validate-json` for JSON validation through the Swift Universal json-formatter package.
- `status` and `warehouse` for vaporware inventory.
- `inspect-project-yml`, `compare-project-yml-pkl`, `import-project-yml`,
  `generate-project-yml`, and `generate-xcodeproj` for Apple project migration.
- `inspect-target-features` for target-level build-config and release-feature
  inspection.
- `inventory` and `graph` for package and graph-adjacent discovery.

Each family narrows a lower-level tool into a product-owned lane. That narrowing
is the engineering value: fewer ambient assumptions, more typed inputs, and
better receipts.

## Toolchain Selection

Vaporize toolchain selection is macOS Xcode state selection, not a generic
toolchain bridge:

```text
vaporize toolchain-selection xcode -- select <xcode-select-options>  # macOS only
```

Temper owns Swift toolchain selection and lifecycle. Vaporize uses the selected
`swift` on `PATH`. Its Xcode provider is omitted outside macOS and owns only the
`xcode-select` selection-state operations: print, switch, and reset.

Toolchain acquisition, lifecycle, general inspection, and execution do not
belong to this command. The complete reasoning and current ownership gaps are
recorded in <doc:command-ownership-map>.

## Swift And Documentation Execution

Normal Swift package operations use the independently selected default Swift
through their operation command:

```text
vaporize test swift --package-path <package> --configuration debug
```

For Swift package API documentation, the modern Swift-facing surface is the
Swift-DocC Plugin command. Until Vaporize has a documentation-specific mode,
generic invocation belongs to `pass`:

```text
vaporize pass -- swift package generate-documentation
```

For standalone `.docc` catalog export in our stack, the modern owned tool name
is the Swift Universal product:

```text
docc.cli@swift-universal.clia.sh export --bundle Product.docc --output /tmp/Product.doccarchive
```

Preview and validation use sibling Swift Universal products:

```text
docc-preview.cli@swift-universal.clia.sh serve --bundle Product.docc
docc-validator.cli@swift-universal.clia.sh workspace /workspace
```

The lower-level Swift-DocC Documentation Compiler executable remains a fallback
compiler boundary, not a toolchain-selection behavior:

```text
vaporize pass -- docc convert Product.docc --output-path /tmp/Product.doccarchive
```

Xcode-selected Swift package execution is an adjacent authority on macOS and
does not change the default Swift selection:

```text
vaporize test xcode --package-path <package>
```

The sibling is `vaporize test swift`. On hosts without Xcode, the public
command collapses to `vaporize test --package-path <package>`.

The owning execution command records its own operation and resolver boundary.
`toolchain-selection` receipts instead record the provider, selection
operation, arguments, embedded or system resolver, and executable reference.

For the canonical feature-by-feature explanation, see <doc:feature-catalog>.
This page explains the architecture; the feature catalog names the user problem,
current surface, and proof boundary for each major Vaporize feature.

## Artifact Flow

For SwiftPM CLI products, Vaporize builds the product and installs executable
artifacts into the expected command location.

For Apple app products, Vaporize accepts explicit app/build inputs:

- package or app root
- product name
- optional app bundle name
- configuration
- destination directory
- Xcode project or workspace
- scheme
- DerivedData path
- Xcode destination
- build settings

This makes app installation reviewable. The command explains what it means to
build, where outputs are expected, and where the installed artifact should land.

## Shared Workspace Product Cache

The shared product-cache slice is designed for large Apple workspaces where
many app projects should reuse one maintained DerivedData product cache.

When product-cache options are provided, Vaporize first searches the shared
DerivedData product path:

```text
Build/Products/<Configuration>/<product>.app
```

If the app already exists, Vaporize installs it from the warm shared cache. If
the product is cold, Vaporize builds through the shared workspace and shared
DerivedData path so future projects can reuse the same product cache.

The current proof covers cache-first lookup and shared workspace invocation. It
does not yet prove fleet-level disk savings or automatic workspace
scheme/product discovery.

## Planned Package-Supply Boundary

Vaporize's next package-supply lane treats a build as more than a command plus
an output path. It binds a logical temporal dependency request to a contextual
SwiftPM resolution and then selects maintained source or an admitted provisioned
product.

Git remains the temporal catalog and admission ledger. An optional artifact
depot carries large payload bytes behind the admitted Git record. SwiftPM
remains the resolver and compiler. Vaporize supplies policy and context,
captures `Package.resolved`, verifies provisioned payloads, and emits the state
machine and build-intelligence receipts.

This lane is requirements-defined and implementation-pending. Its full PRD,
CUJs, visibility rules, freshness policies, privacy boundary, schema inventory,
and X-of-Y coverage model are in
<doc:package-supply-and-build-intelligence>.

## Receipts

Receipts are the bridge between command execution and release review. They let
engineering documents point at evidence instead of asking a reviewer to trust
chat memory.

The receipt boundary should record:

- what was requested
- which paths and products were involved
- which lower-level tool behavior was used
- whether the operation passed or failed
- what output artifacts or evidence files were produced

Every new major Vaporize feature should decide its receipt shape before the
feature is treated as release-ready.
