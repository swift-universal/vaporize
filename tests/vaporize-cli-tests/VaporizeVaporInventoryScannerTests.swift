import Foundation
import Testing

@testable import VaporizeCLI

@Test("Classifies a collapsed annotation at the top level")
func classifiesCollapsedAtTopLevel() throws {
  let fixture = try makeFixtureDirectory(named: "collapsed-top-level")
  defer { try? FileManager.default.removeItem(at: fixture) }
  try writeJSON(
    """
    {
      "x-vaporize-collapse-path": {
        "status": "collapsed",
        "collapseGateRefs": ["vaporize-build-ran-2026-06-11"],
        "pendingCapabilityRefs": []
      }
    }
    """,
    name: "record.json",
    in: fixture
  )
  let result = try VaporInventoryScanner().scan(path: fixture.path)
  #expect(result.totalJsonFilesScanned == 1)
  #expect(result.classifications.first?.status == .collapsed)
  #expect(result.classifications.first?.collapseGateRefsCount == 1)
  #expect(result.classifications.first?.pendingCapabilityRefsCount == 0)
  #expect(result.summary.collapsed == 1)
}

@Test("Classifies a collapse-pending annotation nested under extensions")
func classifiesCollapsePendingNestedUnderExtensions() throws {
  let fixture = try makeFixtureDirectory(named: "collapse-pending-nested")
  defer { try? FileManager.default.removeItem(at: fixture) }
  try writeJSON(
    """
    {
      "slug": "example",
      "extensions": {
        "x-vaporize-collapse-path": {
          "status": "collapse-pending",
          "collapseGateRefs": ["a", "b"],
          "pendingCapabilityRefs": ["FR-X", "FR-Y", "FR-Z"]
        }
      }
    }
    """,
    name: "record.json",
    in: fixture
  )
  let result = try VaporInventoryScanner().scan(path: fixture.path)
  let classification = try #require(result.classifications.first)
  #expect(classification.status == .collapsePending)
  #expect(classification.collapseGateRefsCount == 2)
  #expect(classification.pendingCapabilityRefsCount == 3)
  #expect(result.summary.collapsePending == 1)
}

@Test("Classifies permanent-vapor annotation")
func classifiesPermanentVapor() throws {
  let fixture = try makeFixtureDirectory(named: "permanent-vapor")
  defer { try? FileManager.default.removeItem(at: fixture) }
  try writeJSON(
    """
    {
      "x-vaporize-collapse-path": { "status": "permanent-vapor" }
    }
    """,
    name: "record.json",
    in: fixture
  )
  let result = try VaporInventoryScanner().scan(path: fixture.path)
  #expect(result.summary.permanentVapor == 1)
}

@Test("Classifies a file with no annotation as unannotated")
func classifiesUnannotated() throws {
  let fixture = try makeFixtureDirectory(named: "unannotated")
  defer { try? FileManager.default.removeItem(at: fixture) }
  try writeJSON(
    """
    { "slug": "no-annotation" }
    """,
    name: "record.json",
    in: fixture
  )
  let result = try VaporInventoryScanner().scan(path: fixture.path)
  #expect(result.summary.unannotated == 1)
}

@Test("Walks the directory recursively and ignores non-JSON files")
func walksRecursively() throws {
  let fixture = try makeFixtureDirectory(named: "recursive-walk")
  defer { try? FileManager.default.removeItem(at: fixture) }
  let nested = fixture.appendingPathComponent("nested/deeper")
  try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
  try writeJSON(
    """
    { "x-vaporize-collapse-path": { "status": "collapsed" } }
    """,
    name: "a.json",
    in: fixture
  )
  try writeJSON(
    """
    { "x-vaporize-collapse-path": { "status": "collapse-blocked" } }
    """,
    name: "b.json",
    in: nested
  )
  // Non-JSON files must not be counted.
  try "ignore me".write(
    to: fixture.appendingPathComponent("readme.md"),
    atomically: true,
    encoding: .utf8
  )
  let result = try VaporInventoryScanner().scan(path: fixture.path)
  #expect(result.totalJsonFilesScanned == 2)
  #expect(result.summary.collapsed == 1)
  #expect(result.summary.collapseBlocked == 1)
}

@Test("Receipt embeds scanned path, version, and totals")
func receiptShape() throws {
  let fixture = try makeFixtureDirectory(named: "receipt-shape")
  defer { try? FileManager.default.removeItem(at: fixture) }
  try writeJSON(
    """
    { "x-vaporize-collapse-path": { "status": "collapsed" } }
    """,
    name: "record.json",
    in: fixture
  )
  let scanner = VaporInventoryScanner()
  let result = try scanner.scan(path: fixture.path)
  let receipt = scanner.receipt(from: result, vaporizeVersion: "test-version")
  #expect(receipt.vaporizeVersion == "test-version")
  #expect(receipt.totalJsonFilesScanned == 1)
  #expect(receipt.summary.collapsed == 1)
  #expect(receipt.schemaVersion == "0.0.1-untyped-vaporize-warehouse")
  #expect(receipt.warehouseReceiptModel == "0.0.1-untyped")
}

@Test("Errors when --path does not exist")
func errorsOnMissingPath() {
  let missing = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-vaporware-missing-\(UUID().uuidString)")
  #expect(throws: VaporInventoryScanner.ScannerError.self) {
    _ = try VaporInventoryScanner().scan(path: missing.path)
  }
}

// MARK: - Helpers

private func makeFixtureDirectory(named name: String) throws -> URL {
  let url = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-vaporware-tests")
    .appendingPathComponent("\(name)-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  return url
}

private func writeJSON(_ contents: String, name: String, in directory: URL) throws {
  let target = directory.appendingPathComponent(name)
  try contents.write(to: target, atomically: true, encoding: .utf8)
}
