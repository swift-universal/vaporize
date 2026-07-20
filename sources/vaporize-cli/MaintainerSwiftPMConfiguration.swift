import Foundation

enum MaintainerSwiftPMConfiguration {
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
  case duplicateOriginal(String)
  case missingMaintainerCheckout(identity: String, path: String)
  case missingMirrorFile(String)
  case missingUserCacheDirectory

  var errorDescription: String? {
    switch self {
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
