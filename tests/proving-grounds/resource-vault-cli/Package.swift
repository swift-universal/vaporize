// swift-tools-version: 6.4
import PackageDescription

let package = Package(
  name: "resource-vault-proving-ground",
  platforms: [.macOS(.v15)],
  products: [
    .executable(
      name: "resource-vault.cli@vaporize-tests.clia.sh",
      targets: ["ResourceVaultCLI"]
    ),
  ],
  dependencies: [
    .package(
      name: "common-log",
      path: "../../../../../../../../swift-universal/private/universal/spm/domain/system/common-log"
    ),
    .package(url: "https://github.com/pointfreeco/swift-issue-reporting", exact: "2.0.0"),
  ],
  targets: [
    .executableTarget(
      name: "ResourceVaultCLI",
      dependencies: [
        .product(name: "CommonLog", package: "common-log"),
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
      ],
      path: "sources/resource-vault-cli",
      resources: [
        .copy("resources"),
      ]
    ),
  ]
)
