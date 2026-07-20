import Foundation

enum MaintainerSwiftPMConfiguration {
  struct EditableDependency: Equatable {
    let identity: String
    let checkoutPath: String
    let requiresEdit: Bool
  }

  struct Registry: Decodable {
    let schemaVersion: String
    let authorities: [Authority]
  }

  struct Authority: Decodable {
    let identity: String
    let maintainerPath: String
    let originals: [String]
  }

  private struct SwiftPMConfiguration: Encodable {
    let object: [Mirror]
    let version = 1
  }

  private struct Mirror: Encodable {
    let mirror: String
    let original: String
  }

  private struct ResolvedFile: Decodable {
    let pins: [ResolvedPin]
  }

  private struct ResolvedPin: Decodable {
    let identity: String
  }

  private struct WorkspaceState: Decodable {
    let object: WorkspaceObject
  }

  private struct WorkspaceObject: Decodable {
    let dependencies: [WorkspaceDependency]
  }

  private struct WorkspaceDependency: Decodable {
    let packageRef: WorkspacePackageReference
    let state: WorkspaceDependencyState
  }

  private struct WorkspacePackageReference: Decodable {
    let identity: String
    let kind: String
    let location: String
  }

  private struct WorkspaceDependencyState: Decodable {
    let name: String
    let path: String?
  }

  static func resolve(
    explicitPath: String?,
    packagePath: String,
    fileManager: FileManager = .default
  ) throws -> String? {
    if let explicitPath, !explicitPath.isEmpty {
      let directory = absoluteURL(for: explicitPath, fileManager: fileManager)
      let mirrorFile = directory.appendingPathComponent("mirrors.json")
      guard fileManager.fileExists(atPath: mirrorFile.path) else {
        throw MaintainerSwiftPMConfigurationError.missingMirrorFile(mirrorFile.path)
      }
      return directory.path
    }

    guard let substrateRoot = substrateRoot(containing: packagePath, fileManager: fileManager) else {
      return nil
    }
    let registryURL = substrateRoot
      .appendingPathComponent("maintainers", isDirectory: true)
      .appendingPathComponent("swiftpm-authorities.json")
    guard fileManager.fileExists(atPath: registryURL.path) else { return nil }

    let registry = try JSONDecoder().decode(
      Registry.self,
      from: Data(contentsOf: registryURL)
    )
    var seenOriginals = Set<String>()
    var mirrors: [Mirror] = []
    for authority in registry.authorities.sorted(by: { $0.identity < $1.identity }) {
      let checkout = substrateRoot.appendingPathComponent(authority.maintainerPath)
      let manifest = checkout.appendingPathComponent("Package.swift")
      guard fileManager.fileExists(atPath: manifest.path) else {
        throw MaintainerSwiftPMConfigurationError.missingMaintainerCheckout(
          identity: authority.identity,
          path: checkout.path
        )
      }
      let mirror = checkout.standardizedFileURL.absoluteString
      for original in authority.originals.sorted() {
        guard seenOriginals.insert(original).inserted else {
          throw MaintainerSwiftPMConfigurationError.duplicateOriginal(original)
        }
        mirrors.append(Mirror(mirror: mirror, original: original))
      }
    }

    let cacheRoot = try cacheRoot(for: registryURL, fileManager: fileManager)
    try fileManager.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
    let mirrorFile = cacheRoot.appendingPathComponent("mirrors.json")
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(SwiftPMConfiguration(object: mirrors)).write(
      to: mirrorFile,
      options: .atomic
    )
    return cacheRoot.path
  }

  static func editableDependencies(
    packagePath: String,
    fileManager: FileManager = .default
  ) throws -> [EditableDependency] {
    let packageURL = absoluteURL(for: packagePath, fileManager: fileManager)
      .standardizedFileURL
    guard fileManager.fileExists(
      atPath: packageURL.appendingPathComponent("Package.swift").path
    ), let substrateRoot = substrateRoot(containing: packagePath, fileManager: fileManager)
    else {
      return []
    }

    let registryURL = substrateRoot
      .appendingPathComponent("maintainers", isDirectory: true)
      .appendingPathComponent("swiftpm-authorities.json")
    guard fileManager.fileExists(atPath: registryURL.path) else { return [] }
    let registry = try JSONDecoder().decode(
      Registry.self,
      from: Data(contentsOf: registryURL)
    )

    let resolvedURL = packageURL.appendingPathComponent("Package.resolved")
    let pinnedIdentities: Set<String>
    if fileManager.fileExists(atPath: resolvedURL.path) {
      let resolved = try JSONDecoder().decode(
        ResolvedFile.self,
        from: Data(contentsOf: resolvedURL)
      )
      pinnedIdentities = Set(resolved.pins.map(\.identity))
    } else {
      pinnedIdentities = []
    }

    let workspaceURL = packageURL
      .appendingPathComponent(".build", isDirectory: true)
      .appendingPathComponent("workspace-state.json")
    let workspaceDependencies: [WorkspaceDependency]
    if fileManager.fileExists(atPath: workspaceURL.path) {
      let workspace = try JSONDecoder().decode(
        WorkspaceState.self,
        from: Data(contentsOf: workspaceURL)
      )
      workspaceDependencies = workspace.object.dependencies
    } else {
      workspaceDependencies = []
    }

    var editable: [EditableDependency] = []
    var seenIdentities = Set<String>()
    for authority in registry.authorities.sorted(by: { $0.identity < $1.identity }) {
      guard seenIdentities.insert(authority.identity).inserted else {
        throw MaintainerSwiftPMConfigurationError.duplicateIdentity(authority.identity)
      }
      let checkout = substrateRoot.appendingPathComponent(authority.maintainerPath)
        .standardizedFileURL
      guard fileManager.fileExists(
        atPath: checkout.appendingPathComponent("Package.swift").path
      ) else {
        throw MaintainerSwiftPMConfigurationError.missingMaintainerCheckout(
          identity: authority.identity,
          path: checkout.path
        )
      }

      let workspaceDependency = workspaceDependencies.first {
        $0.packageRef.identity == authority.identity
      }
      if let workspaceDependency {
        if workspaceDependency.state.name == "edited" {
          let actualPath = workspaceDependency.state.path.map {
            standardizedPath($0, relativeTo: packageURL)
          }
          guard actualPath == checkout.path else {
            throw MaintainerSwiftPMConfigurationError.conflictingEditableDependency(
              identity: authority.identity,
              expected: checkout.path,
              actual: actualPath ?? "unknown"
            )
          }
          editable.append(
            EditableDependency(
              identity: authority.identity,
              checkoutPath: checkout.path,
              requiresEdit: false
            )
          )
          continue
        }

        if workspaceDependency.packageRef.kind == "fileSystem" {
          let actualPath = standardizedLocation(
            workspaceDependency.packageRef.location,
            relativeTo: packageURL
          )
          guard actualPath == checkout.path else {
            throw MaintainerSwiftPMConfigurationError.conflictingFileSystemDependency(
              identity: authority.identity,
              expected: checkout.path,
              actual: actualPath
            )
          }
          editable.append(
            EditableDependency(
              identity: authority.identity,
              checkoutPath: checkout.path,
              requiresEdit: false
            )
          )
          continue
        }
      }

      guard pinnedIdentities.contains(authority.identity) || workspaceDependency != nil else {
        continue
      }
      editable.append(
        EditableDependency(
          identity: authority.identity,
          checkoutPath: checkout.path,
          requiresEdit: true
        )
      )
    }
    return editable
  }

  private static func substrateRoot(
    containing packagePath: String,
    fileManager: FileManager
  ) -> URL? {
    var candidate = absoluteURL(for: packagePath, fileManager: fileManager)
      .standardizedFileURL
    while candidate.path != "/" {
      if candidate.lastPathComponent == "substrate" {
        return candidate
      }
      candidate.deleteLastPathComponent()
    }
    return nil
  }

  private static func absoluteURL(for path: String, fileManager: FileManager) -> URL {
    if path.hasPrefix("/") {
      return URL(fileURLWithPath: path, isDirectory: true)
    }
    return URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
      .appendingPathComponent(path, isDirectory: true)
  }

  private static func standardizedPath(_ path: String, relativeTo base: URL) -> String {
    if path.hasPrefix("/") {
      return URL(fileURLWithPath: path).standardizedFileURL.path
    }
    return base.appendingPathComponent(path).standardizedFileURL.path
  }

  private static func standardizedLocation(_ location: String, relativeTo base: URL) -> String {
    if let url = URL(string: location), url.isFileURL {
      return url.standardizedFileURL.path
    }
    return standardizedPath(location, relativeTo: base)
  }

  private static func cacheRoot(for registryURL: URL, fileManager: FileManager) throws -> URL {
    guard let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
      throw MaintainerSwiftPMConfigurationError.missingUserCacheDirectory
    }
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in registryURL.standardizedFileURL.path.utf8 {
      hash ^= UInt64(byte)
      hash &*= 1_099_511_628_211
    }
    return base
      .appendingPathComponent("studio.laussat.vaporize", isDirectory: true)
      .appendingPathComponent("swiftpm", isDirectory: true)
      .appendingPathComponent(String(hash, radix: 16), isDirectory: true)
  }
}

enum MaintainerSwiftPMConfigurationError: LocalizedError {
  case conflictingEditableDependency(identity: String, expected: String, actual: String)
  case conflictingFileSystemDependency(identity: String, expected: String, actual: String)
  case duplicateIdentity(String)
  case duplicateOriginal(String)
  case missingMaintainerCheckout(identity: String, path: String)
  case missingMirrorFile(String)
  case missingUserCacheDirectory

  var errorDescription: String? {
    switch self {
    case .conflictingEditableDependency(let identity, let expected, let actual):
      return "Maintainer dependency \(identity) is already editable at \(actual), but the selected authority is \(expected). Reconcile the workspace before building."
    case .conflictingFileSystemDependency(let identity, let expected, let actual):
      return "Maintainer dependency \(identity) resolves from \(actual), but the selected authority is \(expected). Reconcile the package manifest before building."
    case .duplicateIdentity(let identity):
      return "Maintainer SwiftPM authority registry repeats identity: \(identity)"
    case .duplicateOriginal(let original):
      return "Maintainer SwiftPM authority registry repeats original URL: \(original)"
    case .missingMaintainerCheckout(let identity, let path):
      return "Maintainer dependency \(identity) is selected but its checkout is missing at \(path). Run the maintainer sync before building."
    case .missingMirrorFile(let path):
      return "SwiftPM configuration directory does not contain mirrors.json: \(path)"
    case .missingUserCacheDirectory:
      return "Vaporize could not resolve the user cache directory for generated SwiftPM authority configuration."
    }
  }
}

struct PackageResolutionSnapshot {
  let url: URL
  let existed: Bool
  let data: Data?

  static func capture(
    packagePath: String,
    fileManager: FileManager = .default
  ) throws -> PackageResolutionSnapshot {
    let packageURL: URL
    if packagePath.hasPrefix("/") {
      packageURL = URL(fileURLWithPath: packagePath, isDirectory: true)
    } else {
      packageURL = URL(
        fileURLWithPath: fileManager.currentDirectoryPath,
        isDirectory: true
      ).appendingPathComponent(packagePath, isDirectory: true)
    }
    let url = packageURL.standardizedFileURL.appendingPathComponent("Package.resolved")
    let existed = fileManager.fileExists(atPath: url.path)
    return PackageResolutionSnapshot(
      url: url,
      existed: existed,
      data: existed ? try Data(contentsOf: url) : nil
    )
  }

  func restore(fileManager: FileManager = .default) throws {
    if let data {
      try data.write(to: url, options: .atomic)
    } else if !existed, fileManager.fileExists(atPath: url.path) {
      try fileManager.removeItem(at: url)
    }
  }
}

struct MaintainerDependencyAuthorityReceipt: Encodable {
  struct Dependency: Encodable {
    let identity: String
    let checkoutPath: String
  }

  let schemaVersion = "v0.1.0"
  let packagePath: String
  let swiftPMConfigurationPath: String?
  let preparedDependencyCount: Int
  let activeDependencies: [Dependency]
  let packageResolutionRestored: Bool
  let elapsedNanoseconds: UInt64
}
