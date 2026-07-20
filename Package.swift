// swift-tools-version: 6.4
import Foundation
import PackageDescription

func localOrRemote(path: String, url: String, from version: Version) -> Package.Dependency {
  if ProcessInfo.useLocalDeps { return .package(path: path) }
  return .package(url: url, from: version)
}

let commonShellDependency: Package.Dependency = if ProcessInfo.useLocalDeps {
  .package(
    path: "../../../../../swift-universal/private/universal/domain/dispatch/spm/common-shell",
    traits: []
  )
} else {
  .package(name: "common-shell", path: "../../../../../swift-universal/private/universal/domain/dispatch/spm/common-shell")
}
let commonProcessDependency: Package.Dependency = if ProcessInfo.useLocalDeps {
  .package(
    path: "../../../../../swift-universal/private/universal/domain/dispatch/spm/common-process",
    traits: []
  )
} else {
  .package(name: "common-process", path: "../../../../../swift-universal/private/universal/domain/dispatch/spm/common-process")
}
// swift-cli-installer LIFTED 2026-06-14 from sources/swift-cli-installer to
// swift-universal/private/universal/domain/tooling/spm/swift-cli-installer/
// per CEO decision + [[no-code-gets-left-behind]] doctrine.
let swiftCLIInstallerDependency: Package.Dependency = if ProcessInfo.useLocalDeps {
  .package(
    path: "../../../../../swift-universal/private/universal/domain/tooling/spm/swift-cli-installer",
    traits: []
  )
} else {
  .package(
    url: "https://github.com/swift-universal/swift-cli-installer.git",
    from: "0.0.1",
    traits: []
  )
}
// Consume/verify half of CLI Sparkle (appcast parse, SemanticVersion compare,
// EdDSA verify, atomic replace) — consumed, not reimplemented, per
// FR-CLI-SPARKLE-SELF-UPDATE-VAPORIZE-PKL-SCAFFOLDER-2026-07-14 component C.
let swiftCLIUpdaterDependency = localOrRemote(
  path: "../../../../../swift-universal/private/universal/domain/tooling/spm/swift-cli-updater",
  url: "https://github.com/swift-universal/swift-cli-updater.git",
  from: "0.0.1"
)
let swiftlyDependency = localOrRemote(
  path: "../../../../../../maintainers/swiftlang/public/universal/tooling/swift/swiftly",
  url: "https://github.com/swiftlang/swiftly.git",
  from: "1.1.3"
)
let swiftJSONFormatterDependency = localOrRemote(
  path: "../../../../../swift-universal/private/universal/domain/tooling/spm/swift-json-formatter",
  url: "https://github.com/swift-universal/swift-json-formatter.git",
  from: "0.1.0"
)
let pklSwiftDependency = Package.Dependency.package(
  url: "https://github.com/apple/pkl-swift",
  from: "0.8.2"
)
let swiftIssueReportingDependency = Package.Dependency.package(
  url: "https://github.com/pointfreeco/swift-issue-reporting",
  exact: "2.0.0"
)
let translateSourceGateDependency = Package.Dependency.package(
  path: "../../../../../i18n-universal/private/universal/domain/catalogs/spm/TranslateCatalogCore"
)
let swiftPackageOutputPolicyDependency = Package.Dependency.package(
  name: "swift-package-output-policy",
  path: "../../../../../swift-universal/private/universal/domain/build/spm/swift-package-output-policy"
)

let package = Package(
  name: "vaporize@wrkstrm-core-cli",
  platforms: [
    .macOS("26.0")
  ],
  products: [
    .library(name: "AppleProjectSpecCore", targets: ["AppleProjectSpecCore"]),
    .library(name: "VaporizeIssueReporting", targets: ["VaporizeIssueReporting"]),
    // SwiftCLIInstaller library LIFTED to swift-universal/.../tooling/spm/swift-cli-installer/
    // (CEO decision 2026-06-14). Consumers now import via swiftCLIInstallerDependency.
    .library(name: "SwiftAppInstaller", targets: ["SwiftAppInstaller"]),
    .executable(name: "vaporize.cli@wrkstrm-core.clia.sh", targets: ["VaporizeCLI"]),
  ],
  dependencies: [
    commonProcessDependency,
    commonShellDependency,
    swiftCLIInstallerDependency,
    swiftCLIUpdaterDependency,
    swiftlyDependency,
    swiftJSONFormatterDependency,
    pklSwiftDependency,
    swiftIssueReportingDependency,
    translateSourceGateDependency,
    swiftPackageOutputPolicyDependency,
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.0"),
    .package(url: "https://github.com/jpsim/Yams", from: "5.1.0"),
  ],
  targets: [
    .target(
      name: "AppleProjectSpecCore",
      dependencies: [
        .product(name: "CommonProcess", package: "common-process"),
        .product(name: "CommonProcessExecutionKit", package: "common-process"),
        .product(name: "PklSwift", package: "pkl-swift"),
        .product(name: "Yams", package: "Yams"),
      ],
      path: "sources/apple-project-spec-core"
    ),
    // SwiftCLIInstaller target REMOVED 2026-06-14 — LIFTED to swift-universal
    // package "swift-cli-installer". Consumers below import via
    // .product(name: "SwiftCLIInstaller", package: "swift-cli-installer").
    .target(
      name: "SwiftAppInstaller",
      dependencies: [
        .product(name: "CommonShell", package: "common-shell"),
        .product(name: "CommonProcess", package: "common-process"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "sources/swift-app-installer"
    ),
    .executableTarget(
      name: "VaporizeCLI",
      dependencies: [
        "AppleProjectSpecCore",
        "VaporizeIssueReporting",
        .product(name: "SwiftCLIInstaller", package: "swift-cli-installer"),
        .product(name: "SwiftCLIUpdater", package: "swift-cli-updater"),
        .product(name: "SwiftlyCommands", package: "swiftly"),
        "SwiftAppInstaller",
        .product(name: "CommonShell", package: "common-shell"),
        .product(name: "CommonProcess", package: "common-process"),
        .product(name: "CommonProcessExecutionKit", package: "common-process"),
        .product(name: "SwiftJSONFormatter", package: "swift-json-formatter"),
        .product(name: "TranslateSourceGate", package: "TranslateCatalogCore"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "sources/vaporize-cli"
    ),
    .target(
      name: "VaporizeTestSupport",
      dependencies: ["AppleProjectSpecCore"],
      path: "tests/vaporize-test-support"
    ),
    .target(
      name: "VaporizeIssueReporting",
      dependencies: [
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
      ],
      path: "sources/vaporize-issue-reporting"
    ),
    .testTarget(
      name: "VaporizeIssueReportingTests",
      dependencies: [
        "VaporizeIssueReporting",
        "VaporizeCLI",
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
      ],
      path: "tests/issue-reporting"
    ),
    .testTarget(
      name: "VaporizeCUJ01SwiftPMCLITests",
      dependencies: [
        .product(name: "SwiftCLIInstaller", package: "swift-cli-installer"),
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-01-swiftpm-cli",
      plugins: [
        .plugin(name: "CommonLogOutputPolicyPlugin", package: "swift-package-output-policy"),
      ]
    ),
    .testTarget(
      name: "VaporizeCUJ02MacAppTests",
      dependencies: [
        "AppleProjectSpecCore",
        "SwiftAppInstaller",
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-02-mac-app"
    ),
    .testTarget(
      name: "VaporizeCUJ03PassThroughTests",
      dependencies: ["VaporizeCLI"],
      path: "tests/cuj-03-pass-through"
    ),
    .testTarget(
      name: "VaporizeSwiftUIImportGateTests",
      dependencies: ["VaporizeCLI"],
      path: "tests/swiftui-import-gate"
    ),
    .testTarget(
      name: "VaporizeCUJ04CommonProcessUseTests",
      dependencies: [
        "VaporizeCLI",
        .product(name: "CommonProcess", package: "common-process"),
      ],
      path: "tests/cuj-04-common-process-use"
    ),
    .testTarget(
      name: "VaporizeCUJ05ToolchainTests",
      dependencies: ["VaporizeCLI"],
      path: "tests/cuj-05-toolchain"
    ),
    .testTarget(
      name: "VaporizeCUJ06JSONValidationTests",
      dependencies: [
        "VaporizeCLI",
        .product(name: "SwiftJSONFormatter", package: "swift-json-formatter"),
      ],
      path: "tests/cuj-06-json-validation"
    ),
    .testTarget(
      name: "VaporizeCUJ07VaporInventoryTests",
      dependencies: [
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-07-vapor-inventory"
    ),
    .testTarget(
      name: "VaporizeCUJ08ProjectYMLInspectionTests",
      dependencies: [
        "AppleProjectSpecCore",
        "VaporizeTestSupport",
      ],
      path: "tests/cuj-08-project-yml-inspection"
    ),
    .testTarget(
      name: "VaporizeCUJ09ReleaseReviewTests",
      dependencies: [],
      path: "tests/cuj-09-release-review"
    ),
    .testTarget(
      name: "VaporizeCUJ10YMLPklComparisonTests",
      dependencies: [
        "AppleProjectSpecCore",
        "VaporizeTestSupport",
      ],
      path: "tests/cuj-10-yml-pkl-comparison"
    ),
    .testTarget(
      name: "VaporizeCUJ11PklYMLGenerationTests",
      dependencies: [
        "AppleProjectSpecCore",
        "VaporizeTestSupport",
      ],
      path: "tests/cuj-11-pkl-yml-generation"
    ),
    .testTarget(
      name: "VaporizeCUJ13YMLPklImportTests",
      dependencies: [
        "AppleProjectSpecCore",
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-13-yml-pkl-import"
    ),
    .testTarget(
      name: "VaporizeCUJ14PklXcodeProjectGenerationTests",
      dependencies: [
        "AppleProjectSpecCore",
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-14-pkl-xcodeproj-generation"
    ),
    .testTarget(
      name: "VaporizeCUJ15XcodeProductCacheTests",
      dependencies: [
        "SwiftAppInstaller",
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-15-xcode-product-cache"
    ),
    .testTarget(
      name: "VaporizeCUJ16TargetFeaturesTests",
      dependencies: [
        "AppleProjectSpecCore",
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-16-target-features"
    ),
    .testTarget(
      name: "VaporizeCUJ17ReleaseDoctorTests",
      dependencies: [
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-17-release-doctor"
    ),
    .testTarget(
      name: "VaporizeCUJ18ListTargetsTests",
      dependencies: [
        "AppleProjectSpecCore",
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-18-list-targets"
    ),
    .testTarget(
      name: "VaporizeCUJ19WorkspaceCacheDiscoveryTests",
      dependencies: [
        "AppleProjectSpecCore",
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-19-workspace-cache-discovery"
    ),
    .testTarget(
      name: "VaporizeCUJ20XcodeWorkspaceSchemesTests",
      dependencies: [
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-20-xcode-workspace-schemes"
    ),
    .testTarget(
      name: "VaporizeCUJ21CUJStateTests",
      dependencies: [
        "VaporizeTestSupport",
      ],
      path: "tests/cuj-21-cuj-state"
    ),
    .testTarget(
      name: "VaporizeCUJ22ResourceCLIInstallTests",
      dependencies: [
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-22-resource-cli-install"
    ),
    .testTarget(
      name: "VaporizeCUJ23ProductProvingGroundTests",
      dependencies: [
        "VaporizeTestSupport",
      ],
      path: "tests/cuj-23-product-proving-grounds"
    ),
    .testTarget(
      name: "VaporizeCUJ25PortfolioAuditTests",
      dependencies: [
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-25-portfolio-audit"
    ),
    .testTarget(
      name: "VaporizeCUJ26AutomatedProofLedgerTests",
      dependencies: [
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-26-automated-proof-ledger"
    ),
    .testTarget(
      name: "VaporizeCUJ27ProjectCoverageLedgerTests",
      dependencies: [
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-27-project-coverage-ledger"
    ),
    .testTarget(
      name: "VaporizeCUJ28SparkleConfigGenerationTests",
      dependencies: [
        "AppleProjectSpecCore",
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-28-sparkle-config-generation"
    ),
    .testTarget(
      name: "VaporizeCUJ29ProductSelfUpdateTests",
      dependencies: [
        "VaporizeCLI",
        .product(name: "SwiftCLIInstaller", package: "swift-cli-installer"),
        .product(name: "SwiftCLIUpdater", package: "swift-cli-updater"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-29-product-self-update"
    ),
    .testTarget(
      name: "VaporizeCUJ30FleetStatusTests",
      dependencies: [
        "VaporizeCLI",
        .product(name: "SwiftCLIInstaller", package: "swift-cli-installer"),
        .product(name: "SwiftCLIUpdater", package: "swift-cli-updater"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-30-fleet-status"
    ),
    .testTarget(
      name: "VaporizeCUJ12PackageGraphTests",
      dependencies: [
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-12-package-graph"
    ),
  ]
)

extension ProcessInfo {
  public static var useLocalDeps: Bool {
    guard let raw = ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] else { return true }
    let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return !(normalized == "0" || normalized == "false" || normalized == "no")
  }
}
