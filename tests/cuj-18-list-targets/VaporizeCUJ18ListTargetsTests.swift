import ArgumentParser
import AppleProjectSpecCore
import Foundation
import Testing
import VaporizeTestSupport

@testable import VaporizeCLI

@Test("CUJ-18 parses list-targets CLI arguments")
func parsesListTargetsCLIArguments() throws {
  let command = try VaporizeCLI.parse([
    "list-targets",
    "--package-path",
    "/workspace/App",
    "--format",
    "json",
    "--receipt-path",
    "/tmp/list-targets.receipt.json",
  ])

  #expect(command.mode == .listTargets)
  #expect(command.packagePath == "/workspace/App")
  #expect(command.vaporOutputFormat == .json)
  #expect(command.receiptPath == "/tmp/list-targets.receipt.json")
}

@Test("CUJ-18 discovers targets from legacy project YAML")
func discoversTargetsFromProjectYML() throws {
  let receipt = try AppleProjectTargetDiscovery.discover(
    projectYMLURL: concourseProjectYMLURL,
    requestId: "list-targets-yml"
  )

  #expect(receipt.receiptKind == "vaporize-project-target-discovery")
  #expect(receipt.schemaRef == VaporizeAppleProjectReceiptSchema.targetDiscoverySchemaRef)
  #expect(receipt.discoveryPhase == "apple-project-target-discovery-first-slice")
  #expect(receipt.inputKind == "project-yml")
  #expect(receipt.projectName == "concourse")
  #expect(receipt.targetNames == ["concourse"])
  #expect(receipt.buildableTargetNames == ["concourse"])
  #expect(receipt.packageNames == ["WrkstrmOnboarding", "WrkstrmWalkthrough", "common-terminal"])
  #expect(receipt.targets.first?.productName == "concourse")
  #expect(receipt.targets.first?.packageDependencyCount == 3)
  #expect(!receipt.boundaries.contains { $0.contains("fleet build parity") })
}

@Test("CUJ-18 discovers targets from Pkl forward truth")
func discoversTargetsFromProjectPkl() async throws {
  let receipt = try await AppleProjectTargetDiscovery.discover(
    pklURL: concourseProjectPklURL,
    requestId: "list-targets-pkl"
  )

  #expect(receipt.inputKind == "project-pkl")
  #expect(receipt.selectedProjectSpecPath == concourseProjectPklURL.path)
  #expect(receipt.projectRootPath == concourseProjectPklURL.deletingLastPathComponent().path)
  #expect(receipt.projectName == "concourse")
  #expect(receipt.targetCount == 1)
  #expect(receipt.targets.first?.isBuildableCandidate == true)
  #expect(receipt.candidateSchemeNames.contains("concourse"))
}

@Test("CUJ-18 directory input falls back to project YAML")
func directoryInputFallsBackToProjectYML() async throws {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-list-targets-yml-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: root) }

  try write(
    """
    name: fixture-app
    packages:
      FixtureKit:
        path: Packages/FixtureKit
    targets:
      fixture-app:
        type: application
        platform: macOS
        sources:
          - Sources/App
        dependencies:
          - package: FixtureKit
            product: FixtureKit
    schemes:
      fixture-app:
        shared: true
    """,
    to: root.appendingPathComponent("project.yml")
  )

  let receipt = try await AppleProjectTargetDiscovery.discover(
    projectDirectoryURL: root,
    requestId: "list-targets-directory"
  )

  #expect(receipt.inputKind == "project-yml")
  #expect(receipt.inputPath == root.path)
  #expect(receipt.projectName == "fixture-app")
  #expect(receipt.schemeNames == ["fixture-app"])
  #expect(receipt.packages.first?.kind == "local")
}

@Test("CUJ-18 rejects directories without project specs")
func rejectsDirectoryWithoutProjectSpec() async throws {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-list-targets-empty-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: root) }

  await #expect(throws: AppleProjectTargetDiscoveryError.self) {
    _ = try await AppleProjectTargetDiscovery.discover(
      projectDirectoryURL: root,
      requestId: "list-targets-empty"
    )
  }
}

private func write(_ contents: String, to url: URL) throws {
  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try contents.write(to: url, atomically: true, encoding: .utf8)
}
