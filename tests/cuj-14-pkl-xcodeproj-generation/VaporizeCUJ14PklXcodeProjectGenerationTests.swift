import AppleProjectSpecCore
import ArgumentParser
import Foundation
import Testing
import VaporizeTestSupport

@testable import VaporizeCLI

@Test("CUJ-14 parses Pkl Xcode project generation mode")
func parsesPklXcodeProjectGenerationMode() throws {
  let command = try VaporizeCLI.parse([
    "generate-xcodeproj",
    "--pkl-path",
    "project.pkl",
    "--output-path",
    "Generated.xcodeproj",
    "--format",
    "json",
  ])

  #expect(command.mode == .generateXcodeProject)
  #expect(command.pklPath == "project.pkl")
  #expect(command.generatedOutputPath == "Generated.xcodeproj")
  #expect(command.vaporOutputFormat == .json)
}

@Test("CUJ-14 generates .xcodeproj world-state from AppleProjectSpec Pkl")
func generatesXcodeProjectWorldStateFromPkl() async throws {
  let fixture = try makeTinyPklAppFixture()
  defer { try? FileManager.default.removeItem(at: fixture.temporaryDirectory) }
  defer { try? FileManager.default.removeItem(at: fixture.outputDirectory) }

  let outputURL = fixture.outputDirectory.appendingPathComponent("TinyGenerated.xcodeproj")
  let receipt = try await AppleProjectXcodeProjectGenerator.generate(
    pklURL: fixture.projectPkl,
    outputURL: outputURL,
    requestId: "cuj-14-pkl-xcodeproj-generation"
  )

  let pbxprojData = try Data(contentsOf: outputURL.appendingPathComponent("project.pbxproj"))
  let pbxproj = String(decoding: pbxprojData, as: UTF8.self)
  let workspacePath = outputURL
    .appendingPathComponent("project.xcworkspace")
    .appendingPathComponent("contents.xcworkspacedata")

  #expect(FileManager.default.fileExists(atPath: receipt.pbxprojPath))
  #expect(FileManager.default.fileExists(atPath: workspacePath.path))
  #expect(receipt.receiptKind == "vaporize-pkl-xcodeproj-generation")
  #expect(receipt.generationPhase == "pkl-to-xcodeproj-world-state")
  #expect(receipt.generatorStatus == "xcodeproj-world-state-generated")
  #expect(receipt.buildableWorldStateGenerated)
  #expect(receipt.xcodeProjectGenerated)
  #expect(receipt.projectName == "tiny-pkl-app")
  #expect(receipt.targetNames == ["TinyApp"])
  #expect(receipt.sourceFileCount == 1)
  #expect(receipt.resourceFileCount == 1)
  #expect(pbxproj.contains("isa = PBXProject;"))
  #expect(pbxproj.contains("isa = PBXNativeTarget;"))
  #expect(pbxproj.contains("TinyApp.swift in Sources"))
  #expect(pbxproj.contains("Assets.xcassets in Resources"))
  #expect(pbxproj.contains("Info.plist"))
  #expect(pbxproj.contains("Deploy to Temp"))
  #expect(pbxproj.contains("PRODUCT_BUNDLE_IDENTIFIER = \"com.wrkstrm.tiny-pkl-app\";"))
  #expect(pbxproj.contains("MARKETING_VERSION = 0.0.1;"))
  #expect(pbxproj.contains("CURRENT_PROJECT_VERSION = 1;"))
  #expect(pbxproj.contains("INFOPLIST_KEY_SUFeedURL = \"https://updates.example.com/tiny-pkl-app/appcast.xml\";"))
  #expect(pbxproj.contains("INFOPLIST_KEY_SUPublicEDKey = \"tiny-ed25519-public-key\";"))
  #expect(pbxproj.contains("INFOPLIST_KEY_VaporizeProductBuildSHA = abc123;"))
  #expect(pbxproj.contains("tiny-pkl-app.app"))
}

@Test("CUJ-14 preserves multiple Pkl source roots in generated Xcode project")
func preservesMultiplePklSourceRootsInGeneratedXcodeProject() async throws {
  let fixture = try makeMultiSourcePklAppFixture()
  defer { try? FileManager.default.removeItem(at: fixture.temporaryDirectory) }
  defer { try? FileManager.default.removeItem(at: fixture.outputDirectory) }

  let outputURL = fixture.outputDirectory.appendingPathComponent("MultiSourceGenerated.xcodeproj")
  let receipt = try await AppleProjectXcodeProjectGenerator.generate(
    pklURL: fixture.projectPkl,
    outputURL: outputURL,
    requestId: "cuj-14-multiple-pkl-source-roots"
  )

  let pbxprojData = try Data(contentsOf: outputURL.appendingPathComponent("project.pbxproj"))
  let pbxproj = String(decoding: pbxprojData, as: UTF8.self)

  #expect(receipt.projectName == "multi-source-pkl-app")
  #expect(receipt.targetNames == ["MultiSourceApp"])
  #expect(receipt.sourceFileCount == 2)
  #expect(pbxproj.contains("MacApp.swift in Sources"))
  #expect(pbxproj.contains("SharedFeature.swift in Sources"))
  #expect(pbxproj.contains("path = \"../shared/SharedFeature.swift\";"))
  #expect(!pbxproj.contains("path = \"SharedFeature.swift\";"))
}

@Test("CUJ-14 generates Xcode tool targets with typed release identity from Pkl")
func generatesToolTargetReleaseIdentityFromPkl() async throws {
  let fixture = try makeTinyPklToolFixture()
  defer { try? FileManager.default.removeItem(at: fixture.temporaryDirectory) }
  defer { try? FileManager.default.removeItem(at: fixture.outputDirectory) }

  let outputURL = fixture.outputDirectory.appendingPathComponent("TinyToolGenerated.xcodeproj")
  let receipt = try await AppleProjectXcodeProjectGenerator.generate(
    pklURL: fixture.projectPkl,
    outputURL: outputURL,
    requestId: "cuj-14-pkl-tool-release-identity"
  )

  let pbxprojData = try Data(contentsOf: outputURL.appendingPathComponent("project.pbxproj"))
  let pbxproj = String(decoding: pbxprojData, as: UTF8.self)

  #expect(receipt.targetNames == ["TinyTool"])
  #expect(receipt.sourceFileCount == 1)
  #expect(receipt.resourceFileCount == 0)
  #expect(pbxproj.contains("productType = \"com.apple.product-type.tool\";"))
  #expect(pbxproj.contains("explicitFileType = \"compiled.mach-o.executable\";"))
  #expect(pbxproj.contains("path = \"tiny-release-tool\";"))
  #expect(!pbxproj.contains("tiny-release-tool.app"))
  #expect(pbxproj.contains("PRODUCT_NAME = \"tiny-release-tool\";"))
  #expect(pbxproj.contains("PRODUCT_BUNDLE_IDENTIFIER = \"com.wrkstrm.tiny-release-tool\";"))
  #expect(pbxproj.contains("MARKETING_VERSION = 1.2.3;"))
  #expect(pbxproj.contains("CURRENT_PROJECT_VERSION = 456;"))
  #expect(pbxproj.contains("GENERATE_INFOPLIST_FILE = \"YES\";"))
  #expect(pbxproj.contains("INFOPLIST_KEY_SUFeedURL = \"https://updates.example.com/tiny-release-tool/appcast.xml\";"))
}

@Test("CUJ-14 Xcode project rendering is deterministic")
func xcodeProjectRenderingIsDeterministic() throws {
  let fixture = try makeTinyPklAppFixture()
  defer { try? FileManager.default.removeItem(at: fixture.temporaryDirectory) }

  let spec = try decodeAppleProjectYML(tinyPklAppYML)
  let first = try AppleProjectXcodeProjectRenderer.render(
    spec: spec,
    projectDirectory: fixture.temporaryDirectory
  )
  let second = try AppleProjectXcodeProjectRenderer.render(
    spec: spec,
    projectDirectory: fixture.temporaryDirectory
  )

  #expect(first == second)
  #expect(first.sourceFileCount == 1)
  #expect(first.resourceFileCount == 1)
}

@Test("CUJ-14 generates framework app test graph and shared scheme from Pkl")
func generatesFrameworkAppTestGraphAndSharedSchemeFromPkl() async throws {
  let fixture = try makePklProjectGenerationProvingGroundFixture()
  defer { try? FileManager.default.removeItem(at: fixture.outputDirectory) }

  let manifestData = try Data(contentsOf: fixture.passportJSON)
  let manifest = try #require(JSONSerialization.jsonObject(with: manifestData) as? [String: Any])

  let outputURL = fixture.outputDirectory.appendingPathComponent("PklGroundGenerated.xcodeproj")
  let receipt = try await AppleProjectXcodeProjectGenerator.generate(
    pklURL: fixture.projectPkl,
    outputURL: outputURL,
    requestId: "cuj-14-pkl-project-generation-proving-ground"
  )

  let pbxprojData = try Data(contentsOf: outputURL.appendingPathComponent("project.pbxproj"))
  let pbxproj = String(decoding: pbxprojData, as: UTF8.self)
  let schemeURL = outputURL
    .appendingPathComponent("xcshareddata")
    .appendingPathComponent("xcschemes")
    .appendingPathComponent("pkl-project-generation-proving-ground.xcscheme")
  let scheme = try String(contentsOf: schemeURL, encoding: .utf8)

  #expect(manifest["documentKind"] as? String == "vaporize-pkl-project-generation-proving-ground")
  #expect(manifest["provingGroundSlug"] as? String == "pkl-project-generation")
  #expect(manifest["projectSpecRef"] as? String == "tests/proving-grounds/pkl-project-generation/project.pkl")
  #expect(manifest["targetableTestBundle"] as? String == "VaporizeCUJ14PklXcodeProjectGenerationTests")
  #expect(receipt.projectName == "pkl-project-generation-proving-ground")
  #expect(receipt.targetCount == 3)
  #expect(receipt.packageCount == 1)
  #expect(receipt.schemeCount == 1)
  #expect(receipt.targetNames == ["PklGroundApp", "PklGroundCore", "PklGroundCoreTests"])
  #expect(receipt.sourceFileCount == 3)
  #expect(receipt.resourceFileCount == 0)
  #expect(receipt.generatedByteCount > pbxprojData.count)
  #expect(pbxproj.contains("productType = \"com.apple.product-type.framework\";"))
  #expect(pbxproj.contains("productType = \"com.apple.product-type.bundle.unit-test\";"))
  #expect(pbxproj.contains("PklGroundCore.framework in Frameworks"))
  #expect(pbxproj.contains("PklGroundCore.framework in Embed Frameworks"))
  #expect(pbxproj.contains("PBXContainerItemProxy"))
  #expect(pbxproj.contains("PBXTargetDependency"))
  #expect(pbxproj.contains("PBXCopyFilesBuildPhase"))
  #expect(pbxproj.contains("PklGroundSupport in Frameworks"))
  #expect(pbxproj.contains("PklGroundCoreTests.xctest"))
  #expect(pbxproj.contains("BUNDLE_LOADER = \"$(TEST_HOST)\";"))
  #expect(scheme.contains("<BuildAction"))
  #expect(scheme.contains("<TestAction"))
  #expect(scheme.contains("<LaunchAction"))
  #expect(scheme.contains("BuildableName = \"PklGroundApp.app\""))
  #expect(scheme.contains("BuildableName = \"PklGroundCoreTests.xctest\""))
  #expect(scheme.contains("ReferencedContainer = \"container:PklGroundGenerated.xcodeproj\""))
  #expect(scheme.contains("customWorkingDirectory = \"$(PROJECT_DIR)\""))
}

@Test("CUJ-14 generates above-parity Pkl project-generation proving grounds")
func generatesAboveParityPklProjectGenerationProvingGrounds() async throws {
  #expect(pklProjectGenerationBeyondProvingGrounds.count >= 2)

  for ground in pklProjectGenerationBeyondProvingGrounds {
    let outputDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("vaporize-\(ground.slug)-xcodeproj-output-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: outputDirectory) }

    let manifestData = try Data(contentsOf: ground.passportJSONURL)
    let manifest = try #require(JSONSerialization.jsonObject(with: manifestData) as? [String: Any])
    let outputURL = outputDirectory.appendingPathComponent("BeyondGenerated.xcodeproj")
    let receipt = try await AppleProjectXcodeProjectGenerator.generate(
      pklURL: ground.projectPklURL,
      outputURL: outputURL,
      requestId: "cuj-14-above-parity-\(ground.slug)"
    )

    let pbxprojData = try Data(contentsOf: outputURL.appendingPathComponent("project.pbxproj"))
    let pbxproj = String(decoding: pbxprojData, as: UTF8.self)

    #expect(manifest["documentKind"] as? String == "vaporize-pkl-project-generation-beyond-proving-ground")
    #expect(manifest["provingGroundSlug"] as? String == ground.slug)
    #expect(manifest["targetableTestBundle"] as? String == "VaporizeCUJ14PklXcodeProjectGenerationTests")
    #expect(receipt.projectName == ground.expectedProjectName)
    #expect(receipt.targetNames == ground.expectedTargetNames)
    #expect(receipt.packageNames == ground.expectedPackageNames)
    #expect(receipt.schemeCount == ground.expectedSchemeNames.count)
    #expect(receipt.sourceFileCount == ground.expectedSourceFileCount)
    #expect(receipt.resourceFileCount == ground.expectedResourceFileCount)
    for fragment in ground.expectedPBXProjFragments {
      #expect(pbxproj.contains(fragment))
    }
    for schemeName in ground.expectedSchemeNames {
      let schemeURL = outputURL
        .appendingPathComponent("xcshareddata")
        .appendingPathComponent("xcschemes")
        .appendingPathComponent("\(schemeName).xcscheme")
      let scheme = try String(contentsOf: schemeURL, encoding: .utf8)
      for fragment in ground.expectedSchemeFragments {
        #expect(scheme.contains(fragment))
      }
    }
  }
}

@Test("CUJ-14 rejects unsupported Xcode target types from Pkl")
func rejectsUnsupportedXcodeTargetTypesFromPkl() throws {
  let spec = try decodeAppleProjectYML(tinyUnsupportedTargetYML)
  do {
    _ = try AppleProjectXcodeProjectRenderer.render(
      spec: spec,
      projectDirectory: FileManager.default.temporaryDirectory
    )
    Issue.record("Expected unsupported target type to fail.")
  } catch AppleProjectXcodeProjectGenerationError.unsupportedTargetType(let targetName, let type) {
    #expect(targetName == "TinyLibrary")
    #expect(type == "staticLibrary")
  } catch {
    Issue.record("Unexpected error: \(error).")
  }
}

private struct TinyPklAppFixture {
  var temporaryDirectory: URL
  var outputDirectory: URL
  var projectPkl: URL
}

private struct MultiSourcePklAppFixture {
  var temporaryDirectory: URL
  var outputDirectory: URL
  var projectPkl: URL
}

private struct TinyPklToolFixture {
  var temporaryDirectory: URL
  var outputDirectory: URL
  var projectPkl: URL
}

private struct TinyPklSuiteFixture {
  var temporaryDirectory: URL
  var outputDirectory: URL
  var projectPkl: URL
}

private struct PklProjectGenerationProvingGroundFixture {
  var rootDirectory: URL
  var outputDirectory: URL
  var projectPkl: URL
  var passportJSON: URL
}

private func makePklProjectGenerationProvingGroundFixture() throws -> PklProjectGenerationProvingGroundFixture {
  let rootDirectory = vaporizeTestPackageRoot
    .appendingPathComponent("tests/proving-grounds/pkl-project-generation")
    .standardizedFileURL
  let outputDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-pkl-project-generation-proving-ground-output-\(UUID().uuidString)")
  let projectPkl = rootDirectory.appendingPathComponent("project.pkl")
  let passportJSON = rootDirectory.appendingPathComponent("proving-ground-passport.json")

  guard FileManager.default.fileExists(atPath: projectPkl.path) else {
    throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: projectPkl.path])
  }
  guard FileManager.default.fileExists(atPath: passportJSON.path) else {
    throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: passportJSON.path])
  }

  return PklProjectGenerationProvingGroundFixture(
    rootDirectory: rootDirectory,
    outputDirectory: outputDirectory,
    projectPkl: projectPkl,
    passportJSON: passportJSON
  )
}

private func makeTinyPklAppFixture() throws -> TinyPklAppFixture {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-pkl-xcodeproj-generation-\(UUID().uuidString)")
  let outputDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-pkl-xcodeproj-output-\(UUID().uuidString)")
  let sourceDirectory = temporaryDirectory.appendingPathComponent("Sources/mac-app")
  let assetDirectory = sourceDirectory.appendingPathComponent("Assets.xcassets")
  try FileManager.default.createDirectory(
    at: assetDirectory,
    withIntermediateDirectories: true
  )
  try Data("import SwiftUI\n@main struct TinyApp: App { var body: some Scene { WindowGroup { Text(\"Tiny\") } } }\n".utf8)
    .write(to: sourceDirectory.appendingPathComponent("TinyApp.swift"))
  try Data("""
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
  </dict>
  </plist>
  """.utf8).write(to: sourceDirectory.appendingPathComponent("Info.plist"))
  try Data("{\"info\":{\"author\":\"xcode\"}}\n".utf8)
    .write(to: assetDirectory.appendingPathComponent("Contents.json"))

  let spec = try decodeAppleProjectYML(tinyPklAppYML)
  let projectPkl = temporaryDirectory.appendingPathComponent("project.pkl")
  let schemaAmendsPath = relativePathForPklAmends(
    from: projectPkl.deletingLastPathComponent(),
    to: appleProjectSpecPklSchemaURL
  )
  let data = AppleProjectPklRenderer.renderData(
    spec: spec,
    schemaAmendsPath: schemaAmendsPath,
    sourcePath: "project.yml"
  )
  try data.write(to: projectPkl)

  return TinyPklAppFixture(
    temporaryDirectory: temporaryDirectory,
    outputDirectory: outputDirectory,
    projectPkl: projectPkl
  )
}

private func makeMultiSourcePklAppFixture() throws -> MultiSourcePklAppFixture {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-pkl-multiple-source-roots-\(UUID().uuidString)")
  let outputDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-pkl-multiple-source-roots-output-\(UUID().uuidString)")
  let macAppDirectory = temporaryDirectory.appendingPathComponent("Sources/mac-app")
  let sharedDirectory = temporaryDirectory.appendingPathComponent("Sources/shared")

  try FileManager.default.createDirectory(at: macAppDirectory, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: sharedDirectory, withIntermediateDirectories: true)
  try Data("import SwiftUI\nstruct MacApp {}\n".utf8)
    .write(to: macAppDirectory.appendingPathComponent("MacApp.swift"))
  try Data("public struct SharedFeature {}\n".utf8)
    .write(to: sharedDirectory.appendingPathComponent("SharedFeature.swift"))
  try Data("<?xml version=\"1.0\"?><plist version=\"1.0\"><dict/></plist>\n".utf8)
    .write(to: macAppDirectory.appendingPathComponent("Info.plist"))

  let projectPkl = temporaryDirectory.appendingPathComponent("project.pkl")
  let schemaAmendsPath = relativePathForPklAmends(
    from: projectPkl.deletingLastPathComponent(),
    to: appleProjectSpecPklSchemaURL
  )
  try Data("""
  amends "\(schemaAmendsPath)"

  name = "multi-source-pkl-app"

  settings = new {
    base = new {
      ["SWIFT_VERSION"] = 6.4
    }
  }

  targets = new {
    ["MultiSourceApp"] = new {
      type = "application"
      platform = "macOS"
      sources = new {
        new { path = "Sources/mac-app" }
        new { path = "Sources/shared" }
      }
      settings = new {
        base = new {
          ["GENERATE_INFOPLIST_FILE"] = false
          ["INFOPLIST_FILE"] = "Sources/mac-app/Info.plist"
          ["PRODUCT_BUNDLE_IDENTIFIER"] = "com.wrkstrm.multi-source-pkl-app"
          ["PRODUCT_NAME"] = "multi-source-pkl-app"
        }
      }
    }
  }
  """.utf8).write(to: projectPkl)

  return MultiSourcePklAppFixture(
    temporaryDirectory: temporaryDirectory,
    outputDirectory: outputDirectory,
    projectPkl: projectPkl
  )
}

private func makeTinyPklToolFixture() throws -> TinyPklToolFixture {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-pkl-xcodeproj-tool-\(UUID().uuidString)")
  let outputDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-pkl-xcodeproj-tool-output-\(UUID().uuidString)")
  let sourceDirectory = temporaryDirectory.appendingPathComponent("Sources/tool")
  try FileManager.default.createDirectory(
    at: sourceDirectory,
    withIntermediateDirectories: true
  )
  try Data("import Foundation\nprint(\"tiny tool\")\n".utf8)
    .write(to: sourceDirectory.appendingPathComponent("main.swift"))

  let spec = try decodeAppleProjectYML(tinyPklToolYML)
  let projectPkl = temporaryDirectory.appendingPathComponent("project.pkl")
  let schemaAmendsPath = relativePathForPklAmends(
    from: projectPkl.deletingLastPathComponent(),
    to: appleProjectSpecPklSchemaURL
  )
  let data = AppleProjectPklRenderer.renderData(
    spec: spec,
    schemaAmendsPath: schemaAmendsPath,
    sourcePath: "project.yml"
  )
  try data.write(to: projectPkl)

  return TinyPklToolFixture(
    temporaryDirectory: temporaryDirectory,
    outputDirectory: outputDirectory,
    projectPkl: projectPkl
  )
}

private func makeTinyPklSuiteFixture() throws -> TinyPklSuiteFixture {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-pkl-xcodeproj-suite-\(UUID().uuidString)")
  let outputDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-pkl-xcodeproj-suite-output-\(UUID().uuidString)")
  let coreDirectory = temporaryDirectory.appendingPathComponent("Sources/TinyCore")
  let appDirectory = temporaryDirectory.appendingPathComponent("Sources/TinyApp")
  let testDirectory = temporaryDirectory.appendingPathComponent("Tests/TinyCoreTests")
  try FileManager.default.createDirectory(at: coreDirectory, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
  try Data("public enum TinyCore { public static let value = 1 }\n".utf8)
    .write(to: coreDirectory.appendingPathComponent("TinyCore.swift"))
  try Data("import SwiftUI\nimport TinyCore\n@main struct TinyApp: App { var body: some Scene { WindowGroup { Text(\"\\(TinyCore.value)\") } } }\n".utf8)
    .write(to: appDirectory.appendingPathComponent("TinyApp.swift"))
  try Data("import Testing\n@testable import TinyCore\n@Test func tinyCoreValue() { #expect(TinyCore.value == 1) }\n".utf8)
    .write(to: testDirectory.appendingPathComponent("TinyCoreTests.swift"))

  let spec = try decodeAppleProjectYML(tinyPklSuiteYML)
  let projectPkl = temporaryDirectory.appendingPathComponent("project.pkl")
  let schemaAmendsPath = relativePathForPklAmends(
    from: projectPkl.deletingLastPathComponent(),
    to: appleProjectSpecPklSchemaURL
  )
  let data = AppleProjectPklRenderer.renderData(
    spec: spec,
    schemaAmendsPath: schemaAmendsPath,
    sourcePath: "project.yml"
  )
  try data.write(to: projectPkl)

  return TinyPklSuiteFixture(
    temporaryDirectory: temporaryDirectory,
    outputDirectory: outputDirectory,
    projectPkl: projectPkl
  )
}

private let tinyPklAppYML = """
name: tiny-pkl-app
settings:
  base:
    SWIFT_VERSION: "6.4"
targets:
  TinyApp:
    type: application
    platform: macOS
    deploymentTarget: "26.0"
    sources:
      - path: Sources/mac-app
    info:
      path: Sources/mac-app/Info.plist
      properties:
        CFBundleDisplayName: Tiny Pkl App
        NSPrincipalClass: NSApplication
    releaseIdentity:
      bundleIdentifier: com.wrkstrm.tiny-pkl-app
      shortVersion: "0.0.1"
      buildVersion: "1"
      buildSha: abc123
      buildDate: "2026-07-04T00:00:00Z"
      sparkleFeedURL: https://updates.example.com/tiny-pkl-app/appcast.xml
      sparklePublicEDKey: tiny-ed25519-public-key
    settings:
      base:
        PRODUCT_NAME: tiny-pkl-app
        CODE_SIGNING_ALLOWED: false
        CODE_SIGNING_REQUIRED: false
    postBuildScripts:
      - name: Deploy to Temp
        basedOnDependencyAnalysis: false
        script: |
          set -euo pipefail
          echo "deploy tiny-pkl-app"
"""

private let tinyPklToolYML = """
name: tiny-pkl-tool
settings:
  base:
    SWIFT_VERSION: "6.4"
targets:
  TinyTool:
    type: tool
    platform: macOS
    deploymentTarget: "26.0"
    sources:
      - path: Sources/tool
    releaseIdentity:
      bundleIdentifier: com.wrkstrm.tiny-release-tool
      shortVersion: "1.2.3"
      buildVersion: "456"
      generateInfoPlist: true
      sparkleFeedURL: https://updates.example.com/tiny-release-tool/appcast.xml
    settings:
      base:
        PRODUCT_NAME: tiny-release-tool
        CODE_SIGNING_ALLOWED: false
        CODE_SIGNING_REQUIRED: false
"""

private let tinyPklSuiteYML = """
name: tiny-pkl-suite
settings:
  base:
    SWIFT_VERSION: "6.4"
packages:
  TinySupport:
    path: Packages/TinySupport
targets:
  TinyCore:
    type: framework
    platform: macOS
    deploymentTarget: "26.0"
    sources:
      - path: Sources/TinyCore
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.wrkstrm.tiny-pkl-suite.core
        PRODUCT_NAME: TinyCore
        PRODUCT_MODULE_NAME: TinyCore
        CODE_SIGNING_ALLOWED: false
        CODE_SIGNING_REQUIRED: false
  TinyApp:
    type: application
    platform: macOS
    deploymentTarget: "26.0"
    sources:
      - path: Sources/TinyApp
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.wrkstrm.tiny-pkl-suite
        PRODUCT_NAME: TinyApp
        PRODUCT_MODULE_NAME: TinyApp
        CODE_SIGNING_ALLOWED: false
        CODE_SIGNING_REQUIRED: false
    dependencies:
      - target: TinyCore
      - package: TinySupport
        product: TinySupport
  TinyCoreTests:
    type: bundle.unit-test
    platform: macOS
    deploymentTarget: "26.0"
    sources:
      - path: Tests/TinyCoreTests
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.wrkstrm.tiny-pkl-suite.tests
        PRODUCT_NAME: TinyCoreTests
        PRODUCT_MODULE_NAME: TinyCoreTests
        CODE_SIGNING_ALLOWED: false
        CODE_SIGNING_REQUIRED: false
    dependencies:
      - target: TinyCore
schemes:
  tiny-pkl-suite:
    shared: true
    build:
      targets:
        TinyApp: all
        TinyCoreTests: [test]
    test:
      targets:
        - TinyCoreTests
    run:
      config: Debug
      workingDirectory: $(PROJECT_DIR)
"""

private let tinyUnsupportedTargetYML = """
name: tiny-unsupported
targets:
  TinyLibrary:
    type: staticLibrary
    platform: macOS
    sources:
      - path: Sources/library
"""
