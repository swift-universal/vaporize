// swift-tools-version: 6.4
import Foundation
import PackageDescription

func localOrRemote(path: String, url: String, from version: Version) -> Package.Dependency {
  if ProcessInfo.useLocalDeps { return .package(path: path) }
  return .package(url: url, from: version)
}

let commonShellDependency = localOrRemote(
  path: "../../../../../swift-universal/private/universal/domain/build/spm/common-shell",
  url: "https://github.com/swift-universal/common-shell.git",
  from: "0.0.1"
)
let commonProcessDependency = localOrRemote(
  path: "../../../../../swift-universal/private/universal/domain/build/spm/common-process",
  url: "https://github.com/swift-universal/common-process.git",
  from: "0.3.5"
)
let pklSwiftDependency = Package.Dependency.package(
  url: "https://github.com/apple/pkl-swift",
  from: "0.8.2"
)

let package = Package(
  name: "vaporize@wrkstrm-core-cli",
  platforms: [
    .macOS("26.0")
  ],
  products: [
    .library(name: "AppleProjectSpecCore", targets: ["AppleProjectSpecCore"]),
    .library(name: "SwiftCLIInstaller", targets: ["SwiftCLIInstaller"]),
    .library(name: "SwiftAppInstaller", targets: ["SwiftAppInstaller"]),
    .executable(name: "vaporize@wrkstrm-core.cli", targets: ["VaporizeCLI"]),
  ],
  dependencies: [
    commonProcessDependency,
    commonShellDependency,
    pklSwiftDependency,
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
    .target(
      name: "SwiftCLIInstaller",
      dependencies: [
        .product(name: "CommonShell", package: "common-shell"),
        .product(name: "CommonProcess", package: "common-process"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "sources/swift-cli-installer"
    ),
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
        "SwiftCLIInstaller",
        "SwiftAppInstaller",
        .product(name: "CommonShell", package: "common-shell"),
        .product(name: "CommonProcess", package: "common-process"),
        .product(name: "CommonProcessExecutionKit", package: "common-process"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "sources/vaporize-cli"
    ),
    .target(
      name: "VaporizeTestSupport",
      dependencies: ["AppleProjectSpecCore"],
      path: "tests/vaporize-test-support"
    ),
    .testTarget(
      name: "VaporizeCUJ01SwiftPMCLITests",
      dependencies: [
        "SwiftCLIInstaller",
        "VaporizeCLI",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "tests/cuj-01-swiftpm-cli"
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
      dependencies: ["VaporizeCLI"],
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
