import Foundation
import TranslateSourceGate

enum VaporizeI18nSourceGateError: Error, LocalizedError {
  case blocked(report: TranslateSourceGateReport, receiptPath: String)

  var errorDescription: String? {
    switch self {
    case .blocked(let report, let receiptPath):
      let findings = report.findings.prefix(12).map { finding in
        "\(finding.rule.rawValue) \(finding.location.file):\(finding.location.line):\(finding.location.column) [\(finding.sink)]"
      }
      let remaining = report.findings.count - findings.count
      let tail = remaining > 0 ? "\n... \(remaining) more blocking findings" : ""
      return """
        i18n source gate blocked \(report.targetName).
        \(findings.joined(separator: "\n"))\(tail)
        Receipt: \(receiptPath)
        User-facing app and CLI copy must come from an approved i18n-universal word package.
        """
    }
  }
}

enum VaporizeI18nSourceGate {
  struct Result: Sendable {
    var report: TranslateSourceGateReport
    var receiptURL: URL
  }

  static func enforce(
    productDirectory: URL,
    productName: String,
    surfaceKind: TranslateSourceSurfaceKind,
    enforcement: TranslateSourceGateEnforcement
  ) throws -> Result {
    let productDirectory = productDirectory.standardizedFileURL
    let sources = try TranslateSourceGateFileSystem.discoverSwiftSources(
      below: productDirectory
    )
    let catalogRoot = TranslateSourceGateFileSystem.findCanonicalCatalogPackagesRoot(
      startingAt: productDirectory
    )
    let approvedPackages =
      try catalogRoot.map {
        try ApprovedCopyPackageReceiptDiscovery.discover(below: [$0])
      } ?? []
    let policy = TranslateSourceGatePolicy(
      targetName: productName,
      surfaceKind: surfaceKind,
      enforcement: enforcement,
      approvedCopyPackages: approvedPackages
    )
    let report = try TranslateSourceGate.evaluate(
      sourceURLs: sources,
      relativeTo: productDirectory,
      policy: policy
    )
    let receiptURL =
      productDirectory
      .appendingPathComponent(".build/i18n-source-gate", isDirectory: true)
      .appendingPathComponent(
        "\(safeFileName(productName)).\(enforcement.rawValue).json"
      )
    try FileManager.default.createDirectory(
      at: receiptURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try report.jsonData().write(to: receiptURL, options: .atomic)

    guard report.passed else {
      throw VaporizeI18nSourceGateError.blocked(
        report: report,
        receiptPath: receiptURL.path
      )
    }
    return Result(report: report, receiptURL: receiptURL)
  }
}

private func safeFileName(_ value: String) -> String {
  let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._"))
  let scalars = value.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "-" }
  return String(scalars)
}
