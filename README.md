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
`swift-universal`; Apple-bounded orchestration belongs in `wrkstrm-core`. A
behavior-changing vaporware modification request is release work: it needs a
feature flag or feature-status story, targetable tests, and release evidence.
Treat that catalog as the human engineering narrative for future
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
vaporize toolchain-selection swift -- use 6.4.x-snapshot
# macOS only; Xcode selection is independent from default Swift selection:
vaporize toolchain-selection xcode -- select --print-path
vaporize test --package-path <package> --swift-source xcode --configuration debug
vaporize validate-json --path <packet.json>
vaporize inspect-project-yml --path <project.yml> --format json --receipt-path <receipt.json>
vaporize inspect-target-features --path <project.yml> --target <target> --format json --receipt-path <receipt.json>
vaporize compare-project-yml-pkl --path <project.yml> --pkl-path <project.pkl> --receipt-path <receipt.json>
vaporize import-project-yml --path <project.yml> --output-path <project.pkl> --receipt-path <receipt.json>
vaporize generate-project-yml --pkl-path <project.pkl> --output-path <generated.yml> --receipt-path <receipt.json>
vaporize generate-xcodeproj --pkl-path <project.pkl> --output-path <generated.xcodeproj> --receipt-path <receipt.json>
vaporize list-schemes --xcode-workspace <workspace.xcworkspace> --format json --receipt-path <receipt.json>
vaporize setup --xcode-component MetalToolchain
vaporize status --path <records> --format text
vaporize warehouse --path <records> --receipt-path <receipt.json>
```

## Command grammar and manual pages

Vaporize currently has a flat mode dispatcher. The live grammar is:

```text
vaporize [options] [mode] [-- forwarded-arguments...]
```

`mode` is one of `install`, `uninstall`, `build`, `test`, `run`, `pass`,
`use`, `toolchain-selection`, `setup`, `status`, `warehouse`, `validate-json`,
`validate-json-schema`, `inspect-project-yml`, `inspect-target-features`,
`compare-project-yml-pkl`, `import-project-yml`, `upgrade-project-yml-to-pkl`,
`generate-project-yml`, `generate-xcodeproj`, `generate-sparkle-config`,
`list-targets`, `list-schemes`, `release-doctor`, `inventory`, `cuj-audit`,
`graph`, `domains`, `self-update`, or `fleet-status`. Options are parsed by the
root command and validated by the selected mode; they are not separate
ArgumentParser subcommands yet. The deprecated compatibility spellings `cli`
and `app` are also still accepted by the current parser.

`toolchain-selection` requires an explicit, compiled provider and owns only
active selection state:

```text
vaporize toolchain-selection swift -- use [swiftly-use-options] [selector]
vaporize toolchain-selection xcode -- select <xcode-select-options>  # macOS only
```

The `swift` provider exists on every supported platform and compiles Swiftly's
`use` implementation into Vaporize. The sibling `xcode` provider and its
`xcode-select` implementation are compiled only on macOS, so a Linux build
exposes no Xcode selection provider. Swiftly lifecycle/inspection/execution and
arbitrary `xcrun` execution are deliberately outside this command.

The checked-in section-1 manual is generated from ArgumentParser help, so the
manual and executable share one option source:

```bash
scripts/regenerate-manual.sh
man -M "$PWD/Documentation/man" vaporize
```

The generator uses the default `swift` on `PATH`. On macOS, an explicit Xcode
Swift generation lane is available without changing the default Swift
selection:

```bash
VAPORIZE_USE_XCODE_SWIFT=1 scripts/regenerate-manual.sh
```

CLI installation now treats checked-in manuals as installed artifacts. A
package that provides
`Documentation/man/man1/<canonical-product>.1` has that page and its `.so`
aliases installed under `~/.swiftpm/share/man/man1`; uninstall removes the
recorded pages. For Vaporize, both of these lookups resolve the same manual:

```bash
man vaporize
man vaporize.cli@wrkstrm-core.clia.sh
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

List maintained workspace schemes through Xcode:

```bash
vaporize list-schemes \
  --xcode-workspace /path/to/Huge/Huge.xcworkspace \
  --format json \
  --receipt-path /tmp/huge-workspace-schemes.receipt.json
```

`list-schemes` delegates to `xcodebuild -list -json -workspace` through the
Vaporize/CommonProcess boundary. It lists schemes only; it does not build, warm
caches, inspect products, or prove fleet workspace coverage.

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

## Toolchain selection and JSON validation

Toolchain selection compiles Swiftly's `use` operation into Vaporize. It reports
or changes the selected default Swift without launching an installed `swiftly`
CLI:

```bash
vaporize toolchain-selection swift -- use
vaporize toolchain-selection swift -- use 6.4.x-snapshot
vaporize toolchain-selection swift -- use --global-default 6.4.x-snapshot
```

Until Swift 6.4 has a stable Swift.org release, `6.4.x-snapshot` selects the
latest installed release-branch snapshot. Selection does not install it;
toolchain acquisition remains a separate provisioning responsibility.

On macOS, Xcode is an independent selection domain. Its provider owns only the
selection-state portion of `/usr/bin/xcode-select`; it does not own Xcode
version inspection or arbitrary tool execution:

```bash
vaporize toolchain-selection xcode -- select --print-path
vaporize toolchain-selection xcode -- select --switch /Applications/Xcode.app/Contents/Developer
vaporize toolchain-selection xcode -- select --reset
```

SwiftPM CLI build, install, and test operations follow the same rule. They use
default Swift unless the macOS-only Xcode source is requested explicitly:

```bash
vaporize build --artifact cli --package-path <package> --product <product> --skip-install
vaporize build --artifact cli --package-path <package> --product <product> --swift-source xcode --skip-install
vaporize test --package-path <package> --swift-source xcode --configuration debug
```

The full mode-and-option responsibility map is documented in
`vaporize.engineering.docc/command-ownership-map.md`. Swift toolchain lifecycle
and generic Xcode inspection remain explicit command-design gaps; they are not
smuggled into selection.

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
