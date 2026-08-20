import Foundation

public enum VaporizeTargetFeatureInspectionError: Error, CustomStringConvertible, Sendable {
  case targetNotFound(String, available: [String])
  case targetAmbiguous(available: [String], candidatesWithConfigFiles: [String])

  public var description: String {
    switch self {
    case .targetNotFound(let targetName, let available):
      return "target not found: \(targetName). Available targets: \(available.joined(separator: ", "))"
    case .targetAmbiguous(let available, let candidatesWithConfigFiles):
      if candidatesWithConfigFiles.isEmpty {
        return "target is required because project has multiple targets and none declare configFiles. Available targets: \(available.joined(separator: ", "))"
      }
      return "target is required because multiple targets could be inspected. Targets declaring configFiles: \(candidatesWithConfigFiles.joined(separator: ", "))"
    }
  }
}

public enum VaporizeTargetFeaturesInspector {
  /// The canonical generator moved to Wrkstrm-core. The historical marker is
  /// intentionally still accepted so immutable artifacts emitted before the
  /// migration remain inspectable. This is provenance compatibility, not a
  /// source-package forwarding path.
  private static let currentReleaseFeaturesProvenance =
    "release-features.digikoma-s@wrkstrm-core.collective.clia.sh"
  private static let historicalReleaseFeaturesProvenance = "digikoma-release-features"

  public static func inspect(
    projectYMLURL: URL,
    targetName requestedTargetName: String?,
    requestId: String
  ) throws -> VaporizeTargetFeaturesInspectionReceipt {
    let projectYMLURL = projectYMLURL.standardizedFileURL
    let projectRoot = projectYMLURL.deletingLastPathComponent()
    let spec = try AppleProjectYMLReader.load(url: projectYMLURL)
    let resolved = try resolveTarget(in: spec, requestedTargetName: requestedTargetName)
    let target = resolved.target
    let targetConfigFiles = target.configFiles ?? [:]
    let manifestURL = inferManifestURL(
      configFiles: targetConfigFiles,
      projectRoot: projectRoot
    )
    let manifest = try loadManifestIfPresent(url: manifestURL)
    let releaseFeaturesSwiftURL = releaseFeaturesSwiftURL(for: manifestURL)

    let targetConfigFileInspections = inspectTargetConfigFiles(
      configFiles: targetConfigFiles,
      projectRoot: projectRoot
    )
    let tierInspections = inspectGeneratedXcconfigs(
      manifest: manifest,
      manifestURL: manifestURL,
      configFiles: targetConfigFiles,
      projectRoot: projectRoot
    )
    let releaseFeaturesSwift = inspectGeneratedFile(url: releaseFeaturesSwiftURL)
    let minimums = minimumInspections(
      spec: spec,
      targetConfigFiles: targetConfigFiles,
      manifest: manifest,
      manifestURL: manifestURL,
      tierInspections: tierInspections,
      releaseFeaturesSwift: releaseFeaturesSwift
    )
    let overallStatus = minimums.allSatisfy { $0.status == "pass" } ? "pass" : "fail"

    return VaporizeTargetFeaturesInspectionReceipt(
      projectYMLPath: projectYMLURL.path,
      requestId: requestId,
      projectName: spec.name,
      targetName: resolved.name,
      targetType: target.type,
      targetPlatform: target.platform,
      overallStatus: overallStatus,
      declaredBuildConfigurations: declaredBuildConfigurations(in: spec),
      targetConfigFiles: targetConfigFileInspections,
      releaseFeatureManifest: manifestInspection(manifest: manifest, url: manifestURL),
      generatedXcconfigs: tierInspections,
      releaseFeaturesSwift: releaseFeaturesSwift,
      minimums: minimums
    )
  }

  private static func resolveTarget(
    in spec: AppleProjectSpec,
    requestedTargetName: String?
  ) throws -> (name: String, target: AppleProjectTarget) {
    let targetNames = spec.targets.keys.sorted()
    if let requestedTargetName, !requestedTargetName.isEmpty {
      guard let target = spec.targets[requestedTargetName] else {
        throw VaporizeTargetFeatureInspectionError.targetNotFound(
          requestedTargetName,
          available: targetNames
        )
      }
      return (requestedTargetName, target)
    }

    let candidatesWithConfigFiles = targetNames.filter { name in
      !(spec.targets[name]?.configFiles?.isEmpty ?? true)
    }
    if candidatesWithConfigFiles.count == 1,
      let name = candidatesWithConfigFiles.first,
      let target = spec.targets[name]
    {
      return (name, target)
    }
    if targetNames.count == 1,
      let name = targetNames.first,
      let target = spec.targets[name]
    {
      return (name, target)
    }
    throw VaporizeTargetFeatureInspectionError.targetAmbiguous(
      available: targetNames,
      candidatesWithConfigFiles: candidatesWithConfigFiles
    )
  }

  private static func declaredBuildConfigurations(in spec: AppleProjectSpec) -> [VaporizeBuildConfigurationInspection] {
    (spec.configs ?? [:])
      .map { name, kind in
        VaporizeBuildConfigurationInspection(name: name, kind: kind)
      }
      .sorted { $0.name < $1.name }
  }

  private static func inspectTargetConfigFiles(
    configFiles: [String: String],
    projectRoot: URL
  ) -> [VaporizeTargetConfigFileInspection] {
    configFiles
      .map { configuration, path in
        let url = resolvedURL(path: path, relativeTo: projectRoot)
        return VaporizeTargetConfigFileInspection(
          configuration: configuration,
          path: path,
          absolutePath: url.path,
          exists: FileManager.default.fileExists(atPath: url.path)
        )
      }
      .sorted { $0.configuration < $1.configuration }
  }

  private static func inspectGeneratedXcconfigs(
    manifest: ReleaseFeaturesManifest?,
    manifestURL: URL,
    configFiles: [String: String],
    projectRoot: URL
  ) -> [VaporizeGeneratedXcconfigInspection] {
    guard let manifest else { return [] }
    return manifest.tiers.map { tier in
      let declaredPath = value(in: configFiles, caseInsensitiveKey: tier.xcodeConfig)
      let path = declaredPath ?? inferredXcconfigPath(for: tier, manifestURL: manifestURL)
      let url = resolvedURL(path: path, relativeTo: projectRoot)
      let text = try? String(contentsOf: url, encoding: .utf8)
      let conditions = compilationConditions(in: text ?? "")
      let requiredConditions = ([tier.compilationCondition] + tier.features)
        .filter { !$0.isEmpty }
      let missingConditions = requiredConditions.filter { !conditions.contains($0) }
      let generatedByDigikoma = hasReleaseFeaturesProvenance(text)
      let exists = FileManager.default.fileExists(atPath: url.path)
      let status = declaredPath != nil && exists && generatedByDigikoma && missingConditions.isEmpty
        ? "pass"
        : "fail"

      return VaporizeGeneratedXcconfigInspection(
        tierId: tier.id,
        xcodeConfig: tier.xcodeConfig,
        path: path,
        absolutePath: url.path,
        declaredByTarget: declaredPath != nil,
        exists: exists,
        generatedByDigikomaReleaseFeatures: generatedByDigikoma,
        compilationConditions: conditions,
        missingCompilationConditions: missingConditions,
        status: status
      )
    }
  }

  private static func inspectGeneratedFile(url: URL) -> VaporizeGeneratedFileInspection {
    let text = try? String(contentsOf: url, encoding: .utf8)
    let exists = FileManager.default.fileExists(atPath: url.path)
    let generatedByDigikoma = hasReleaseFeaturesProvenance(text)
    return VaporizeGeneratedFileInspection(
      path: url.path,
      exists: exists,
      generatedByDigikomaReleaseFeatures: generatedByDigikoma,
      status: exists && generatedByDigikoma ? "pass" : "fail"
    )
  }

  private static func manifestInspection(
    manifest: ReleaseFeaturesManifest?,
    url: URL
  ) -> VaporizeReleaseFeatureManifestInspection {
    let tiers = manifest?.tiers.map {
      VaporizeReleaseFeatureTierInspection(
        id: $0.id,
        xcodeConfig: $0.xcodeConfig,
        displayName: $0.displayName,
        compilationCondition: $0.compilationCondition,
        features: $0.features
      )
    } ?? []
    let featureFlags = Set(tiers.flatMap(\.features)).sorted()
    let exists = FileManager.default.fileExists(atPath: url.path)
    return VaporizeReleaseFeatureManifestInspection(
      path: url.path,
      exists: exists,
      appSlug: manifest?.appSlug,
      tierCount: tiers.count,
      tiers: tiers,
      featureFlags: featureFlags,
      status: exists && manifest != nil && !tiers.isEmpty ? "pass" : "fail"
    )
  }

  private static func minimumInspections(
    spec: AppleProjectSpec,
    targetConfigFiles: [String: String],
    manifest: ReleaseFeaturesManifest?,
    manifestURL: URL,
    tierInspections: [VaporizeGeneratedXcconfigInspection],
    releaseFeaturesSwift: VaporizeGeneratedFileInspection
  ) -> [VaporizeMinimumInspection] {
    let declaredConfigs = !(spec.configs?.isEmpty ?? true)
    let declaredConfigFiles = !targetConfigFiles.isEmpty
    let manifestExists = FileManager.default.fileExists(atPath: manifestURL.path)
    let tiersDeclared = !(manifest?.tiers.isEmpty ?? true)
    let allTiersMapped = manifest?.tiers.allSatisfy {
      value(in: targetConfigFiles, caseInsensitiveKey: $0.xcodeConfig) != nil
    } ?? false
    let allXcconfigsPass = !tierInspections.isEmpty && tierInspections.allSatisfy { $0.status == "pass" }
    let allConditionsPresent = !tierInspections.isEmpty
      && tierInspections.allSatisfy { $0.missingCompilationConditions.isEmpty }
    let xcconfigProvenancePresent = !tierInspections.isEmpty
      && tierInspections.allSatisfy(\.generatedByDigikomaReleaseFeatures)
    let digikomaProvenancePresent = xcconfigProvenancePresent
      && releaseFeaturesSwift.generatedByDigikomaReleaseFeatures

    return [
      minimum(
        "projectConfigurationsDeclared",
        pass: declaredConfigs,
        detail: declaredConfigs ? "project.yml declares top-level Xcode configurations" : "project.yml does not declare top-level configs"
      ),
      minimum(
        "targetConfigFilesDeclared",
        pass: declaredConfigFiles,
        detail: declaredConfigFiles ? "target maps configurations to xcconfig files" : "target does not declare configFiles"
      ),
      minimum(
        "releaseFeatureManifest",
        pass: manifestExists && manifest != nil,
        detail: manifestExists ? manifestURL.path : "missing \(manifestURL.path)"
      ),
      minimum(
        "manifestTiersDeclared",
        pass: tiersDeclared,
        detail: tiersDeclared ? "release-features.json declares tiers" : "release-features.json has no tiers"
      ),
      minimum(
        "projectWiringMatchesManifest",
        pass: allTiersMapped,
        detail: allTiersMapped ? "each manifest xcodeConfig has target configFiles wiring" : "one or more manifest xcodeConfig values are not mapped by target configFiles"
      ),
      minimum(
        "generatedXcconfigs",
        pass: allXcconfigsPass,
        detail: allXcconfigsPass ? "generated xcconfigs exist and match manifest conditions" : "one or more generated xcconfigs are missing, stale, or not wired"
      ),
      minimum(
        "featureFlagConditionsMatchManifest",
        pass: allConditionsPresent,
        detail: allConditionsPresent ? "xcconfig compilation conditions match release-features.json" : "one or more manifest conditions are missing from generated xcconfigs"
      ),
      minimum(
        "releaseFeaturesSwift",
        pass: releaseFeaturesSwift.status == "pass",
        detail: releaseFeaturesSwift.path
      ),
      minimum(
        "digikomaReleaseFeaturesProvenance",
        pass: digikomaProvenancePresent,
        detail: digikomaProvenancePresent ? "generated files carry recognized release-features provenance" : "generated file provenance is missing"
      ),
    ]
  }

  private static func minimum(_ name: String, pass: Bool, detail: String) -> VaporizeMinimumInspection {
    VaporizeMinimumInspection(
      name: name,
      status: pass ? "pass" : "fail",
      detail: detail
    )
  }

  private static func hasReleaseFeaturesProvenance(_ text: String?) -> Bool {
    guard let text else { return false }
    return text.contains(currentReleaseFeaturesProvenance)
      || text.contains(historicalReleaseFeaturesProvenance)
  }

  private static func inferManifestURL(
    configFiles: [String: String],
    projectRoot: URL
  ) -> URL {
    guard let firstPath = configFiles.sorted(by: { $0.key < $1.key }).first?.value else {
      return projectRoot.appendingPathComponent("Config/release-features.json").standardizedFileURL
    }
    let firstURL = resolvedURL(path: firstPath, relativeTo: projectRoot)
    let configDirectory: URL
    if firstURL.deletingLastPathComponent().lastPathComponent == "xcconfigs" {
      configDirectory = firstURL.deletingLastPathComponent().deletingLastPathComponent()
    } else {
      configDirectory = firstURL.deletingLastPathComponent()
    }
    return configDirectory.appendingPathComponent("release-features.json").standardizedFileURL
  }

  private static func inferredXcconfigPath(
    for tier: ReleaseFeatureTier,
    manifestURL: URL
  ) -> String {
    manifestURL
      .deletingLastPathComponent()
      .appendingPathComponent("xcconfigs")
      .appendingPathComponent("\(tier.xcodeConfig).xcconfig")
      .path
  }

  private static func releaseFeaturesSwiftURL(for manifestURL: URL) -> URL {
    manifestURL
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Sources/ReleaseFeatures.swift")
      .standardizedFileURL
  }

  private static func loadManifestIfPresent(url: URL) throws -> ReleaseFeaturesManifest? {
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(ReleaseFeaturesManifest.self, from: data)
  }

  private static func compilationConditions(in text: String) -> [String] {
    for line in text.components(separatedBy: .newlines) {
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      guard trimmed.hasPrefix("SWIFT_ACTIVE_COMPILATION_CONDITIONS") else {
        continue
      }
      guard let equals = trimmed.firstIndex(of: "=") else {
        continue
      }
      let rightHandSide = trimmed[trimmed.index(after: equals)...]
      return rightHandSide
        .split { $0 == " " || $0 == "\t" }
        .map(String.init)
        .filter { $0 != "$(inherited)" }
    }
    return []
  }

  private static func value(in mapping: [String: String], caseInsensitiveKey key: String) -> String? {
    if let exact = mapping[key] {
      return exact
    }
    return mapping.first { candidate, _ in
      candidate.caseInsensitiveCompare(key) == .orderedSame
    }?.value
  }

  private static func resolvedURL(path: String, relativeTo base: URL) -> URL {
    if path.hasPrefix("/") {
      return URL(fileURLWithPath: path).standardizedFileURL
    }
    return base.appendingPathComponent(path).standardizedFileURL
  }
}

public struct VaporizeTargetFeaturesInspectionReceipt: Codable, Equatable, Sendable {
  public var schemaVersion = "0.1.0"
  public var schemaFamilySlug = VaporizeAppleProjectReceiptSchema.schemaFamilySlug
  public var schemaFamilyVersion = VaporizeAppleProjectReceiptSchema.schemaFamilyVersion
  public var schemaRef = VaporizeAppleProjectReceiptSchema.targetFeaturesInspectionSchemaRef
  public var receiptKind = "vaporize-target-features-inspection"
  public var inspectionPhase = "xcodegen-release-features-first-slice"
  public var projectYMLPath: String
  public var requestId: String
  public var projectName: String
  public var targetName: String
  public var targetType: String?
  public var targetPlatform: String?
  public var overallStatus: String
  public var declaredBuildConfigurations: [VaporizeBuildConfigurationInspection]
  public var targetConfigFiles: [VaporizeTargetConfigFileInspection]
  public var releaseFeatureManifest: VaporizeReleaseFeatureManifestInspection
  public var generatedXcconfigs: [VaporizeGeneratedXcconfigInspection]
  public var releaseFeaturesSwift: VaporizeGeneratedFileInspection
  public var minimums: [VaporizeMinimumInspection]
  public var boundaries = [
    "Reads XcodeGen project.yml plus release-features.json; does not mutate project files.",
    "First slice supports wrkstrm release-features topology generated by the canonical release-features Digikoma, while retaining historical provenance inspection.",
    "Pkl-equivalent configFiles inspection is represented in AppleProjectSpec but fleet-wide app registry inspection is future work.",
  ]
}

public struct VaporizeBuildConfigurationInspection: Codable, Equatable, Sendable {
  public var name: String
  public var kind: String
}

public struct VaporizeTargetConfigFileInspection: Codable, Equatable, Sendable {
  public var configuration: String
  public var path: String
  public var absolutePath: String
  public var exists: Bool
}

public struct VaporizeReleaseFeatureManifestInspection: Codable, Equatable, Sendable {
  public var path: String
  public var exists: Bool
  public var appSlug: String?
  public var tierCount: Int
  public var tiers: [VaporizeReleaseFeatureTierInspection]
  public var featureFlags: [String]
  public var status: String
}

public struct VaporizeReleaseFeatureTierInspection: Codable, Equatable, Sendable {
  public var id: String
  public var xcodeConfig: String
  public var displayName: String
  public var compilationCondition: String
  public var features: [String]
}

public struct VaporizeGeneratedXcconfigInspection: Codable, Equatable, Sendable {
  public var tierId: String
  public var xcodeConfig: String
  public var path: String
  public var absolutePath: String
  public var declaredByTarget: Bool
  public var exists: Bool
  public var generatedByDigikomaReleaseFeatures: Bool
  public var compilationConditions: [String]
  public var missingCompilationConditions: [String]
  public var status: String
}

public struct VaporizeGeneratedFileInspection: Codable, Equatable, Sendable {
  public var path: String
  public var exists: Bool
  public var generatedByDigikomaReleaseFeatures: Bool
  public var status: String
}

public struct VaporizeMinimumInspection: Codable, Equatable, Sendable {
  public var name: String
  public var status: String
  public var detail: String
}

public struct ReleaseFeaturesManifest: Codable, Equatable, Sendable {
  public var appSlug: String
  public var tiers: [ReleaseFeatureTier]
  public var featureDescriptions: [String: String]?
}

public struct ReleaseFeatureTier: Codable, Equatable, Sendable {
  public var id: String
  public var xcodeConfig: String
  public var displayName: String
  public var compilationCondition: String
  public var features: [String]
}
