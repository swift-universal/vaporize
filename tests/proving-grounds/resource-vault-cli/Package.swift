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
  targets: [
    .executableTarget(
      name: "ResourceVaultCLI",
      path: "sources/resource-vault-cli",
      resources: [
        .copy("resources"),
      ]
    ),
  ]
)
