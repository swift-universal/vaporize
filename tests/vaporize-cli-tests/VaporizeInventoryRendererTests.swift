import Foundation
import Testing

@testable import VaporizeCLI

@Test("Renderer formats relative paths and summary counts")
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

@Test("Renderer reports an empty inventory explicitly")
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

@Test("Renderer JSON decodes as a warehouse receipt")
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
