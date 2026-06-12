import Foundation
import Yams

public struct AppleProjectSpec: Codable, Equatable, Sendable {
  public var name: String
  public var options: AppleProjectOptions?
  public var settings: AppleProjectSettings?
  public var packages: [String: AppleProjectPackage]
  public var targets: [String: AppleProjectTarget]
  public var schemes: [String: AppleProjectScheme]

  public init(
    name: String,
    options: AppleProjectOptions? = nil,
    settings: AppleProjectSettings? = nil,
    packages: [String: AppleProjectPackage] = [:],
    targets: [String: AppleProjectTarget] = [:],
    schemes: [String: AppleProjectScheme] = [:]
  ) {
    self.name = name
    self.options = options
    self.settings = settings
    self.packages = packages
    self.targets = targets
    self.schemes = schemes
  }

  enum CodingKeys: String, CodingKey {
    case name
    case options
    case settings
    case packages
    case targets
    case schemes
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.name = try container.decode(String.self, forKey: .name)
    self.options = try container.decodeIfPresent(AppleProjectOptions.self, forKey: .options)
    self.settings = try container.decodeIfPresent(AppleProjectSettings.self, forKey: .settings)
    self.packages = try container.decodeIfPresent([String: AppleProjectPackage].self, forKey: .packages) ?? [:]
    self.targets = try container.decodeIfPresent([String: AppleProjectTarget].self, forKey: .targets) ?? [:]
    self.schemes = try container.decodeIfPresent([String: AppleProjectScheme].self, forKey: .schemes) ?? [:]
  }
}

public struct AppleProjectOptions: Codable, Equatable, Sendable {
  public var minimumXcodeGenVersion: String?
  public var useBaseInternationalization: Bool?
  public var createIntermediateGroups: Bool?
}

public struct AppleProjectSettings: Codable, Equatable, Sendable {
  public var base: [String: AppleProjectValue]?
  public var configs: [String: [String: AppleProjectValue]]?
}

public struct AppleProjectPackage: Codable, Equatable, Sendable {
  public var path: String?
  public var url: String?
  public var from: String?
  public var branch: String?
  public var exact: String?
  public var revision: String?
}

public struct AppleProjectTarget: Codable, Equatable, Sendable {
  public var type: String?
  public var platform: String?
  public var deploymentTarget: AppleProjectValue?
  public var sources: [AppleProjectSource]?
  public var info: AppleProjectInfo?
  public var settings: AppleProjectSettings?
  public var dependencies: [AppleProjectDependency]?
  public var preBuildScripts: [AppleProjectBuildScript]?
  public var postBuildScripts: [AppleProjectBuildScript]?
}

public struct AppleProjectSource: Codable, Equatable, Sendable {
  public var path: String
  public var name: String?
  public var type: String?
  public var optional: Bool?
  public var excludes: [String]?

  public init(
    path: String,
    name: String? = nil,
    type: String? = nil,
    optional: Bool? = nil,
    excludes: [String]? = nil
  ) {
    self.path = path
    self.name = name
    self.type = type
    self.optional = optional
    self.excludes = excludes
  }

  public init(from decoder: Decoder) throws {
    if let single = try? decoder.singleValueContainer(),
      let path = try? single.decode(String.self)
    {
      self.init(path: path)
      return
    }

    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      path: try container.decode(String.self, forKey: .path),
      name: try container.decodeIfPresent(String.self, forKey: .name),
      type: try container.decodeIfPresent(String.self, forKey: .type),
      optional: try container.decodeIfPresent(Bool.self, forKey: .optional),
      excludes: try container.decodeIfPresent([String].self, forKey: .excludes)
    )
  }
}

public struct AppleProjectInfo: Codable, Equatable, Sendable {
  public var path: String?
  public var properties: [String: AppleProjectValue]?
}

public struct AppleProjectDependency: Codable, Equatable, Sendable {
  public var package: String?
  public var product: String?
  public var target: String?
  public var embed: Bool?
  public var codeSign: Bool?
}

public struct AppleProjectBuildScript: Codable, Equatable, Sendable {
  public var name: String?
  public var basedOnDependencyAnalysis: Bool?
  public var script: String
}

public struct AppleProjectScheme: Codable, Equatable, Sendable {
  public var shared: Bool?
  public var build: AppleProjectValue?
  public var run: AppleProjectValue?
  public var test: AppleProjectValue?
}

public enum AppleProjectValue: Codable, Equatable, Sendable {
  case null
  case bool(Bool)
  case int(Int)
  case double(Double)
  case string(String)
  case array([AppleProjectValue])
  case object([String: AppleProjectValue])

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(Int.self) {
      self = .int(value)
    } else if let value = try? container.decode(Double.self) {
      self = .double(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode([AppleProjectValue].self) {
      self = .array(value)
    } else if let value = try? container.decode([String: AppleProjectValue].self) {
      self = .object(value)
    } else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported YAML value.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .null:
      try container.encodeNil()
    case .bool(let value):
      try container.encode(value)
    case .int(let value):
      try container.encode(value)
    case .double(let value):
      try container.encode(value)
    case .string(let value):
      try container.encode(value)
    case .array(let value):
      try container.encode(value)
    case .object(let value):
      try container.encode(value)
    }
  }

  public var stringValue: String? {
    switch self {
    case .null:
      return nil
    case .bool(let value):
      return value ? "true" : "false"
    case .int(let value):
      return String(value)
    case .double(let value):
      return String(value)
    case .string(let value):
      return value
    case .array, .object:
      return nil
    }
  }

  public var boolValue: Bool? {
    if case .bool(let value) = self { return value }
    return nil
  }
}

public enum AppleProjectYMLReader {
  public static func load(url: URL) throws -> AppleProjectSpec {
    let data = try Data(contentsOf: url)
    return try decode(data: data)
  }

  public static func decode(data: Data) throws -> AppleProjectSpec {
    try YAMLDecoder().decode(AppleProjectSpec.self, from: data)
  }

  public static func receipt(
    for spec: AppleProjectSpec,
    path: String,
    requestId: String
  ) -> AppleProjectYMLInspectionReceipt {
    let targetSummaries = spec.targets
      .map { name, target in
        AppleProjectTargetSummary(
          name: name,
          type: target.type,
          platform: target.platform,
          sourceCount: target.sources?.count ?? 0,
          dependencyCount: target.dependencies?.count ?? 0,
          hasPreBuildScripts: !(target.preBuildScripts?.isEmpty ?? true),
          hasPostBuildScripts: !(target.postBuildScripts?.isEmpty ?? true)
        )
      }
      .sorted { $0.name < $1.name }

    return AppleProjectYMLInspectionReceipt(
      path: path,
      requestId: requestId,
      projectName: spec.name,
      targetCount: spec.targets.count,
      packageCount: spec.packages.count,
      schemeCount: spec.schemes.count,
      targetNames: spec.targets.keys.sorted(),
      packageNames: spec.packages.keys.sorted(),
      targetSummaries: targetSummaries
    )
  }
}

public enum AppleProjectAppBundleNameResolver {
  public static func appBundleName(
    in spec: AppleProjectSpec,
    targetName: String,
    configuration: String
  ) -> String? {
    guard let target = spec.targets[targetName] ?? singleTarget(in: spec) else {
      return nil
    }

    var settings: [String: String] = [:]
    merge(spec.settings?.base, into: &settings)
    merge(configValues(in: spec.settings, configuration: configuration), into: &settings)
    merge(target.settings?.base, into: &settings)
    merge(configValues(in: target.settings, configuration: configuration), into: &settings)

    guard let declaredName = settings["WRAPPER_NAME"] ?? settings["PRODUCT_NAME"] else {
      return nil
    }

    let expandedName = expand(declaredName, settings: settings)
    guard !expandedName.contains("$("), !expandedName.contains("${") else {
      return nil
    }

    if expandedName.hasSuffix(".app") {
      return String(expandedName.dropLast(4))
    }
    return expandedName.isEmpty ? nil : expandedName
  }

  private static func singleTarget(in spec: AppleProjectSpec) -> AppleProjectTarget? {
    guard spec.targets.count == 1 else { return nil }
    return spec.targets.first?.value
  }

  private static func configValues(
    in settings: AppleProjectSettings?,
    configuration: String
  ) -> [String: AppleProjectValue]? {
    guard let configs = settings?.configs else { return nil }
    if let exact = configs[configuration] {
      return exact
    }
    return configs.first { key, _ in
      key.caseInsensitiveCompare(configuration) == .orderedSame
    }?.value
  }

  private static func merge(
    _ values: [String: AppleProjectValue]?,
    into settings: inout [String: String]
  ) {
    guard let values else { return }
    for (key, value) in values {
      if let stringValue = value.stringValue {
        settings[key] = stringValue
      }
    }
  }

  private static func expand(_ value: String, settings: [String: String]) -> String {
    var expanded = value
    for _ in 0..<8 {
      var changed = false
      for (key, replacement) in settings {
        let parenthesized = "$(\(key))"
        let braced = "${\(key)}"
        if expanded.contains(parenthesized) {
          expanded = expanded.replacingOccurrences(of: parenthesized, with: replacement)
          changed = true
        }
        if expanded.contains(braced) {
          expanded = expanded.replacingOccurrences(of: braced, with: replacement)
          changed = true
        }
      }
      if !changed { break }
    }
    return expanded
  }
}

public struct AppleProjectYMLInspectionReceipt: Codable, Equatable, Sendable {
  public var schemaVersion = "0.1.0"
  public var receiptKind = "vaporize-apple-project-yml-inspection"
  public var bridgeStatus = "legacy-xcodegen-yaml-read-only"
  public var migrationPhase = "swift-yaml-read-parity"
  public var path: String
  public var requestId: String
  public var projectName: String
  public var targetCount: Int
  public var packageCount: Int
  public var schemeCount: Int
  public var targetNames: [String]
  public var packageNames: [String]
  public var targetSummaries: [AppleProjectTargetSummary]
}

public struct AppleProjectTargetSummary: Codable, Equatable, Sendable {
  public var name: String
  public var type: String?
  public var platform: String?
  public var sourceCount: Int
  public var dependencyCount: Int
  public var hasPreBuildScripts: Bool
  public var hasPostBuildScripts: Bool
}
