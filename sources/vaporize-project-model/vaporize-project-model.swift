import Foundation
import PklSwift

public struct VaporizeProject: Codable, Equatable, Sendable {
  public var name: String
  public var platformTargets: [String: VaporizePlatformTarget]

  public init(name: String, platformTargets: [String: VaporizePlatformTarget] = [:]) {
    self.name = name
    self.platformTargets = platformTargets
  }

  private enum CodingKeys: String, CodingKey {
    case name
    case platformTargets
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
    platformTargets =
      try container.decodeIfPresent([String: VaporizePlatformTarget].self, forKey: .platformTargets)
      ?? [:]
  }
}

public enum VaporizePlatform: String, Codable, Equatable, Sendable {
  case macos
  case windows
  case linux
}

public enum VaporizeAdapter: String, Codable, Equatable, Sendable {
  case xcode
  case swiftpm
  case wcode
}

public enum VaporizePresentation: String, Codable, Equatable, Sendable {
  case swiftui
  case swiftUUI = "swift-uui"
}

public enum VaporizeUIBackend: String, Codable, Equatable, Sendable {
  case appkit
  case uikit
  case winui
}

public struct VaporizePlatformTarget: Codable, Equatable, Sendable {
  public var platform: VaporizePlatform
  public var adapter: VaporizeAdapter
  public var product: String
  public var packagePath: String?
  public var entryPoint: String?
  public var presentation: VaporizePresentation?
  public var backend: VaporizeUIBackend?
  public var resources: [VaporizePlatformResource]?

  public init(
    platform: VaporizePlatform,
    adapter: VaporizeAdapter,
    product: String,
    packagePath: String? = nil,
    entryPoint: String? = nil,
    presentation: VaporizePresentation? = nil,
    backend: VaporizeUIBackend? = nil,
    resources: [VaporizePlatformResource]? = nil
  ) {
    self.platform = platform
    self.adapter = adapter
    self.product = product
    self.packagePath = packagePath
    self.entryPoint = entryPoint
    self.presentation = presentation
    self.backend = backend
    self.resources = resources
  }
}

public enum VaporizePlatformResourceMode: String, Codable, Equatable, Sendable {
  case copy
  case process
}

public struct VaporizePlatformResource: Codable, Equatable, Sendable {
  public var path: String
  public var mode: VaporizePlatformResourceMode
  public var destination: String?
  public var includes: [String]?
  public var excludes: [String]?
  public var optional: Bool

  public init(
    path: String,
    mode: VaporizePlatformResourceMode,
    destination: String? = nil,
    includes: [String]? = nil,
    excludes: [String]? = nil,
    optional: Bool = false
  ) {
    self.path = path
    self.mode = mode
    self.destination = destination
    self.includes = includes
    self.excludes = excludes
    self.optional = optional
  }

  private enum CodingKeys: String, CodingKey {
    case path
    case mode
    case destination
    case includes
    case excludes
    case optional
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      path: try container.decode(String.self, forKey: .path),
      mode: try container.decode(VaporizePlatformResourceMode.self, forKey: .mode),
      destination: try container.decodeIfPresent(String.self, forKey: .destination),
      includes: try container.decodeIfPresent([String].self, forKey: .includes),
      excludes: try container.decodeIfPresent([String].self, forKey: .excludes),
      optional: try container.decodeIfPresent(Bool.self, forKey: .optional) ?? false
    )
  }
}

public enum VaporizeProjectLoaderError: Error, CustomStringConvertible {
  case evaluationFailed(path: String, underlying: Error)

  public var description: String {
    switch self {
    case .evaluationFailed(let path, let underlying):
      return "Vaporize project evaluation failed for \(path): \(underlying)"
    }
  }
}

public enum VaporizeProjectLoader {
  public static func load(url: URL) async throws -> VaporizeProject {
    do {
      return try await PklSwift.withEvaluator { evaluator in
        try await evaluator.evaluateModule(source: .path(url.path), as: VaporizeProject.self)
      }
    } catch {
      throw VaporizeProjectLoaderError.evaluationFailed(path: url.path, underlying: error)
    }
  }
}
