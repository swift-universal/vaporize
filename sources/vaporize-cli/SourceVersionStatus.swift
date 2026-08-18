import AppleProjectSpecCore
import Foundation

/// The policy outcome for one source-declared marketing version. Build numbers
/// deliberately use a separate status because their cadence is independent of
/// the marketing-version policy.
enum SourceVersionPolicyStatus: String, Codable, Equatable {
  case compliant
  case outsidePolicy = "outside-policy"
  case unresolved
}

enum SourceBuildNumberStatus: String, Codable, Equatable {
  case sourceDeclared = "source-declared"
  case notApplicable = "not-applicable"
  case unresolved
}

enum SourceVersionAuthorityStatus: String, Codable, Equatable {
  case sourceDeclared = "source-declared"
  case candidateNotRuntimeLinked = "candidate-not-runtime-linked"
  case sourceCarrierMissing = "source-carrier-missing"
}

enum SourceVersionTargetKind: String, Codable, Equatable {
  case xcodeApp = "xcode-app"
  case swiftPMApp = "swiftpm-app"
}

enum SourceVersionCarrierKind: String, Codable, Equatable {
  case xcodegenProjectYML = "xcodegen-project-yml"
  case pklAppleProject = "pkl-apple-project"
  case swiftPMRuntimeSourceAppVersion = "swiftpm-runtime-source-app-version"
}

/// An exact source target reference. The report uses paths and target names,
/// never reconstructed slugs, so a row can be reopened at its source carrier.
struct SourceVersionTargetRef: Codable, Equatable {
  var path: String
  var target: String
}

/// The effective source values for one build configuration. Each value carries
/// its own exact carrier reference because a target may source the marketing
/// version and build number from different declarations.
struct SourceVersionStatusConfiguration: Codable, Equatable {
  var name: String
  var marketingVersion: String?
  var marketingVersionCarrierRef: String?
  var buildNumber: String?
  var buildNumberCarrierRef: String?
}

struct SourceVersionStatusUnit: Codable, Equatable {
  var targetRef: SourceVersionTargetRef
  var owner: String?
  var ownershipScope: OwnedSurfaceOwnershipScope
  var targetKind: SourceVersionTargetKind
  var carrierKind: SourceVersionCarrierKind
  var authorityStatus: SourceVersionAuthorityStatus
  var configurations: [SourceVersionStatusConfiguration]
  var versionPolicyStatus: SourceVersionPolicyStatus
  var buildNumberStatus: SourceBuildNumberStatus
  var diagnostic: String?
}

struct SourceVersionStatusFinding: Codable, Equatable {
  var kind: String
  var sourceRef: String
  var detail: String
}

struct SourceVersionStatusSummary: Codable, Equatable {
  var totalUnits: Int
  var xcodeApplicationTargets: Int
  var swiftPMApplicationTargets: Int
  var zeroMinorCompliant: Int
  var outsidePolicy: Int
  var unresolved: Int
  var sourceDeclaredBuildNumbers: Int
  var buildNumbersNotApplicable: Int
  var unresolvedBuildNumbers: Int
  var discoveryFindings: Int

  init(units: [SourceVersionStatusUnit], findings: [SourceVersionStatusFinding]) {
    totalUnits = units.count
    xcodeApplicationTargets = units.count { $0.targetKind == .xcodeApp }
    swiftPMApplicationTargets = units.count { $0.targetKind == .swiftPMApp }
    zeroMinorCompliant = units.count { $0.versionPolicyStatus == .compliant }
    outsidePolicy = units.count { $0.versionPolicyStatus == .outsidePolicy }
    unresolved = units.count { $0.versionPolicyStatus == .unresolved }
    sourceDeclaredBuildNumbers = units.count { $0.buildNumberStatus == .sourceDeclared }
    buildNumbersNotApplicable = units.count { $0.buildNumberStatus == .notApplicable }
    unresolvedBuildNumbers = units.count { $0.buildNumberStatus == .unresolved }
    discoveryFindings = findings.count
  }
}

struct SourceVersionStatusResult: Equatable {
  var scannedPath: String
  var units: [SourceVersionStatusUnit]
  var findings: [SourceVersionStatusFinding]
  var summary: SourceVersionStatusSummary
}

struct SourceVersionStatusReporter: Codable, Equatable {
  var product: String
  var version: String
  var buildNumber: String
  var versionPolicyStatus: SourceVersionPolicyStatus
}

/// Stable JSON receipt emitted by `vaporize version-status`. This is a source
/// identity report: it does not assert an installed app bundle, a release
/// channel, a package public version, or a historical schema wire version.
struct SourceVersionStatusReceipt: Codable, Equatable {
  var schemaVersion: String = "0.0.1"
  var sourceVersionStatusModel: String = "0.0.1"
  var kind: String = "vaporize-source-version-status"
  var capturedAt: String
  var scannedPath: String
  var scope: String
  var evidenceBoundary: String
  var reporter: SourceVersionStatusReporter
  var summary: SourceVersionStatusSummary
  var units: [SourceVersionStatusUnit]
  var discoveryFindings: [SourceVersionStatusFinding]
}

/// Reads owner-controlled Apple application source carriers below the supplied
/// substrate path. The scanner intentionally reports missing or unsupported
/// carriers as loud findings instead of turning generated build output into a
/// presumed source of truth.
struct SourceVersionStatusScanner {
  var fileManager: FileManager = .default

  func scan(path: String) async throws -> SourceVersionStatusResult {
    let inventory = try OwnedSurfaceInventoryScanner(fileManager: fileManager).scan(path: path)
    let surfaces = inventory.surfaces.filter(Self.isActiveAppleAppSurface)

    var units: [SourceVersionStatusUnit] = []
    var findings: [SourceVersionStatusFinding] = []

    let projectYMLSurfaces = surfaces.filter {
      $0.kind == .appleProjectYML && Self.isDirectAppHomeSurface($0)
    }
    let projectYMLPaths = Set(projectYMLSurfaces.map(\.path))
    let projectPKLSurfaces = surfaces.filter {
      $0.kind == .appleProjectPKL
        && Self.isDirectAppHomeSurface($0)
        && !projectYMLPaths.contains(
          URL(fileURLWithPath: $0.path)
            .deletingLastPathComponent()
            .appendingPathComponent("project.yml")
            .path
        )
    }
    let projectPKLPaths = Set(projectPKLSurfaces.map(\.path))

    for surface in projectYMLSurfaces {
      let sourceURL = URL(fileURLWithPath: surface.path)
      do {
        let spec = try AppleProjectYMLReader.load(url: sourceURL)
        for (targetName, target) in spec.targets where Self.isApplicationTarget(target) {
          units.append(
            Self.xcodeUnit(
              surface: surface,
              projectSourceURL: sourceURL,
              spec: spec,
              targetName: targetName,
              target: target,
              carrierKind: .xcodegenProjectYML
            )
          )
        }
      } catch {
        findings.append(
          SourceVersionStatusFinding(
            kind: "unreadable-project-yml",
            sourceRef: sourceURL.path,
            detail: String(describing: error)
          )
        )
      }
    }

    for surface in projectPKLSurfaces {
      let sourceURL = URL(fileURLWithPath: surface.path)
      do {
        let spec = try await AppleProjectPklLoader.load(url: sourceURL)
        for (targetName, target) in spec.targets where Self.isApplicationTarget(target) {
          units.append(
            Self.xcodeUnit(
              surface: surface,
              projectSourceURL: sourceURL,
              spec: spec,
              targetName: targetName,
              target: target,
              carrierKind: .pklAppleProject
            )
          )
        }
      } catch {
        findings.append(
          SourceVersionStatusFinding(
            kind: "unreadable-project-pkl",
            sourceRef: sourceURL.path,
            detail: String(describing: error)
          )
        )
      }
    }

    for surface in surfaces where surface.kind == .xcodeProject && Self.isDirectAppHomeSurface(surface) {
      let projectURL = URL(fileURLWithPath: surface.path)
      let appHome = projectURL.deletingLastPathComponent()
      let projectYMLPath = appHome.appendingPathComponent("project.yml").path
      let projectPKLPath = appHome.appendingPathComponent("project.pkl").path
      guard !projectYMLPaths.contains(projectYMLPath), !projectPKLPaths.contains(projectPKLPath) else {
        continue
      }
      findings.append(
        SourceVersionStatusFinding(
          kind: "xcode-project-without-project-yml-source-carrier",
          sourceRef: projectURL.path,
          detail: "No owner-controlled project.yml or evaluable project.pkl sits beside this Xcode project; source version and build carriers require an explicit adapter."
        )
      )
    }

    for surface in surfaces where surface.kind == .swiftPackage && Self.isDirectAppHomeSurface(surface) {
      let packageURL = URL(fileURLWithPath: surface.path)
      let appHome = packageURL.deletingLastPathComponent()
      guard !Self.appHomeContainsXcodeProject(appHome, fileManager: fileManager) else { continue }
      units.append(contentsOf: Self.swiftPMUnits(surface: surface, packageURL: packageURL, fileManager: fileManager))
    }

    units.sort {
      if $0.owner != $1.owner { return ($0.owner ?? "").localizedStandardCompare($1.owner ?? "") == .orderedAscending }
      if $0.targetRef.path != $1.targetRef.path {
        return $0.targetRef.path.localizedStandardCompare($1.targetRef.path) == .orderedAscending
      }
      return $0.targetRef.target.localizedStandardCompare($1.targetRef.target) == .orderedAscending
    }
    findings.sort {
      if $0.sourceRef != $1.sourceRef {
        return $0.sourceRef.localizedStandardCompare($1.sourceRef) == .orderedAscending
      }
      return $0.kind < $1.kind
    }

    return SourceVersionStatusResult(
      scannedPath: inventory.scannedPath,
      units: units,
      findings: findings,
      summary: SourceVersionStatusSummary(units: units, findings: findings)
    )
  }

  func receipt(
    from result: SourceVersionStatusResult,
    reporterVersion: String,
    reporterBuildNumber: String,
    capturedAt: Date = Date()
  ) -> SourceVersionStatusReceipt {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return SourceVersionStatusReceipt(
      capturedAt: formatter.string(from: capturedAt),
      scannedPath: result.scannedPath,
      scope: "Owner-controlled Apple application source identities below explicit app homes: private/apple/apps/<app> and product-lines/<product-line>/apps/<app>. XcodeGen and Pkl Apple-project application targets plus SwiftPM application-entry targets are included. Package public release carriers, historical schema version roots, payload wire versions, generated project output, and installed app bundles are outside this report's scope.",
      evidenceBoundary: "Rows are source declarations only. A compliant source row is not an installed, published, consumer-upgraded, or Launch Review claim. Use fleet-status for installed CLI sidecars and dedicated release evidence for built applications.",
      reporter: SourceVersionStatusReporter(
        product: "vaporize.cli@wrkstrm-core.clia.sh",
        version: reporterVersion,
        buildNumber: reporterBuildNumber,
        versionPolicyStatus: Self.policyStatus(for: [reporterVersion], authorityStatus: .sourceDeclared)
      ),
      summary: result.summary,
      units: result.units,
      discoveryFindings: result.findings
    )
  }

  static func policyStatus(
    for versions: [String],
    authorityStatus: SourceVersionAuthorityStatus
  ) -> SourceVersionPolicyStatus {
    guard authorityStatus == .sourceDeclared else { return .unresolved }
    guard !versions.isEmpty else { return .unresolved }
    return versions.allSatisfy(isZeroMinorVersion) ? .compliant : .outsidePolicy
  }

  private static func isActiveAppleAppSurface(_ surface: OwnedSurfaceRecord) -> Bool {
    surface.ownershipScope == .activeOwned && appHomeURL(for: URL(fileURLWithPath: surface.path)) != nil
  }

  private static func isDirectAppHomeSurface(_ surface: OwnedSurfaceRecord) -> Bool {
    let url = URL(fileURLWithPath: surface.path)
    guard let appHome = appHomeURL(for: url) else { return false }
    return url.deletingLastPathComponent().standardizedFileURL.path == appHome.path
  }

  private static func appHomeURL(for url: URL) -> URL? {
    let path = url.standardizedFileURL.path
    if let marker = path.range(of: "/private/apple/apps/") {
      let remainder = path[marker.upperBound...]
      guard let appName = remainder.split(separator: "/", maxSplits: 1).first, !appName.isEmpty else {
        return nil
      }
      return URL(fileURLWithPath: String(path[..<marker.upperBound]) + String(appName))
        .standardizedFileURL
    }
    guard let marker = path.range(of: "/product-lines/") else { return nil }
    let components = path[marker.upperBound...].split(separator: "/")
    guard components.count >= 3,
      !components[0].isEmpty,
      components[1] == "apps",
      !components[2].isEmpty
    else { return nil }
    return URL(
      fileURLWithPath: String(path[..<marker.upperBound]) + "\(components[0])/apps/\(components[2])"
    )
    .standardizedFileURL
  }

  private static func appHomeContainsXcodeProject(_ appHome: URL, fileManager: FileManager) -> Bool {
    guard let contents = try? fileManager.contentsOfDirectory(
      at: appHome,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    ) else { return false }
    return contents.contains { $0.pathExtension == "xcodeproj" }
  }

  private static func isApplicationTarget(_ target: AppleProjectTarget) -> Bool {
    let type = target.type?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
    return type == "application"
      || type == "application.watchapp2"
      || (type.contains("watch") && type.contains("app"))
  }

  private static func xcodeUnit(
    surface: OwnedSurfaceRecord,
    projectSourceURL: URL,
    spec: AppleProjectSpec,
    targetName: String,
    target: AppleProjectTarget,
    carrierKind: SourceVersionCarrierKind
  ) -> SourceVersionStatusUnit {
    let configurations = configurationNames(spec: spec, target: target).map { configuration in
      let marketing = resolvedXcodeValue(
        key: "MARKETING_VERSION",
        infoKey: "CFBundleShortVersionString",
        projectSourceURL: projectSourceURL,
        spec: spec,
        targetName: targetName,
        target: target,
        configuration: configuration
      )
      let build = resolvedXcodeValue(
        key: "CURRENT_PROJECT_VERSION",
        infoKey: "CFBundleVersion",
        projectSourceURL: projectSourceURL,
        spec: spec,
        targetName: targetName,
        target: target,
        configuration: configuration
      )
      return SourceVersionStatusConfiguration(
        name: configuration,
        marketingVersion: marketing.value,
        marketingVersionCarrierRef: marketing.carrierRef,
        buildNumber: build.value,
        buildNumberCarrierRef: build.carrierRef
      )
    }
    let authorityStatus: SourceVersionAuthorityStatus = .sourceDeclared
    let versions = configurations.compactMap(\.marketingVersion)
    let policyStatus: SourceVersionPolicyStatus = configurations.contains { $0.marketingVersion == nil }
      ? .unresolved
      : Self.policyStatus(for: versions, authorityStatus: authorityStatus)
    let buildStatus: SourceBuildNumberStatus =
      configurations.allSatisfy { $0.buildNumber != nil } ? .sourceDeclared : .unresolved
    let diagnostic = configurations.contains { $0.marketingVersion == nil || $0.buildNumber == nil }
      ? "One or more build configurations do not resolve an owner-controlled source version or build number."
      : nil
    return SourceVersionStatusUnit(
      targetRef: SourceVersionTargetRef(path: projectSourceURL.path, target: targetName),
      owner: surface.owner,
      ownershipScope: surface.ownershipScope,
      targetKind: .xcodeApp,
      carrierKind: carrierKind,
      authorityStatus: authorityStatus,
      configurations: configurations,
      versionPolicyStatus: policyStatus,
      buildNumberStatus: buildStatus,
      diagnostic: diagnostic
    )
  }

  private struct ResolvedSourceValue {
    var value: String?
    var carrierRef: String?
  }

  private static func resolvedXcodeValue(
    key: String,
    infoKey: String,
    projectSourceURL: URL,
    spec: AppleProjectSpec,
    targetName: String,
    target: AppleProjectTarget,
    configuration: String
  ) -> ResolvedSourceValue {
    let targetPrefix = "\(projectSourceURL.path)#targets.\(targetName)"
    if key == "MARKETING_VERSION", let value = usableSourceValue(target.releaseIdentity?.shortVersion) {
      return ResolvedSourceValue(value: value, carrierRef: "\(targetPrefix).releaseIdentity.shortVersion")
    }
    if key == "CURRENT_PROJECT_VERSION", let value = usableSourceValue(target.releaseIdentity?.buildVersion) {
      return ResolvedSourceValue(value: value, carrierRef: "\(targetPrefix).releaseIdentity.buildVersion")
    }
    if let result = settingsValue(
      key: key,
      settings: target.settings,
      prefix: "\(targetPrefix).settings",
      configuration: configuration
    ) {
      return result
    }
    if let result = settingsValue(
      key: key,
      settings: spec.settings,
      prefix: "\(projectSourceURL.path)#settings",
      configuration: configuration
    ) {
      return result
    }
    if let properties = target.info?.properties,
      let value = usableSourceValue(properties[infoKey]?.stringValue)
    {
      return ResolvedSourceValue(value: value, carrierRef: "\(targetPrefix).info.properties.\(infoKey)")
    }
    if let infoPath = target.info?.path {
      let infoURL = projectSourceURL.deletingLastPathComponent().appendingPathComponent(infoPath)
      if let value = directInfoPlistValue(at: infoURL, key: infoKey) {
        return ResolvedSourceValue(value: value, carrierRef: "\(infoURL.path)#\(infoKey)")
      }
    }
    return ResolvedSourceValue(value: nil, carrierRef: nil)
  }

  private static func settingsValue(
    key: String,
    settings: AppleProjectSettings?,
    prefix: String,
    configuration: String
  ) -> ResolvedSourceValue? {
    if let value = usableSourceValue(settings?.configs?[configuration]?[key]?.stringValue) {
      return ResolvedSourceValue(value: value, carrierRef: "\(prefix).configs.\(configuration).\(key)")
    }
    if let value = usableSourceValue(settings?.base?[key]?.stringValue) {
      return ResolvedSourceValue(value: value, carrierRef: "\(prefix).base.\(key)")
    }
    return nil
  }

  private static func directInfoPlistValue(at url: URL, key: String) -> String? {
    guard let data = try? Data(contentsOf: url),
      let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
      let dictionary = object as? [String: Any]
    else { return nil }
    return usableSourceValue(dictionary[key] as? String)
  }

  private static func usableSourceValue(_ raw: String?) -> String? {
    guard let raw else { return nil }
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, !value.contains("$(") else { return nil }
    return value
  }

  private static func configurationNames(spec: AppleProjectSpec, target: AppleProjectTarget) -> [String] {
    var names: Set<String> = ["Debug", "Release"]
    if let configs = spec.configs { names.formUnion(configs.keys) }
    if let configs = spec.settings?.configs { names.formUnion(configs.keys) }
    if let configs = target.settings?.configs { names.formUnion(configs.keys) }
    return names.sorted {
      let lhsRank = configurationRank($0)
      let rhsRank = configurationRank($1)
      if lhsRank != rhsRank { return lhsRank < rhsRank }
      return $0.localizedStandardCompare($1) == .orderedAscending
    }
  }

  private static func configurationRank(_ value: String) -> Int {
    switch value {
    case "Debug": return 0
    case "Release": return 1
    default: return 100
    }
  }

  private static func swiftPMUnits(
    surface: OwnedSurfaceRecord,
    packageURL: URL,
    fileManager: FileManager
  ) -> [SourceVersionStatusUnit] {
    let packageDirectory = packageURL.deletingLastPathComponent()
    let sourcesDirectory = packageDirectory.appendingPathComponent("Sources", isDirectory: true)
    guard let targetDirectories = swiftPMTargetDirectories(at: sourcesDirectory, fileManager: fileManager) else {
      return []
    }

    return targetDirectories.compactMap { targetDirectory in
      let sourceFiles = swiftSourceFiles(at: targetDirectory, fileManager: fileManager)
      guard !sourceFiles.isEmpty else { return nil }
      let sourceTexts = sourceFiles.compactMap { try? String(contentsOf: $0, encoding: .utf8) }
      let combinedSource = sourceTexts.joined(separator: "\n")
      guard hasApplicationEntry(in: combinedSource) else { return nil }

      let versionFile = sourceFiles
        .filter { $0.lastPathComponent == "AppVersion.swift" }
        .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
        .first
      let declaredVersion = versionFile.flatMap { marketingVersion(in: $0) }
      let versionIsRuntimeLinked = versionFile.map {
        runtimeVersionCarrierIsLinked(versionFile: $0, sourceFiles: sourceFiles)
      } ?? false
      let authorityStatus: SourceVersionAuthorityStatus
      let diagnostic: String?
      if declaredVersion == nil {
        authorityStatus = .sourceCarrierMissing
        diagnostic = "Application entry exists but no AppVersion.swift marketing-version carrier was found."
      } else if !versionIsRuntimeLinked {
        authorityStatus = .candidateNotRuntimeLinked
        diagnostic = "AppVersion.swift declares a marketing version but the target source does not reference its .marketingVersion value."
      } else {
        authorityStatus = .sourceDeclared
        diagnostic = nil
      }

      let carrierRef = versionFile?.path ?? "\(packageURL.path)#Sources/\(targetDirectory.lastPathComponent)"
      let configuration = SourceVersionStatusConfiguration(
        name: "runtime-source",
        marketingVersion: declaredVersion,
        marketingVersionCarrierRef: carrierRef,
        buildNumber: nil,
        buildNumberCarrierRef: nil
      )
      return SourceVersionStatusUnit(
        targetRef: SourceVersionTargetRef(path: packageURL.path, target: targetDirectory.lastPathComponent),
        owner: surface.owner,
        ownershipScope: surface.ownershipScope,
        targetKind: .swiftPMApp,
        carrierKind: .swiftPMRuntimeSourceAppVersion,
        authorityStatus: authorityStatus,
        configurations: [configuration],
        versionPolicyStatus: policyStatus(
          for: declaredVersion.map { [$0] } ?? [],
          authorityStatus: authorityStatus
        ),
        buildNumberStatus: .notApplicable,
        diagnostic: diagnostic
      )
    }
  }

  private static func swiftPMTargetDirectories(
    at sourcesDirectory: URL,
    fileManager: FileManager
  ) -> [URL]? {
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: sourcesDirectory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
      return nil
    }
    guard let contents = try? fileManager.contentsOfDirectory(
      at: sourcesDirectory,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    ) else { return nil }
    let directories = contents.filter {
      (try? $0.resourceValues(forKeys: Set([.isDirectoryKey])).isDirectory) == true
    }
    let directSwiftFiles = contents.contains { $0.pathExtension == "swift" }
    var targets = directories
    if directSwiftFiles { targets.append(sourcesDirectory) }
    return targets.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
  }

  private static func swiftSourceFiles(at directory: URL, fileManager: FileManager) -> [URL] {
    let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey]
    guard let enumerator = fileManager.enumerator(
      at: directory,
      includingPropertiesForKeys: keys,
      options: [.skipsHiddenFiles],
      errorHandler: { _, _ in true }
    ) else { return [] }
    var files: [URL] = []
    while let candidate = enumerator.nextObject() as? URL {
      let values = try? candidate.resourceValues(forKeys: Set(keys))
      if values?.isDirectory == true {
        if [".build", ".git", ".swiftpm"].contains(candidate.lastPathComponent) {
          enumerator.skipDescendants()
        }
        continue
      }
      if values?.isRegularFile == true, candidate.pathExtension == "swift" {
        files.append(candidate)
      }
    }
    return files.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
  }

  private static func hasApplicationEntry(in source: String) -> Bool {
    source.contains("NSApplication.shared")
      || source.range(of: #":\s*(SwiftUI\.)?App\b"#, options: .regularExpression) != nil
      || source.range(of: #"[A-Za-z0-9_]+App\.main\(\)"#, options: .regularExpression) != nil
  }

  private static func marketingVersion(in file: URL) -> String? {
    guard let source = try? String(contentsOf: file, encoding: .utf8) else { return nil }
    let pattern = #"static\s+let\s+marketingVersion\s*=\s*\"([^\"]+)\""#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(source.startIndex..<source.endIndex, in: source)
    guard let match = regex.firstMatch(in: source, range: range),
      match.numberOfRanges > 1,
      let valueRange = Range(match.range(at: 1), in: source)
    else { return nil }
    return usableSourceValue(String(source[valueRange]))
  }

  private static func runtimeVersionCarrierIsLinked(versionFile: URL, sourceFiles: [URL]) -> Bool {
    guard let source = try? String(contentsOf: versionFile, encoding: .utf8),
      let typeName = declaredTypeName(in: source)
    else { return false }
    let usage = "\(typeName).marketingVersion"
    return sourceFiles.contains { file in
      guard file.standardizedFileURL != versionFile.standardizedFileURL,
        let text = try? String(contentsOf: file, encoding: .utf8)
      else { return false }
      return text.contains(usage)
    }
  }

  private static func declaredTypeName(in source: String) -> String? {
    let pattern = #"(?m)^\s*(?:enum|struct|class)\s+([A-Za-z_][A-Za-z0-9_]*)"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(source.startIndex..<source.endIndex, in: source)
    guard let match = regex.firstMatch(in: source, range: range),
      match.numberOfRanges > 1,
      let nameRange = Range(match.range(at: 1), in: source)
    else { return nil }
    return String(source[nameRange])
  }

  private static func isZeroMinorVersion(_ version: String) -> Bool {
    let parts = version.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count == 3, parts[0] == "0", parts[1] == "0", !parts[2].isEmpty else {
      return false
    }
    return parts[2].allSatisfy { $0.isNumber }
  }
}

enum SourceVersionStatusRenderer {
  static func renderText(_ receipt: SourceVersionStatusReceipt) -> String {
    var lines: [String] = []
    lines.append("vaporize version-status - Apple application source identities at \(receipt.scannedPath)")
    lines.append("boundary: source declarations only; no installed, publication, consumer-upgrade, or historical-wire claim")
    lines.append(
      "reporter: \(receipt.reporter.product) \(receipt.reporter.version) build \(receipt.reporter.buildNumber) [\(receipt.reporter.versionPolicyStatus.rawValue)]"
    )
    lines.append(
      "summary: units=\(receipt.summary.totalUnits) compliant=\(receipt.summary.zeroMinorCompliant) outside-policy=\(receipt.summary.outsidePolicy) unresolved=\(receipt.summary.unresolved) source-build=\(receipt.summary.sourceDeclaredBuildNumbers) build-not-applicable=\(receipt.summary.buildNumbersNotApplicable) build-unresolved=\(receipt.summary.unresolvedBuildNumbers) findings=\(receipt.summary.discoveryFindings)"
    )
    lines.append(String(repeating: "-", count: 116))
    lines.append(header())
    lines.append(String(repeating: "-", count: 116))
    if receipt.units.isEmpty {
      lines.append("(no Apple application source targets discovered in scope)")
    } else {
      for unit in receipt.units {
        lines.append(row(unit, basePath: receipt.scannedPath))
        if let diagnostic = unit.diagnostic {
          lines.append("    ! \(diagnostic)")
        }
      }
    }
    if !receipt.discoveryFindings.isEmpty {
      lines.append(String(repeating: "-", count: 116))
      lines.append("discovery findings")
      for finding in receipt.discoveryFindings {
        lines.append("  [\(finding.kind)] \(finding.sourceRef): \(finding.detail)")
      }
    }
    return lines.joined(separator: "\n")
  }

  static func renderJSON(_ receipt: SourceVersionStatusReceipt) throws -> Data {
    try VaporInventoryRenderer.makeJSONEncoder().encode(receipt)
  }

  private static func header() -> String {
    "\(pad("owner", 18)) \(pad("target", 26)) \(pad("version", 18)) \(pad("build", 18)) \(pad("policy", 16)) \(pad("build-status", 20)) carrier"
  }

  private static func row(_ unit: SourceVersionStatusUnit, basePath: String) -> String {
    let versions = uniqueConfigurationValues(unit.configurations.map(\.marketingVersion))
    let builds = uniqueConfigurationValues(unit.configurations.map(\.buildNumber))
    let target = "\(relativePath(unit.targetRef.path, relativeTo: basePath))#\(unit.targetRef.target)"
    let carrier = unit.configurations.compactMap(\.marketingVersionCarrierRef).first ?? "-"
    return "\(pad(unit.owner ?? "-", 18)) \(pad(target, 26)) \(pad(versions, 18)) \(pad(builds, 18)) \(pad(unit.versionPolicyStatus.rawValue, 16)) \(pad(unit.buildNumberStatus.rawValue, 20)) \(carrier)"
  }

  private static func uniqueConfigurationValues(_ values: [String?]) -> String {
    let unique = values.compactMap { $0 }.reduce(into: [String]()) { result, value in
      if !result.contains(value) { result.append(value) }
    }
    return unique.isEmpty ? "missing" : unique.joined(separator: ",")
  }

  private static func relativePath(_ path: String, relativeTo basePath: String) -> String {
    if path.hasPrefix(basePath + "/") {
      return String(path.dropFirst(basePath.count + 1))
    }
    return path
  }

  private static func pad(_ value: String, _ width: Int) -> String {
    guard value.count < width else { return value }
    return value + String(repeating: " ", count: width - value.count)
  }
}
