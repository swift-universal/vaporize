import ArgumentParser
import Foundation
import Testing

import XcodeProjectDefinitionCore
@testable import VaporizeCLI
import VaporizeTestSupport

@Test("CUJ-19 parses list-targets workspace cache discovery options")
func parsesListTargetsWorkspaceCacheDiscoveryOptions() throws {
  let command = try VaporizeCLI.parse([
    "list-targets",
    "--package-path",
    "/workspace/App",
    "--configuration",
    "debug",
    "--xcode-product-cache-workspace",
    "/workspace/Huge/Huge.xcworkspace",
    "--xcode-product-cache-derived-data-path",
    "/workspace/Huge/.derived-data",
  ])

  #expect(command.mode == .listTargets)
  #expect(command.packagePath == "/workspace/App")
  #expect(command.configuration == .debug)
  #expect(command.xcodeProductCacheWorkspace == "/workspace/Huge/Huge.xcworkspace")
  #expect(command.xcodeProductCacheDerivedDataPath == "/workspace/Huge/.derived-data")
}

@Test("CUJ-19 discovers missing workspace cache candidates from target facts")
func discoversMissingWorkspaceCacheCandidatesFromTargetFacts() throws {
  let cacheRoot = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-workspace-cache-missing-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: cacheRoot) }

  let receipt = try XcodeProjectTargetDiscovery.discover(
    projectYMLURL: concourseProjectYMLURL,
    requestId: "workspace-cache-missing",
    productCacheOptions: .init(
      workspacePath: "/workspace/Huge/Huge.xcworkspace",
      derivedDataPath: cacheRoot.path,
      configurationName: "Debug"
    )
  )

  let candidate = try #require(receipt.productCacheCandidates.first)
  #expect(receipt.productCacheCandidateCount == 1)
  #expect(receipt.warmProductCacheCandidateCount == 0)
  #expect(candidate.targetName == "concourse")
  #expect(candidate.productName == "concourse")
  #expect(candidate.configurationName == "Debug")
  #expect(candidate.status == "missing")
  #expect(!candidate.isWarm)
  #expect(candidate.appBundlePath.hasSuffix("Build/Products/Debug/concourse.app"))
}

@Test("CUJ-19 reports warm workspace cache products")
func reportsWarmWorkspaceCacheProducts() async throws {
  let cacheRoot = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-workspace-cache-warm-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: cacheRoot) }

  let warmApp = cacheRoot.appendingPathComponent("Build/Products/Release/creative-selection-v0.2.app")
  try FileManager.default.createDirectory(at: warmApp, withIntermediateDirectories: true)

  let receipt = try await XcodeProjectTargetDiscovery.discover(
    pklURL: creativeSelectionProjectPklURL,
    requestId: "workspace-cache-warm",
    productCacheOptions: .init(
      workspacePath: "/workspace/Huge/Huge.xcworkspace",
      derivedDataPath: cacheRoot.path,
      configurationName: "Release"
    )
  )

  let candidate = try #require(receipt.productCacheCandidates.first)
  #expect(receipt.productCacheCandidateCount == 1)
  #expect(receipt.warmProductCacheCandidateCount == 1)
  #expect(candidate.targetName == "creative-selection-v0.2")
  #expect(candidate.productName == "creative-selection-v0.2")
  #expect(candidate.status == "warm")
  #expect(candidate.isWarm)
  #expect(candidate.appBundlePath == warmApp.path)
}

@Test("CUJ-19 excludes non-buildable targets from workspace cache candidates")
func excludesNonBuildableTargetsFromWorkspaceCacheCandidates() throws {
  let spec = try decodeXcodeProjectYML(
    """
    name: Mixed
    targets:
      Tool:
        type: commandLineTool
        platform: macOS
        sources:
          - Sources/Tool
      App:
        type: application
        platform: macOS
        sources:
          - Sources/App
        settings:
          base:
            PRODUCT_NAME: MixedApp
    """
  )
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-workspace-cache-mixed-\(UUID().uuidString)")
  let ymlURL = temporaryDirectory.appendingPathComponent("project.yml")
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
  try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
  try XcodeProjectYMLRenderer.renderData(spec: spec).write(to: ymlURL)

  let receipt = try XcodeProjectTargetDiscovery.discover(
    projectYMLURL: ymlURL,
    requestId: "workspace-cache-mixed",
    productCacheOptions: .init(
      workspacePath: "/workspace/Huge/Huge.xcworkspace",
      derivedDataPath: temporaryDirectory.appendingPathComponent("DerivedData").path,
      configurationName: "Release"
    )
  )

  #expect(receipt.targetCount == 2)
  #expect(receipt.buildableTargetNames == ["App"])
  #expect(receipt.productCacheCandidates.map(\.targetName) == ["App"])
  #expect(receipt.productCacheCandidates.map(\.productName) == ["MixedApp"])
}

@Test("CUJ-19 rejects incomplete workspace cache discovery configuration")
func rejectsIncompleteWorkspaceCacheDiscoveryConfiguration() throws {
  #expect(throws: XcodeProjectTargetDiscoveryError.self) {
    try XcodeProjectTargetDiscovery.discover(
      projectYMLURL: concourseProjectYMLURL,
      requestId: "workspace-cache-missing-derived-data",
      productCacheOptions: .init(
        workspacePath: "/workspace/Huge/Huge.xcworkspace",
        derivedDataPath: nil,
        configurationName: "Debug"
      )
    )
  }

  #expect(throws: XcodeProjectTargetDiscoveryError.self) {
    try XcodeProjectTargetDiscovery.discover(
      projectYMLURL: concourseProjectYMLURL,
      requestId: "workspace-cache-missing-workspace",
      productCacheOptions: .init(
        workspacePath: nil,
        derivedDataPath: "/workspace/Huge/.derived-data",
        configurationName: "Debug"
      )
    )
  }
}

private let creativeSelectionProjectPklURL = vaporizeTestPackageRoot
  .appendingPathComponent("../../apps/creative-selection-v0.2/project.pkl")
  .standardizedFileURL
