# vaporize@wrkstrm-core.cli

Vaporize is the wrkstrm-core build/test/install/uninstall/open/run gate for Swift
artifacts and Apple app bundles. Agents should use this CLI when they need to
build, test, install, reinstall, uninstall, open, or run SwiftPM-built CLIs, app
bundles, Xcode projects, or Xcode workspaces.

The name is doctrine: Vaporize builds. Warehouse stores. Vaporware is the main
unit of economics. Agents call Vaporize instead of improvising local shell
choreography, and use warehouse mode to store or emit vaporware inventory
receipts.

Durable engineering documentation lives in
`vaporize.engineering.docc/`, with
`vaporize.engineering.docc/feature-catalog.md` as the canonical human-readable
feature list and explanation surface. The catalog also carries the modularity
and ownership rule: genuinely Swift Universal primitives belong in
`swift-universal`; Apple-bounded orchestration belongs in `wrkstrm-core`. Treat
that catalog as the human engineering narrative for future
`wrkstrm.com/engineering` publication, and treat `release/v0.0.1/evidence/` as
the linked proof corpus.

Vaporize is intentionally not a swift-universal tool. The Xcode project/workspace
surface is Apple product infrastructure, and the restricted native-tool route is
owned by wrkstrm-core.

The package path, executable product, and command surface are all
`vaporize@wrkstrm-core.cli` per operator OD-N 2026-06-11. The legacy
`vaporize@wrkstrm-core.cli` package directory, compatibility executable, and
`craze.cli.tool.json` manifest have been retired with no compatibility
breadcrumbs (axiom: `no-compatibility-breadcrumbs-after-false-home-rehome`).
The legacy `x-craze-collapse-path` annotation key remains supported by the
scanner as a read-only fallback so historical vaporware records still
classify; the canonical write key is `x-vaporize-collapse-path`.

## Requirements

- macOS 26.0+
- Swift 6.4+

## Canonical installed command

```bash
vaporize install --artifact cli --package-path <package> --product <product> --configuration release --force
vaporize uninstall --artifact cli --package-path <package> --product <product>
vaporize build --artifact cli --package-path <package> --product <product> --configuration release
vaporize test --package-path <package> --configuration debug -- --filter <test-filter>
vaporize run --artifact cli --package-path <package> --product <product> --configuration release -- <arguments>
vaporize run --artifact app --package-path <package> --product <app-product> --configuration release --force
vaporize pass -- swift --version
vaporize use --common-process-spec <spec.json> --receipt-path <receipt.json>
vaporize toolchain -- swift test
vaporize validate-json --path <packet.json>
vaporize inspect-project-yml --path <project.yml> --format json --receipt-path <receipt.json>
vaporize inspect-target-features --path <project.yml> --target <target> --format json --receipt-path <receipt.json>
vaporize compare-project-yml-pkl --path <project.yml> --pkl-path <project.pkl> --receipt-path <receipt.json>
vaporize import-project-yml --path <project.yml> --output-path <project.pkl> --receipt-path <receipt.json>
vaporize generate-project-yml --pkl-path <project.pkl> --output-path <generated.yml> --receipt-path <receipt.json>
vaporize generate-xcodeproj --pkl-path <project.pkl> --output-path <generated.xcodeproj> --receipt-path <receipt.json>
vaporize setup --xcode-component MetalToolchain
vaporize status --path <records> --format text
vaporize warehouse --path <records> --receipt-path <receipt.json>
```

## CLI install and uninstall

```bash
vaporize install \
  --artifact cli \
  --package-path private/universal/substrate/collectives/clia-org/private/universal/domain/tooling/spm/clia-agent \
  --product clia \
  --configuration release
```

Force a reinstall (uninstall then install):

```bash
vaporize install \
  --artifact cli \
  --package-path private/universal/substrate/collectives/clia-org/private/universal/domain/tooling/spm/clia-agent \
  --product clia \
  --configuration release \
  --force
```

Uninstall a CLI product:

```bash
vaporize uninstall \
  --artifact cli \
  --package-path private/universal/substrate/collectives/clia-org/private/universal/domain/tooling/spm/clia-agent \
  --product clia
```

## App install and open

SwiftPM package:

```bash
vaporize install \
  --artifact app \
  --package-path private/universal/substrate/collectives/clia-org/private/universal/domain/tooling/spm/clia \
  --product clia-mac \
  --configuration release \
  --destination /Applications \
  --force \
  --launch
```

Xcode project (no Package.swift):

```bash
vaporize install \
  --artifact app \
  --package-path private/universal/substrate/collectives/clia-org/private/apple/apps/clia \
  --product clia-mac \
  --configuration release \
  --destination /Applications \
  --xcode-project private/universal/substrate/collectives/clia-org/private/apple/apps/clia/clia.xcodeproj \
  --scheme clia-mac-app \
  --derived-data-path private/universal/substrate/collectives/clia-org/private/apple/apps/clia/.build/xcode-derived \
  --xcode-destination 'platform=macOS,arch=arm64' \
  --xcode-build-setting CODE_SIGNING_ALLOWED=NO \
  --force \
  --launch
```

Xcode workspace (no Package.swift):

```bash
vaporize install \
  --artifact app \
  --package-path /path/to/workspace/root \
  --product MyApp \
  --configuration release \
  --destination /Applications \
  --xcode-workspace /path/to/Workspace.xcworkspace \
  --scheme MyApp \
  --derived-data-path /path/to/.build/xcode-derived \
  --xcode-destination 'platform=macOS,arch=arm64' \
  --force \
  --launch
```

Warm shared Xcode workspace cache:

```bash
vaporize install \
  --artifact app \
  --package-path /path/to/app/root \
  --product MyApp \
  --configuration debug \
  --destination /Applications \
  --xcode-project /path/to/app/MyApp.xcodeproj \
  --scheme MyApp \
  --derived-data-path /path/to/app/.derived-data \
  --xcode-product-cache-workspace /path/to/Huge/Huge.xcworkspace \
  --xcode-product-cache-derived-data-path /path/to/Huge/.derived-data \
  --xcode-destination 'platform=macOS,arch=arm64' \
  --force
```

When both product-cache options are present, Vaporize first looks for
`Build/Products/<Configuration>/<product>.app` under the shared DerivedData
path. If the product is not already warm, the app build uses the shared
workspace and shared DerivedData path so all workspace projects resolve products
from the same cache.

When the built `.app` bundle name differs from the install product name, keep
the install product stable and locate the built artifact with `--app-bundle-name`:

```bash
vaporize install \
  --artifact app \
  --package-path private/universal/substrate/collectives/wrkstrm-core/private/apple/apps/creative-selection \
  --product creative-selection \
  --app-bundle-name creative-selection.debug \
  --configuration debug \
  --destination /Applications \
  --xcode-project private/universal/substrate/collectives/wrkstrm-core/private/apple/apps/creative-selection/creative-selection.xcodeproj \
  --scheme creative-selection \
  --derived-data-path private/universal/substrate/collectives/wrkstrm-core/private/apple/apps/creative-selection/.derived-data \
  --xcode-destination 'platform=macOS,arch=arm64' \
  --xcode-build-setting CODE_SIGNING_ALLOWED=NO \
  --xcode-build-setting SKIP_APPLICATION_DEPLOY=YES \
  --force
```

Run an app product. This installs by default and opens the installed app:

```bash
vaporize run \
  --artifact app \
  --package-path /path/to/workspace/root \
  --product MyApp \
  --configuration release \
  --force
```

Uninstall an app from the destination directory:

```bash
vaporize uninstall \
  --artifact app \
  --package-path /path/to/workspace/root \
  --product MyApp \
  --destination /Applications
```

## Build and run CLIs

Build a SwiftPM product through Vaporize. Build mode installs by default unless
`--skip-install` is provided.

```bash
vaporize build \
  --artifact cli \
  --package-path private/universal/substrate/collectives/swift-universal/private/universal/domain/build/spm/common-shell \
  --product common-shell-cli \
  --configuration release
```

Run a SwiftPM executable product through Vaporize. Run mode installs by default,
then executes the installed product from `~/.swiftpm/bin/<product>`.

```bash
vaporize run \
  --artifact cli \
  --package-path private/universal/substrate/collectives/swift-universal/private/universal/domain/build/spm/common-shell \
  --product common-shell-cli \
  --configuration release \
  -- --help
```

## Swift pass-through

Pass-through mode is the no-fuss lane for Swift commands that do not need an
install/open wrapper. It runs through CommonProcess and preserves normal stdout,
stderr, and exit-code behavior.

```bash
vaporize pass -- swift package describe \
  --package-path private/universal/substrate/collectives/wrkstrm-core/private/apple/spm/vaporize@wrkstrm-core.cli
```

Use `--analyze` or `--receipt-path` when a run should emit a structured receipt
for later analysis:

```bash
vaporize pass \
  --analyze \
  --receipt-path /tmp/vaporize-swift-version.receipt.json \
  -- swift --version
```

Receipt fields include the tool, executable, arguments, working directory,
CommonProcess request id, runner kind, exit code or signal, process identifier,
and stdout/stderr byte counts.

## CommonProcess use

Use mode is the typed invocation lane for a caller-supplied CommonProcess
`CommandSpec` JSON file:

```bash
vaporize use \
  --common-process-spec /tmp/command-spec.json \
  --receipt-path /tmp/vaporize-use.receipt.json
```

The spec is decoded before execution, invalid executable refs are rejected, and
receipts record the process result without serializing environment values.

## Toolchain and JSON validation

Toolchain mode is the owned route for Xcode-selected Swift. Assistants should
use it instead of calling `xcrun` directly:

```bash
vaporize toolchain -- swift test
```

Release packet JSON validation also stays inside Vaporize:

```bash
vaporize validate-json --path release/v0.0.1/evidence/launch-review-packet.json
```

## Apple project migration

The project migration modes support the XcodeGen-to-Pkl release path without
treating legacy YAML as the forward source of truth:

```bash
vaporize inspect-project-yml --path private/apple/apps/concourse/project.yml --format json
vaporize inspect-target-features --path private/universal/substrate/collectives/wrkstrm-components/private/hello-world-google/demo-apps/hello-world-google.demo/project.yml --target hello-world-google.demo --format json
vaporize compare-project-yml-pkl --path private/apple/apps/concourse/project.yml --pkl-path private/apple/apps/concourse/project.pkl
vaporize import-project-yml --path private/apple/apps/creative-selection-v0.2/project.yml --output-path private/apple/apps/creative-selection-v0.2/project.pkl
vaporize generate-project-yml --pkl-path private/apple/apps/concourse/project.pkl --output-path /tmp/concourse.generated.yml
vaporize generate-xcodeproj --pkl-path private/apple/apps/creative-selection-v0.2/project.pkl --output-path /tmp/creative-selection.generated.xcodeproj
```

`generate-project-yml` is transitional migration evidence. `generate-xcodeproj`
is the owned world-state generation path, currently proven as a first slice
rather than fleet parity.
`inspect-target-features` is the target-level release-feature topology inspector:
it reads project configs, target `configFiles`, `release-features.json`,
generated xcconfigs, generated `ReleaseFeatures.swift`, and
`digikoma-release-features` provenance without mutating the project.

## Xcode component setup

Setup mode is the owned lane for Xcode component downloads required by Apple app
builds. It keeps direct `xcodebuild` calls inside Vaporize:

```bash
vaporize setup --xcode-component MetalToolchain
```

Use this when SwiftTerm or another dependency needs the Metal compiler and Xcode
reports a missing Metal Toolchain.

## Notes

- Direct `xcodebuild` is blacklisted as a restricted native tool for agent use.
  Agents route Swift app build/install/open/run proof through
  `vaporize@wrkstrm-core.cli`; Vaporize may invoke `xcodebuild` only as an
  implementation detail.
- CLI install/uninstall uses `swift package experimental-install` and
  `swift package experimental-uninstall` under the hood.
- App install uses `swift build` with the Xcode build system, or a typed
  `xcodebuild` invocation when Xcode project/workspace fields are provided.
- Shared Xcode workspace product cache reuse requires both
  `--xcode-product-cache-workspace` and
  `--xcode-product-cache-derived-data-path`; providing only one is invalid.
- Xcode build settings must be passed as repeatable `--xcode-build-setting`
  `KEY=VALUE` fields. Do not smuggle native-tool shell fragments into runbooks.
- Pass-through mode currently defaults to Swift. It is for analyzable Swift
  command proof, not for bypassing the restricted `xcodebuild` route.
- Build mode installs by default. Use `--skip-install` only when explicitly
  proving build output without installing it.
- Run mode installs by default. CLI runs execute the installed binary; app runs
  open the installed app.
- If the tool or app is already installed, re-run with `--force` to replace it.
