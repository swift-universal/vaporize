import Foundation

/// Output format selector shared by `vaporize status` and `vaporize warehouse`.
enum VaporOutputFormat: String, CaseIterable {
  /// Human-readable table + summary footer.
  case text
  /// Machine-readable JSON (matches the warehouse receipt shape for `status`,
  /// and the typed receipt for `warehouse`).
  case json
}

/// Rendering helpers for the Phase 0 vapor-awareness modes. Text output is
/// intentionally simple: a per-file table followed by a summary footer, sized
/// to fit a typical terminal without depending on a tabulation library.
enum VaporInventoryRenderer {

  /// Render a scan result as a human-readable status report.
  static func renderText(_ result: VaporScanResult) -> String {
    var lines: [String] = []
    lines.append("vaporize status - vaporware classification at \(result.scannedPath)")
    lines.append(String(repeating: "-", count: 80))

    if result.classifications.isEmpty {
      lines.append("(no .json files found at path)")
    } else {
      lines.append(headerRow())
      lines.append(String(repeating: "-", count: 80))
      for classification in result.classifications {
        lines.append(formatRow(classification, basePath: result.scannedPath))
      }
    }

    lines.append(String(repeating: "-", count: 80))
    lines.append("summary")
    lines.append("  total .json files scanned:    \(result.totalJsonFilesScanned)")
    lines.append("  collapsed:                    \(result.summary.collapsed)")
    lines.append("  collapse-pending:             \(result.summary.collapsePending)")
    lines.append("  collapse-blocked:             \(result.summary.collapseBlocked)")
    lines.append("  permanent-vapor:              \(result.summary.permanentVapor)")
    lines.append("  unannotated:                  \(result.summary.unannotated)")
    return lines.joined(separator: "\n")
  }

  /// Encode a scan result as pretty-printed JSON (matches the warehouse receipt
  /// shape so `--format json` produces a useful machine-readable surface even
  /// from `vaporize status`).
  static func renderJSON(
    _ result: VaporScanResult,
    vaporizeVersion: String,
    scannedAt: Date = Date()
  ) throws -> Data {
    let receipt = VaporInventoryScanner().receipt(
      from: result,
      vaporizeVersion: vaporizeVersion,
      scannedAt: scannedAt
    )
    return try makeJSONEncoder().encode(receipt)
  }

  /// Build a fresh encoder. Pretty-printed + sorted keys to match
  /// the existing `PassThroughReceipt` emission style. Returned per-call so
  /// the renderer stays free of Swift 6 strict-concurrency caveats around
  /// non-Sendable `JSONEncoder` shared state.
  static func makeJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return encoder
  }

  // MARK: - Row formatting

  private static func headerRow() -> String {
    let path = padTrailing("path", to: 50)
    let status = padTrailing("status", to: 18)
    let pending = padTrailing("pending", to: 8)
    let gates = padTrailing("gates", to: 6)
    return "\(path) \(status) \(pending) \(gates)"
  }

  private static func formatRow(
    _ classification: VaporClassification,
    basePath: String
  ) -> String {
    let display = relativePath(classification.filePath, relativeTo: basePath)
    let path = padTrailing(display, to: 50)
    let status = padTrailing(classification.status.rawValue, to: 18)
    let pending = padTrailing("\(classification.pendingCapabilityRefsCount)", to: 8)
    let gates = padTrailing("\(classification.collapseGateRefsCount)", to: 6)
    return "\(path) \(status) \(pending) \(gates)"
  }

  private static func padTrailing(_ string: String, to width: Int) -> String {
    if string.count >= width { return string }
    return string + String(repeating: " ", count: width - string.count)
  }

  private static func relativePath(_ filePath: String, relativeTo basePath: String) -> String {
    if filePath.hasPrefix(basePath + "/") {
      return String(filePath.dropFirst(basePath.count + 1))
    }
    if filePath == basePath {
      return "."
    }
    return filePath
  }
}
