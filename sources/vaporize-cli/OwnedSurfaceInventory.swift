import Foundation

enum OwnedSurfaceKind: String, Codable, CaseIterable {
  case swiftPackage = "swift-package"
  case xcodeProject = "xcode-project"
  case xcodeWorkspace = "xcode-workspace"
  case appleProjectYML = "apple-project-yml"
  case appleProjectPKL = "apple-project-pkl"
}

enum OwnedSurfaceOwnershipScope: String, Codable, CaseIterable {
  case activeOwned = "active-owned"
  case generatedOwned = "generated-owned"
  case derived = "derived"
  case dependencyCheckout = "dependency-checkout"
  case externalReference = "external-reference"
  case unclassified = "unclassified"
}

struct OwnedSurfaceRecord: Codable, Equatable {
  var kind: OwnedSurfaceKind
  var path: String
  var owner: String?
  var ownershipScope: OwnedSurfaceOwnershipScope
  var domain: String
  var productLine: String
  var name: String
  var declaredProducts: [String]
}

struct OwnedSurfaceInventorySummary: Codable, Equatable {
  var total: Int = 0
  var swiftPackages: Int = 0
  var xcodeProjects: Int = 0
  var xcodeWorkspaces: Int = 0
  var appleProjectYML: Int = 0
  var appleProjectPKL: Int = 0
  var activeOwnedSurfaces: Int = 0
  var activeOwnedSwiftPackages: Int = 0
  var generatedOwnedSurfaces: Int = 0
  var generatedOwnedSwiftPackages: Int = 0
  var derivedSurfaces: Int = 0
  var derivedSwiftPackages: Int = 0
  var dependencyCheckoutSurfaces: Int = 0
  var dependencyCheckoutSwiftPackages: Int = 0
  var externalReferenceSurfaces: Int = 0
  var externalReferenceSwiftPackages: Int = 0
  var unclassifiedSurfaces: Int = 0
  var unclassifiedSwiftPackages: Int = 0
  var byOwnershipScope: [String: Int] = [:]
  var byDomain: [String: Int] = [:]
  var byProductLine: [String: Int] = [:]
  var byDomainProductLine: [String: Int] = [:]
  var byOwnershipScopeDomainProductLine: [String: Int] = [:]

  mutating func record(_ surface: OwnedSurfaceRecord) {
    total += 1
    switch surface.kind {
    case .swiftPackage: swiftPackages += 1
    case .xcodeProject: xcodeProjects += 1
    case .xcodeWorkspace: xcodeWorkspaces += 1
    case .appleProjectYML: appleProjectYML += 1
    case .appleProjectPKL: appleProjectPKL += 1
    }
    switch surface.ownershipScope {
    case .activeOwned:
      activeOwnedSurfaces += 1
      if surface.kind == .swiftPackage { activeOwnedSwiftPackages += 1 }
    case .generatedOwned:
      generatedOwnedSurfaces += 1
      if surface.kind == .swiftPackage { generatedOwnedSwiftPackages += 1 }
    case .derived:
      derivedSurfaces += 1
      if surface.kind == .swiftPackage { derivedSwiftPackages += 1 }
    case .dependencyCheckout:
      dependencyCheckoutSurfaces += 1
      if surface.kind == .swiftPackage { dependencyCheckoutSwiftPackages += 1 }
    case .externalReference:
      externalReferenceSurfaces += 1
      if surface.kind == .swiftPackage { externalReferenceSwiftPackages += 1 }
    case .unclassified:
      unclassifiedSurfaces += 1
      if surface.kind == .swiftPackage { unclassifiedSwiftPackages += 1 }
    }
    byOwnershipScope[surface.ownershipScope.rawValue, default: 0] += 1
    byDomain[surface.domain, default: 0] += 1
    byProductLine[surface.productLine, default: 0] += 1
    byDomainProductLine["\(surface.domain)/\(surface.productLine)", default: 0] += 1
    byOwnershipScopeDomainProductLine[
      "\(surface.ownershipScope.rawValue)/\(surface.domain)/\(surface.productLine)",
      default: 0
    ] += 1
  }
}

struct OwnedSurfaceInventoryResult: Equatable {
  var scannedPath: String
  var surfaces: [OwnedSurfaceRecord]
  var summary: OwnedSurfaceInventorySummary
}

struct OwnedSurfaceInventoryReceipt: Codable, Equatable {
  var schemaVersion: String = "0.1.0-owned-surface-inventory"
  var ownedSurfaceInventoryModel: String = "0.1.0"
  var scannedPath: String
  var scannedAt: String
  var vaporizeVersion: String
  var summary: OwnedSurfaceInventorySummary
  var surfaces: [OwnedSurfaceRecord]

  enum CodingKeys: String, CodingKey {
    case schemaVersion
    case ownedSurfaceInventoryModel = "OwnedSurfaceInventoryModel"
    case scannedPath
    case scannedAt
    case vaporizeVersion
    case summary
    case surfaces
  }
}

struct OwnedSurfaceInventoryScanner {
  enum ScannerError: Error, CustomStringConvertible {
    case pathDoesNotExist(String)
    case pathIsNotDirectory(String)

    var description: String {
      switch self {
      case .pathDoesNotExist(let path):
        return "vaporize inventory: --path does not exist: \(path)"
      case .pathIsNotDirectory(let path):
        return "vaporize inventory: --path is not a directory: \(path)"
      }
    }
  }

  var fileManager: FileManager = .default

  func scan(path: String) throws -> OwnedSurfaceInventoryResult {
    let absolutePath = VaporInventoryScanner.resolveAbsolutePath(path)
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: absolutePath, isDirectory: &isDirectory) else {
      throw ScannerError.pathDoesNotExist(absolutePath)
    }
    guard isDirectory.boolValue else {
      throw ScannerError.pathIsNotDirectory(absolutePath)
    }

    let root = URL(fileURLWithPath: absolutePath, isDirectory: true)
    let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey]
    guard let enumerator = fileManager.enumerator(
      at: root,
      includingPropertiesForKeys: resourceKeys,
      options: [.skipsHiddenFiles],
      errorHandler: { _, _ in true }
    ) else {
      return OwnedSurfaceInventoryResult(
        scannedPath: absolutePath,
        surfaces: [],
        summary: OwnedSurfaceInventorySummary()
      )
    }

    var surfaces: [OwnedSurfaceRecord] = []
    while let candidate = enumerator.nextObject() as? URL {
      let values = try? candidate.resourceValues(forKeys: Set(resourceKeys))
      if shouldSkip(candidate, values: values) {
        if values?.isDirectory == true { enumerator.skipDescendants() }
        continue
      }

      if values?.isDirectory == true {
        if candidate.pathExtension == "xcodeproj" {
          surfaces.append(record(for: candidate, kind: .xcodeProject))
          enumerator.skipDescendants()
        } else if candidate.pathExtension == "xcworkspace" {
          surfaces.append(record(for: candidate, kind: .xcodeWorkspace))
          enumerator.skipDescendants()
        }
        continue
      }

      guard values?.isRegularFile == true else { continue }
      if candidate.lastPathComponent == "Package.swift" {
        surfaces.append(record(for: candidate, kind: .swiftPackage))
      } else if candidate.lastPathComponent == "project.yml" {
        surfaces.append(record(for: candidate, kind: .appleProjectYML))
      } else if candidate.lastPathComponent == "project.pkl" {
        surfaces.append(record(for: candidate, kind: .appleProjectPKL))
      }
    }

    surfaces.sort {
      if $0.domain != $1.domain { return $0.domain.localizedStandardCompare($1.domain) == .orderedAscending }
      if $0.productLine != $1.productLine { return $0.productLine.localizedStandardCompare($1.productLine) == .orderedAscending }
      if $0.kind != $1.kind { return $0.kind.rawValue < $1.kind.rawValue }
      return $0.path.localizedStandardCompare($1.path) == .orderedAscending
    }

    var summary = OwnedSurfaceInventorySummary()
    for surface in surfaces {
      summary.record(surface)
    }

    return OwnedSurfaceInventoryResult(
      scannedPath: absolutePath,
      surfaces: surfaces,
      summary: summary
    )
  }

  func receipt(
    from result: OwnedSurfaceInventoryResult,
    vaporizeVersion: String,
    scannedAt: Date = Date()
  ) -> OwnedSurfaceInventoryReceipt {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return OwnedSurfaceInventoryReceipt(
      scannedPath: result.scannedPath,
      scannedAt: formatter.string(from: scannedAt),
      vaporizeVersion: vaporizeVersion,
      summary: result.summary,
      surfaces: result.surfaces
    )
  }

  private func shouldSkip(_ url: URL, values: URLResourceValues?) -> Bool {
    let component = url.lastPathComponent
    if Self.skippedDirectoryNames.contains(component), values?.isDirectory == true {
      return true
    }
    if url.path.contains("/Package.resolved") {
      return true
    }
    if isWorkspaceInsideXcodeProject(url) {
      return true
    }
    return false
  }

  private func isWorkspaceInsideXcodeProject(_ url: URL) -> Bool {
    let components = url.pathComponents
    guard components.contains(where: { $0.hasSuffix(".xcodeproj") }) else { return false }
    return url.pathExtension == "xcworkspace" || url.path.contains(".xcworkspace/")
  }

  private func record(for url: URL, kind: OwnedSurfaceKind) -> OwnedSurfaceRecord {
    let path = url.standardizedFileURL.path
    let components = url.standardizedFileURL.pathComponents
    let owner = Self.inferOwner(from: components)
    let domain = Self.inferDomain(from: components, kind: kind)
    let productLine = Self.inferProductLine(from: components, kind: kind, url: url)
    return OwnedSurfaceRecord(
      kind: kind,
      path: path,
      owner: owner,
      ownershipScope: Self.inferOwnershipScope(from: components, owner: owner),
      domain: domain,
      productLine: productLine,
      name: Self.surfaceName(for: url, kind: kind),
      declaredProducts: kind == .swiftPackage ? Self.declaredProducts(in: url) : []
    )
  }

  private static func inferOwner(from components: [String]) -> String? {
    for root in ["collectives", "operators", "collaborators", "maintainers", "roles", "audiences"] {
      if let index = components.firstIndex(of: root), index + 1 < components.count {
        return root == "collectives" ? components[index + 1] : "\(root)/\(components[index + 1])"
      }
    }
    return nil
  }

  private static func inferDomain(from components: [String], kind: OwnedSurfaceKind) -> String {
    if let pair = inferDomainProductLinePair(from: components) {
      return pair.domain
    }
    if let index = components.firstIndex(of: "product-lines"), index + 1 < components.count {
      return clean(components[index + 1])
    }
    if let index = components.firstIndex(of: "kura-spaces"), index + 1 < components.count {
      return clean(components[index + 1])
    }
    if let privateIndex = components.lastIndex(of: "private"),
      privateIndex + 1 < components.count,
      components[privateIndex + 1] != "universal"
    {
      return clean(components[privateIndex + 1])
    }
    if kind == .xcodeProject || kind == .xcodeWorkspace || kind == .appleProjectYML || kind == .appleProjectPKL {
      return "apple"
    }
    return "unclassified"
  }

  private static func inferProductLine(
    from components: [String],
    kind: OwnedSurfaceKind,
    url: URL
  ) -> String {
    if let index = components.firstIndex(of: "product-lines"), index + 1 < components.count {
      return clean(components[index + 1])
    }
    if let pair = inferDomainProductLinePair(from: components) {
      return pair.productLine
    }
    if let index = components.firstIndex(of: "apps"), index + 1 < components.count {
      return clean(stripSurfaceSuffixes(components[index + 1]))
    }
    if let index = components.firstIndex(of: "demo-apps"), index + 1 < components.count {
      return clean(stripSurfaceSuffixes(components[index + 1]))
    }
    if let index = components.lastIndex(of: "spm"), index + 1 < components.count {
      if components[index + 1] == "domain", index + 3 < components.count {
        return clean(stripSurfaceSuffixes(components[index + 3]))
      }
      return clean(stripSurfaceSuffixes(components[index + 1]))
    }
    if let index = components.lastIndex(of: "domain"), index + 2 < components.count {
      return clean(stripSurfaceSuffixes(components[index + 2]))
    }
    if let index = components.lastIndex(of: "private"), index + 1 < components.count,
      components[index + 1] != "universal"
    {
      return clean(stripSurfaceSuffixes(components[index + 1]))
    }
    return clean(stripSurfaceSuffixes(surfaceName(for: url, kind: kind)))
  }

  private static func inferDomainProductLinePair(from components: [String]) -> (
    domain: String,
    productLine: String
  )? {
    if let spmIndex = components.firstIndex(of: "spm"),
      spmIndex + 3 < components.count,
      components[spmIndex + 1] == "domain"
    {
      return (
        domain: clean(components[spmIndex + 2]),
        productLine: clean(stripSurfaceSuffixes(components[spmIndex + 3]))
      )
    }

    for index in components.indices where components[index] == "domain" {
      if index + 3 < components.count, components[index + 1] == "spm" {
        return (
          domain: clean(components[index + 2]),
          productLine: clean(stripSurfaceSuffixes(components[index + 3]))
        )
      }
      if index + 2 < components.count {
        return (
          domain: clean(components[index + 1]),
          productLine: clean(stripSurfaceSuffixes(components[index + 2]))
        )
      }
    }
    return nil
  }

  private static func inferOwnershipScope(
    from components: [String],
    owner: String?
  ) -> OwnedSurfaceOwnershipScope {
    if containsSubsequence(["SourcePackages", "checkouts"], in: components)
      || containsSubsequence(["build", "SourcePackages"], in: components)
    {
      return .dependencyCheckout
    }

    if containsAny(components, ["harvest", "retired-agent-homes", "_recovered"]) {
      return .derived
    }

    if containsSubsequence(
      ["collectives", "takumi-org", "private", "universal", "domain", "harnesses", "digikoma"],
      in: components
    ) {
      return .generatedOwned
    }

    if owner?.hasPrefix("maintainers/") == true || owner?.hasPrefix("collaborators/") == true {
      return .externalReference
    }

    if owner != nil {
      return .activeOwned
    }

    return .unclassified
  }

  private static func surfaceName(for url: URL, kind: OwnedSurfaceKind) -> String {
    switch kind {
    case .swiftPackage:
      return url.deletingLastPathComponent().lastPathComponent
    case .xcodeProject, .xcodeWorkspace:
      return stripSurfaceSuffixes(url.lastPathComponent)
    case .appleProjectYML, .appleProjectPKL:
      return url.deletingLastPathComponent().lastPathComponent
    }
  }

  private static func declaredProducts(in packageSwiftURL: URL) -> [String] {
    guard let source = try? String(contentsOf: packageSwiftURL, encoding: .utf8) else {
      return []
    }
    let patterns = [
      #"\.executable\s*\(\s*name\s*:\s*"([^"]+)""#,
      #"\.library\s*\(\s*name\s*:\s*"([^"]+)""#,
      #"\.plugin\s*\(\s*name\s*:\s*"([^"]+)""#,
    ]
    var names: Set<String> = []
    for pattern in patterns {
      guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
      let range = NSRange(source.startIndex..<source.endIndex, in: source)
      for match in regex.matches(in: source, range: range) {
        guard match.numberOfRanges > 1,
          let nameRange = Range(match.range(at: 1), in: source)
        else { continue }
        names.insert(String(source[nameRange]))
      }
    }
    return names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
  }

  private static func stripSurfaceSuffixes(_ value: String) -> String {
    var result = value
    for suffix in [".xcodeproj", ".xcworkspace", ".demo"] where result.hasSuffix(suffix) {
      result.removeLast(suffix.count)
    }
    return result
  }

  private static func clean(_ value: String) -> String {
    let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return cleaned.isEmpty ? "unclassified" : cleaned
  }

  private static func containsAny(_ components: [String], _ values: Set<String>) -> Bool {
    components.contains { values.contains($0) }
  }

  private static func containsSubsequence(_ subsequence: [String], in components: [String]) -> Bool {
    guard !subsequence.isEmpty, components.count >= subsequence.count else { return false }
    for start in components.startIndex...(components.count - subsequence.count) {
      if Array(components[start..<(start + subsequence.count)]) == subsequence {
        return true
      }
    }
    return false
  }

  private static let skippedDirectoryNames: Set<String> = [
    ".build",
    ".derived-data",
    ".git",
    ".swiftpm",
    "Carthage",
    "DerivedData",
    "Pods",
    "Vendor",
    "_recovered",
    "node_modules",
    "retired-agent-homes",
    "target",
    "vendor",
  ]
}

enum OwnedSurfaceInventoryRenderer {
  static func renderText(_ result: OwnedSurfaceInventoryResult) -> String {
    var lines: [String] = []
    lines.append("vaporize inventory - owned build surfaces at \(result.scannedPath)")
    lines.append(String(repeating: "-", count: 96))
    lines.append("summary")
    lines.append("  total surfaces:      \(result.summary.total)")
    lines.append("  Package.swift:       \(result.summary.swiftPackages)")
    lines.append("  .xcodeproj:          \(result.summary.xcodeProjects)")
    lines.append("  .xcworkspace:        \(result.summary.xcodeWorkspaces)")
    lines.append("  project.yml:         \(result.summary.appleProjectYML)")
    lines.append("  project.pkl:         \(result.summary.appleProjectPKL)")
    lines.append("")
    lines.append("ownership scope")
    lines.append("  active-owned surfaces:         \(result.summary.activeOwnedSurfaces)")
    lines.append("  active-owned Package.swift:    \(result.summary.activeOwnedSwiftPackages)")
    lines.append("  generated-owned surfaces:      \(result.summary.generatedOwnedSurfaces)")
    lines.append("  generated-owned Package.swift: \(result.summary.generatedOwnedSwiftPackages)")
    lines.append("  derived surfaces:              \(result.summary.derivedSurfaces)")
    lines.append("  derived Package.swift:         \(result.summary.derivedSwiftPackages)")
    lines.append("  dependency-checkout surfaces:  \(result.summary.dependencyCheckoutSurfaces)")
    lines.append("  dependency-checkout Package.swift: \(result.summary.dependencyCheckoutSwiftPackages)")
    lines.append("  external-reference surfaces:   \(result.summary.externalReferenceSurfaces)")
    lines.append("  external-reference Package.swift: \(result.summary.externalReferenceSwiftPackages)")
    lines.append("")
    appendDomainProductLineSection(
      to: &lines,
      title: "active-owned domain / product-line",
      scope: .activeOwned,
      summary: result.summary
    )
    appendDomainProductLineSection(
      to: &lines,
      title: "generated-owned domain / product-line",
      scope: .generatedOwned,
      summary: result.summary
    )
    appendDomainProductLineSection(
      to: &lines,
      title: "dependency-checkout domain / product-line",
      scope: .dependencyCheckout,
      summary: result.summary
    )
    appendDomainProductLineSection(
      to: &lines,
      title: "derived domain / product-line",
      scope: .derived,
      summary: result.summary
    )
    appendDomainProductLineSection(
      to: &lines,
      title: "external-reference domain / product-line",
      scope: .externalReference,
      summary: result.summary
    )
    lines.append(headerRow())
    lines.append(String(repeating: "-", count: 96))
    for surface in result.surfaces {
      lines.append(format(surface, basePath: result.scannedPath))
    }
    return lines.joined(separator: "\n")
  }

  static func renderJSON(
    _ result: OwnedSurfaceInventoryResult,
    vaporizeVersion: String,
    scannedAt: Date = Date()
  ) throws -> Data {
    let receipt = OwnedSurfaceInventoryScanner().receipt(
      from: result,
      vaporizeVersion: vaporizeVersion,
      scannedAt: scannedAt
    )
    return try VaporInventoryRenderer.makeJSONEncoder().encode(receipt)
  }

  private static func headerRow() -> String {
    "\(pad("kind", 18)) \(pad("scope", 18)) \(pad("domain", 18)) \(pad("product-line", 24)) path"
  }

  private static func format(_ surface: OwnedSurfaceRecord, basePath: String) -> String {
    let relative = relativePath(surface.path, relativeTo: basePath)
    return "\(pad(surface.kind.rawValue, 18)) \(pad(surface.ownershipScope.rawValue, 18)) \(pad(surface.domain, 18)) \(pad(surface.productLine, 24)) \(relative)"
  }

  private static func appendDomainProductLineSection(
    to lines: inout [String],
    title: String,
    scope: OwnedSurfaceOwnershipScope,
    summary: OwnedSurfaceInventorySummary
  ) {
    let prefix = "\(scope.rawValue)/"
    let entries = summary.byOwnershipScopeDomainProductLine
      .filter { $0.key.hasPrefix(prefix) }
      .map { (key: String($0.key.dropFirst(prefix.count)), value: $0.value) }
      .sorted {
        if $0.value != $1.value { return $0.value > $1.value }
        return localizedLessThan($0.key, $1.key)
      }

    guard !entries.isEmpty else { return }
    lines.append(title)
    for entry in entries.prefix(40) {
      lines.append("  \(entry.key): \(entry.value)")
    }
    if entries.count > 40 {
      lines.append("  ... \(entries.count - 40) more")
    }
    lines.append("")
  }

  private static func pad(_ value: String, _ width: Int) -> String {
    if value.count >= width { return value }
    return value + String(repeating: " ", count: width - value.count)
  }

  private static func relativePath(_ path: String, relativeTo basePath: String) -> String {
    if path.hasPrefix(basePath + "/") {
      return String(path.dropFirst(basePath.count + 1))
    }
    if path == basePath {
      return "."
    }
    return path
  }

  private static func localizedLessThan(_ lhs: String, _ rhs: String) -> Bool {
    lhs.localizedStandardCompare(rhs) == .orderedAscending
  }
}
