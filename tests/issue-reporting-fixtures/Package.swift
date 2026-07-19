// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "vaporize-issue-reporting-fixtures",
  platforms: [.macOS("26.0")],
  products: [
    .executable(
      name: "fixture.cli@vaporize-tests.clia.sh",
      targets: ["FixtureCLI"]
    )
  ],
  dependencies: [
    .package(path: "../.."),
    .package(
      url: "https://github.com/pointfreeco/swift-issue-reporting",
      exact: "2.0.0"
    ),
  ],
  targets: [
    .executableTarget(
      name: "FixtureCLI",
      path: "Sources/FixtureCLI"
    ),
    .target(
      name: "FixtureIssueSupport",
      dependencies: [
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
        .product(name: "VaporizeIssueReporting", package: "vaporize@wrkstrm-core.cli"),
      ],
      path: "Sources/FixtureIssueSupport"
    ),
    .testTarget(
      name: "SwiftTestingUnexpectedTests",
      dependencies: ["FixtureIssueSupport"],
      path: "Tests/SwiftTestingUnexpectedTests"
    ),
    .testTarget(
      name: "SwiftTestingExpectedTests",
      dependencies: ["FixtureIssueSupport"],
      path: "Tests/SwiftTestingExpectedTests"
    ),
    .testTarget(
      name: "GreenTests",
      path: "Tests/GreenTests"
    ),
  ]
)
