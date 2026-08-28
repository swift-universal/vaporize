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
    let escapedSchemaPath = schemaURL.path.replacingOccurrences(of: "\\", with: "\\\\")
    let projectURL = fixtureRoot.appendingPathComponent("project.pkl")
    let declaration = """
      amends "\(escapedSchemaPath)"

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
}
