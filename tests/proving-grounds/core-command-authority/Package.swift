// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "vaporize-core-command-authority-proving-ground",
  targets: [
    .testTarget(
      name: "CoreCommandAuthorityProvingGroundTests",
      path: "tests"
    )
  ]
)

