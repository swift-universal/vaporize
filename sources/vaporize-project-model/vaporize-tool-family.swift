import Foundation
import ToolMaterializationSchemas_v0001_2608_30210

public typealias VaporizeToolSurface = ToolMaterializationSurface
public typealias VaporizeToolLanguage = ToolMaterializationLanguage
public typealias VaporizeToolBuildIntent = ToolMaterializationIntent
public typealias VaporizeToolMaterializationPlan = ToolMaterializationPlanModel

public struct VaporizeToolOwner: Codable, Equatable, Sendable {
  public var slug: String
  public var type: String

  public init(slug: String, type: String = "coll") {
    self.slug = slug
    self.type = type
  }

  private enum CodingKeys: String, CodingKey {
    case slug
    case type
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    slug = try container.decode(String.self, forKey: .slug)
    type = try container.decodeIfPresent(String.self, forKey: .type) ?? "coll"
  }
}

public struct VaporizeToolVariant: Codable, Equatable, Sendable {
  public var surface: VaporizeToolSurface
  public var language: VaporizeToolLanguage
  public var digi: Bool
  public var sourceProduct: String

  public init(
    surface: VaporizeToolSurface,
    language: VaporizeToolLanguage = .swift,
    digi: Bool = false,
    sourceProduct: String
  ) {
    self.surface = surface
    self.language = language
    self.digi = digi
    self.sourceProduct = sourceProduct
  }

  private enum CodingKeys: String, CodingKey {
    case surface
    case language
    case digi
    case sourceProduct
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    surface = try container.decode(VaporizeToolSurface.self, forKey: .surface)
    language = try container.decodeIfPresent(VaporizeToolLanguage.self, forKey: .language) ?? .swift
    digi = try container.decodeIfPresent(Bool.self, forKey: .digi) ?? false
    sourceProduct = try container.decode(String.self, forKey: .sourceProduct)
  }
}

public struct VaporizeToolFamily: Codable, Equatable, Sendable {
  public var packagePath: String
  public var owner: VaporizeToolOwner
  public var variants: [String: VaporizeToolVariant]

  public init(
    packagePath: String = ".",
    owner: VaporizeToolOwner,
    variants: [String: VaporizeToolVariant]
  ) {
    self.packagePath = packagePath
    self.owner = owner
    self.variants = variants
  }

  private enum CodingKeys: String, CodingKey {
    case packagePath
    case owner
    case variants
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    packagePath = try container.decodeIfPresent(String.self, forKey: .packagePath) ?? "."
    owner = try container.decode(VaporizeToolOwner.self, forKey: .owner)
    variants = try container.decode([String: VaporizeToolVariant].self, forKey: .variants)
  }
}

public enum VaporizeToolFamilyPlanningError: Error, CustomStringConvertible, Equatable, Sendable {
  case familyNotFound(String)
  case variantNotFound(family: String, variant: String)
  case invalidComponent(field: String, value: String)
  case debugCoordinateRequired
  case releaseCoordinateForbidden(String)
  case invalidSourceCoordinate(String)

  public var description: String {
    switch self {
    case .familyNotFound(let family):
      "project.pkl does not declare tool family '\(family)'."
    case .variantNotFound(let family, let variant):
      "project.pkl tool family '\(family)' does not declare variant '\(variant)'."
    case .invalidComponent(let field, let value):
      "project.pkl tool family has invalid \(field) '\(value)'; expected lowercase kebab case."
    case .debugCoordinateRequired:
      "debug tool-family projection requires --source-coordinate v<major>_<yymm>_<ddhhr>."
    case .releaseCoordinateForbidden(let coordinate):
      "release tool-family projection omits the debug source coordinate; remove '\(coordinate)'."
    case .invalidSourceCoordinate(let coordinate):
      "invalid debug source coordinate '\(coordinate)'; expected v<major>_<yymm>_<ddhhr> with no leading zero in major."
    }
  }
}

public enum VaporizeToolFamilyPlanner {
  public static func plan(
    project: VaporizeProject,
    family familyName: String,
    variant variantName: String,
    intent: VaporizeToolBuildIntent,
    sourceCoordinate: String? = nil
  ) throws -> VaporizeToolMaterializationPlan {
    guard let family = project.toolFamilies[familyName] else {
      throw VaporizeToolFamilyPlanningError.familyNotFound(familyName)
    }
    guard let variant = family.variants[variantName] else {
      throw VaporizeToolFamilyPlanningError.variantNotFound(
        family: familyName,
        variant: variantName
      )
    }

    try validateKebabCase(familyName, field: "family name")
    try validateKebabCase(family.owner.slug, field: "owner slug")
    guard family.owner.type == "coll" else {
      throw VaporizeToolFamilyPlanningError.invalidComponent(
        field: "owner type",
        value: family.owner.type
      )
    }
    guard !variant.sourceProduct.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw VaporizeToolFamilyPlanningError.invalidComponent(
        field: "source product",
        value: variant.sourceProduct
      )
    }

    let resolvedCoordinate: String?
    switch intent {
    case .debug:
      guard let sourceCoordinate else {
        throw VaporizeToolFamilyPlanningError.debugCoordinateRequired
      }
      try validateSourceCoordinate(sourceCoordinate)
      resolvedCoordinate = sourceCoordinate
    case .release:
      if let sourceCoordinate {
        throw VaporizeToolFamilyPlanningError.releaseCoordinateForbidden(sourceCoordinate)
      }
      resolvedCoordinate = nil
    }

    let classification = [
      variant.digi ? "digi" : nil,
      variant.surface.rawValue,
      variant.language.rawValue,
    ].compactMap { $0 }.joined(separator: "-")
    let temporal = resolvedCoordinate.map { ".\($0)" } ?? ""
    let executableName =
      "\(familyName).\(classification)\(temporal)@\(family.owner.slug).\(family.owner.type)"

    return VaporizeToolMaterializationPlan(
      project: project.name,
      family: familyName,
      variant: variantName,
      intent: intent,
      packagePath: family.packagePath,
      sourceProduct: variant.sourceProduct,
      executableName: executableName,
      surface: variant.surface,
      language: variant.language,
      digi: variant.digi,
      sourceCoordinate: resolvedCoordinate
    )
  }

  private static func validateKebabCase(_ value: String, field: String) throws {
    let pieces = value.split(separator: "-", omittingEmptySubsequences: false)
    let valid =
      !pieces.isEmpty
      && pieces.allSatisfy { piece in
        !piece.isEmpty
          && piece.allSatisfy { character in
            character.isLowercase || character.isNumber
          }
      }
    guard valid else {
      throw VaporizeToolFamilyPlanningError.invalidComponent(field: field, value: value)
    }
  }

  private static func validateSourceCoordinate(_ coordinate: String) throws {
    let segments = coordinate.split(separator: "_", omittingEmptySubsequences: false)
    guard segments.count == 3,
      segments[0].first == "v",
      segments[0].count >= 2,
      segments[0].dropFirst().allSatisfy(\.isNumber),
      segments[0].dropFirst().first != "0",
      segments[1].count == 4,
      segments[1].allSatisfy(\.isNumber),
      segments[2].count == 5,
      segments[2].allSatisfy(\.isNumber)
    else {
      throw VaporizeToolFamilyPlanningError.invalidSourceCoordinate(coordinate)
    }
  }
}
