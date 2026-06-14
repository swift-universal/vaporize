import Foundation

public enum AppleProjectTargetDiscoveryError: Error, CustomStringConvertible, Sendable {
  case missingProjectSpec(path: String)
  case unsupportedProjectSpec(path: String)
  case incompleteProductCacheDiscovery(String)

  public var description: String {
    switch self {
    case .missingProjectSpec(let path):
      return "No project.pkl or project.yml found at \(path)."
    case .unsupportedProjectSpec(let path):
      return "Unsupported project discovery input: \(path). Expected a project directory, project.pkl, or project.yml."
    case .incompleteProductCacheDiscovery(let reason):
      return reason
    }
  }
}

public struct AppleProjectProductCacheDiscoveryOptions: Equatable, Sendable {
  public var workspacePath: String?
  public var derivedDataPath: String?
  public var configurationName: String

  public init(
    workspacePath: String? = nil,
    derivedDataPath: String? = nil,
    configurationName: String = "Release"
  ) {
    self.workspacePath = workspacePath
    self.derivedDataPath = derivedDataPath
    self.configurationName = configurationName
  }

  var isEnabled: Bool {
    workspacePath != nil || derivedDataPath != nil
  }

  func validate() throws {
    switch (workspacePath, derivedDataPath) {
    case (.none, .none), (.some, .some):
      return
    case (.some, .none):
      throw AppleProjectTargetDiscoveryError.incompleteProductCacheDiscovery(
        "--xcode-product-cache-workspace requires --xcode-product-cache-derived-data-path for list-targets cache discovery."
      )
    case (.none, .some):
      throw AppleProjectTargetDiscoveryError.incompleteProductCacheDiscovery(
        "--xcode-product-cache-derived-data-path requires --xcode-product-cache-workspace for list-targets cache discovery."
      )
    }
  }
}

public enum AppleProjectTargetDiscovery {
  public static func discover(
    path: String,
    requestId: String,
    productCacheOptions: AppleProjectProductCacheDiscoveryOptions = .init()
  ) async throws -> AppleProjectTargetDiscoveryReceipt {
    let url = URL(fileURLWithPath: path).standardizedFileURL
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)

    if exists && isDirectory.boolValue {
      return try await discover(
        projectDirectoryURL: url,
        requestId: requestId,
        productCacheOptions: productCacheOptions
      )
    }
    if url.lastPathComponent == "project.pkl" || url.pathExtension == "pkl" {
      return try await discover(
        pklURL: url,
        requestId: requestId,
        productCacheOptions: productCacheOptions
      )
    }
    if url.lastPathComponent == "project.yml" || url.pathExtension == "yml" || url.pathExtension == "yaml" {
      return try discover(
        projectYMLURL: url,
        requestId: requestId,
        productCacheOptions: productCacheOptions
      )
    }
    throw AppleProjectTargetDiscoveryError.unsupportedProjectSpec(path: url.path)
  }

  public static func discover(
    projectDirectoryURL: URL,
    requestId: String,
    productCacheOptions: AppleProjectProductCacheDiscoveryOptions = .init()
  ) async throws -> AppleProjectTargetDiscoveryReceipt {
    let projectDirectoryURL = projectDirectoryURL.standardizedFileURL
    let pklURL = projectDirectoryURL.appendingPathComponent("project.pkl")
    let ymlURL = projectDirectoryURL.appendingPathComponent("project.yml")

    if FileManager.default.fileExists(atPath: pklURL.path) {
      return try await discover(
        pklURL: pklURL,
        inputPath: projectDirectoryURL.path,
        requestId: requestId,
        productCacheOptions: productCacheOptions
      )
    }
    if FileManager.default.fileExists(atPath: ymlURL.path) {
      return try discover(
        projectYMLURL: ymlURL,
        inputPath: projectDirectoryURL.path,
        requestId: requestId,
        productCacheOptions: productCacheOptions
      )
    }
    throw AppleProjectTargetDiscoveryError.missingProjectSpec(path: projectDirectoryURL.path)
  }

  public static func discover(
    projectYMLURL: URL,
    inputPath: String? = nil,
    requestId: String,
    productCacheOptions: AppleProjectProductCacheDiscoveryOptions = .init()
  ) throws -> AppleProjectTargetDiscoveryReceipt {
    try productCacheOptions.validate()
    let projectYMLURL = projectYMLURL.standardizedFileURL
    let spec = try AppleProjectYMLReader.load(url: projectYMLURL)
    return receipt(
      spec: spec,
      inputKind: "project-yml",
      inputPath: inputPath ?? projectYMLURL.path,
      selectedProjectSpecPath: projectYMLURL.path,
      projectRootURL: projectYMLURL.deletingLastPathComponent(),
      requestId: requestId,
      productCacheOptions: productCacheOptions
    )
  }

  public static func discover(
    pklURL: URL,
    inputPath: String? = nil,
    requestId: String,
    productCacheOptions: AppleProjectProductCacheDiscoveryOptions = .init()
  ) async throws -> AppleProjectTargetDiscoveryReceipt {
    try productCacheOptions.validate()
    let pklURL = pklURL.standardizedFileURL
    let spec = try await AppleProjectPklLoader.load(url: pklURL)
    return receipt(
      spec: spec,
      inputKind: "project-pkl",
      inputPath: inputPath ?? pklURL.path,
      selectedProjectSpecPath: pklURL.path,
      projectRootURL: pklURL.deletingLastPathComponent(),
      requestId: requestId,
      productCacheOptions: productCacheOptions
    )
  }

  private static func receipt(
    spec: AppleProjectSpec,
    inputKind: String,
    inputPath: String,
    selectedProjectSpecPath: String,
    projectRootURL: URL,
    requestId: String,
    productCacheOptions: AppleProjectProductCacheDiscoveryOptions
  ) -> AppleProjectTargetDiscoveryReceipt {
    let targets = spec.targets
      .map { name, target in
        AppleProjectDiscoveredTarget(name: name, target: target)
      }
      .sorted { $0.name < $1.name }
    let packages = spec.packages
      .map { name, package in
        AppleProjectDiscoveredPackage(name: name, package: package)
      }
      .sorted { $0.name < $1.name }
    let schemes = spec.schemes
      .map { name, scheme in
        AppleProjectDiscoveredScheme(name: name, scheme: scheme)
      }
      .sorted { $0.name < $1.name }
    let buildableTargetNames = targets
      .filter(\.isBuildableCandidate)
      .map(\.name)
    let candidateSchemeNames = Array(Set(schemes.map(\.name) + buildableTargetNames)).sorted()
    let productCacheCandidates = productCacheCandidates(
      targets: targets,
      options: productCacheOptions
    )

    return AppleProjectTargetDiscoveryReceipt(
      inputKind: inputKind,
      inputPath: inputPath,
      selectedProjectSpecPath: selectedProjectSpecPath,
      projectRootPath: projectRootURL.standardizedFileURL.path,
      requestId: requestId,
      projectName: spec.name,
      targetCount: spec.targets.count,
      packageCount: spec.packages.count,
      schemeCount: spec.schemes.count,
      targetNames: spec.targets.keys.sorted(),
      buildableTargetNames: buildableTargetNames,
      candidateSchemeNames: candidateSchemeNames,
      packageNames: spec.packages.keys.sorted(),
      schemeNames: spec.schemes.keys.sorted(),
      productCacheWorkspacePath: productCacheOptions.workspacePath.map {
        URL(fileURLWithPath: $0).standardizedFileURL.path
      },
      productCacheDerivedDataPath: productCacheOptions.derivedDataPath.map {
        URL(fileURLWithPath: $0).standardizedFileURL.path
      },
      productCacheConfigurationName: productCacheOptions.isEnabled ? productCacheOptions.configurationName : nil,
      productCacheCandidateCount: productCacheCandidates.count,
      warmProductCacheCandidateCount: productCacheCandidates.filter(\.isWarm).count,
      targets: targets,
      packages: packages,
      schemes: schemes,
      productCacheCandidates: productCacheCandidates
    )
  }

  private static func productCacheCandidates(
    targets: [AppleProjectDiscoveredTarget],
    options: AppleProjectProductCacheDiscoveryOptions
  ) -> [AppleProjectProductCacheCandidate] {
    guard let workspacePath = options.workspacePath,
      let derivedDataPath = options.derivedDataPath
    else {
      return []
    }
    return targets
      .filter(\.isBuildableCandidate)
      .map { target in
        AppleProjectProductCacheCandidate(
          targetName: target.name,
          productName: target.productName,
          configurationName: options.configurationName,
          workspacePath: workspacePath,
          derivedDataPath: derivedDataPath
        )
      }
  }
}

public struct AppleProjectTargetDiscoveryReceipt: Codable, Equatable, Sendable {
  public var schemaVersion = "0.1.0"
  public var schemaFamilySlug = VaporizeAppleProjectReceiptSchema.schemaFamilySlug
  public var schemaFamilyVersion = VaporizeAppleProjectReceiptSchema.schemaFamilyVersion
  public var schemaRef = VaporizeAppleProjectReceiptSchema.targetDiscoverySchemaRef
  public var receiptKind = "vaporize-project-target-discovery"
  public var discoveryPhase = "apple-project-target-discovery-first-slice"
  public var inputKind: String
  public var inputPath: String
  public var selectedProjectSpecPath: String
  public var projectRootPath: String
  public var requestId: String
  public var projectName: String
  public var targetCount: Int
  public var packageCount: Int
  public var schemeCount: Int
  public var targetNames: [String]
  public var buildableTargetNames: [String]
  public var candidateSchemeNames: [String]
  public var packageNames: [String]
  public var schemeNames: [String]
  public var productCacheWorkspacePath: String?
  public var productCacheDerivedDataPath: String?
  public var productCacheConfigurationName: String?
  public var productCacheCandidateCount: Int
  public var warmProductCacheCandidateCount: Int
  public var targets: [AppleProjectDiscoveredTarget]
  public var packages: [AppleProjectDiscoveredPackage]
  public var schemes: [AppleProjectDiscoveredScheme]
  public var productCacheCandidates: [AppleProjectProductCacheCandidate]
  public var boundaries = [
    "Reads AppleProjectSpec from project.pkl or legacy project.yml; does not build, install, or generate .xcodeproj world-state.",
    "Directory input prefers project.pkl as forward truth and falls back to project.yml for migration discovery.",
    "First slice discovers project targets, packages, schemes, and buildable candidates for later Pkl parity, workspace-cache, and build-watch lanes.",
    "Product-cache discovery checks expected DerivedData product paths from discovered target facts; it does not parse the .xcworkspace graph or prove fleet membership.",
  ]
}

public struct AppleProjectDiscoveredTarget: Codable, Equatable, Sendable {
  public var name: String
  public var type: String?
  public var platform: String?
  public var productName: String
  public var sourcePathCount: Int
  public var sourcePaths: [String]
  public var dependencyCount: Int
  public var packageDependencyCount: Int
  public var targetDependencyCount: Int
  public var configFileCount: Int
  public var buildConfigurationNames: [String]
  public var hasPreBuildScripts: Bool
  public var hasPostBuildScripts: Bool
  public var isApplication: Bool
  public var isBuildableCandidate: Bool

  init(name: String, target: AppleProjectTarget) {
    let dependencies = target.dependencies ?? []
    self.name = name
    self.type = target.type
    self.platform = target.platform
    self.productName = target.settings?.base?["PRODUCT_NAME"]?.stringValue ?? name
    self.sourcePaths = (target.sources ?? []).map(\.path).sorted()
    self.sourcePathCount = sourcePaths.count
    self.dependencyCount = dependencies.count
    self.packageDependencyCount = dependencies.filter { $0.package != nil && $0.product != nil }.count
    self.targetDependencyCount = dependencies.filter { $0.target != nil }.count
    self.buildConfigurationNames = (target.configFiles ?? [:]).keys.sorted()
    self.configFileCount = buildConfigurationNames.count
    self.hasPreBuildScripts = !(target.preBuildScripts?.isEmpty ?? true)
    self.hasPostBuildScripts = !(target.postBuildScripts?.isEmpty ?? true)
    self.isApplication = target.type == "application"
    self.isBuildableCandidate = target.type == "application" && (target.platform == nil || target.platform == "macOS")
  }
}

public struct AppleProjectDiscoveredPackage: Codable, Equatable, Sendable {
  public var name: String
  public var kind: String
  public var path: String?
  public var url: String?
  public var requirement: String?

  init(name: String, package: AppleProjectPackage) {
    self.name = name
    self.path = package.path
    self.url = package.url
    if package.path != nil {
      self.kind = "local"
    } else {
      self.kind = "remote"
    }
    self.requirement = package.from ?? package.branch ?? package.exact ?? package.revision
  }
}

public struct AppleProjectDiscoveredScheme: Codable, Equatable, Sendable {
  public var name: String
  public var shared: Bool
  public var hasBuildAction: Bool
  public var hasRunAction: Bool
  public var hasTestAction: Bool

  init(name: String, scheme: AppleProjectScheme) {
    self.name = name
    self.shared = scheme.shared ?? false
    self.hasBuildAction = scheme.build != nil
    self.hasRunAction = scheme.run != nil
    self.hasTestAction = scheme.test != nil
  }
}

public struct AppleProjectProductCacheCandidate: Codable, Equatable, Sendable {
  public var targetName: String
  public var productName: String
  public var configurationName: String
  public var workspacePath: String
  public var derivedDataPath: String
  public var appBundlePath: String
  public var isWarm: Bool
  public var status: String

  init(
    targetName: String,
    productName: String,
    configurationName: String,
    workspacePath: String,
    derivedDataPath: String
  ) {
    self.targetName = targetName
    self.productName = productName
    self.configurationName = configurationName
    self.workspacePath = URL(fileURLWithPath: workspacePath).standardizedFileURL.path
    self.derivedDataPath = URL(fileURLWithPath: derivedDataPath).standardizedFileURL.path
    self.appBundlePath = URL(fileURLWithPath: derivedDataPath)
      .standardizedFileURL
      .appendingPathComponent("Build/Products/\(configurationName)/\(productName).app")
      .path
    self.isWarm = FileManager.default.fileExists(atPath: appBundlePath)
    self.status = isWarm ? "warm" : "missing"
  }
}
