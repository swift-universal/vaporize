import Foundation
import PklSwift
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

public enum AppleProjectPklLoaderError: Error, CustomStringConvertible {
  case evaluationFailed(path: String, underlying: Error)

  public var description: String {
    switch self {
    case .evaluationFailed(let path, let underlying):
      return "PklSwift evaluation failed for \(path): \(underlying)"
    }
  }
}

public enum AppleProjectPklLoader {
  public static func load(url: URL) async throws -> AppleProjectSpec {
    do {
      return try await PklSwift.withEvaluator { evaluator in
        try await evaluator.evaluateModule(source: .path(url.path), as: AppleProjectSpec.self)
      }
    } catch {
      throw AppleProjectPklLoaderError.evaluationFailed(
        path: url.path,
        underlying: error
      )
    }
  }
}

public enum AppleProjectYMLRenderer {
  public static func renderData(spec: AppleProjectSpec) throws -> Data {
    let yaml = try YAMLEncoder().encode(spec)
    return Data(yaml.utf8)
  }
}

public enum AppleProjectPklRenderer {
  public static func renderData(
    spec: AppleProjectSpec,
    schemaAmendsPath: String,
    sourcePath: String? = nil
  ) -> Data {
    Data(render(spec: spec, schemaAmendsPath: schemaAmendsPath, sourcePath: sourcePath).utf8)
  }

  public static func render(
    spec: AppleProjectSpec,
    schemaAmendsPath: String,
    sourcePath: String? = nil
  ) -> String {
    var lines: [String] = [
      "/// Generated by Vaporize from legacy XcodeGen `project.yml`.",
    ]
    if let sourcePath, !sourcePath.isEmpty {
      lines.append("/// Source: \(sourcePath)")
    }
    lines.append("/// Boundary: migration specimen only; Pkl is the forward project truth.")
    lines.append("")
    lines.append("amends \(renderString(schemaAmendsPath))")
    lines.append("")
    lines.append("name = \(renderString(spec.name))")

    if let options = spec.options {
      lines.append("")
      lines.append("options = new {")
      appendOptional("minimumXcodeGenVersion", options.minimumXcodeGenVersion.map(renderString), indent: 2, to: &lines)
      appendOptional("useBaseInternationalization", options.useBaseInternationalization.map(renderBool), indent: 2, to: &lines)
      appendOptional("createIntermediateGroups", options.createIntermediateGroups.map(renderBool), indent: 2, to: &lines)
      lines.append("}")
    }

    if let settings = spec.settings {
      lines.append("")
      lines.append("settings = \(renderSettings(settings, indent: 0))")
    }

    if !spec.targets.isEmpty {
      lines.append("")
      lines.append("targets = new {")
      for name in spec.targets.keys.sorted() {
        guard let target = spec.targets[name] else { continue }
        lines.append("\(indent(2))[\(renderString(name))] = \(renderTarget(target, indent: 2))")
      }
      lines.append("}")
    }

    if !spec.packages.isEmpty {
      lines.append("")
      lines.append("packages = new {")
      for name in spec.packages.keys.sorted() {
        guard let package = spec.packages[name] else { continue }
        lines.append("\(indent(2))[\(renderString(name))] = \(renderPackage(package, indent: 2))")
      }
      lines.append("}")
    }

    if !spec.schemes.isEmpty {
      lines.append("")
      lines.append("schemes = new {")
      for name in spec.schemes.keys.sorted() {
        guard let scheme = spec.schemes[name] else { continue }
        lines.append("\(indent(2))[\(renderString(name))] = \(renderScheme(scheme, indent: 2))")
      }
      lines.append("}")
    }

    lines.append("")
    return lines.joined(separator: "\n")
  }

  private static func renderPackage(_ package: AppleProjectPackage, indent level: Int) -> String {
    var lines = ["new {"]
    appendOptional("path", package.path.map(renderString), indent: level + 2, to: &lines)
    appendOptional("url", package.url.map(renderString), indent: level + 2, to: &lines)
    appendOptional("from", package.from.map(renderString), indent: level + 2, to: &lines)
    appendOptional("branch", package.branch.map(renderString), indent: level + 2, to: &lines)
    appendOptional("exact", package.exact.map(renderString), indent: level + 2, to: &lines)
    appendOptional("revision", package.revision.map(renderString), indent: level + 2, to: &lines)
    lines.append("\(indent(level))}")
    return lines.joined(separator: "\n")
  }

  private static func renderTarget(_ target: AppleProjectTarget, indent level: Int) -> String {
    var lines = ["new {"]
    appendOptional("type", target.type.map(renderString), indent: level + 2, to: &lines)
    appendOptional("platform", target.platform.map(renderString), indent: level + 2, to: &lines)
    appendOptional("deploymentTarget", target.deploymentTarget.map { renderValue($0, indent: level + 2) }, indent: level + 2, to: &lines)
    if let sources = target.sources, !sources.isEmpty {
      appendAssignment("sources", renderListing(sources.map { renderSource($0, indent: level + 4) }, indent: level + 2), indent: level + 2, to: &lines)
    }
    if let info = target.info {
      appendAssignment("info", renderInfo(info, indent: level + 2), indent: level + 2, to: &lines)
    }
    if let settings = target.settings {
      appendAssignment("settings", renderSettings(settings, indent: level + 2), indent: level + 2, to: &lines)
    }
    if let dependencies = target.dependencies, !dependencies.isEmpty {
      appendAssignment("dependencies", renderListing(dependencies.map { renderDependency($0, indent: level + 4) }, indent: level + 2), indent: level + 2, to: &lines)
    }
    if let preBuildScripts = target.preBuildScripts, !preBuildScripts.isEmpty {
      appendAssignment("preBuildScripts", renderListing(preBuildScripts.map { renderBuildScript($0, indent: level + 4) }, indent: level + 2), indent: level + 2, to: &lines)
    }
    if let postBuildScripts = target.postBuildScripts, !postBuildScripts.isEmpty {
      appendAssignment("postBuildScripts", renderListing(postBuildScripts.map { renderBuildScript($0, indent: level + 4) }, indent: level + 2), indent: level + 2, to: &lines)
    }
    lines.append("\(indent(level))}")
    return lines.joined(separator: "\n")
  }

  private static func renderSource(_ source: AppleProjectSource, indent level: Int) -> String {
    var lines = ["new {"]
    appendAssignment("path", renderString(source.path), indent: level + 2, to: &lines)
    appendOptional("name", source.name.map(renderString), indent: level + 2, to: &lines)
    appendOptional("type", source.type.map(renderString), indent: level + 2, to: &lines)
    appendOptional("optional", source.optional.map(renderBool), indent: level + 2, to: &lines)
    if let excludes = source.excludes, !excludes.isEmpty {
      appendAssignment("excludes", renderListing(excludes.map(renderString), indent: level + 2), indent: level + 2, to: &lines)
    }
    lines.append("\(indent(level))}")
    return lines.joined(separator: "\n")
  }

  private static func renderInfo(_ info: AppleProjectInfo, indent level: Int) -> String {
    var lines = ["new {"]
    appendOptional("path", info.path.map(renderString), indent: level + 2, to: &lines)
    if let properties = info.properties, !properties.isEmpty {
      appendAssignment("properties", renderMapping(properties, indent: level + 2), indent: level + 2, to: &lines)
    }
    lines.append("\(indent(level))}")
    return lines.joined(separator: "\n")
  }

  private static func renderSettings(_ settings: AppleProjectSettings, indent level: Int) -> String {
    var lines = ["new {"]
    if let base = settings.base, !base.isEmpty {
      appendAssignment("base", renderMapping(base, indent: level + 2), indent: level + 2, to: &lines)
    }
    if let configs = settings.configs, !configs.isEmpty {
      var configLines = ["new {"]
      for name in configs.keys.sorted() {
        guard let config = configs[name] else { continue }
        configLines.append("\(indent(level + 4))[\(renderString(name))] = \(renderMapping(config, indent: level + 4))")
      }
      configLines.append("\(indent(level + 2))}")
      appendAssignment("configs", configLines.joined(separator: "\n"), indent: level + 2, to: &lines)
    }
    lines.append("\(indent(level))}")
    return lines.joined(separator: "\n")
  }

  private static func renderDependency(_ dependency: AppleProjectDependency, indent level: Int) -> String {
    var lines = ["new {"]
    appendOptional("package", dependency.package.map(renderString), indent: level + 2, to: &lines)
    appendOptional("product", dependency.product.map(renderString), indent: level + 2, to: &lines)
    appendOptional("target", dependency.target.map(renderString), indent: level + 2, to: &lines)
    appendOptional("embed", dependency.embed.map(renderBool), indent: level + 2, to: &lines)
    appendOptional("codeSign", dependency.codeSign.map(renderBool), indent: level + 2, to: &lines)
    lines.append("\(indent(level))}")
    return lines.joined(separator: "\n")
  }

  private static func renderBuildScript(_ script: AppleProjectBuildScript, indent level: Int) -> String {
    var lines = ["new {"]
    appendOptional("name", script.name.map(renderString), indent: level + 2, to: &lines)
    appendOptional("basedOnDependencyAnalysis", script.basedOnDependencyAnalysis.map(renderBool), indent: level + 2, to: &lines)
    appendAssignment("script", renderString(script.script), indent: level + 2, to: &lines)
    lines.append("\(indent(level))}")
    return lines.joined(separator: "\n")
  }

  private static func renderScheme(_ scheme: AppleProjectScheme, indent level: Int) -> String {
    var lines = ["new {"]
    appendOptional("shared", scheme.shared.map(renderBool), indent: level + 2, to: &lines)
    appendOptional("build", scheme.build.map { renderValue($0, indent: level + 2) }, indent: level + 2, to: &lines)
    appendOptional("run", scheme.run.map { renderValue($0, indent: level + 2) }, indent: level + 2, to: &lines)
    appendOptional("test", scheme.test.map { renderValue($0, indent: level + 2) }, indent: level + 2, to: &lines)
    lines.append("\(indent(level))}")
    return lines.joined(separator: "\n")
  }

  private static func renderMapping(
    _ values: [String: AppleProjectValue],
    indent level: Int,
    constructor: String? = nil
  ) -> String {
    let constructorPrefix = constructor.map { " \($0)" } ?? ""
    guard !values.isEmpty else { return "new\(constructorPrefix) {}" }
    var lines = ["new\(constructorPrefix) {"]
    for key in values.keys.sorted() {
      guard let value = values[key] else { continue }
      lines.append("\(indent(level + 2))[\(renderString(key))] = \(renderValue(value, indent: level + 2))")
    }
    lines.append("\(indent(level))}")
    return lines.joined(separator: "\n")
  }

  private static func renderValue(_ value: AppleProjectValue, indent level: Int) -> String {
    switch value {
    case .null:
      return "null"
    case .bool(let value):
      return renderBool(value)
    case .int(let value):
      return String(value)
    case .double(let value):
      return String(value)
    case .string(let value):
      return renderString(value)
    case .array(let values):
      return renderListing(values.map { renderValue($0, indent: level + 2) }, indent: level, constructor: "Listing")
    case .object(let values):
      return renderMapping(values, indent: level, constructor: "Mapping")
    }
  }

  private static func renderListing(
    _ values: [String],
    indent level: Int,
    constructor: String? = nil
  ) -> String {
    let constructorPrefix = constructor.map { " \($0)" } ?? ""
    guard !values.isEmpty else { return "new\(constructorPrefix) {}" }
    var lines = ["new\(constructorPrefix) {"]
    for value in values {
      lines.append("\(indent(level + 2))\(value)")
    }
    lines.append("\(indent(level))}")
    return lines.joined(separator: "\n")
  }

  private static func appendOptional(
    _ name: String,
    _ value: String?,
    indent level: Int,
    to lines: inout [String]
  ) {
    guard let value else { return }
    appendAssignment(name, value, indent: level, to: &lines)
  }

  private static func appendAssignment(
    _ name: String,
    _ value: String,
    indent level: Int,
    to lines: inout [String]
  ) {
    lines.append("\(indent(level))\(name) = \(value)")
  }

  private static func renderBool(_ value: Bool) -> String {
    value ? "true" : "false"
  }

  private static func renderString(_ value: String) -> String {
    var rendered = "\""
    for scalar in value.unicodeScalars {
      switch scalar {
      case "\\":
        rendered += "\\\\"
      case "\"":
        rendered += "\\\""
      case "\n":
        rendered += "\\n"
      case "\r":
        rendered += "\\r"
      case "\t":
        rendered += "\\t"
      default:
        rendered.unicodeScalars.append(scalar)
      }
    }
    rendered += "\""
    return rendered
  }

  private static func indent(_ count: Int) -> String {
    String(repeating: " ", count: count)
  }
}

public enum AppleProjectSpecPklImporter {
  public static func generate(
    ymlURL: URL,
    outputURL: URL,
    schemaAmendsPath: String,
    requestId: String
  ) throws -> AppleProjectYMLImportReceipt {
    let spec = try AppleProjectYMLReader.load(url: ymlURL)
    let data = AppleProjectPklRenderer.renderData(
      spec: spec,
      schemaAmendsPath: schemaAmendsPath,
      sourcePath: ymlURL.lastPathComponent
    )
    try FileManager.default.createDirectory(
      at: outputURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try data.write(to: outputURL)

    return AppleProjectYMLImportReceipt(
      ymlPath: ymlURL.path,
      outputPath: outputURL.path,
      schemaAmendsPath: schemaAmendsPath,
      requestId: requestId,
      projectName: spec.name,
      targetCount: spec.targets.count,
      packageCount: spec.packages.count,
      schemeCount: spec.schemes.count,
      targetNames: spec.targets.keys.sorted(),
      packageNames: spec.packages.keys.sorted(),
      generatedByteCount: data.count,
      ymlSignature: AppleProjectSpecParitySignature(spec: spec)
    )
  }
}

public enum AppleProjectSpecYMLGenerator {
  public static func generate(
    pklURL: URL,
    outputURL: URL,
    requestId: String
  ) async throws -> PklProjectGenerationReceipt {
    let spec = try await AppleProjectPklLoader.load(url: pklURL)
    let data = try AppleProjectYMLRenderer.renderData(spec: spec)
    try FileManager.default.createDirectory(
      at: outputURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try data.write(to: outputURL)

    return PklProjectGenerationReceipt(
      pklPath: pklURL.path,
      outputPath: outputURL.path,
      requestId: requestId,
      projectName: spec.name,
      targetCount: spec.targets.count,
      packageCount: spec.packages.count,
      schemeCount: spec.schemes.count,
      targetNames: spec.targets.keys.sorted(),
      packageNames: spec.packages.keys.sorted(),
      generatedByteCount: data.count,
      pklSignature: AppleProjectSpecParitySignature(spec: spec)
    )
  }
}

public enum AppleProjectSpecComparator {
  public static func receipt(
    ymlSpec: AppleProjectSpec,
    pklSpec: AppleProjectSpec,
    ymlPath: String,
    pklPath: String,
    requestId: String
  ) -> AppleProjectSpecComparisonReceipt {
    let ymlSignature = AppleProjectSpecParitySignature(spec: ymlSpec)
    let pklSignature = AppleProjectSpecParitySignature(spec: pklSpec)
    let mismatchDescriptions = mismatches(yml: ymlSignature, pkl: pklSignature)
    return AppleProjectSpecComparisonReceipt(
      ymlPath: ymlPath,
      pklPath: pklPath,
      requestId: requestId,
      matched: mismatchDescriptions.isEmpty,
      mismatchCount: mismatchDescriptions.count,
      mismatches: mismatchDescriptions,
      ymlSignature: ymlSignature,
      pklSignature: pklSignature
    )
  }

  private static func mismatches(
    yml: AppleProjectSpecParitySignature,
    pkl: AppleProjectSpecParitySignature
  ) -> [String] {
    var mismatches: [String] = []
    appendMismatch("projectName", yml.projectName, pkl.projectName, to: &mismatches)
    appendMismatch("options", yml.options, pkl.options, to: &mismatches)
    appendMismatch("settingsBase", yml.settingsBase, pkl.settingsBase, to: &mismatches)
    appendMismatch("packages", yml.packages, pkl.packages, to: &mismatches)
    appendMismatch("targets", yml.targets, pkl.targets, to: &mismatches)
    return mismatches
  }

  private static func appendMismatch<T: Equatable>(
    _ label: String,
    _ yml: T,
    _ pkl: T,
    to mismatches: inout [String]
  ) {
    if yml != pkl {
      mismatches.append(label)
    }
  }
}

public enum VaporizeAppleProjectReceiptSchema {
  public static let schemaFamilySlug = "vaporize-schemas"
  public static let schemaFamilyVersion = "0.0.1"

  private static let schemaRoot =
    "private/universal/domain/tooling/schema-families/vaporize-schemas/v0.0.1/json/vaporize-schemas-v000-000-001/schemas"

  public static let inspectionSchemaRef =
    "\(schemaRoot)/apple-project-yml-inspection-receipt/apple-project-yml-inspection-receipt.schema.json"
  public static let comparisonSchemaRef =
    "\(schemaRoot)/apple-project-yml-pkl-comparison-receipt/apple-project-yml-pkl-comparison-receipt.schema.json"
  public static let generationSchemaRef =
    "\(schemaRoot)/pkl-project-yml-generation-receipt/pkl-project-yml-generation-receipt.schema.json"
  public static let importSchemaRef =
    "\(schemaRoot)/apple-project-yml-pkl-import-receipt/apple-project-yml-pkl-import-receipt.schema.json"
}

public struct AppleProjectSpecComparisonReceipt: Codable, Equatable, Sendable {
  public var schemaVersion = "0.1.0"
  public var schemaFamilySlug = VaporizeAppleProjectReceiptSchema.schemaFamilySlug
  public var schemaFamilyVersion = VaporizeAppleProjectReceiptSchema.schemaFamilyVersion
  public var schemaRef = VaporizeAppleProjectReceiptSchema.comparisonSchemaRef
  public var receiptKind = "vaporize-apple-project-yml-pkl-comparison"
  public var migrationPhase = "pkl-parity-specimen"
  public var ymlPath: String
  public var pklPath: String
  public var requestId: String
  public var matched: Bool
  public var mismatchCount: Int
  public var mismatches: [String]
  public var ymlSignature: AppleProjectSpecParitySignature
  public var pklSignature: AppleProjectSpecParitySignature
}

public struct PklProjectGenerationReceipt: Codable, Equatable, Sendable {
  public var schemaVersion = "0.1.0"
  public var schemaFamilySlug = VaporizeAppleProjectReceiptSchema.schemaFamilySlug
  public var schemaFamilyVersion = VaporizeAppleProjectReceiptSchema.schemaFamilyVersion
  public var schemaRef = VaporizeAppleProjectReceiptSchema.generationSchemaRef
  public var receiptKind = "vaporize-pkl-project-yml-generation"
  public var generationPhase = "pkl-to-transitional-apple-project-spec-yaml"
  public var generatorStatus = "transitional-yaml-only"
  public var pklPath: String
  public var outputPath: String
  public var requestId: String
  public var projectName: String
  public var targetCount: Int
  public var packageCount: Int
  public var schemeCount: Int
  public var targetNames: [String]
  public var packageNames: [String]
  public var generatedByteCount: Int
  public var buildableWorldStateGenerated = false
  public var xcodeProjectGenerated = false
  public var boundary = "Generates transitional AppleProjectSpec YAML from Pkl; does not rewrite checked-in project.yml and does not generate .xcodeproj world-state."
  public var pklSignature: AppleProjectSpecParitySignature
}

public struct AppleProjectYMLImportReceipt: Codable, Equatable, Sendable {
  public var schemaVersion = "0.1.0"
  public var schemaFamilySlug = VaporizeAppleProjectReceiptSchema.schemaFamilySlug
  public var schemaFamilyVersion = VaporizeAppleProjectReceiptSchema.schemaFamilyVersion
  public var schemaRef = VaporizeAppleProjectReceiptSchema.importSchemaRef
  public var receiptKind = "vaporize-apple-project-yml-pkl-import"
  public var migrationPhase = "legacy-yaml-to-pkl-import"
  public var importerStatus = "pkl-parity-specimen"
  public var ymlPath: String
  public var outputPath: String
  public var schemaAmendsPath: String
  public var requestId: String
  public var projectName: String
  public var targetCount: Int
  public var packageCount: Int
  public var schemeCount: Int
  public var targetNames: [String]
  public var packageNames: [String]
  public var generatedByteCount: Int
  public var buildableWorldStateGenerated = false
  public var xcodeProjectGenerated = false
  public var boundary = "Imports legacy XcodeGen YAML into an AppleProjectSpec Pkl parity specimen; does not generate .xcodeproj world-state."
  public var ymlSignature: AppleProjectSpecParitySignature
}

public struct AppleProjectSpecParitySignature: Codable, Equatable, Sendable {
  public var projectName: String
  public var options: [String: String]
  public var settingsBase: [String: String]
  public var packages: [String: AppleProjectPackageSignature]
  public var targets: [String: AppleProjectTargetSignature]

  public init(spec: AppleProjectSpec) {
    self.projectName = spec.name
    self.options = [
      "minimumXcodeGenVersion": spec.options?.minimumXcodeGenVersion,
      "useBaseInternationalization": spec.options?.useBaseInternationalization.map(String.init),
      "createIntermediateGroups": spec.options?.createIntermediateGroups.map(String.init),
    ].compactMapValues { $0 }
    self.settingsBase = signatureMap(spec.settings?.base)
    self.packages = spec.packages.mapValues { AppleProjectPackageSignature(package: $0) }
    self.targets = spec.targets.mapValues { AppleProjectTargetSignature(target: $0) }
  }
}

public struct AppleProjectPackageSignature: Codable, Equatable, Sendable {
  public var path: String?
  public var url: String?
  public var from: String?
  public var branch: String?
  public var exact: String?
  public var revision: String?

  public init(package: AppleProjectPackage) {
    self.path = package.path
    self.url = package.url
    self.from = package.from
    self.branch = package.branch
    self.exact = package.exact
    self.revision = package.revision
  }
}

public struct AppleProjectTargetSignature: Codable, Equatable, Sendable {
  public var type: String?
  public var platform: String?
  public var deploymentTarget: String?
  public var sourcePaths: [String]
  public var settingsBase: [String: String]
  public var settingConfigs: [String: [String: String]]
  public var dependencies: [AppleProjectDependencySignature]
  public var preBuildScripts: [AppleProjectBuildScriptSignature]
  public var postBuildScripts: [AppleProjectBuildScriptSignature]

  public init(target: AppleProjectTarget) {
    self.type = target.type
    self.platform = target.platform
    self.deploymentTarget = target.deploymentTarget?.stringValue
    self.sourcePaths = (target.sources ?? []).map(\.path)
    self.settingsBase = signatureMap(target.settings?.base)
    self.settingConfigs = (target.settings?.configs ?? [:]).mapValues(signatureMap)
    self.dependencies = (target.dependencies ?? []).map(AppleProjectDependencySignature.init)
    self.preBuildScripts = (target.preBuildScripts ?? []).map(AppleProjectBuildScriptSignature.init)
    self.postBuildScripts = (target.postBuildScripts ?? []).map(AppleProjectBuildScriptSignature.init)
  }
}

public struct AppleProjectDependencySignature: Codable, Equatable, Sendable {
  public var package: String?
  public var product: String?
  public var target: String?
  public var embed: Bool?
  public var codeSign: Bool?

  public init(dependency: AppleProjectDependency) {
    self.package = dependency.package
    self.product = dependency.product
    self.target = dependency.target
    self.embed = dependency.embed
    self.codeSign = dependency.codeSign
  }
}

public struct AppleProjectBuildScriptSignature: Codable, Equatable, Sendable {
  public var name: String?
  public var basedOnDependencyAnalysis: Bool?
  public var normalizedScript: String

  public init(script: AppleProjectBuildScript) {
    self.name = script.name
    self.basedOnDependencyAnalysis = script.basedOnDependencyAnalysis
    self.normalizedScript = script.script.normalizedProjectScript
  }
}

private func signatureMap(_ values: [String: AppleProjectValue]?) -> [String: String] {
  guard let values else { return [:] }
  return values.compactMapValues(\.stringValue)
}

extension String {
  fileprivate var normalizedProjectScript: String {
    split(whereSeparator: \.isNewline)
      .map { line in line.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
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
  public var schemaFamilySlug = VaporizeAppleProjectReceiptSchema.schemaFamilySlug
  public var schemaFamilyVersion = VaporizeAppleProjectReceiptSchema.schemaFamilyVersion
  public var schemaRef = VaporizeAppleProjectReceiptSchema.inspectionSchemaRef
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
