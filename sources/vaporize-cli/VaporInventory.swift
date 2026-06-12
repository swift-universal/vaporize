import Foundation

/// Substrate-canonical vaporware-collapse status surfaced by ``VaporizeCLI``
/// modes `status` and `warehouse`. Mirrors the
/// `x-vaporize-collapse-path.status` annotation shape. The legacy
/// `x-craze-collapse-path` key remains readable during migration.
///
/// Phase 0 only — values are matched as raw strings against the annotation,
/// so additional substrate-typed enumerants stay forward-compatible.
enum VaporStatus: String, Codable, CaseIterable {
  /// World-state has caught up to the typed declaration.
  case collapsed
  /// Typed declaration exists; collapse-path identified but not yet executed.
  case collapsePending = "collapse-pending"
  /// Collapse blocked on a substrate-pending capability or dependency.
  case collapseBlocked = "collapse-blocked"
  /// Substrate-doctrine-violating: typed record asserts vapor with no collapse path.
  case permanentVapor = "permanent-vapor"
  /// No annotation discovered at scan-time.
  case unannotated
}

/// Per-file classification record emitted by ``VaporInventoryScanner``.
struct VaporClassification: Codable, Equatable {
  /// Absolute path of the JSON file that was scanned.
  var filePath: String
  /// Resolved vapor status — see ``VaporStatus``.
  var status: VaporStatus
  /// Count of `pendingCapabilityRefs` entries discovered in the annotation, or 0.
  var pendingCapabilityRefsCount: Int
  /// Count of `collapseGateRefs` entries discovered in the annotation, or 0.
  var collapseGateRefsCount: Int

  enum CodingKeys: String, CodingKey {
    case filePath
    case status
    case pendingCapabilityRefsCount
    case collapseGateRefsCount
  }
}

/// Aggregate counts emitted in the warehouse receipt summary footer.
struct VaporInventorySummary: Codable, Equatable {
  var collapsed: Int = 0
  var collapsePending: Int = 0
  var collapseBlocked: Int = 0
  var permanentVapor: Int = 0
  var unannotated: Int = 0

  enum CodingKeys: String, CodingKey {
    case collapsed
    case collapsePending = "collapse-pending"
    case collapseBlocked = "collapse-blocked"
    case permanentVapor = "permanent-vapor"
    case unannotated
  }

  mutating func record(_ status: VaporStatus) {
    switch status {
    case .collapsed: collapsed += 1
    case .collapsePending: collapsePending += 1
    case .collapseBlocked: collapseBlocked += 1
    case .permanentVapor: permanentVapor += 1
    case .unannotated: unannotated += 1
    }
  }
}

/// Phase 0 untyped warehouse receipt emitted by `vaporize warehouse`. Schema
/// version is intentionally stamped `0.0.1-untyped-vaporize-warehouse` to
/// flag the Phase 0 status — Phase 2 replaces this with the typed schema-family
/// equivalent once `FR-VAPOR-COORDINATION-CUT-v0.0.1` lands.
struct VaporInventoryReceipt: Codable, Equatable {
  var schemaVersion: String = "0.0.1-untyped-vaporize-warehouse"
  var warehouseReceiptModel: String = "0.0.1-untyped"
  var scannedPath: String
  var scannedAt: String
  var vaporizeVersion: String
  var totalJsonFilesScanned: Int
  var perFileClassifications: [VaporClassification]
  var summary: VaporInventorySummary

  enum CodingKeys: String, CodingKey {
    case schemaVersion
    case warehouseReceiptModel = "VaporizeWarehouseReceiptModel"
    case scannedPath
    case scannedAt
    case vaporizeVersion
    case totalJsonFilesScanned
    case perFileClassifications
    case summary
  }
}

/// Result returned by ``VaporInventoryScanner/scan(path:)``: classifications
/// plus an aggregate summary. Receipt construction lives at the call site so
/// `vaporize status` and `vaporize warehouse` can share the same scanner.
struct VaporScanResult: Equatable {
  var scannedPath: String
  var classifications: [VaporClassification]
  var summary: VaporInventorySummary
  var totalJsonFilesScanned: Int
}

/// Phase 0 text-based vapor-awareness scanner. Walks a directory, enumerates
/// every `*.json` file, and parses them leniently for
/// `x-vaporize-collapse-path` annotations regardless of nesting depth. The
/// legacy `x-craze-collapse-path` key remains supported while older vaporware
/// records migrate.
struct VaporInventoryScanner {
  /// Errors surfaced by the scanner.
  enum ScannerError: Error, CustomStringConvertible {
    case pathDoesNotExist(String)
    case pathIsNotDirectory(String)

    var description: String {
      switch self {
      case .pathDoesNotExist(let path):
        return "vaporize status/warehouse: --path does not exist: \(path)"
      case .pathIsNotDirectory(let path):
        return "vaporize status/warehouse: --path is not a directory: \(path)"
      }
    }
  }

  /// File manager used for filesystem walks. Injectable for tests.
  var fileManager: FileManager = .default

  /// Walk `path` recursively, classifying every `.json` file by its
  /// `x-vaporize-collapse-path` annotation (or marking it `unannotated` when
  /// none is found / when the file fails to parse).
  func scan(path: String) throws -> VaporScanResult {
    let absolutePath = Self.resolveAbsolutePath(path)
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: absolutePath, isDirectory: &isDirectory) else {
      throw ScannerError.pathDoesNotExist(absolutePath)
    }
    guard isDirectory.boolValue else {
      throw ScannerError.pathIsNotDirectory(absolutePath)
    }

    var classifications: [VaporClassification] = []
    var summary = VaporInventorySummary()

    let rootURL = URL(fileURLWithPath: absolutePath, isDirectory: true)
    let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
    let enumerator = fileManager.enumerator(
      at: rootURL,
      includingPropertiesForKeys: resourceKeys,
      options: [.skipsHiddenFiles],
      errorHandler: { _, _ in true }
    )

    while let candidate = enumerator?.nextObject() as? URL {
      guard candidate.pathExtension.lowercased() == "json" else { continue }
      let isRegular = (try? candidate.resourceValues(forKeys: Set(resourceKeys)).isRegularFile) ?? false
      guard isRegular else { continue }
      let classification = classifyFile(at: candidate)
      summary.record(classification.status)
      classifications.append(classification)
    }

    classifications.sort { $0.filePath < $1.filePath }

    return VaporScanResult(
      scannedPath: absolutePath,
      classifications: classifications,
      summary: summary,
      totalJsonFilesScanned: classifications.count
    )
  }

  /// Build an untyped warehouse receipt from a scan result. Used by
  /// `vaporize warehouse` to emit the Phase 0 `0.0.1-untyped` receipt shape.
  func receipt(
    from result: VaporScanResult,
    vaporizeVersion: String,
    scannedAt: Date = Date()
  ) -> VaporInventoryReceipt {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return VaporInventoryReceipt(
      scannedPath: result.scannedPath,
      scannedAt: formatter.string(from: scannedAt),
      vaporizeVersion: vaporizeVersion,
      totalJsonFilesScanned: result.totalJsonFilesScanned,
      perFileClassifications: result.classifications,
      summary: result.summary
    )
  }

  // MARK: - Classification internals

  private func classifyFile(at url: URL) -> VaporClassification {
    guard let data = try? Data(contentsOf: url) else {
      return VaporClassification(
        filePath: url.path,
        status: .unannotated,
        pendingCapabilityRefsCount: 0,
        collapseGateRefsCount: 0
      )
    }

    // Preferred path: structured JSON parse + recursive search for the annotation.
    if let parsed = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) {
      if let annotation = Self.findCollapsePathAnnotation(in: parsed) {
        return classify(annotation: annotation, filePath: url.path)
      }
      return VaporClassification(
        filePath: url.path,
        status: .unannotated,
        pendingCapabilityRefsCount: 0,
        collapseGateRefsCount: 0
      )
    }

    // Lenient fallback: text-scan for the annotation key. The key alone does not
    // tell us the status, so we only flag unannotated vs. annotated-but-unparseable.
    if let text = String(data: data, encoding: .utf8),
      text.contains("\"\(Self.canonicalCollapsePathKey)\"")
        || text.contains("\"\(Self.legacyCollapsePathKey)\"")
    {
      // We saw the annotation key in source text but could not parse a status from it.
      // Treat as unannotated for Phase 0 — a future phase can surface
      // a typed parse-failure status if desired.
      return VaporClassification(
        filePath: url.path,
        status: .unannotated,
        pendingCapabilityRefsCount: 0,
        collapseGateRefsCount: 0
      )
    }

    return VaporClassification(
      filePath: url.path,
      status: .unannotated,
      pendingCapabilityRefsCount: 0,
      collapseGateRefsCount: 0
    )
  }

  private func classify(annotation: [String: Any], filePath: String) -> VaporClassification {
    let statusRaw = (annotation["status"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased() ?? ""
    let status = VaporStatus(rawValue: statusRaw) ?? .unannotated
    let pending = countRefs(in: annotation["pendingCapabilityRefs"])
    let gates = countRefs(in: annotation["collapseGateRefs"])
    return VaporClassification(
      filePath: filePath,
      status: status,
      pendingCapabilityRefsCount: pending,
      collapseGateRefsCount: gates
    )
  }

  private func countRefs(in value: Any?) -> Int {
    if let array = value as? [Any] { return array.count }
    return 0
  }

  /// Recursively search for an `x-vaporize-collapse-path` annotation. Substrate
  /// JSON shapes vary — it may live at the top level, under `extensions`, or
  /// nested deeper — so we walk dictionaries breadth-flat and return the first
  /// dictionary-valued annotation we find.
  static func findCollapsePathAnnotation(in value: Any) -> [String: Any]? {
    if let dict = value as? [String: Any] {
      if let annotation = dict[canonicalCollapsePathKey] as? [String: Any] {
        return annotation
      }
      if let annotation = dict[legacyCollapsePathKey] as? [String: Any] {
        return annotation
      }
      // Common nested locations: `extensions`, `metadata`, `annotations`.
      // Walk every value to remain shape-agnostic for Phase 0.
      for child in dict.values {
        if let found = findCollapsePathAnnotation(in: child) {
          return found
        }
      }
    } else if let array = value as? [Any] {
      for element in array {
        if let found = findCollapsePathAnnotation(in: element) {
          return found
        }
      }
    }
    return nil
  }

  private static let canonicalCollapsePathKey = "x-vaporize-collapse-path"
  private static let legacyCollapsePathKey = "x-craze-collapse-path"

  /// Resolve `path` to an absolute path, expanding `~` and normalizing.
  static func resolveAbsolutePath(_ path: String) -> String {
    let expanded = (path as NSString).expandingTildeInPath
    if (expanded as NSString).isAbsolutePath {
      return (expanded as NSString).standardizingPath
    }
    let cwd = FileManager.default.currentDirectoryPath
    return ((cwd as NSString).appendingPathComponent(expanded) as NSString).standardizingPath
  }
}
