import ArgumentParser
import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-07 parses status mode with JSON output")
func parsesStatusModeWithJSONOutput() throws {
  let command = try VaporizeCLI.parse([
    "status",
    "--path",
    "/tmp/vaporware",
    "--format",
    "json",
  ])

  #expect(command.mode == .status)
  #expect(command.vaporScanPath == "/tmp/vaporware")
  #expect(command.vaporOutputFormat == .json)
  #expect(command.vaporOutputFormat.rendererFormat == .json)
}

@Test("CUJ-07 parses inventory as owned surface inventory")
func parsesInventoryAsOwnedSurfaceInventory() throws {
  let command = try VaporizeCLI.parse([
    "inventory",
    "--path", "/tmp/substrate",
    "--format", "json",
    "--receipt-path", "/tmp/owned-surfaces.json",
  ])

  #expect(command.mode == .inventory)
  #expect(command.vaporScanPath == "/tmp/substrate")
  #expect(command.vaporOutputFormat == .json)
  #expect(command.receiptPath == "/tmp/owned-surfaces.json")
}

@Test("CUJ-07 owned surface inventory finds packages projects and workspaces")
func ownedSurfaceInventoryFindsPackagesProjectsAndWorkspaces() throws {
  let fixture = try makeFixtureDirectory(named: "owned-surfaces")
  defer { try? FileManager.default.removeItem(at: fixture) }

  try writeText(
    """
    // swift-tools-version: 6.4
    import PackageDescription
    let package = Package(
      name: "wrkstrm-docc-cli",
      products: [
        .library(name: "WrkstrmDocC", targets: ["WrkstrmDocC"]),
        .executable(name: "wrkstrm-docc-cli@wrkstrm.clia.sh", targets: ["wrkstrm-docc-cli"])
      ],
      targets: []
    )
    """,
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm/private/universal/spm/domain/tooling/wrkstrm-docc-cli/Package.swift"
    )
  )

  try FileManager.default.createDirectory(
    at: fixture.appendingPathComponent(
      "collectives/wrkstrm-components/private/docc-browser/demo-apps/docc-browser.demo/docc-browser.demo.xcodeproj"
    ),
    withIntermediateDirectories: true
  )
  try FileManager.default.createDirectory(
    at: fixture.appendingPathComponent(
      "collectives/wrkstrm-core/private/product-lines/concourse/apps/concourse/Concourse.xcworkspace"
    ),
    withIntermediateDirectories: true
  )

  let result = try OwnedSurfaceInventoryScanner().scan(path: fixture.path)

  #expect(result.summary.total == 3)
  #expect(result.summary.swiftPackages == 1)
  #expect(result.summary.xcodeProjects == 1)
  #expect(result.summary.xcodeWorkspaces == 1)
  #expect(result.summary.activeOwnedSurfaces == 3)
  #expect(result.summary.activeOwnedSwiftPackages == 1)
  #expect(result.summary.byDomainProductLine["tooling/wrkstrm-docc-cli"] == 1)
  #expect(result.summary.byDomainProductLine["docc-browser/docc-browser"] == 1)
  #expect(result.summary.byDomainProductLine["concourse/concourse"] == 1)

  let package = try #require(result.surfaces.first { $0.kind == .swiftPackage })
  #expect(package.owner == "wrkstrm")
  #expect(package.ownershipScope == .activeOwned)
  #expect(package.domain == "tooling")
  #expect(package.productLine == "wrkstrm-docc-cli")
  #expect(Set(package.declaredProducts) == Set(["WrkstrmDocC", "wrkstrm-docc-cli@wrkstrm.clia.sh"]))
}

@Test("CUJ-07 owned surface inventory separates active generated derived dependency checkouts and references")
func ownedSurfaceInventorySeparatesActiveGeneratedDerivedDependencyCheckoutsAndReferences() throws {
  let fixture = try makeFixtureDirectory(named: "owned-surface-scopes")
  defer { try? FileManager.default.removeItem(at: fixture) }

  try writeText(
    packageManifest(named: "active-tool"),
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm/private/universal/spm/domain/tooling/active-tool/Package.swift"
    )
  )
  try writeText(
    packageManifest(named: "digikoma-swift-format"),
    to: fixture.appendingPathComponent(
      "collectives/takumi-org/private/universal/domain/harnesses/digikoma/domain/build/digikoma-swift-format/Package.swift"
    )
  )
  try writeText(
    packageManifest(named: "derived-tool"),
    to: fixture.appendingPathComponent(
      "collectives/spaces-universal/private/universal/kura-spaces/assistants/chatgpt/private/universal/harvest/2026-03-16/derived-tool/Package.swift"
    )
  )
  try writeText(
    packageManifest(named: "checkout-tool"),
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm-core/private/apple/apps/concourse/build/smoke/SourcePackages/checkouts/checkout-tool/Package.swift"
    )
  )
  try writeText(
    packageManifest(named: "referenced-tool"),
    to: fixture.appendingPathComponent(
      "maintainers/apple/referenced-tool/Package.swift"
    )
  )

  let result = try OwnedSurfaceInventoryScanner().scan(path: fixture.path)

  #expect(result.summary.swiftPackages == 5)
  #expect(result.summary.activeOwnedSwiftPackages == 1)
  #expect(result.summary.generatedOwnedSwiftPackages == 1)
  #expect(result.summary.derivedSwiftPackages == 1)
  #expect(result.summary.dependencyCheckoutSwiftPackages == 1)
  #expect(result.summary.externalReferenceSwiftPackages == 1)
  #expect(result.summary.byOwnershipScope["active-owned"] == 1)
  #expect(result.summary.byOwnershipScope["generated-owned"] == 1)
  #expect(result.summary.byOwnershipScope["derived"] == 1)
  #expect(result.summary.byOwnershipScope["dependency-checkout"] == 1)
  #expect(result.summary.byOwnershipScope["external-reference"] == 1)
  #expect(result.summary.byOwnershipScopeDomainProductLine["active-owned/tooling/active-tool"] == 1)
  #expect(result.summary.byOwnershipScopeDomainProductLine["generated-owned/harnesses/digikoma"] == 1)
  #expect(result.summary.byOwnershipScopeDomainProductLine["derived/assistants/derived-tool"] == 1)
  #expect(result.summary.byOwnershipScopeDomainProductLine["dependency-checkout/apple/concourse"] == 1)
  #expect(result.summary.byOwnershipScopeDomainProductLine["external-reference/unclassified/referenced-tool"] == 1)

  let generated = try #require(result.surfaces.first { $0.name == "digikoma-swift-format" })
  #expect(generated.owner == "takumi-org")
  #expect(generated.ownershipScope == .generatedOwned)
  #expect(generated.domain == "harnesses")
  #expect(generated.productLine == "digikoma")
  #expect(result.summary.byDomainProductLine["harnesses/digikoma"] == 1)

  let checkout = try #require(result.surfaces.first { $0.name == "checkout-tool" })
  #expect(checkout.owner == "wrkstrm-core")
  #expect(checkout.ownershipScope == .dependencyCheckout)

  let derived = try #require(result.surfaces.first { $0.name == "derived-tool" })
  #expect(derived.owner == "spaces-universal")
  #expect(derived.ownershipScope == .derived)
}

@Test("CUJ-07 classifies a collapsed annotation at the top level")
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

@Test("CUJ-07 classifies a collapse-pending annotation nested under extensions")
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

@Test("CUJ-07 classifies permanent vapor")
func classifiesPermanentVapor() throws {
  let fixture = try makeFixtureDirectory(named: "permanent-vapor")
  defer { try? FileManager.default.removeItem(at: fixture) }
  try writeJSON(
    """
    { "x-vaporize-collapse-path": { "status": "permanent-vapor" } }
    """,
    name: "record.json",
    in: fixture
  )
  let result = try VaporInventoryScanner().scan(path: fixture.path)
  #expect(result.summary.permanentVapor == 1)
}

@Test("CUJ-07 classifies legacy x-craze collapse-path annotations")
func classifiesLegacyCrazeCollapsePathAnnotation() throws {
  let fixture = try makeFixtureDirectory(named: "legacy-craze-key")
  defer { try? FileManager.default.removeItem(at: fixture) }
  try writeJSON(
    """
    {
      "metadata": {
        "annotations": [
          {
            "x-craze-collapse-path": {
              "status": "collapse-blocked",
              "collapseGateRefs": ["legacy-gate"],
              "pendingCapabilityRefs": ["missing-tool"]
            }
          }
        ]
      }
    }
    """,
    name: "legacy.json",
    in: fixture
  )

  let result = try VaporInventoryScanner().scan(path: fixture.path)
  let classification = try #require(result.classifications.first)
  #expect(classification.status == .collapseBlocked)
  #expect(classification.collapseGateRefsCount == 1)
  #expect(classification.pendingCapabilityRefsCount == 1)
  #expect(result.summary.collapseBlocked == 1)
}

@Test("CUJ-07 classifies a file with no annotation as unannotated")
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

@Test("CUJ-07 malformed JSON with an annotation key is counted as unannotated")
func malformedJSONWithAnnotationKeyIsUnannotated() throws {
  let fixture = try makeFixtureDirectory(named: "malformed-annotation")
  defer { try? FileManager.default.removeItem(at: fixture) }
  try """
  { "x-vaporize-collapse-path": { "status": "collapsed",
  """.write(
    to: fixture.appendingPathComponent("broken.json"),
    atomically: true,
    encoding: .utf8
  )

  let result = try VaporInventoryScanner().scan(path: fixture.path)
  #expect(result.totalJsonFilesScanned == 1)
  #expect(result.summary.unannotated == 1)
}

@Test("CUJ-07 walks the directory recursively and ignores non-JSON files")
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

@Test("CUJ-07 receipt embeds scanned path, version, and totals")
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

@Test("CUJ-07 errors when path does not exist")
func errorsOnMissingPath() {
  let missing = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-vaporware-missing-\(UUID().uuidString)")
  #expect(throws: VaporInventoryScanner.ScannerError.self) {
    _ = try VaporInventoryScanner().scan(path: missing.path)
  }
}

@Test("CUJ-07 errors when path points at a file")
func errorsOnFilePath() throws {
  let fixture = try makeFixtureDirectory(named: "file-path")
  defer { try? FileManager.default.removeItem(at: fixture) }
  let file = fixture.appendingPathComponent("record.json")
  try "{}".write(to: file, atomically: true, encoding: .utf8)

  #expect(throws: VaporInventoryScanner.ScannerError.self) {
    _ = try VaporInventoryScanner().scan(path: file.path)
  }
}

@Test("CUJ-07 resolves relative scan paths to absolute standardized paths")
func resolvesRelativeScanPaths() {
  let resolved = VaporInventoryScanner.resolveAbsolutePath("./private/../private/universal")

  #expect(resolved.hasPrefix("/"))
  #expect(resolved.hasSuffix("/private/universal"))
}

@Test("CUJ-07 renderer formats relative paths and summary counts")
func rendererFormatsRelativePathsAndSummaryCounts() {
  let result = VaporScanResult(
    scannedPath: "/workspace/vapor",
    classifications: [
      VaporClassification(
        filePath: "/workspace/vapor/nested/blocked.json",
        status: .collapseBlocked,
        pendingCapabilityRefsCount: 2,
        collapseGateRefsCount: 1
      ),
      VaporClassification(
        filePath: "/other/place/collapsed.json",
        status: .collapsed,
        pendingCapabilityRefsCount: 0,
        collapseGateRefsCount: 3
      ),
    ],
    summary: VaporInventorySummary(
      collapsed: 1,
      collapsePending: 0,
      collapseBlocked: 1,
      permanentVapor: 0,
      unannotated: 0
    ),
    totalJsonFilesScanned: 2
  )

  let rendered = VaporInventoryRenderer.renderText(result)

  #expect(rendered.contains("vaporize status - vaporware classification at /workspace/vapor"))
  #expect(rendered.contains("nested/blocked.json"))
  #expect(rendered.contains("/other/place/collapsed.json"))
  #expect(rendered.contains("collapse-blocked"))
  #expect(rendered.contains("total .json files scanned:    2"))
  #expect(rendered.contains("collapsed:                    1"))
}

@Test("CUJ-07 renderer reports an empty inventory explicitly")
func rendererReportsEmptyInventoryExplicitly() {
  let rendered = VaporInventoryRenderer.renderText(
    VaporScanResult(
      scannedPath: "/workspace/empty",
      classifications: [],
      summary: VaporInventorySummary(),
      totalJsonFilesScanned: 0
    )
  )

  #expect(rendered.contains("(no .json files found at path)"))
  #expect(rendered.contains("unannotated:                  0"))
}

@Test("CUJ-07 renderer JSON decodes as a warehouse receipt")
func rendererJSONDecodesAsWarehouseReceipt() throws {
  let result = VaporScanResult(
    scannedPath: "/workspace/vapor",
    classifications: [
      VaporClassification(
        filePath: "/workspace/vapor/record.json",
        status: .permanentVapor,
        pendingCapabilityRefsCount: 0,
        collapseGateRefsCount: 0
      ),
    ],
    summary: VaporInventorySummary(
      collapsed: 0,
      collapsePending: 0,
      collapseBlocked: 0,
      permanentVapor: 1,
      unannotated: 0
    ),
    totalJsonFilesScanned: 1
  )
  let data = try VaporInventoryRenderer.renderJSON(
    result,
    vaporizeVersion: "test-version",
    scannedAt: Date(timeIntervalSince1970: 0)
  )
  let receipt = try JSONDecoder().decode(VaporInventoryReceipt.self, from: data)

  #expect(receipt.vaporizeVersion == "test-version")
  #expect(receipt.scannedAt == "1970-01-01T00:00:00Z")
  #expect(receipt.totalJsonFilesScanned == 1)
  #expect(receipt.summary.permanentVapor == 1)
  #expect(receipt.perFileClassifications.first?.filePath == "/workspace/vapor/record.json")
}

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

private func writeText(_ contents: String, to target: URL) throws {
  try FileManager.default.createDirectory(
    at: target.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try contents.write(to: target, atomically: true, encoding: .utf8)
}

private func packageManifest(named name: String) -> String {
  """
  // swift-tools-version: 6.4
  import PackageDescription
  let package = Package(
    name: "\(name)",
    products: [
      .executable(name: "\(name)", targets: ["\(name)"])
    ],
    targets: []
  )
  """
}
