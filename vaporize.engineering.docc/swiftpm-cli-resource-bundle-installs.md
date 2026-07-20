@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("SwiftPM CLI Resource Bundle Installs")
  @Available(platform: macOS, introduced: "0.1.0")
}

# SwiftPM CLI Resource Bundle Installs

SwiftPM executable products can depend on target resources through
`Bundle.module`. Vaporize must preserve that runtime contract when it installs a
CLI into `~/.swiftpm/bin`.

The rule is simple:

- Package authors declare file resources on the owning target with
  `.process(...)` or `.copy(...)`.
- Product code reads those resources with `Bundle.module`.
- Vaporize installs the executable with `swift package experimental-install`.
- Vaporize asks SwiftPM for the build products directory with
  `swift build --show-bin-path`.
- Vaporize copies `.bundle` siblings from that SwiftPM-reported directory into
  the installed CLI bin directory.

This keeps SwiftPM responsible for build layout and resource processing, while
Vaporize owns the install-time artifact carry that raw `experimental-install`
does not perform.

## Product Metadata Info.plist

SwiftPM resource bundles already contain their own `Contents/Info.plist`, and
Vaporize copies that bundle plist when it carries the bundle next to the
installed executable. That plist describes the resource bundle. It is not the
installed CLI product's version/build identity.

For bare SwiftPM CLI installs, Vaporize writes a product metadata sidecar next
to the installed executable:

```text
~/.swiftpm/bin/<product>.metadata/Info.plist
```

The sidecar is a normal property list. When version/build values are supplied,
Vaporize writes the standard keys:

```text
CFBundleShortVersionString
CFBundleVersion
```

The sidecar also records install/build facts Vaporize can prove for every CLI:

- `CFBundleExecutable`
- `CFBundleIdentifier`
- `CFBundleName`
- `VaporizeArtifactKind`
- `VaporizePackagePath`
- `VaporizeConfiguration`
- `VaporizeBuildProductsDirectory`
- `VaporizeInstalledAt`
- `VaporizeProduct`
- `VaporizeTool`
- `VaporizeSurface`
- `VaporizeCollective`
- `VaporizeRuntime`

CLI package authors can provide product identity at install time:

```text
vaporize.cli@wrkstrm-core.clia.sh install swift \
  --artifact cli \
  --package-path <package> \
  --product <product> \
  --product-version <version> \
  --product-build <build> \
  --product-build-sha <sha> \
  --product-build-date <iso8601-date>
```

This sidecar is installer-owned metadata. It does not make
`Bundle.main.infoDictionary` point at those values. If a CLI needs
`Bundle.main.infoDictionary` specifically, that is a separate native executable
linking requirement, not the SwiftPM resource-bundle carry step.

## Problem

`swift package experimental-install` installs the executable product, but it
does not install SwiftPM resource bundles next to that executable.

SwiftPM's generated `Bundle.module` accessor looks for the resource bundle next
to `Bundle.main` and then falls back to the build-products path compiled into
the accessor. That works while the package build directory remains available,
but installed CLIs are expected to run from `~/.swiftpm/bin` without depending on
a live `.build` directory.

The failing shape is:

1. A target declares processed resources in `Package.swift`.
2. SwiftPM emits a target resource bundle under the build products directory.
3. `experimental-install` copies only the executable to `~/.swiftpm/bin`.
4. The installed executable starts from `~/.swiftpm/bin`.
5. `Bundle.module` cannot find the bundle next to the executable.
6. If the build directory is absent or stale, the generated accessor fails at
   runtime.

## Solution

Vaporize keeps `experimental-install` as the executable install primitive, then
performs a resource-bundle carry step.

The installer runs:

```text
xcrun swift package experimental-install --package-path <package> -c <configuration> --product <product>
xcrun swift build --package-path <package> -c <configuration> --product <product> --show-bin-path
```

The second command is the important refinement. Vaporize does not infer the
products directory from `.build` path conventions. It asks SwiftPM for the
products directory for the same package, product, and configuration.

After SwiftPM returns the products directory, Vaporize:

1. Reads that directory only.
2. Selects direct children whose path extension is `.bundle`.
3. Creates `~/.swiftpm/bin` if needed.
4. Replaces any installed bundle with the same name.
5. Copies the bundle next to the installed executable.

The direct-child rule is intentional. Resource bundles are products-directory
siblings of the executable, not arbitrary recursive payloads somewhere under
`.build`.

## Resource API Choice

For roster-style resource catalogs, use SwiftPM file resources:

```swift
.executableTarget(
  name: "ToolCLI",
  resources: [
    .process("Resources"),
  ]
)
```

Runtime code should keep using `Bundle.module`:

```swift
let url = Bundle.module.url(forResource: "message", withExtension: "txt")
```

Do not move large directory-shaped catalogs to `Resource.embedInCode(...)` just
to avoid bundle copying. `embedInCode` is useful for small fixed byte payloads,
but it changes the runtime API to generated `[UInt8]` properties and removes the
normal file/directory lookup shape that resource catalogs need.

Do not turn a CLI into an app bundle solely to solve this install gap. App
bundles are the right artifact shape for app products, not for command-line
products expected under `~/.swiftpm/bin`.

## Proof Boundary

The durable proof is a simulation proving ground CUJ:

- A typed manifest names the generated SwiftPM CLI fixture kind, resource mode,
  expected stdout, isolation requirements, cleanup requirements, and proof
  command.
- Coverage fails when a manifest scenario is missing a receipt.
- Fixture CLIs declare `.process("resources")` or `.copy("resources")`.
- The fixtures read text, JSON, and byte-count payloads through
  `Bundle.module`.
- Vaporize installs each generated product through `install`.
- Each test confirms Vaporize copied the resource bundle into the installed bin
  directory.
- Each test hides `.build` and runs from a temporary directory, proving the
  installed executable is not falling back to build products.
- The stale reinstall scenario proves a fresh Vaporize install replaces the
  installed bundle payload.
- The checked-in `resource-vault.cli@vaporize-tests.clia.sh` proving-ground
  package exercises a lowercase, non-generated CLI that reads nested copied
  JSON and text resources from the installed bundle.
- The legacy `zshift@wrkstrm-core.clia.sh` scenario records the current
  product-name gate for an existing resource-bearing CLI and the actionable
  canonical suggestion before any SwiftPM build begins.

The focused test is:

```text
vaporize.cli@wrkstrm-core.clia.sh test swift --package-path private/universal/substrate/collectives/wrkstrm-core/private/apple/spm/vaporize@wrkstrm-core.cli --configuration debug -- --filter VaporizeCUJ22ResourceCLIInstallTests
```

The broader SwiftPM CLI surface is:

```text
vaporize.cli@wrkstrm-core.clia.sh test swift --package-path private/universal/substrate/collectives/wrkstrm-core/private/apple/spm/vaporize@wrkstrm-core.cli --configuration debug -- --filter VaporizeCUJ01SwiftPMCLITests
```

The shared installer unit tests are:

```text
vaporize.cli@wrkstrm-core.clia.sh test xcode --package-path private/universal/substrate/collectives/swift-universal/private/universal/domain/tooling/spm/swift-cli-installer -- --filter SwiftCLIInstallerTests
```

## Implementation Surface

The installer implementation lives in Swift Universal:

- `SwiftCLIInstaller.install()` runs `experimental-install`, then installs
  resource bundles.
- `SwiftCLIInstaller.buildProductsDirectoryArguments()` builds the
  `swift build --show-bin-path` request.
- `SwiftCLIInstaller.resourceBundlesToInstall(buildProductsDirectory:)` selects
  direct `.bundle` siblings from the SwiftPM-reported products directory.
- `SwiftCLIInstaller.installProductInfoPlist(buildProductsDirectory:)` writes
  the product metadata sidecar at
  `~/.swiftpm/bin/<product>.metadata/Info.plist`.

The release-facing Vaporize CUJ proof lives in
`VaporizeCUJ22ResourceCLIInstallTests`. CUJ-01 keeps additional SwiftPM CLI
lifecycle regression coverage, but CUJ-22 is the targetable launch-review owner
for resource-bearing CLI installs.

## Operational Check

For a live resource-bearing CLI, the operator check is:

```text
vaporize.cli@wrkstrm-core.clia.sh install swift --package-path <package> --product <product> --configuration release --force
<installed-product> <resource-reading-command>
```

If the resource bundle is deliberately removed from `~/.swiftpm/bin`, rerunning
Vaporize install must restore it before the command succeeds.
