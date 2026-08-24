// swift-tools-version: 6.4
import Foundation
import PackageDescription

func localOrRemote(path: String, url: String, from version: Version) -> Package.Dependency {
  if ProcessInfo.useLocalDeps { return .package(path: path) }
  return .package(url: url, from: version)
}

func ancestor(named component: String, from start: URL) -> URL? {
  var current = start
  while true {
    if current.lastPathComponent == component { return current }
    let parent = current.deletingLastPathComponent()
    if parent.path == current.path { return nil }
    current = parent
  }
}

let manifestDirectory = URL(filePath: #filePath)
  .deletingLastPathComponent()
  .standardizedFileURL
guard let swiftUniversalDirectory = ancestor(
  named: "swift-universal",
  from: manifestDirectory
) else {
  fatalError("Vaporize must live beneath the swift-universal repository")
}
let collectivesDirectory = swiftUniversalDirectory.deletingLastPathComponent()

func repositoryPath(_ root: URL, _ relativePath: String) -> String {
  root.appendingPathComponent(relativePath).standardizedFileURL.path
}

let commonShellDependency: Package.Dependency = if ProcessInfo.useLocalDeps {
  .package(
    path: repositoryPath(
      swiftUniversalDirectory,
      "private/universal/domain/dispatch/spm/common-shell"
    )
  )
} else {
  .package(
    name: "common-shell",
    path: repositoryPath(
      swiftUniversalDirectory,
      "private/universal/domain/dispatch/spm/common-shell"
    )
  )
}
let commonProcessDependency: Package.Dependency = if ProcessInfo.useLocalDeps {
  .package(
    path: repositoryPath(
      swiftUniversalDirectory,
      "private/universal/domain/dispatch/spm/common-process"
    )
  )
} else {
  .package(
    name: "common-process",
    path: repositoryPath(
      swiftUniversalDirectory,
      "private/universal/domain/dispatch/spm/common-process"
    )
  )
}
let commonLogDependency = Package.Dependency.package(
  name: "common-log",
  path: repositoryPath(
    swiftUniversalDirectory,
    "private/universal/spm/domain/system/common-log"
  )
)
// swift-cli-installer LIFTED 2026-06-14 from sources/swift-cli-installer to
// swift-universal/private/universal/domain/tooling/spm/swift-cli-installer/
// per CEO decision + [[no-code-gets-left-behind]] doctrine.
// This package was lifted into the shared topology and is not independently
// published. Keep the dependency edge local in both dependency modes.
let swiftCLIInstallerDependency = Package.Dependency.package(
  path: repositoryPath(
    swiftUniversalDirectory,
    "private/universal/domain/tooling/spm/swift-cli-installer"
  )
)
// Consume/verify half of CLI Sparkle (appcast parse, SemanticVersion compare,
// EdDSA verify, atomic replace) — consumed, not reimplemented, per
// FR-CLI-SPARKLE-SELF-UPDATE-VAPORIZE-PKL-SCAFFOLDER-2026-07-14 component C.
// Like the installer, the updater is topology-owned and has no standalone
// remote repository.
let swiftCLIUpdaterDependency = Package.Dependency.package(
  path: repositoryPath(
    swiftUniversalDirectory,
    "private/universal/domain/tooling/spm/swift-cli-updater"
  ),
)
let swiftJSONFormatterDependency = localOrRemote(
  path: repositoryPath(
    swiftUniversalDirectory,
    "private/universal/domain/tooling/spm/swift-json-formatter"
  ),
  url: "https://github.com/swift-universal/swift-json-formatter.git",
  from: "0.1.0"
)
let xcodeProjectDefinitionDependency = Package.Dependency.package(
  path: repositoryPath(
    collectivesDirectory,
    "wrkstrm-core/private/universal/domain/build/spm/xcode-project-definition"
  )
)
let swiftIssueReportingDependency = Package.Dependency.package(
  url: "https://github.com/pointfreeco/swift-issue-reporting",
  exact: "2.0.0"
)
let translateSourceGateDependency = Package.Dependency.package(
  path: repositoryPath(
    collectivesDirectory,
    "i18n-universal/private/universal/domain/catalogs/spm/TranslateCatalogCore"
  )
)
let vaporizeCLICopyDependency = Package.Dependency.package(
  path: repositoryPath(
    collectivesDirectory,
    "i18n-universal/private/universal/domain/catalogs/spm/VaporizeCLICopy_v000_000_001"
  )
)
let swiftPackageOutputPolicyDependency = Package.Dependency.package(
  name: "swift-package-output-policy",
  path: repositoryPath(
    swiftUniversalDirectory,
    "private/universal/domain/build/spm/swift-package-output-policy"
  )
)
let vaporizeJSONSchemaValidationDependency = Package.Dependency.package(
  name: "vaporize-json-schema-validation",
  path: repositoryPath(
    collectivesDirectory,
    "wrkstrm-core/private/apple/spm/vaporize-json-schema-validation@wrkstrm-core.cli"
  )
)
let testFixtureLifecycleDependency = Package.Dependency.package(
  name: "common-test-fixture-lifecycle",
  path: repositoryPath(
    swiftUniversalDirectory,
    "private/universal/domain/build/spm/common-test-fixture-lifecycle"
  )
)
let testServiceAdoptionPolicyDependency = Package.Dependency.package(
  name: "test-service-adoption-policy@wrkstrm-core",
  path: repositoryPath(
    collectivesDirectory,
    "wrkstrm-core/private/universal/domain/build/spm/test-service-adoption-policy@wrkstrm-core"
  )
)
let bumpBuildDependency = Package.Dependency.package(
  name: "bump-build@takumi-org.cli",
  path: repositoryPath(
    collectivesDirectory,
    "takumi-org/private/universal/domain/tooling/spm/bump-build@takumi-org.cli"
  )
)

let packageDependencies: [Package.Dependency] = [
  commonLogDependency,
  commonProcessDependency,
  commonShellDependency,
  swiftCLIInstallerDependency,
  swiftCLIUpdaterDependency,
  swiftJSONFormatterDependency,
  xcodeProjectDefinitionDependency,
  swiftIssueReportingDependency,
  translateSourceGateDependency,
  vaporizeCLICopyDependency,
  swiftPackageOutputPolicyDependency,
  vaporizeJSONSchemaValidationDependency,
  testFixtureLifecycleDependency,
  testServiceAdoptionPolicyDependency,
  bumpBuildDependency,
  .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.0"),
  .package(url: "https://github.com/apple/swift-crypto.git", from: "3.15.1"),
]

let vaporizeCLIDependencies: [Target.Dependency] = [
  .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
  "VaporizeIssueReporting",
  .product(name: "CommonLog", package: "common-log"),
  .product(name: "VaporizeJSONSchemaValidation", package: "vaporize-json-schema-validation"),
  .product(name: "BumpBuildTakumiOrgCore", package: "bump-build@takumi-org.cli"),
  .product(name: "SwiftCLIInstaller", package: "swift-cli-installer"),
  .product(name: "SwiftCLIUpdater", package: "swift-cli-updater"),
  "SwiftAppInstaller",
  .product(name: "CommonShell", package: "common-shell"),
  .product(name: "CommonProcess", package: "common-process"),
  .product(name: "CommonProcessExecutionKit", package: "common-process"),
  .product(name: "SwiftJSONFormatter", package: "swift-json-formatter"),
  .product(name: "TranslateSourceGate", package: "TranslateCatalogCore"),
  .product(name: "VaporizeCLICopy_v000_000_001", package: "VaporizeCLICopy_v000_000_001"),
  .product(name: "ArgumentParser", package: "swift-argument-parser"),
]

let package = Package(
  name: "vaporize@wrkstrm-core.cli",
  platforms: [
    .macOS("26.0")
  ],
  products: [
    .library(name: "VaporizeIssueReporting", targets: ["VaporizeIssueReporting"]),
    // SwiftCLIInstaller library LIFTED to swift-universal/.../tooling/spm/swift-cli-installer/
    // (CEO decision 2026-06-14). Consumers now import via swiftCLIInstallerDependency.
    .library(name: "SwiftAppInstaller", targets: ["SwiftAppInstaller"]),
    .executable(name: "vaporize.cli@wrkstrm-core.clia.sh", targets: ["VaporizeCLI"]),
  ],
  dependencies: packageDependencies,
  targets: [
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
      dependencies: vaporizeCLIDependencies,
      path: "sources/vaporize-cli"
    ),
    .target(
      name: "VaporizeTestSupport",
      dependencies: [
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
        .product(name: "CommonProcess", package: "common-process"),
        .product(name: "CommonProcessExecutionKit", package: "common-process"),
        .product(name: "TestFixtureLifecycle", package: "common-test-fixture-lifecycle"),
        .product(name: "TestServiceAdoptionPolicy", package: "test-service-adoption-policy@wrkstrm-core"),
      ],
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
      name: "VaporizeLoggingTests",
      dependencies: [
        "VaporizeTestSupport",
        "VaporizeCLI",
        .product(name: "CommonLog", package: "common-log"),
      ],
      path: "tests/logging"
    ),
    .testTarget(
      name: "VaporizeIssueReportingTests",
      dependencies: [
        "VaporizeTestSupport",
        "VaporizeIssueReporting",
        "VaporizeCLI",
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
      ],
      path: "tests/issue-reporting"
    ),
    .testTarget(
      name: "VaporizeCUJ01SwiftPMCLITests",
      dependencies: [
        "VaporizeTestSupport",
        .product(name: "SwiftCLIInstaller", package: "swift-cli-installer"),
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "CommonProcess", package: "common-process"),
        .product(name: "CommonProcessExecutionKit", package: "common-process"),
      ],
      path: "tests/cuj-01-swiftpm-cli",
      plugins: [
        .plugin(name: "CommonLogOutputPolicyPlugin", package: "swift-package-output-policy"),
      ]
    ),
    .testTarget(
      name: "VaporizeCUJ02MacAppTests",
      dependencies: [
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
        "SwiftAppInstaller",
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-02-mac-app"
    ),
    .testTarget(
      name: "VaporizeCUJ03PassThroughTests",
      dependencies: ["VaporizeTestSupport", "VaporizeCLI"],
      path: "tests/cuj-03-pass-through"
    ),
    .testTarget(
      name: "VaporizeSwiftUIImportGateTests",
      dependencies: ["VaporizeTestSupport", "VaporizeCLI"],
      path: "tests/swiftui-import-gate"
    ),
    .testTarget(
      name: "VaporizeCUJ04CommonProcessUseTests",
      dependencies: [
        "VaporizeTestSupport",
        "VaporizeCLI",
        .product(name: "CommonProcess", package: "common-process"),
      ],
      path: "tests/cuj-04-common-process-use"
    ),
    .testTarget(
      name: "VaporizeCUJ05ToolchainTests",
      dependencies: ["VaporizeTestSupport", "VaporizeCLI"],
      path: "tests/cuj-05-toolchain"
    ),
    .testTarget(
      name: "VaporizeCUJ06JSONValidationTests",
      dependencies: [
        "VaporizeTestSupport",
        "VaporizeCLI",
        .product(name: "SwiftJSONFormatter", package: "swift-json-formatter"),
      ],
      path: "tests/cuj-06-json-validation"
    ),
    .testTarget(
      name: "VaporizeCUJ07VaporInventoryTests",
      dependencies: [
        "VaporizeTestSupport",
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-07-vapor-inventory"
    ),
    .testTarget(
      name: "VaporizeCUJ08ProjectYMLInspectionTests",
      dependencies: [
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
        "VaporizeTestSupport",
      ],
      path: "tests/cuj-08-project-yml-inspection"
    ),
    .testTarget(
      name: "VaporizeCUJ09ReleaseReviewTests",
      dependencies: ["VaporizeTestSupport"],
      path: "tests/cuj-09-release-review"
    ),
    .testTarget(
      name: "VaporizeCUJ10YMLPklComparisonTests",
      dependencies: [
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
        "VaporizeTestSupport",
      ],
      path: "tests/cuj-10-yml-pkl-comparison"
    ),
    .testTarget(
      name: "VaporizeCUJ11PklYMLGenerationTests",
      dependencies: [
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
        "VaporizeTestSupport",
      ],
      path: "tests/cuj-11-pkl-yml-generation"
    ),
    .testTarget(
      name: "VaporizeCUJ13YMLPklImportTests",
      dependencies: [
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-13-yml-pkl-import"
    ),
    .testTarget(
      name: "VaporizeCUJ14PklXcodeProjectGenerationTests",
      dependencies: [
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-14-pkl-xcodeproj-generation"
    ),
    .testTarget(
      name: "XcodeProjectDefinitionCoreXcrunMaterializationTests",
      dependencies: [
        "VaporizeTestSupport",
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
      ],
      path: "tests/xcode-project-definition-core-xcrun-materialization"
    ),
    .testTarget(
      name: "VaporizeCUJ14RemotePackageGenerationTests",
      dependencies: [
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
        "VaporizeTestSupport",
      ],
      path: "tests/cuj-14-remote-package-generation"
    ),
    .testTarget(
      name: "VaporizeCUJ15XcodeProductCacheTests",
      dependencies: [
        "VaporizeTestSupport",
        "SwiftAppInstaller",
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-15-xcode-product-cache"
    ),
    .testTarget(
      name: "VaporizeCUJ16TargetFeaturesTests",
      dependencies: [
        "VaporizeTestSupport",
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-16-target-features"
    ),
    .testTarget(
      name: "VaporizeCUJ17ReleaseDoctorTests",
      dependencies: [
        "VaporizeTestSupport",
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-17-release-doctor"
    ),
    .testTarget(
      name: "VaporizeCUJ18ListTargetsTests",
      dependencies: [
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-18-list-targets"
    ),
    .testTarget(
      name: "VaporizeCUJ19WorkspaceCacheDiscoveryTests",
      dependencies: [
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-19-workspace-cache-discovery"
    ),
    .testTarget(
      name: "VaporizeCUJ20XcodeWorkspaceSchemesTests",
      dependencies: [
        "VaporizeTestSupport",
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
        "VaporizeTestSupport",
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-25-portfolio-audit"
    ),
    .testTarget(
      name: "VaporizeCUJ26AutomatedProofLedgerTests",
      dependencies: [
        "VaporizeTestSupport",
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-26-automated-proof-ledger"
    ),
    .testTarget(
      name: "VaporizeCUJ27ProjectCoverageLedgerTests",
      dependencies: [
        "VaporizeTestSupport",
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-27-project-coverage-ledger"
    ),
    .testTarget(
      name: "VaporizeCUJ28SparkleConfigGenerationTests",
      dependencies: [
        .product(name: "XcodeProjectDefinitionCore", package: "xcode-project-definition"),
        "VaporizeCLI",
        "VaporizeTestSupport",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-28-sparkle-config-generation"
    ),
    .testTarget(
      name: "VaporizeCUJ29ProductSelfUpdateTests",
      dependencies: [
        "VaporizeTestSupport",
        "VaporizeCLI",
        .product(name: "SwiftCLIInstaller", package: "swift-cli-installer"),
        .product(name: "SwiftCLIUpdater", package: "swift-cli-updater"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Crypto", package: "swift-crypto"),
      ],
      path: "tests/cuj-29-product-self-update"
    ),
    .testTarget(
      name: "VaporizeCUJ30FleetStatusTests",
      dependencies: [
        "VaporizeTestSupport",
        "VaporizeCLI",
        .product(name: "SwiftCLIInstaller", package: "swift-cli-installer"),
        .product(name: "SwiftCLIUpdater", package: "swift-cli-updater"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-30-fleet-status"
    ),
    .testTarget(
      name: "VaporizeCUJ31HomebrewStatusTests",
      dependencies: [
        "VaporizeTestSupport",
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-31-homebrew-status"
    ),
    .testTarget(
      name: "VaporizeCUJ12PackageGraphTests",
      dependencies: [
        "VaporizeTestSupport",
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-12-package-graph"
    ),
    .testTarget(
      name: "VaporizeCUJ32TestServiceAdoptionTests",
      dependencies: ["VaporizeTestSupport"],
      path: "tests/cuj-32-test-service-adoption"
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
