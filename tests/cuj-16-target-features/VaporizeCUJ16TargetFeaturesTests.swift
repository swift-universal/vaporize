import AppleProjectSpecCore
import ArgumentParser
import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-16 inspects target build configs and release features")
func inspectsTargetBuildConfigsAndReleaseFeatures() throws {
  let projectYML = try makeTargetFeaturesFixture()
  defer { try? FileManager.default.removeItem(at: projectYML.deletingLastPathComponent()) }

  let receipt = try VaporizeTargetFeaturesInspector.inspect(
    projectYMLURL: projectYML,
    targetName: "feature-app",
    requestId: "target-features-happy-path"
  )

  #expect(receipt.receiptKind == "vaporize-target-features-inspection")
  #expect(receipt.overallStatus == "pass")
  #expect(receipt.projectName == "feature-fixture")
  #expect(receipt.targetName == "feature-app")
  #expect(receipt.declaredBuildConfigurations.map(\.name) == ["Debug", "Dogfood"])
  #expect(receipt.targetConfigFiles.map(\.configuration) == ["Debug", "Dogfood"])
  #expect(receipt.releaseFeatureManifest.appSlug == "feature-fixture")
  #expect(receipt.releaseFeatureManifest.tierCount == 2)
  #expect(receipt.releaseFeatureManifest.featureFlags == ["FEATURE_DEBUG", "FEATURE_DOGFOOD"])
  #expect(receipt.generatedXcconfigs.allSatisfy { $0.status == "pass" })
  #expect(receipt.releaseFeaturesSwift.status == "pass")
  #expect(receipt.minimums.allSatisfy { $0.status == "pass" })
}

@Test("CUJ-16 infers the single target that declares configFiles")
func infersSingleTargetDeclaringConfigFiles() throws {
  let projectYML = try makeTargetFeaturesFixture()
  defer { try? FileManager.default.removeItem(at: projectYML.deletingLastPathComponent()) }

  let receipt = try VaporizeTargetFeaturesInspector.inspect(
    projectYMLURL: projectYML,
    targetName: nil,
    requestId: "target-features-infer-target"
  )

  #expect(receipt.targetName == "feature-app")
  #expect(receipt.overallStatus == "pass")
}

@Test("CUJ-16 accepts the relocated Wrkstrm-core digikoma-s provenance")
func acceptsRelocatedDigikomaProvenance() throws {
  let projectYML = try makeTargetFeaturesFixture(
    provenance: "release-features.digikoma-s@wrkstrm-core.collective.clia.sh"
  )
  defer { try? FileManager.default.removeItem(at: projectYML.deletingLastPathComponent()) }

  let receipt = try VaporizeTargetFeaturesInspector.inspect(
    projectYMLURL: projectYML,
    targetName: "feature-app",
    requestId: "target-features-relocated-provenance"
  )

  #expect(receipt.overallStatus == "pass")
  #expect(receipt.generatedXcconfigs.allSatisfy(\.generatedByDigikomaReleaseFeatures))
  #expect(receipt.releaseFeaturesSwift.generatedByDigikomaReleaseFeatures == true)
}

@Test("CUJ-16 detects stale generated xcconfig conditions")
func detectsStaleGeneratedXcconfigConditions() throws {
  let projectYML = try makeTargetFeaturesFixture(debugXcconfigOmitsFeature: true)
  defer { try? FileManager.default.removeItem(at: projectYML.deletingLastPathComponent()) }

  let receipt = try VaporizeTargetFeaturesInspector.inspect(
    projectYMLURL: projectYML,
    targetName: "feature-app",
    requestId: "target-features-stale-xcconfig"
  )
  let debugXcconfig = try #require(receipt.generatedXcconfigs.first { $0.xcodeConfig == "Debug" })

  #expect(receipt.overallStatus == "fail")
  #expect(debugXcconfig.status == "fail")
  #expect(debugXcconfig.missingCompilationConditions == ["FEATURE_DEBUG"])
  #expect(receipt.minimums.first { $0.name == "generatedXcconfigs" }?.status == "fail")
  #expect(receipt.minimums.first { $0.name == "featureFlagConditionsMatchManifest" }?.status == "fail")
}

@Test("CUJ-16 detects missing digikoma ReleaseFeatures provenance")
func detectsMissingReleaseFeaturesSwiftProvenance() throws {
  let projectYML = try makeTargetFeaturesFixture(releaseFeaturesSwiftHasProvenance: false)
  defer { try? FileManager.default.removeItem(at: projectYML.deletingLastPathComponent()) }

  let receipt = try VaporizeTargetFeaturesInspector.inspect(
    projectYMLURL: projectYML,
    targetName: "feature-app",
    requestId: "target-features-missing-swift-provenance"
  )

  #expect(receipt.overallStatus == "fail")
  #expect(receipt.releaseFeaturesSwift.exists == true)
  #expect(receipt.releaseFeaturesSwift.generatedByDigikomaReleaseFeatures == false)
  #expect(receipt.minimums.first { $0.name == "releaseFeaturesSwift" }?.status == "fail")
  #expect(receipt.minimums.first { $0.name == "digikomaReleaseFeaturesProvenance" }?.status == "fail")
}

@Test("CUJ-16 parses inspect-target-features CLI arguments")
func parsesInspectTargetFeaturesCLIArguments() throws {
  let command = try VaporizeCLI.parse([
    "inspect-target-features",
    "--path",
    "/workspace/App/project.yml",
    "--target",
    "feature-app",
    "--format",
    "json",
  ])

  #expect(command.mode == .inspectTargetFeatures)
  #expect(command.vaporScanPath == "/workspace/App/project.yml")
  #expect(command.targetName == "feature-app")
  #expect(command.vaporOutputFormat == .json)
}

private func makeTargetFeaturesFixture(
  debugXcconfigOmitsFeature: Bool = false,
  releaseFeaturesSwiftHasProvenance: Bool = true,
  provenance: String = "digikoma-release-features"
) throws -> URL {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-target-features-\(UUID().uuidString)")
  let projectYML = root.appendingPathComponent("project.yml")

  try write(
    """
    name: feature-fixture
    configs:
      Debug: debug
      Dogfood: release
    targets:
      helper:
        type: application
        platform: macOS
      feature-app:
        type: application
        platform: iOS
        configFiles:
          Debug: app/feature-app/Config/xcconfigs/Debug.xcconfig
          Dogfood: app/feature-app/Config/xcconfigs/Dogfood.xcconfig
    """,
    to: projectYML
  )

  try write(
    """
    {
      "appSlug": "feature-fixture",
      "tiers": [
        {
          "id": "debug",
          "xcodeConfig": "Debug",
          "displayName": "Dev",
          "compilationCondition": "TIER_DEBUG",
          "features": ["FEATURE_DEBUG"]
        },
        {
          "id": "dogfood",
          "xcodeConfig": "Dogfood",
          "displayName": "Dogfood",
          "compilationCondition": "TIER_DOGFOOD",
          "features": ["FEATURE_DOGFOOD"]
        }
      ],
      "featureDescriptions": {
        "FEATURE_DEBUG": "Enable debug tools",
        "FEATURE_DOGFOOD": "Enable dogfood tools"
      }
    }
    """,
    to: root.appendingPathComponent("app/feature-app/Config/release-features.json")
  )

  let debugConditions = debugXcconfigOmitsFeature
    ? "SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) TIER_DEBUG"
    : "SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) TIER_DEBUG FEATURE_DEBUG"
  try write(
    """
    // AUTO-GENERATED by \(provenance). Manifest: release-features.json
    \(debugConditions)
    """,
    to: root.appendingPathComponent("app/feature-app/Config/xcconfigs/Debug.xcconfig")
  )
  try write(
    """
    // AUTO-GENERATED by \(provenance). Manifest: release-features.json
    SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) TIER_DOGFOOD FEATURE_DOGFOOD
    """,
    to: root.appendingPathComponent("app/feature-app/Config/xcconfigs/Dogfood.xcconfig")
  )

  let swiftHeader = releaseFeaturesSwiftHasProvenance
    ? "// Generated by \(provenance)"
    : "// Generated by another-tool"
  try write(
    """
    \(swiftHeader)
    enum ReleaseFeatures {}
    """,
    to: root.appendingPathComponent("app/feature-app/Sources/ReleaseFeatures.swift")
  )

  return projectYML
}

private func write(_ contents: String, to url: URL) throws {
  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try Data(contents.utf8).write(to: url)
}
