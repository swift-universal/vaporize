import Foundation
import Testing
import VaporizeProjectModel

@Suite("Vaporize cross-platform project model")
struct VaporizeProjectModelTests {
  @Test("Vaporize loads a typed Windows target from its project schema")
  func loadsWindowsTarget() async throws {
    let fixtureRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent("vaporize-project-\(UUID().uuidString.lowercased())")
    defer { try? FileManager.default.removeItem(at: fixtureRoot) }
    try FileManager.default.createDirectory(at: fixtureRoot, withIntermediateDirectories: false)

    let schemaURL = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Pkl/vaporize-project.pkl")
    // Pkl module imports are URIs. A raw Windows drive path (for example, C:/...)
    // has no `file:` scheme and is correctly rejected by Pkl's module allowlist.
    let schemaModuleURI = schemaURL.absoluteString
    let projectURL = fixtureRoot.appendingPathComponent("project.pkl")
    let declaration = """
      amends "\(schemaModuleURI)"

      name = "savepoint"
      platformTargets = new {
        ["savepoint-windows"] = new {
          platform = "windows"
          adapter = "wcode"
          product = "savepoint@kura.collective.app"
          packagePath = "."
          entryPoint = "Sources/windows-app/savepoint-windows-app.swift"
          presentation = "swift-uui"
          backend = "winui"
        }
      }
      """
    try Data(declaration.utf8).write(to: projectURL)

    let project = try await VaporizeProjectLoader.load(url: projectURL)
    let target = try #require(project.platformTargets["savepoint-windows"])

    #expect(project.name == "savepoint")
    #expect(target.platform == .windows)
    #expect(target.adapter == .wcode)
    #expect(target.presentation == .swiftUUI)
    #expect(target.backend == .winui)
    #expect(target.entryPoint == "Sources/windows-app/savepoint-windows-app.swift")
  }

  @Test("Vaporize projects debug and release identities from one Pkl tool family")
  func projectsToolFamilyIdentities() async throws {
    let fixtureURL = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("proving-grounds/tool-family-project/project.pkl")
    let project = try await VaporizeProjectLoader.load(url: fixtureURL)

    let debug = try VaporizeToolFamilyPlanner.plan(
      project: project,
      family: "vaporize",
      variant: "digi-stui",
      intent: .debug,
      sourceCoordinate: "v1_2608_30200"
    )
    #expect(debug.sourceProduct == "VaporizeDigiSTUI")
    #expect(debug.executableName == "vaporize.digi-stui-s.v1_2608_30200@wrkstrm-core.coll")
    let encodedDebug = try JSONEncoder().encode(debug)
    let debugJSON = try #require(JSONSerialization.jsonObject(with: encodedDebug) as? [String: Any])
    #expect(debugJSON["VaporizeToolMaterializationPlan"] as? String == "v1_2608_30200")
    #expect(debugJSON["schemaVersion"] == nil)
    #expect(debugJSON["kind"] == nil)

    let release = try VaporizeToolFamilyPlanner.plan(
      project: project,
      family: "vaporize",
      variant: "digi-stui",
      intent: .release
    )
    #expect(release.executableName == "vaporize.digi-stui-s@wrkstrm-core.coll")
    #expect(release.sourceCoordinate == nil)
  }

  @Test("Tool-family projection refuses debug and release identity ambiguity")
  func refusesAmbiguousTemporalIdentity() throws {
    let project = VaporizeProject(
      name: "fixture",
      toolFamilies: [
        "vaporize": .init(
          owner: .init(slug: "wrkstrm-core"),
          variants: [
            "cli": .init(surface: .cli, sourceProduct: "VaporizeCLI")
          ]
        )
      ]
    )

    #expect(throws: VaporizeToolFamilyPlanningError.debugCoordinateRequired) {
      try VaporizeToolFamilyPlanner.plan(
        project: project,
        family: "vaporize",
        variant: "cli",
        intent: .debug
      )
    }
    #expect(throws: VaporizeToolFamilyPlanningError.invalidSourceCoordinate("v0001_2608_30200")) {
      try VaporizeToolFamilyPlanner.plan(
        project: project,
        family: "vaporize",
        variant: "cli",
        intent: .debug,
        sourceCoordinate: "v0001_2608_30200"
      )
    }
    #expect(throws: VaporizeToolFamilyPlanningError.releaseCoordinateForbidden("v1_2608_30200")) {
      try VaporizeToolFamilyPlanner.plan(
        project: project,
        family: "vaporize",
        variant: "cli",
        intent: .release,
        sourceCoordinate: "v1_2608_30200"
      )
    }
  }
}
