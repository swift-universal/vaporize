import Foundation
import TranslateSourceGate

enum VaporizeI18nSourceGateError: Error, LocalizedError {
  case blocked(
    report: TranslateSourceGateReport,
    imprintReceipt: I18nSourceGateBeadImprintReceipt,
    receiptPath: String,
    imprintReceiptPath: String
  )
  case beadImprintFailed(
    report: TranslateSourceGateReport,
    receiptPath: String,
    failure: String
  )

  var errorDescription: String? {
    switch self {
    case .blocked(let report, let imprintReceipt, let receiptPath, let imprintReceiptPath):
      return """
        \(report.standard.title) v\(report.standard.version) blocked \(report.targetName).
        \(I18nSourceGateAssistantRenderer.render(
          report: report,
          receipt: imprintReceipt,
          reportReceiptPath: receiptPath,
          beadReceiptPath: imprintReceiptPath
        ))
        """
    case .beadImprintFailed(let report, let receiptPath, let failure):
      return """
        \(report.standard.title) v\(report.standard.version) completed for \(report.targetName), but owner-local Bead reconciliation failed.
        Report receipt: \(receiptPath)
        Bead reconciliation error: \(failure)
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
    let identity = try I18nSourceGateBeadImprint.resolvedIdentity(
      owningHome: productDirectory,
      requestedTargetName: productName,
      fallbackOwnerID: productName
    )
    let policy = TranslateSourceGatePolicy(
      targetName: identity.targetName,
      surfaceKind: surfaceKind,
      enforcement: enforcement,
      approvedCopyPackages: approvedPackages,
      // A generated package can be shared by several product targets. This
      // gate proves this target consumes approved copy; the package-wide
      // declared-versus-used inventory belongs to `translate census`.
      enforceDeclaredUsedKeyEquality: false
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

    let imprintReceipt: I18nSourceGateBeadImprintReceipt
    let imprintReceiptURL: URL
    do {
      imprintReceipt = try I18nSourceGateBeadImprint.reconcile(
        report: report,
        owningHome: productDirectory,
        ownerID: identity.ownerID,
        reportReceiptURL: receiptURL,
        mode: .write,
        scanCompleteness: .complete,
        observedAt: Date()
      )
      imprintReceiptURL = receiptURL.deletingLastPathComponent().appendingPathComponent(
        "\(receiptURL.deletingPathExtension().lastPathComponent).bead-imprint.json"
      )
      try imprintReceipt.jsonData().write(to: imprintReceiptURL, options: .atomic)
    } catch {
      throw VaporizeI18nSourceGateError.beadImprintFailed(
        report: report,
        receiptPath: receiptURL.path,
        failure: error.localizedDescription
      )
    }

    guard report.passed else {
      throw VaporizeI18nSourceGateError.blocked(
        report: report,
        imprintReceipt: imprintReceipt,
        receiptPath: receiptURL.path,
        imprintReceiptPath: imprintReceiptURL.path
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
