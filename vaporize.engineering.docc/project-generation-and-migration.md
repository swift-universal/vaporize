@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Project Generation And Migration")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Project Generation And Migration

Vaporize is moving owned Apple project surfaces from legacy `project.yml`
generation toward a Pkl-backed source of truth and generated Xcode world-state.

The migration is intentionally piecemeal. Each step has a command, a receipt,
and a test bundle so release review can distinguish first-slice proof from full
fleet parity.

## Migration Stages

The current stages are:

1. Read legacy `project.yml` into Swift models.
2. Compare legacy YAML and Pkl parity.
3. Import legacy YAML into Pkl.
4. Generate transitional YAML from Pkl.
5. Generate first-slice `.xcodeproj` world-state from Pkl.
6. Discover target, package, scheme, and buildable-candidate facts from
   AppleProjectSpec.
7. Discover expected shared workspace DerivedData product-cache candidates from
   buildable target facts.
8. Prove build parity across owned Apple surfaces.
9. Quarantine or retire remaining XcodeGen surfaces.

Stages 1 through 7 have first-slice evidence. Stage 8 and the final disposition
of remaining XcodeGen surfaces are still release blockers.

## Why Pkl

Pkl gives Vaporize a typed configuration language for Apple project shape. The
goal is not just to replace one file format with another. The goal is for
wrkstrm-core to own the project model, the renderer, the comparison receipts,
and the generated world-state.

That ownership matters because future features should be added to the model
instead of inherited from a general-purpose generator by accident.

## Release Identity

XcodeGen let owned projects express release identity as untyped target build
settings such as `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`,
`PRODUCT_BUNDLE_IDENTIFIER`, and `GENERATE_INFOPLIST_FILE`. Vaporize's Pkl
replacement makes that a typed target concern instead.

Targets can declare `releaseIdentity` with:

- `bundleIdentifier`
- `shortVersion`
- `buildVersion`
- `buildSha`
- `buildDate`
- `generateInfoPlist`
- `sparkleFeedURL`
- `sparklePublicEDKey`

During `.xcodeproj` generation, Vaporize projects those fields into Xcode build
settings. That gives app and tool targets the same Xcode-facing behavior while
keeping the source of truth in the Pkl model.

This matters for Sparkle because appcast generation and update comparison depend
on the same two typed values Xcode writes into bundle metadata:

- `shortVersion` maps to `MARKETING_VERSION` and Sparkle's
  `sparkle:shortVersionString`.
- `buildVersion` maps to `CURRENT_PROJECT_VERSION` and Sparkle's
  `sparkle:version`.

For generated Info.plist targets, Vaporize also maps Sparkle feed/signing values
through `INFOPLIST_KEY_SUFeedURL` and `INFOPLIST_KEY_SUPublicEDKey`.

## Receipt Chain

The migration chain is proven through receipts under
`release/v0.0.1/evidence/`.

Important specimens include:

- `concourse-project-yml-inspection.receipt.json`
- `project-yml-fleet-parse-audit.receipt.json`
- `concourse-project-yml-pkl-comparison.receipt.json`
- `concourse-pkl-project-yml-generation.receipt.json`
- `creative-selection-v0.2-project-yml-pkl-import.receipt.json`
- `creative-selection-v0.2-project-yml-pkl-comparison.receipt.json`
- `creative-selection-v0.2-pkl-xcodeproj-generation.receipt.json`
- `creative-selection-v0.2-list-targets.receipt.json`
- `creative-selection-v0.2-workspace-cache-discovery.receipt.json`

These receipts prove slices. They do not by themselves prove fleet build parity.

## Release Blocker

Final internal v0.0.1 approval still needs fleet build parity for
substrate-owned Apple project generation. The release question is not whether
Vaporize can generate one project. It can. The release question is whether the
owned project model covers enough scheme, resource, package, configuration, and
build behavior to replace or quarantine the old generator surfaces honestly.
