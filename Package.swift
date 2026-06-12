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
    .testTarget(
      name: "SwiftCLIInstallerTests",
      dependencies: ["SwiftCLIInstaller"],
      path: "tests/swift-cli-installer-tests"
    ),
    .testTarget(
      name: "SwiftAppInstallerTests",
      dependencies: ["SwiftAppInstaller"],
      path: "tests/swift-app-installer-tests"
    ),
    .testTarget(
      name: "VaporizeCLITests",
      dependencies: [
        "AppleProjectSpecCore",
        "VaporizeCLI",
        .product(name: "CommonProcess", package: "common-process"),
      ],
      path: "tests/vaporize-cli-tests"
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
