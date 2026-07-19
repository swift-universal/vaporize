import Foundation
import Testing

@testable import VaporizeCLI

@Suite("VaporizeSwiftUIImportGate")
struct VaporizeSwiftUIImportGateTests {

  /// Builds a throwaway package tree. The manifest is scanned as text for the
  /// wrapper marker, never evaluated, so any string containing "SwiftUniversalUI"
  /// counts as adopted.
  private func makeTempPackage(adopted: Bool, files: [String: String]) throws -> URL {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent("swiftui-import-gate-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let manifest =
      adopted
      ? "// depends on SwiftUniversalUI\n"
      : "// no ui wrapper here\n"
    try manifest.write(
      to: root.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
    for (relative, contents) in files {
      let url = root.appendingPathComponent(relative)
      try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
      try contents.write(to: url, atomically: true, encoding: .utf8)
    }
    return root
  }

  @Test("import-line parser flags SwiftUI (plain, attributed, submodule); passes the wrapper")
  func parsesImportLines() {
    #expect(VaporizeSwiftUIImportGate.bannedModule(inImportLine: "import SwiftUI") == "SwiftUI")
    #expect(
      VaporizeSwiftUIImportGate.bannedModule(inImportLine: "  @_exported import SwiftUI")
        == "SwiftUI")
    #expect(
      VaporizeSwiftUIImportGate.bannedModule(inImportLine: "import SwiftUI.Foo") == "SwiftUI")
    #expect(VaporizeSwiftUIImportGate.bannedModule(inImportLine: "import SwiftUniversalUI") == nil)
    #expect(VaporizeSwiftUIImportGate.bannedModule(inImportLine: "import Foundation") == nil)
    #expect(VaporizeSwiftUIImportGate.bannedModule(inImportLine: "// import SwiftUI") == nil)
  }

  @Test("adopted package with a direct SwiftUI import is hard-blocked")
  func adoptedViolationBlocks() throws {
    let pkg = try makeTempPackage(
      adopted: true, files: ["Sources/View.swift": "import SwiftUniversalUI\nimport SwiftUI\n"])
    defer { try? FileManager.default.removeItem(at: pkg) }
    #expect(throws: VaporizeSwiftUIImportGateError.self) {
      _ = try VaporizeSwiftUIImportGate.enforce(
        packageDirectory: pkg, productName: "X", enforcement: "release")
    }
  }

  @Test("adopted package that is clean passes and records adoption")
  func adoptedCleanPasses() throws {
    let pkg = try makeTempPackage(
      adopted: true, files: ["Sources/View.swift": "import SwiftUniversalUI\n"])
    defer { try? FileManager.default.removeItem(at: pkg) }
    let result = try VaporizeSwiftUIImportGate.enforce(
      packageDirectory: pkg, productName: "X", enforcement: "release")
    #expect(result.report.passed)
    #expect(result.report.adoptedWrapper)
  }

  @Test("non-adopted package warns via receipt but does not block")
  func nonAdoptedWarnsNotBlocks() throws {
    let pkg = try makeTempPackage(adopted: false, files: ["Sources/View.swift": "import SwiftUI\n"])
    defer { try? FileManager.default.removeItem(at: pkg) }
    let result = try VaporizeSwiftUIImportGate.enforce(
      packageDirectory: pkg, productName: "X", enforcement: "release")
    #expect(!result.report.passed)
    #expect(!result.report.blocking)
    #expect(result.report.findings.count == 1)
  }

  @Test("the SwiftUniversalUI wrapper module itself is exempt")
  func wrapperModuleExempt() throws {
    let pkg = try makeTempPackage(
      adopted: true,
      files: ["Sources/SwiftUniversalUI/Wrapper.swift": "@_exported import SwiftUI\n"])
    defer { try? FileManager.default.removeItem(at: pkg) }
    let result = try VaporizeSwiftUIImportGate.enforce(
      packageDirectory: pkg, productName: "SwiftUniversalUI", enforcement: "release")
    #expect(result.report.passed)
    #expect(result.report.findings.isEmpty)
  }
}
