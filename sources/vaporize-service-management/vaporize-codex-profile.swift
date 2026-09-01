import AIModelSchemas_v0002_2609_01200
import Foundation
import Link_Ref_Schemas_v000_000_005
import VaporizeProjectModel

public struct VaporizeCodexProfileProjectionPlan: Equatable, Sendable {
  public var serviceID: String
  public var offeringID: String
  public var modelAlias: String
  public var contextWindow: Int
  public var profileURL: URL
  public var catalogURL: URL
  public var profileData: Data
  public var catalogData: Data

  public init(
    serviceID: String,
    offeringID: String,
    modelAlias: String,
    contextWindow: Int,
    profileURL: URL,
    catalogURL: URL,
    profileData: Data,
    catalogData: Data
  ) {
    self.serviceID = serviceID
    self.offeringID = offeringID
    self.modelAlias = modelAlias
    self.contextWindow = contextWindow
    self.profileURL = profileURL
    self.catalogURL = catalogURL
    self.profileData = profileData
    self.catalogData = catalogData
  }
}

public enum VaporizeCodexProfileProjectionError: Error, CustomStringConvertible, Equatable {
  case serviceNotFound(String)
  case profileNotDeclared(String)
  case offeringReferenceNotDeclared(String)
  case relativePathTargetRequired(String)
  case modelAliasRequired(String)
  case responsesIngressRequired(String)
  case healthCheckRequired(String)
  case invalidHealthCheckURL(String)
  case invalidProfileSlug(String)
  case invalidProvider(String)
  case invalidCompactionRatio

  public var description: String {
    switch self {
    case .serviceNotFound(let id): "project.pkl does not declare service '\(id)'."
    case .profileNotDeclared(let id): "service '\(id)' does not declare codexProfile."
    case .offeringReferenceNotDeclared(let id):
      "service '\(id)' does not declare aiModelServingOfferingRef."
    case .relativePathTargetRequired(let field):
      "\(field) requires a LinkRef 0.0.5 relative-path target."
    case .modelAliasRequired(let id): "AI serving offering '\(id)' has no runtime alias."
    case .responsesIngressRequired(let id):
      "AI serving offering '\(id)' does not expose the Responses ingress protocol."
    case .healthCheckRequired(let id): "service '\(id)' does not declare an HTTP health check."
    case .invalidHealthCheckURL(let value): "service health-check URL is invalid: '\(value)'."
    case .invalidProfileSlug(let value):
      "Codex profile slug must be lowercase kebab case: '\(value)'."
    case .invalidProvider(let value):
      "Codex provider must contain only lowercase letters, numbers, and underscores: '\(value)'."
    case .invalidCompactionRatio:
      "Codex auto-compaction ratio must be greater than zero and at most one."
    }
  }
}

public enum VaporizeCodexProfileProjector {
  public static func plan(
    serviceID: String,
    project: VaporizeProject,
    projectURL: URL,
    outputDirectory: URL
  ) throws -> VaporizeCodexProfileProjectionPlan {
    guard let service = project.services[serviceID] else {
      throw VaporizeCodexProfileProjectionError.serviceNotFound(serviceID)
    }
    guard let policy = service.codexProfile else {
      throw VaporizeCodexProfileProjectionError.profileNotDeclared(serviceID)
    }
    guard let offeringRef = service.aiModelServingOfferingRef else {
      throw VaporizeCodexProfileProjectionError.offeringReferenceNotDeclared(serviceID)
    }
    try validate(policy: policy)

    let offeringURL = try resolve(
      offeringRef,
      relativeTo: projectURL.deletingLastPathComponent(),
      field: "aiModelServingOfferingRef"
    )
    let offering = try JSONDecoder().decode(
      AIModelServingOfferingModel.self,
      from: Data(contentsOf: offeringURL)
    ).validated()
    guard offering.route.ingressProtocol == .responses else {
      throw VaporizeCodexProfileProjectionError.responsesIngressRequired(offering.id)
    }
    guard let modelAlias = offering.aliases.first else {
      throw VaporizeCodexProfileProjectionError.modelAliasRequired(offering.id)
    }

    let loadoutURL = try resolve(
      offering.loadoutRef,
      relativeTo: offeringURL.deletingLastPathComponent(),
      field: "offering.loadoutRef"
    )
    let loadout = try JSONDecoder().decode(
      AIModelServingLoadoutModel.self,
      from: Data(contentsOf: loadoutURL)
    ).validated()
    guard let healthCheck = service.healthCheck else {
      throw VaporizeCodexProfileProjectionError.healthCheckRequired(serviceID)
    }
    let baseURL = try servingBaseURL(from: healthCheck.url)

    let profileURL = outputDirectory.appendingPathComponent("\(policy.slug).config.toml")
    let catalogURL = outputDirectory.appendingPathComponent("\(policy.slug).models.json")
    let contextWindow = loadout.context.allocatedTokensPerSlot
    let compactLimit = contextWindow * policy.autoCompactNumerator / policy.autoCompactDenominator
    let effectivePercent = policy.autoCompactNumerator * 100 / policy.autoCompactDenominator
    let profile = renderProfile(
      policy: policy,
      modelAlias: modelAlias,
      displayName: offering.displayName,
      contextWindow: contextWindow,
      compactLimit: compactLimit,
      catalogPath: catalogURL.path,
      baseURL: baseURL
    )
    let catalog = try renderCatalog(
      policy: policy,
      offering: offering,
      loadout: loadout,
      modelAlias: modelAlias,
      effectivePercent: effectivePercent
    )
    return VaporizeCodexProfileProjectionPlan(
      serviceID: serviceID,
      offeringID: offering.id,
      modelAlias: modelAlias,
      contextWindow: contextWindow,
      profileURL: profileURL,
      catalogURL: catalogURL,
      profileData: Data(profile.utf8),
      catalogData: catalog
    )
  }

  public static func materialize(
    _ plan: VaporizeCodexProfileProjectionPlan,
    fileManager: FileManager = .default
  ) throws {
    try fileManager.createDirectory(
      at: plan.profileURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try plan.catalogData.write(to: plan.catalogURL, options: .atomic)
    try plan.profileData.write(to: plan.profileURL, options: .atomic)
  }

  private static func resolve(
    _ reference: LinkRefModel,
    relativeTo baseURL: URL,
    field: String
  ) throws -> URL {
    for target in reference.targets {
      if case .relativePath(let path, _) = target {
        return baseURL.appendingPathComponent(path).standardizedFileURL
      }
    }
    throw VaporizeCodexProfileProjectionError.relativePathTargetRequired(field)
  }

  private static func servingBaseURL(from healthCheckURL: String) throws -> URL {
    guard var components = URLComponents(string: healthCheckURL),
      let scheme = components.scheme,
      scheme == "http" || scheme == "https",
      components.host != nil
    else {
      throw VaporizeCodexProfileProjectionError.invalidHealthCheckURL(healthCheckURL)
    }
    components.path = "/v1"
    components.query = nil
    components.fragment = nil
    guard let url = components.url else {
      throw VaporizeCodexProfileProjectionError.invalidHealthCheckURL(healthCheckURL)
    }
    return url
  }

  private static func validate(policy: VaporizeCodexProfile) throws {
    guard isKebabCase(policy.slug) else {
      throw VaporizeCodexProfileProjectionError.invalidProfileSlug(policy.slug)
    }
    guard !policy.provider.isEmpty,
      policy.provider.allSatisfy({ $0.isLowercase || $0.isNumber || $0 == "_" })
    else { throw VaporizeCodexProfileProjectionError.invalidProvider(policy.provider) }
    guard policy.autoCompactNumerator > 0, policy.autoCompactDenominator > 0,
      policy.autoCompactNumerator <= policy.autoCompactDenominator
    else { throw VaporizeCodexProfileProjectionError.invalidCompactionRatio }
  }

  private static func isKebabCase(_ value: String) -> Bool {
    let parts = value.split(separator: "-", omittingEmptySubsequences: false)
    return !parts.isEmpty
      && parts.allSatisfy {
        !$0.isEmpty && $0.allSatisfy { $0.isLowercase || $0.isNumber }
      }
  }

  private static func renderProfile(
    policy: VaporizeCodexProfile,
    modelAlias: String,
    displayName: String,
    contextWindow: Int,
    compactLimit: Int,
    catalogPath: String,
    baseURL: URL
  ) -> String {
    """
    model = \(toml(modelAlias))
    model_provider = \(toml(policy.provider))
    model_context_window = \(contextWindow)
    model_auto_compact_token_limit = \(compactLimit)
    model_reasoning_effort = \(toml(policy.reasoningEffort))
    model_reasoning_summary = \(toml(policy.reasoningSummary))
    model_catalog_json = \(toml(catalogPath))
    approvals_reviewer = "user"

    [features]
    apps = false
    code_mode = false
    code_mode_only = false
    multi_agent = false

    [model_providers.\(policy.provider)]
    name = \(toml("\(displayName) local"))
    base_url = \(toml(baseURL.absoluteString))
    wire_api = "responses"
    requires_openai_auth = false

    [plugins."browser@openai-bundled"]
    enabled = false

    [plugins."visualize@openai-bundled"]
    enabled = false

    [plugins."codex-app-tools@openai-bundled"]
    enabled = false

    [plugins."sites@openai-bundled"]
    enabled = false

    [plugins."figma@openai-curated-remote"]
    enabled = false

    [plugins."google-drive@openai-curated-remote"]
    enabled = false

    [plugins."plugin-management@openai-curated-remote"]
    enabled = false
    """ + "\n"
  }

  private static func renderCatalog(
    policy: VaporizeCodexProfile,
    offering: AIModelServingOfferingModel,
    loadout: AIModelServingLoadoutModel,
    modelAlias: String,
    effectivePercent: Int
  ) throws -> Data {
    let model: [String: Any] = [
      "slug": modelAlias,
      "display_name": offering.displayName,
      "description": "Local \(offering.displayName) offering projected from \(offering.id).",
      "default_reasoning_level": policy.reasoningEffort,
      "supported_reasoning_levels": [
        ["effort": policy.reasoningEffort, "description": "Bounded local reasoning"]
      ],
      "shell_type": "shell_command",
      "visibility": "list",
      "supported_in_api": true,
      "priority": 1,
      "support_verbosity": false,
      "truncation_policy": [
        "mode": "tokens",
        "limit": min(loadout.context.maximumOutputTokens, 10_000),
      ],
      "supports_parallel_tool_calls": false,
      "model_messages": [:] as [String: String],
      "include_skills_usage_instructions": false,
      "include_plugin_usage_instructions": false,
      "include_apps_usage_instructions": false,
      "default_reasoning_summary": policy.reasoningSummary,
      "context_window": loadout.context.allocatedTokensPerSlot,
      "max_context_window": loadout.context.allocatedTokensPerSlot,
      "effective_context_window_percent": effectivePercent,
      "experimental_supported_tools": [] as [String],
      "input_modalities": ["text"],
      "supports_search_tool": false,
      "use_responses_lite": false,
      "node_repl_auto_review_required": false,
      "node_repl_disabled": true,
      "base_instructions": policy.baseInstructions,
    ]
    return try JSONSerialization.data(
      withJSONObject: ["models": [model]],
      options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    ) + Data("\n".utf8)
  }

  private static func toml(_ value: String) -> String {
    let escaped =
      value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
      .replacingOccurrences(of: "\n", with: "\\n")
      .replacingOccurrences(of: "\r", with: "\\r")
      .replacingOccurrences(of: "\t", with: "\\t")
    return "\"\(escaped)\""
  }
}
