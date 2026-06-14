@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Target Feature Inspection")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Target Feature Inspection

`inspect-target-features` is the first Vaporize slice that checks whether a
target has the build-configuration and release-feature wiring expected by
wrkstrm app standards.

The command exists because app claims depend on project shape. If Vaporize is
going to build, install, benchmark, or release an app, it needs to know whether
the target already carries the minimum feature topology.

## What It Checks

For a selected `project.yml` target, the inspector reads:

- top-level build configurations
- target `configFiles`
- `Config/release-features.json`
- generated `Config/xcconfigs/*.xcconfig`
- generated `Sources/ReleaseFeatures.swift`
- `digikoma-release-features` provenance markers

It verifies that configured tiers have matching Swift active compilation
conditions and that generated files preserve the expected provenance.

## Example

```sh
vaporize inspect-target-features \
  --path private/universal/substrate/collectives/wrkstrm-components/private/hello-world-google/demo-apps/hello-world-google.demo/project.yml \
  --target hello-world-google.demo \
  --format json \
  --receipt-path release/v0.0.1/evidence/hello-world-google-target-features-inspection.receipt.json
```

The current Hello World Google receipt passes for Debug, Dogfood, TestFlight,
and Release tiers. It is target-level proof, not fleet proof.

## Boundary

This command does not yet discover every app in the fleet. Registry-backed app
minimums inspection remains follow-up work.

The future fleet shape should compose Vaporize with existing wrkstrm-core app
config sources:

- `tool-registry@wrkstrm-core.cli` for discovered app/project records
- `identifier@wrkstrm-core.cli` for app variant names and paths
- `app-artifacts@wrkstrm-core.cli` for bundle audits and build/export receipts

The target-level command is still valuable because it makes one target's
minimums inspectable and receiptable without waiting for the fleet registry
composition.
