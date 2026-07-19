import Foundation

// Vaporize's direct-`import SwiftUI` ban gate — the twin of VaporizeI18nSourceGate.
//
// Substrate UI code imports the owned wrapper `SwiftUniversalUI` (which
// `@_exported import`s SwiftUI on Apple and provides a native backend on
// Windows), never SwiftUI directly. This gate makes that rule an executable
// invariant of the canonical build path instead of a convention that lives in
// memory and provably erodes.
//
// Adoption ratchet: a product whose package depends on `SwiftUniversalUI` has
// declared intent to be clean, so a direct `import SwiftUI` there is a hard
// block. A product that has not adopted the wrapper yet is scanned and gets a
// receipt (an honest inventory of its direct imports) but is not blocked, so
// turning the gate on cannot brick the un-migrated fleet. Flip the whole fleet
// to hard-block once the receipts show it is clean.

struct SwiftUIImportFinding: Codable, Sendable, Equatable {
  var file: String
  var line: Int
  var module: String
}

struct SwiftUIImportGateReport: Codable, Sendable {
  var productName: String
  var enforcement: String
  var blocking: Bool
  var adoptedWrapper: Bool
  var scannedFileCount: Int
  var findings: [SwiftUIImportFinding]
  var passed: Bool

  func jsonData() throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(self)
  }
}

/// Thrown when an adopted package imports a banned module directly.
///
/// The human-readable detail — which files and lines, and how to fix them —
/// lives in the JSON receipt (a typed record), not in a user-facing
/// `errorDescription` literal. That keeps the gate itself clean under the
/// substrate's own i18n discipline and follows "truth lives in typed records,
/// not prose": the receipt is the record a reader consults.
struct VaporizeSwiftUIImportGateError: Error {
  let report: SwiftUIImportGateReport
  let receiptPath: String
}

enum VaporizeSwiftUIImportGate {
  /// Modules whose direct import is banned in consumer code.
  static let bannedModules: [String] = ["SwiftUI"]

  /// Path fragments that legitimately import the banned modules — the owned
  /// wrapper module and its platform backends. These are never findings.
  static let exemptPathFragments: [String] = [
    "swift-universal-ui/Sources/SwiftUniversalUI",
    "/SwiftUniversalUI/",
  ]

  struct Result: Sendable {
    var report: SwiftUIImportGateReport
    var receiptURL: URL
  }

  static func enforce(
    packageDirectory: URL,
    productName: String,
    enforcement: String
  ) throws -> Result {
    let packageDirectory = packageDirectory.standardizedFileURL
    let adopted = packageDependsOnWrapper(packageDirectory: packageDirectory)
    let sources = discoverSwiftSources(below: packageDirectory)

    var findings: [SwiftUIImportFinding] = []
    for url in sources {
      let relative = relativePath(of: url, from: packageDirectory)
      if exemptPathFragments.contains(where: { relative.contains($0) }) { continue }
      guard let contents = try? String(contentsOf: url, encoding: .utf8) else { continue }
      var lineNumber = 0
      contents.enumerateLines { line, _ in
        lineNumber += 1
        if let module = bannedModule(inImportLine: line) {
          findings.append(SwiftUIImportFinding(file: relative, line: lineNumber, module: module))
        }
      }
    }

    let passed = findings.isEmpty
    let report = SwiftUIImportGateReport(
      productName: productName,
      enforcement: enforcement,
      blocking: adopted,
      adoptedWrapper: adopted,
      scannedFileCount: sources.count,
      findings: findings,
      passed: passed
    )

    let receiptURL =
      packageDirectory
      .appendingPathComponent(".build/swiftui-import-gate", isDirectory: true)
      .appendingPathComponent("\(safeFileName(productName)).\(enforcement).json")
    try FileManager.default.createDirectory(
      at: receiptURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try report.jsonData().write(to: receiptURL, options: .atomic)

    // Hard-block only when the package adopted the wrapper (declared intent to
    // be clean). Un-adopted packages get the receipt but are not blocked.
    if adopted, !passed {
      throw VaporizeSwiftUIImportGateError(
        report: report,
        receiptPath: receiptURL.path
      )
    }
    return Result(report: report, receiptURL: receiptURL)
  }

  /// Returns the banned module named by an `import` line, if any. Matches
  /// optional leading attributes (`@_exported`, `@testable`, `@preconcurrency`)
  /// and submodule imports (`import SwiftUI.Foo`).
  static func bannedModule(inImportLine rawLine: String) -> String? {
    var line = rawLine.trimmingCharacters(in: .whitespaces)
    while line.hasPrefix("@") {
      guard let space = line.firstIndex(of: " ") else { return nil }
      line = String(line[line.index(after: space)...]).trimmingCharacters(in: .whitespaces)
    }
    guard line.hasPrefix("import ") else { return nil }
    let rest = line.dropFirst("import ".count).trimmingCharacters(in: .whitespaces)
    let head = rest.split(whereSeparator: { $0 == "." || $0 == " " }).first.map(String.init) ?? ""
    return bannedModules.contains(head) ? head : nil
  }

  private static func packageDependsOnWrapper(packageDirectory: URL) -> Bool {
    let manifests = ["Package.swift", "project.yml", "project.pkl"]
    for manifest in manifests {
      let url = packageDirectory.appendingPathComponent(manifest)
      if let contents = try? String(contentsOf: url, encoding: .utf8),
        contents.contains("SwiftUniversalUI") || contents.contains("swift-universal-ui")
      {
        return true
      }
    }
    return false
  }

  private static func discoverSwiftSources(below root: URL) -> [URL] {
    guard
      let enumerator = FileManager.default.enumerator(
        at: root,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
      )
    else { return [] }
    var results: [URL] = []
    for case let url as URL in enumerator {
      let path = url.path
      if path.contains("/.build/") || path.contains("/.swiftpm/") { continue }
      if url.pathExtension == "swift" { results.append(url) }
    }
    return results
  }

  private static func relativePath(of url: URL, from base: URL) -> String {
    let full = url.standardizedFileURL.path
    let basePath = base.standardizedFileURL.path
    if full.hasPrefix(basePath) {
      return String(full.dropFirst(basePath.count)).drop(while: { $0 == "/" }).description
    }
    return full
  }

  private static func safeFileName(_ value: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._"))
    let scalars = value.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "-" }
    return String(scalars)
  }
}
