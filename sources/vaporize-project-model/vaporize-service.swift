import Foundation

public enum VaporizeServiceScope: String, Codable, Equatable, Sendable {
  case user
  case system
}

public enum VaporizeServiceActivation: String, Codable, Equatable, Sendable {
  case login
  case manual
}

public enum VaporizeServiceRestartPolicy: String, Codable, Equatable, Sendable {
  case never
  case onFailure = "on-failure"
  case always
}

public enum VaporizeServiceHealthCheckKind: String, Codable, Equatable, Sendable {
  case http
}

public struct VaporizeServiceHealthCheck: Codable, Equatable, Sendable {
  public var kind: VaporizeServiceHealthCheckKind
  public var url: String

  public init(kind: VaporizeServiceHealthCheckKind, url: String) {
    self.kind = kind
    self.url = url
  }
}

public struct VaporizeService: Codable, Equatable, Sendable {
  public var scope: VaporizeServiceScope
  public var activation: VaporizeServiceActivation
  public var executable: String
  public var arguments: [String]
  public var workingDirectory: String?
  public var environment: [String: String]
  public var restartPolicy: VaporizeServiceRestartPolicy
  public var standardOutputPath: String?
  public var standardErrorPath: String?
  public var healthCheck: VaporizeServiceHealthCheck?

  public init(
    scope: VaporizeServiceScope = .user,
    activation: VaporizeServiceActivation = .login,
    executable: String,
    arguments: [String] = [],
    workingDirectory: String? = nil,
    environment: [String: String] = [:],
    restartPolicy: VaporizeServiceRestartPolicy = .onFailure,
    standardOutputPath: String? = nil,
    standardErrorPath: String? = nil,
    healthCheck: VaporizeServiceHealthCheck? = nil
  ) {
    self.scope = scope
    self.activation = activation
    self.executable = executable
    self.arguments = arguments
    self.workingDirectory = workingDirectory
    self.environment = environment
    self.restartPolicy = restartPolicy
    self.standardOutputPath = standardOutputPath
    self.standardErrorPath = standardErrorPath
    self.healthCheck = healthCheck
  }

  private enum CodingKeys: String, CodingKey {
    case scope
    case activation
    case executable
    case arguments
    case workingDirectory
    case environment
    case restartPolicy
    case standardOutputPath
    case standardErrorPath
    case healthCheck
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      scope: try container.decodeIfPresent(VaporizeServiceScope.self, forKey: .scope) ?? .user,
      activation: try container.decodeIfPresent(VaporizeServiceActivation.self, forKey: .activation)
        ?? .login,
      executable: try container.decode(String.self, forKey: .executable),
      arguments: try container.decodeIfPresent([String].self, forKey: .arguments) ?? [],
      workingDirectory: try container.decodeIfPresent(String.self, forKey: .workingDirectory),
      environment: try container.decodeIfPresent([String: String].self, forKey: .environment)
        ?? [:],
      restartPolicy: try container.decodeIfPresent(
        VaporizeServiceRestartPolicy.self,
        forKey: .restartPolicy
      ) ?? .onFailure,
      standardOutputPath: try container.decodeIfPresent(String.self, forKey: .standardOutputPath),
      standardErrorPath: try container.decodeIfPresent(String.self, forKey: .standardErrorPath),
      healthCheck: try container.decodeIfPresent(
        VaporizeServiceHealthCheck.self, forKey: .healthCheck)
    )
  }
}
