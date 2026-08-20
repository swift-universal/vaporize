// swift-tools-version: 6.4
import PackageDescription

let package = Package(
  name: "PortableFixtureSupport",
  platforms: [.macOS(.v26)],
  products: [
    .library(name: "PortableFixtureSupport", targets: ["PortableFixtureSupport"]),
  ],
  targets: [
    .target(name: "PortableFixtureSupport"),
  ]
)
