import Foundation

public struct XcodeGenToPklParityProvingGround: Sendable {
  public var slug: String
  public var expectedProjectName: String
  public var expectedTargetNames: [String]
  public var expectedPackageNames: [String]
  public var expectedSchemeNames: [String]

  public init(
    slug: String,
    expectedProjectName: String,
    expectedTargetNames: [String],
    expectedPackageNames: [String] = [],
    expectedSchemeNames: [String]
  ) {
    self.slug = slug
    self.expectedProjectName = expectedProjectName
    self.expectedTargetNames = expectedTargetNames
    self.expectedPackageNames = expectedPackageNames
    self.expectedSchemeNames = expectedSchemeNames
  }

  public var rootURL: URL {
    vaporizeTestPackageRoot
      .appendingPathComponent("tests/proving-grounds/xcodegen-to-pkl-parity")
      .appendingPathComponent(slug)
      .standardizedFileURL
  }

  public var projectYMLURL: URL {
    rootURL.appendingPathComponent("project.yml")
  }

  public var projectPklURL: URL {
    rootURL.appendingPathComponent("project.pkl")
  }
}

public struct PklProjectGenerationBeyondProvingGround: Sendable {
  public var slug: String
  public var expectedProjectName: String
  public var expectedTargetNames: [String]
  public var expectedPackageNames: [String]
  public var expectedSchemeNames: [String]
  public var expectedSourceFileCount: Int
  public var expectedResourceFileCount: Int
  public var expectedPBXProjFragments: [String]
  public var expectedSchemeFragments: [String]

  public init(
    slug: String,
    expectedProjectName: String,
    expectedTargetNames: [String],
    expectedPackageNames: [String] = [],
    expectedSchemeNames: [String],
    expectedSourceFileCount: Int,
    expectedResourceFileCount: Int,
    expectedPBXProjFragments: [String],
    expectedSchemeFragments: [String]
  ) {
    self.slug = slug
    self.expectedProjectName = expectedProjectName
    self.expectedTargetNames = expectedTargetNames
    self.expectedPackageNames = expectedPackageNames
    self.expectedSchemeNames = expectedSchemeNames
    self.expectedSourceFileCount = expectedSourceFileCount
    self.expectedResourceFileCount = expectedResourceFileCount
    self.expectedPBXProjFragments = expectedPBXProjFragments
    self.expectedSchemeFragments = expectedSchemeFragments
  }

  public var rootURL: URL {
    vaporizeTestPackageRoot
      .appendingPathComponent("tests/proving-grounds/pkl-project-generation")
      .appendingPathComponent(slug)
      .standardizedFileURL
  }

  public var projectPklURL: URL {
    rootURL.appendingPathComponent("project.pkl")
  }

  public var passportJSONURL: URL {
    rootURL.appendingPathComponent("proving-ground-passport.json")
  }
}

public let xcodeGenToPklParityProvingGrounds: [XcodeGenToPklParityProvingGround] = [
  XcodeGenToPklParityProvingGround(
    slug: "minimal-mac-app",
    expectedProjectName: "parity-minimal-mac-app",
    expectedTargetNames: ["MinimalMacApp"],
    expectedSchemeNames: ["MinimalMacApp"]
  ),
  XcodeGenToPklParityProvingGround(
    slug: "configured-release-app",
    expectedProjectName: "parity-configured-release-app",
    expectedTargetNames: ["ConfiguredReleaseApp"],
    expectedSchemeNames: ["ConfiguredReleaseApp"]
  ),
  XcodeGenToPklParityProvingGround(
    slug: "package-framework-suite",
    expectedProjectName: "parity-package-framework-suite",
    expectedTargetNames: ["PackageApp", "SharedFramework"],
    expectedPackageNames: ["LocalSupport", "RemoteAnalytics"],
    expectedSchemeNames: ["PackageApp"]
  ),
  XcodeGenToPklParityProvingGround(
    slug: "test-host-suite",
    expectedProjectName: "parity-test-host-suite",
    expectedTargetNames: ["HostApp", "HostCore", "HostCoreTests"],
    expectedSchemeNames: ["HostApp"]
  ),
  XcodeGenToPklParityProvingGround(
    slug: "tooling-cli",
    expectedProjectName: "parity-tooling-cli",
    expectedTargetNames: ["ParityTool"],
    expectedSchemeNames: ["ParityTool"]
  ),
]

public let pklProjectGenerationBeyondProvingGrounds: [PklProjectGenerationBeyondProvingGround] = [
  PklProjectGenerationBeyondProvingGround(
    slug: "beyond-resourceful-sparkle-app",
    expectedProjectName: "pkl-beyond-resourceful-sparkle-app",
    expectedTargetNames: ["ResourcefulSparkleApp"],
    expectedSchemeNames: ["ResourcefulSparkleApp"],
    expectedSourceFileCount: 1,
    expectedResourceFileCount: 1,
    expectedPBXProjFragments: [
      "Assets.xcassets in Resources",
      "INFOPLIST_KEY_SUFeedURL = \"https://updates.example.com/resourceful-sparkle-app/appcast.xml\";",
      "INFOPLIST_KEY_SUPublicEDKey = \"resourceful-sparkle-app-ed25519\";",
      "INFOPLIST_KEY_VaporizeProductBuildSHA = sparkleabc;",
      "Stage Sparkle Draft",
    ],
    expectedSchemeFragments: [
      "BuildableName = \"ResourcefulSparkleApp.app\"",
      "ReferencedContainer = \"container:BeyondGenerated.xcodeproj\"",
      "customWorkingDirectory = \"$(PROJECT_DIR)\"",
    ]
  ),
  PklProjectGenerationBeyondProvingGround(
    slug: "beyond-release-tool",
    expectedProjectName: "pkl-beyond-release-tool",
    expectedTargetNames: ["ReleaseTool"],
    expectedSchemeNames: ["ReleaseTool"],
    expectedSourceFileCount: 1,
    expectedResourceFileCount: 0,
    expectedPBXProjFragments: [
      "productType = \"com.apple.product-type.tool\";",
      "explicitFileType = \"compiled.mach-o.executable\";",
      "path = \"pkl-beyond-release-tool\";",
      "GENERATE_INFOPLIST_FILE = \"YES\";",
      "INFOPLIST_KEY_SUFeedURL = \"https://updates.example.com/pkl-beyond-release-tool/appcast.xml\";",
    ],
    expectedSchemeFragments: [
      "BuildableName = \"pkl-beyond-release-tool\"",
      "ReferencedContainer = \"container:BeyondGenerated.xcodeproj\"",
    ]
  ),
]
