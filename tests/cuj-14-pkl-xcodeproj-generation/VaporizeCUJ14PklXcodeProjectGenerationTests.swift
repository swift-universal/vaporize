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
    #expect(targetName == "TinyFramework")
    #expect(type == "framework")
  } catch {
    Issue.record("Unexpected error: \(error).")
  }
}

private struct TinyPklAppFixture {
  var temporaryDirectory: URL
  var outputDirectory: URL
  var projectPkl: URL
}

private struct TinyPklToolFixture {
  var temporaryDirectory: URL
  var outputDirectory: URL
  var projectPkl: URL
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

private let tinyUnsupportedTargetYML = """
name: tiny-unsupported
targets:
  TinyFramework:
    type: framework
    platform: macOS
    sources:
      - path: Sources/framework
"""
