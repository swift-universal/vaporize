import AppleProjectSpecCore
import Foundation
import TranslateSourceGate
import VaporizeCLICopy_v000_000_001

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
      return vaporizeCopyFill(VaporizeCLICopy_v000_000_001.CLI.vaporizeA1VA2BlockedA3A4, [String(describing: report.standard.title), String(describing: report.standard.version), String(describing: report.targetName), String(describing: I18nSourceGateAssistantRenderer.render(
  report: report,
  receipt: imprintReceipt,
  reportReceiptPath: receiptPath,
  beadReceiptPath: imprintReceiptPath
))])
    case .beadImprintFailed(let report, let receiptPath, let failure):
      return vaporizeCopyFill(VaporizeCLICopy_v000_000_001.CLI.vaporizeA1VA2CompletedForA3, [String(describing: report.standard.title), String(describing: report.standard.version), String(describing: report.targetName), String(describing: receiptPath), String(describing: failure)])
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
  ) async throws -> Result {
    let productDirectory = productDirectory.standardizedFileURL
    let sourceRoots = try await declaredSourceRoots(
      productDirectory: productDirectory,
      productName: productName
    )
    let sources = try sourceRoots.flatMap {
      try TranslateSourceGateFileSystem.discoverSwiftSources(below: $0)
    }
    let importedModules = try sourceImportedModules(sources)
    let catalogRoot = TranslateSourceGateFileSystem.findCanonicalCatalogPackagesRoot(
      startingAt: productDirectory
    )
    let approvedPackages =
      try catalogRoot.map {
        try ApprovedCopyPackageReceiptDiscovery.discover(
          below: [$0],
          matchingModules: importedModules
        )
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

  private static func sourceImportedModules(_ sources: [URL]) throws -> Set<String> {
    let scopedImportKinds: Set<String> = [
      "class", "enum", "func", "let", "protocol", "struct", "typealias", "var",
    ]
    var modules: Set<String> = []
    for source in sources {
      let contents = try String(contentsOf: source, encoding: .utf8)
      for rawLine in contents.split(whereSeparator: \.isNewline) {
        var line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.hasPrefix("@testable ") {
          line.removeFirst("@testable ".count)
        }
        guard line.hasPrefix("import ") else { continue }
        let tokens = line.split(whereSeparator: \.isWhitespace).map(String.init)
        guard tokens.count >= 2 else { continue }
        let moduleToken = scopedImportKinds.contains(tokens[1]) && tokens.count >= 3
          ? tokens[2]
          : tokens[1]
        if let module = moduleToken.split(separator: ".").first {
          modules.insert(String(module))
        }
      }
    }
    return modules
  }

  /// Pkl owns an Apple product's target-to-source boundary.  Scanning the
  /// project root also traverses generated build directories and vendored
  /// SwiftPM checkouts, incorrectly treating dependency copy as product copy.
  private static func declaredSourceRoots(
    productDirectory: URL,
    productName: String
  ) async throws -> [URL] {
    let pklURL = productDirectory.appendingPathComponent("project.pkl")
    guard FileManager.default.fileExists(atPath: pklURL.path) else {
      return [productDirectory]
    }

    let specification = try await AppleProjectPklLoader.load(url: pklURL)
    let targetSources = specification.targets.compactMap { targetName, target -> [AppleProjectSource]? in
      guard targetName == productName
        || target.settings?.base?["PRODUCT_NAME"]?.stringValue == productName
      else { return nil }
      return target.sources
    }.flatMap { $0 }

    guard !targetSources.isEmpty else {
      return [productDirectory]
    }

    return try targetSources.map { source in
      let root = productDirectory.appendingPathComponent(source.path).standardizedFileURL
      var isDirectory: ObjCBool = false
      guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue
      else {
        throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: root.path])
      }
      return root
    }
  }
}

private func safeFileName(_ value: String) -> String {
  let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._"))
  let scalars = value.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "-" }
  return String(scalars)
}
