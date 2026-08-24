import XcodeProjectDefinitionCore
import ArgumentParser
import Foundation
import Testing
import VaporizeTestSupport

@testable import VaporizeCLI

@Test("CUJ-28 parses Sparkle config generation mode")
func parsesSparkleConfigGenerationMode() throws {
  let command = try VaporizeCLI.parse([
    "generate-sparkle-config",
    "--pkl-path",
    "project.pkl",
    "--target",
    "TinyTool",
    "--output",
    "SparkleConfig.swift",
  ])

  #expect(command.mode == .generateSparkleConfig)
  #expect(command.pklPath == "project.pkl")
  #expect(command.targetName == "TinyTool")
  #expect(command.sparkleConfigOutputPath == "SparkleConfig.swift")
}

@Test("CUJ-28 renders compiled-in SparkleConfig.swift for a tool target with full release identity")
func rendersSparkleConfigForToolTargetWithFullReleaseIdentity() throws {
  let spec = try decodeXcodeProjectYML(sparkleToolYML)
  let rendered = try XcodeProjectSparkleConfigRenderer.render(
    spec: spec,
    targetName: "TinyTool",
    sourcePath: "project.pkl"
  )

  #expect(rendered.contains("import Foundation"))
  #expect(rendered.contains("import SwiftCLIUpdater"))
  #expect(rendered.contains("extension SparkleConfig {"))
  #expect(rendered.contains("public static let generated = SparkleConfig("))
  #expect(rendered.contains("productName: \"tiny-release-tool\","))
  #expect(
    rendered.contains(
      "feedURL: URL(string: \"https://updates.example.com/tiny-release-tool/appcast.xml\")!,"
    )
  )
  #expect(rendered.contains("publicEDKeyBase64: \"tiny-ed25519-public-key\","))
  #expect(rendered.contains("currentVersion: \"1.2.3\""))
  #expect(rendered.contains("GENERATED FROM PKL"))
  #expect(rendered.contains("Source manifest: project.pkl"))
}

@Test("CUJ-28 falls back to the target name when PRODUCT_NAME is not set")
func fallsBackToTargetNameWithoutProductNameSetting() throws {
  var spec = try decodeXcodeProjectYML(sparkleToolYML)
  spec.targets["TinyTool"]?.settings = nil
  let rendered = try XcodeProjectSparkleConfigRenderer.render(spec: spec, targetName: "TinyTool")

  #expect(rendered.contains("productName: \"TinyTool\","))
}

@Test("CUJ-28 renders SparkleConfig from an evaluated project.pkl fixture")
func rendersSparkleConfigFromEvaluatedPklFixture() async throws {
  let fixture = try makeSparkleToolPklFixture()
  defer { try? FileManager.default.removeItem(at: fixture.temporaryDirectory) }

  let spec = try await XcodeProjectPklLoader.load(url: fixture.projectPkl)
  let rendered = try XcodeProjectSparkleConfigRenderer.render(
    spec: spec,
    targetName: "TinyTool",
    sourcePath: fixture.projectPkl.path
  )

  #expect(rendered.contains("import SwiftCLIUpdater"))
  #expect(
    rendered.contains(
      "feedURL: URL(string: \"https://updates.example.com/tiny-release-tool/appcast.xml\")!,"
    )
  )
  #expect(rendered.contains("publicEDKeyBase64: \"tiny-ed25519-public-key\","))
  #expect(rendered.contains("currentVersion: \"1.2.3\""))
  #expect(rendered.contains("Source manifest: \(fixture.projectPkl.path)"))
}

@Test("CUJ-28 missing sparklePublicEDKey is a typed error, never a silent emission")
func missingSparklePublicEDKeyIsATypedError() throws {
  var spec = try decodeXcodeProjectYML(sparkleToolYML)
  spec.targets["TinyTool"]?.releaseIdentity?.sparklePublicEDKey = nil

  #expect(
    throws: XcodeProjectSparkleConfigRendererError.missingSparklePublicEDKey(
      targetName: "TinyTool")
  ) {
    try XcodeProjectSparkleConfigRenderer.render(spec: spec, targetName: "TinyTool")
  }
}

@Test("CUJ-28 missing sparkleFeedURL is a typed error")
func missingSparkleFeedURLIsATypedError() throws {
  var spec = try decodeXcodeProjectYML(sparkleToolYML)
  spec.targets["TinyTool"]?.releaseIdentity?.sparkleFeedURL = nil

  #expect(
    throws: XcodeProjectSparkleConfigRendererError.missingSparkleFeedURL(targetName: "TinyTool")
  ) {
    try XcodeProjectSparkleConfigRenderer.render(spec: spec, targetName: "TinyTool")
  }
}

@Test("CUJ-28 non-URL sparkleFeedURL is a typed error")
func invalidSparkleFeedURLIsATypedError() throws {
  var spec = try decodeXcodeProjectYML(sparkleToolYML)
  spec.targets["TinyTool"]?.releaseIdentity?.sparkleFeedURL = "not a url"

  #expect(
    throws: XcodeProjectSparkleConfigRendererError.invalidSparkleFeedURL(
      targetName: "TinyTool",
      sparkleFeedURL: "not a url")
  ) {
    try XcodeProjectSparkleConfigRenderer.render(spec: spec, targetName: "TinyTool")
  }
}

@Test("CUJ-28 missing shortVersion is a typed error")
func missingShortVersionIsATypedError() throws {
  var spec = try decodeXcodeProjectYML(sparkleToolYML)
  spec.targets["TinyTool"]?.releaseIdentity?.shortVersion = nil

  #expect(
    throws: XcodeProjectSparkleConfigRendererError.missingShortVersion(targetName: "TinyTool")
  ) {
    try XcodeProjectSparkleConfigRenderer.render(spec: spec, targetName: "TinyTool")
  }
}

@Test("CUJ-28 missing releaseIdentity is a typed error")
func missingReleaseIdentityIsATypedError() throws {
  var spec = try decodeXcodeProjectYML(sparkleToolYML)
  spec.targets["TinyTool"]?.releaseIdentity = nil

  #expect(
    throws: XcodeProjectSparkleConfigRendererError.missingReleaseIdentity(targetName: "TinyTool")
  ) {
    try XcodeProjectSparkleConfigRenderer.render(spec: spec, targetName: "TinyTool")
  }
}

@Test("CUJ-28 unknown target is a typed error naming the available targets")
func unknownTargetIsATypedError() throws {
  let spec = try decodeXcodeProjectYML(sparkleToolYML)

  #expect(
    throws: XcodeProjectSparkleConfigRendererError.targetNotFound(
      targetName: "NoSuchTool",
      availableTargets: ["TinyTool"])
  ) {
    try XcodeProjectSparkleConfigRenderer.render(spec: spec, targetName: "NoSuchTool")
  }
}

private struct SparkleToolPklFixture {
  var temporaryDirectory: URL
  var projectPkl: URL
}

private func makeSparkleToolPklFixture() throws -> SparkleToolPklFixture {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-sparkle-config-generation-\(UUID().uuidString)")
  try FileManager.default.createDirectory(
    at: temporaryDirectory,
    withIntermediateDirectories: true
  )

  let spec = try decodeXcodeProjectYML(sparkleToolYML)
  let projectPkl = temporaryDirectory.appendingPathComponent("project.pkl")
  let schemaAmendsPath = relativePathForPklAmends(
    from: projectPkl.deletingLastPathComponent(),
    to: xcodeProjectDefinitionPklSchemaURL
  )
  let data = XcodeProjectPklRenderer.renderData(
    spec: spec,
    schemaAmendsPath: schemaAmendsPath,
    sourcePath: "project.yml"
  )
  try data.write(to: projectPkl)

  return SparkleToolPklFixture(
    temporaryDirectory: temporaryDirectory,
    projectPkl: projectPkl
  )
}

private let sparkleToolYML = """
  name: tiny-sparkle-tool
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
        sparklePublicEDKey: tiny-ed25519-public-key
      settings:
        base:
          PRODUCT_NAME: tiny-release-tool
          CODE_SIGNING_ALLOWED: false
          CODE_SIGNING_REQUIRED: false
  """
