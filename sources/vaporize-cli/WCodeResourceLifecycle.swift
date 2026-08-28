import Foundation
import VaporizeProjectModel

enum WCodeResourceLifecycleError: Error, Equatable, CustomStringConvertible {
  case targetNotFound(String)
  case platformNotDeclared(target: String)
  case platformMismatch(target: String, expected: String, actual: String)
  case emptyPath(target: String)
  case absolutePath(String)
  case pathTraversal(String)
  case unsupportedMode(path: String, mode: VaporizePlatformResourceMode)
  case unsupportedFilters(path: String)
  case missingRequiredResource(String)
  case symbolicLinkNotAllowed(String)
  case destinationCollision(String, String)
  case unsafeProductName(String)
  case resourceRootOutsideBuildProducts(resourceRoot: String, buildProducts: String)
  case missingBuiltExecutable(String)
  case missingResourceRoot(String)
  case unsafeRuntimeArtifactName(String)
  case missingRuntimeArtifact(String)
  case unsupportedRuntimeArtifact(String)
  case installDestinationExists(String)
  case invalidInstallDestination(String)
  case installDestinationOutsideAllowedRoot(destination: String, allowedRoot: String)
  case runtimeArtifactCollision(String)

  var description: String {
    switch self {
    case .targetNotFound(let target):
      return "project.pkl does not declare target '\(target)'."
    case .platformNotDeclared(let target):
      return "project.pkl target '\(target)' does not declare a platform."
    case .platformMismatch(let target, let expected, let actual):
      return "project.pkl target '\(target)' declares platform '\(actual)', expected '\(expected)'."
    case .emptyPath(let target):
      return "project.pkl target '\(target)' contains an empty resource path."
    case .absolutePath(let path):
      return "Resource path must be relative to its declared root: \(path)"
    case .pathTraversal(let path):
      return "Resource path cannot traverse outside its declared root: \(path)"
    case .unsupportedMode(let path, let mode):
      return "Resource '\(path)' requests unsupported WCode mode '\(mode.rawValue)'."
    case .unsupportedFilters(let path):
      return
        "Resource '\(path)' declares includes or excludes before typed filter semantics are admitted."
    case .missingRequiredResource(let path):
      return "Required project.pkl resource does not exist: \(path)"
    case .symbolicLinkNotAllowed(let path):
      return "Resource staging refuses symbolic links: \(path)"
    case .destinationCollision(let first, let second):
      return "Resource destinations overlap: '\(first)' and '\(second)'."
    case .unsafeProductName(let name):
      return "WCode product must be one safe Windows filename component: \(name)"
    case .resourceRootOutsideBuildProducts(let resourceRoot, let buildProducts):
      return
        "WCode resource root '\(resourceRoot)' must be beneath build-products root '\(buildProducts)'."
    case .missingBuiltExecutable(let path):
      return "WCode build did not produce the expected executable: \(path)"
    case .missingResourceRoot(let path):
      return "WCode resource materialization did not produce the expected root: \(path)"
    case .unsafeRuntimeArtifactName(let name):
      return "WCode runtime artifact must be one safe Windows filename component: \(name)"
    case .missingRuntimeArtifact(let path):
      return "Declared WCode runtime artifact does not exist: \(path)"
    case .unsupportedRuntimeArtifact(let name):
      return "WCode runtime artifact must name a .dll file or .bundle/.resources directory: \(name)"
    case .installDestinationExists(let path):
      return "WCode install destination already exists; pass --force to replace it: \(path)"
    case .invalidInstallDestination(let path):
      return "WCode refuses an unsafe install destination: \(path)"
    case .installDestinationOutsideAllowedRoot(let destination, let allowedRoot):
      return
        "WCode install destination '\(destination)' must be beneath allowed root '\(allowedRoot)'."
    case .runtimeArtifactCollision(let name):
      return "WCode runtime artifacts contain a duplicate destination name: \(name)"
    }
  }
}

struct WCodeResourcePlan: Equatable, Sendable {
  let projectPath: String
  let targetName: String
  let platform: String
  let projectRoot: String
  let resourceRoot: String
  let entries: [WCodeResourcePlanEntry]
}

struct WCodeResourcePlanEntry: Equatable, Sendable {
  enum Disposition: String, Equatable, Sendable {
    case copy
    case skipOptionalMissing
  }

  let declarationPath: String
  let sourcePath: String
  let destinationPath: String
  let disposition: Disposition
}

struct WCodeResourceMaterializationReceipt: Codable, Equatable, Sendable {
  let projectPath: String
  let targetName: String
  let platform: String
  let resourceRoot: String
  let entries: [WCodeResourceMaterializationEntry]
}

struct WCodeResourceMaterializationEntry: Codable, Equatable, Sendable {
  enum Disposition: String, Codable, Equatable, Sendable {
    case copied
    case skippedOptionalMissing
  }

  let declarationPath: String
  let sourcePath: String
  let destinationPath: String
  let disposition: Disposition
}

struct WCodeBuiltArtifactLayout: Codable, Equatable, Sendable {
  let product: String
  let buildProductsDirectory: String
  let executablePath: String
  let resourceRoot: String
  let runtimeArtifactPaths: [String]
}

struct WCodeArtifactInstallReceipt: Codable, Equatable, Sendable {
  let destinationPath: String
  let installedExecutablePath: String
  let installedResourceRoot: String
  let installedArtifactPaths: [String]
}

struct WCodeLifecycleReceipt: Codable, Equatable, Sendable {
  let materialization: WCodeResourceMaterializationReceipt
  let artifactLayout: WCodeBuiltArtifactLayout
  let install: WCodeArtifactInstallReceipt?
}

enum WCodeResourceLifecycle {
  static func validateProductName(_ product: String) throws -> String {
    guard isSafeWindowsFilenameComponent(product) else {
      throw WCodeResourceLifecycleError.unsafeProductName(product)
    }
    return product
  }

  static func resourceRoot(
    product: String,
    buildProductsDirectory: URL
  ) throws -> URL {
    let product = try validateProductName(product)
    let buildProductsDirectory = buildProductsDirectory.standardizedFileURL
      .resolvingSymlinksInPath()
    let resourceRoot = buildProductsDirectory.appendingPathComponent(
      "\(product).resources",
      isDirectory: true
    ).standardizedFileURL
    guard isStrictDescendant(resourceRoot, of: buildProductsDirectory) else {
      throw WCodeResourceLifecycleError.resourceRootOutsideBuildProducts(
        resourceRoot: resourceRoot.path,
        buildProducts: buildProductsDirectory.path
      )
    }
    return resourceRoot
  }

  static func validatedInstallDestination(
    _ destination: URL,
    allowedInstallRoot: URL
  ) throws -> URL {
    let destination = destination.standardizedFileURL
    let allowedInstallRoot = allowedInstallRoot.standardizedFileURL
    guard isStrictDescendant(destination, of: allowedInstallRoot) else {
      throw WCodeResourceLifecycleError.installDestinationOutsideAllowedRoot(
        destination: destination.path,
        allowedRoot: allowedInstallRoot.path
      )
    }
    return destination
  }

  static func loadPlan(
    projectURL: URL,
    targetName: String,
    expectedPlatform: String,
    projectRoot: URL,
    product: String,
    buildProductsDirectory: URL,
    fileManager: FileManager = .default
  ) async throws -> WCodeResourcePlan {
    let project = try await VaporizeProjectLoader.load(url: projectURL)
    return try plan(
      project: project,
      projectURL: projectURL,
      targetName: targetName,
      expectedPlatform: expectedPlatform,
      projectRoot: projectRoot,
      product: product,
      buildProductsDirectory: buildProductsDirectory,
      fileManager: fileManager
    )
  }

  static func plan(
    project: VaporizeProject,
    projectURL: URL,
    targetName: String,
    expectedPlatform: String,
    projectRoot: URL,
    product: String,
    buildProductsDirectory: URL,
    fileManager: FileManager = .default
  ) throws -> WCodeResourcePlan {
    guard let target = project.platformTargets[targetName] else {
      throw WCodeResourceLifecycleError.targetNotFound(targetName)
    }
    let platform = target.platform.rawValue
    guard platform.caseInsensitiveCompare(expectedPlatform) == .orderedSame else {
      throw WCodeResourceLifecycleError.platformMismatch(
        target: targetName,
        expected: expectedPlatform,
        actual: platform
      )
    }

    let projectRoot = projectRoot.standardizedFileURL.resolvingSymlinksInPath()
    let resourceRoot = try Self.resourceRoot(
      product: product,
      buildProductsDirectory: buildProductsDirectory
    )
    var entries: [WCodeResourcePlanEntry] = []

    for resource in target.resources ?? [] {
      let declarationPath = resource.path.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !declarationPath.isEmpty else {
        throw WCodeResourceLifecycleError.emptyPath(target: targetName)
      }
      guard resource.mode == .copy else {
        throw WCodeResourceLifecycleError.unsupportedMode(
          path: declarationPath,
          mode: resource.mode
        )
      }
      if !(resource.includes?.isEmpty ?? true) || !(resource.excludes?.isEmpty ?? true) {
        throw WCodeResourceLifecycleError.unsupportedFilters(path: declarationPath)
      }

      let declaredSource = try confinedURL(relativePath: declarationPath, root: projectRoot)
      let source = declaredSource.resolvingSymlinksInPath()
      guard contains(source, within: projectRoot) else {
        throw WCodeResourceLifecycleError.pathTraversal(declarationPath)
      }

      let destinationDeclaration =
        resource.destination?.trimmingCharacters(in: .whitespacesAndNewlines)
        ?? declarationPath
      guard !destinationDeclaration.isEmpty else {
        throw WCodeResourceLifecycleError.emptyPath(target: targetName)
      }
      let destination = try confinedURL(
        relativePath: destinationDeclaration,
        root: resourceRoot
      )

      var isDirectory: ObjCBool = false
      guard fileManager.fileExists(atPath: source.path, isDirectory: &isDirectory) else {
        if resource.optional {
          entries.append(
            WCodeResourcePlanEntry(
              declarationPath: declarationPath,
              sourcePath: source.path,
              destinationPath: destination.path,
              disposition: .skipOptionalMissing
            )
          )
          continue
        }
        throw WCodeResourceLifecycleError.missingRequiredResource(source.path)
      }
      try refuseSymbolicLinks(at: declaredSource, fileManager: fileManager)

      let candidate = WCodeResourcePlanEntry(
        declarationPath: declarationPath,
        sourcePath: source.path,
        destinationPath: destination.path,
        disposition: .copy
      )
      for existing in entries where existing.disposition == .copy {
        if destinationsOverlap(existing.destinationPath, candidate.destinationPath) {
          throw WCodeResourceLifecycleError.destinationCollision(
            existing.destinationPath,
            candidate.destinationPath
          )
        }
      }
      entries.append(candidate)
    }

    return WCodeResourcePlan(
      projectPath: projectURL.standardizedFileURL.path,
      targetName: targetName,
      platform: platform,
      projectRoot: projectRoot.path,
      resourceRoot: resourceRoot.path,
      entries: entries
    )
  }

  static func builtArtifactLayout(
    product: String,
    buildProductsDirectory: URL,
    runtimeArtifactNames: [String],
    fileManager: FileManager = .default
  ) throws -> WCodeBuiltArtifactLayout {
    let product = try validateProductName(product)
    let buildProductsDirectory = buildProductsDirectory.standardizedFileURL
      .resolvingSymlinksInPath()
    let resourceRoot = try Self.resourceRoot(
      product: product,
      buildProductsDirectory: buildProductsDirectory
    )
    let executableName = product.lowercased().hasSuffix(".exe") ? product : "\(product).exe"
    let executable = buildProductsDirectory.appendingPathComponent(executableName)
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: executable.path, isDirectory: &isDirectory),
      !isDirectory.boolValue
    else {
      throw WCodeResourceLifecycleError.missingBuiltExecutable(executable.path)
    }
    guard fileManager.fileExists(atPath: resourceRoot.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      throw WCodeResourceLifecycleError.missingResourceRoot(resourceRoot.path)
    }
    try refuseSymbolicLinks(at: executable, fileManager: fileManager)
    try refuseSymbolicLinks(at: resourceRoot, fileManager: fileManager)

    var artifacts: [URL] = [executable, resourceRoot]
    for declaredName in runtimeArtifactNames {
      guard isSafeWindowsFilenameComponent(declaredName) else {
        throw WCodeResourceLifecycleError.unsafeRuntimeArtifactName(declaredName)
      }
      let artifact = buildProductsDirectory.appendingPathComponent(declaredName).standardizedFileURL
      guard isStrictDescendant(artifact, of: buildProductsDirectory) else {
        throw WCodeResourceLifecycleError.unsafeRuntimeArtifactName(declaredName)
      }
      guard !sameWindowsPath(artifact, executable), !sameWindowsPath(artifact, resourceRoot) else {
        throw WCodeResourceLifecycleError.runtimeArtifactCollision(declaredName)
      }
      var isDirectory: ObjCBool = false
      guard fileManager.fileExists(atPath: artifact.path, isDirectory: &isDirectory) else {
        throw WCodeResourceLifecycleError.missingRuntimeArtifact(artifact.path)
      }
      let pathExtension = artifact.pathExtension.lowercased()
      let supportedFile = !isDirectory.boolValue && pathExtension == "dll"
      let supportedDirectory =
        isDirectory.boolValue
        && (pathExtension == "bundle" || pathExtension == "resources")
      guard supportedFile || supportedDirectory else {
        throw WCodeResourceLifecycleError.unsupportedRuntimeArtifact(declaredName)
      }
      try refuseSymbolicLinks(at: artifact, fileManager: fileManager)
      artifacts.append(artifact)
    }

    var names = Set<String>()
    for artifact in artifacts {
      let name = normalizedArtifactName(artifact.lastPathComponent)
      guard names.insert(name).inserted else {
        throw WCodeResourceLifecycleError.runtimeArtifactCollision(artifact.lastPathComponent)
      }
    }
    artifacts.sort {
      normalizedArtifactName($0.lastPathComponent) < normalizedArtifactName($1.lastPathComponent)
    }

    return WCodeBuiltArtifactLayout(
      product: product,
      buildProductsDirectory: buildProductsDirectory.path,
      executablePath: executable.path,
      resourceRoot: resourceRoot.path,
      runtimeArtifactPaths: artifacts.map(\.path)
    )
  }

  static func install(
    _ layout: WCodeBuiltArtifactLayout,
    destination: URL,
    allowedInstallRoot: URL,
    force: Bool,
    fileManager: FileManager = .default
  ) throws -> WCodeArtifactInstallReceipt {
    let allowedInstallRoot = allowedInstallRoot.standardizedFileURL
    let destination = try validatedInstallDestination(
      destination,
      allowedInstallRoot: allowedInstallRoot
    )
    let parent = destination.deletingLastPathComponent()
    let leaf = destination.lastPathComponent
    guard !leaf.isEmpty, destination.path != parent.path else {
      throw WCodeResourceLifecycleError.invalidInstallDestination(destination.path)
    }
    try fileManager.createDirectory(at: allowedInstallRoot, withIntermediateDirectories: true)
    let resolvedAllowedRoot = allowedInstallRoot.resolvingSymlinksInPath()
    let preflightDestination = parent.resolvingSymlinksInPath()
      .appendingPathComponent(leaf)
      .standardizedFileURL
    guard isStrictDescendant(preflightDestination, of: resolvedAllowedRoot) else {
      throw WCodeResourceLifecycleError.installDestinationOutsideAllowedRoot(
        destination: destination.path,
        allowedRoot: allowedInstallRoot.path
      )
    }
    try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
    let resolvedDestination = parent.resolvingSymlinksInPath()
      .appendingPathComponent(leaf)
      .standardizedFileURL
    guard isStrictDescendant(resolvedDestination, of: resolvedAllowedRoot) else {
      throw WCodeResourceLifecycleError.installDestinationOutsideAllowedRoot(
        destination: destination.path,
        allowedRoot: allowedInstallRoot.path
      )
    }
    if fileManager.fileExists(atPath: destination.path),
      try destination.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true
    {
      throw WCodeResourceLifecycleError.invalidInstallDestination(destination.path)
    }
    if fileManager.fileExists(atPath: destination.path), !force {
      throw WCodeResourceLifecycleError.installDestinationExists(destination.path)
    }

    let staging = parent.appendingPathComponent(".\(leaf).staging-\(UUID().uuidString)")
    let backup = parent.appendingPathComponent(".\(leaf).previous-\(UUID().uuidString)")
    try fileManager.createDirectory(at: staging, withIntermediateDirectories: false)

    do {
      var installed: [String] = []
      for artifactPath in layout.runtimeArtifactPaths {
        let source = URL(fileURLWithPath: artifactPath).standardizedFileURL
        let target = staging.appendingPathComponent(source.lastPathComponent)
        try fileManager.copyItem(at: source, to: target)
        installed.append(destination.appendingPathComponent(source.lastPathComponent).path)
      }

      let executableName = URL(fileURLWithPath: layout.executablePath).lastPathComponent
      let resourceName = URL(fileURLWithPath: layout.resourceRoot).lastPathComponent
      let stagedExecutable = staging.appendingPathComponent(executableName)
      let stagedResourceRoot = staging.appendingPathComponent(resourceName)
      try requireRegularFile(
        stagedExecutable,
        missingError: .missingBuiltExecutable(stagedExecutable.path),
        fileManager: fileManager
      )
      try requireDirectory(
        stagedResourceRoot,
        missingError: .missingResourceRoot(stagedResourceRoot.path),
        fileManager: fileManager
      )

      let hadExistingDestination = fileManager.fileExists(atPath: destination.path)
      if hadExistingDestination {
        try fileManager.moveItem(at: destination, to: backup)
      }
      do {
        try fileManager.moveItem(at: staging, to: destination)
        if hadExistingDestination {
          try? fileManager.removeItem(at: backup)
        }
      } catch {
        if hadExistingDestination,
          !fileManager.fileExists(atPath: destination.path),
          fileManager.fileExists(atPath: backup.path)
        {
          try? fileManager.moveItem(at: backup, to: destination)
        }
        throw error
      }

      let installedExecutable = destination.appendingPathComponent(executableName)
      let installedResourceRoot = destination.appendingPathComponent(resourceName)
      return WCodeArtifactInstallReceipt(
        destinationPath: destination.path,
        installedExecutablePath: installedExecutable.path,
        installedResourceRoot: installedResourceRoot.path,
        installedArtifactPaths: installed.sorted()
      )
    } catch {
      if fileManager.fileExists(atPath: staging.path) {
        try? fileManager.removeItem(at: staging)
      }
      if fileManager.fileExists(atPath: backup.path),
        !fileManager.fileExists(atPath: destination.path)
      {
        try? fileManager.moveItem(at: backup, to: destination)
      }
      throw error
    }
  }

  static func materialize(
    _ plan: WCodeResourcePlan,
    fileManager: FileManager = .default
  ) throws -> WCodeResourceMaterializationReceipt {
    let resourceRoot = URL(fileURLWithPath: plan.resourceRoot).standardizedFileURL
    let parent = resourceRoot.deletingLastPathComponent()
    let leaf = resourceRoot.lastPathComponent
    guard !leaf.isEmpty, resourceRoot.path != parent.path else {
      throw WCodeResourceLifecycleError.pathTraversal(resourceRoot.path)
    }

    try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
    let stagingRoot = parent.appendingPathComponent(".\(leaf).staging-\(UUID().uuidString)")
    let backupRoot = parent.appendingPathComponent(".\(leaf).previous-\(UUID().uuidString)")
    try fileManager.createDirectory(at: stagingRoot, withIntermediateDirectories: false)

    do {
      var receiptEntries: [WCodeResourceMaterializationEntry] = []
      for entry in plan.entries {
        let finalDestination = URL(fileURLWithPath: entry.destinationPath).standardizedFileURL
        let relativeDestination = try relativePath(of: finalDestination, beneath: resourceRoot)
        let stagedDestination = stagingRoot.appendingPathComponent(relativeDestination)

        switch entry.disposition {
        case .skipOptionalMissing:
          receiptEntries.append(
            WCodeResourceMaterializationEntry(
              declarationPath: entry.declarationPath,
              sourcePath: entry.sourcePath,
              destinationPath: finalDestination.path,
              disposition: .skippedOptionalMissing
            )
          )
        case .copy:
          try fileManager.createDirectory(
            at: stagedDestination.deletingLastPathComponent(),
            withIntermediateDirectories: true
          )
          try fileManager.copyItem(
            at: URL(fileURLWithPath: entry.sourcePath),
            to: stagedDestination
          )
          receiptEntries.append(
            WCodeResourceMaterializationEntry(
              declarationPath: entry.declarationPath,
              sourcePath: entry.sourcePath,
              destinationPath: finalDestination.path,
              disposition: .copied
            )
          )
        }
      }

      try requireDirectory(
        stagingRoot,
        missingError: .missingResourceRoot(stagingRoot.path),
        fileManager: fileManager
      )
      for entry in plan.entries where entry.disposition == .copy {
        let finalDestination = URL(fileURLWithPath: entry.destinationPath).standardizedFileURL
        let relativeDestination = try relativePath(of: finalDestination, beneath: resourceRoot)
        let stagedDestination = stagingRoot.appendingPathComponent(relativeDestination)
        guard fileManager.fileExists(atPath: stagedDestination.path) else {
          throw WCodeResourceLifecycleError.missingRequiredResource(stagedDestination.path)
        }
      }

      let hadExistingRoot = fileManager.fileExists(atPath: resourceRoot.path)
      if hadExistingRoot {
        try fileManager.moveItem(at: resourceRoot, to: backupRoot)
      }
      do {
        try fileManager.moveItem(at: stagingRoot, to: resourceRoot)
        if hadExistingRoot {
          try? fileManager.removeItem(at: backupRoot)
        }
      } catch {
        if hadExistingRoot,
          !fileManager.fileExists(atPath: resourceRoot.path),
          fileManager.fileExists(atPath: backupRoot.path)
        {
          try? fileManager.moveItem(at: backupRoot, to: resourceRoot)
        }
        throw error
      }

      return WCodeResourceMaterializationReceipt(
        projectPath: plan.projectPath,
        targetName: plan.targetName,
        platform: plan.platform,
        resourceRoot: resourceRoot.path,
        entries: receiptEntries
      )
    } catch {
      if fileManager.fileExists(atPath: stagingRoot.path) {
        try? fileManager.removeItem(at: stagingRoot)
      }
      if fileManager.fileExists(atPath: backupRoot.path),
        !fileManager.fileExists(atPath: resourceRoot.path)
      {
        try? fileManager.moveItem(at: backupRoot, to: resourceRoot)
      }
      throw error
    }
  }

  private static func confinedURL(relativePath: String, root: URL) throws -> URL {
    let normalized = relativePath.replacingOccurrences(of: "\\", with: "/")
    let components = normalized.split(separator: "/", omittingEmptySubsequences: false)
    guard !normalized.hasPrefix("/"), !normalized.hasPrefix("\\"), !hasDrivePrefix(normalized)
    else {
      throw WCodeResourceLifecycleError.absolutePath(relativePath)
    }
    guard !components.contains(where: { $0 == ".." }) else {
      throw WCodeResourceLifecycleError.pathTraversal(relativePath)
    }
    guard !components.contains(where: { $0.isEmpty }) else {
      throw WCodeResourceLifecycleError.pathTraversal(relativePath)
    }
    let result = components.reduce(root.standardizedFileURL) {
      $0.appendingPathComponent(String($1), isDirectory: false)
    }.standardizedFileURL
    guard contains(result, within: root.standardizedFileURL) else {
      throw WCodeResourceLifecycleError.pathTraversal(relativePath)
    }
    return result
  }

  private static func hasDrivePrefix(_ path: String) -> Bool {
    guard path.utf8.count >= 2 else { return false }
    let characters = Array(path)
    return characters[1] == ":" && characters[0].isLetter
  }

  private static func isSafeWindowsFilenameComponent(_ value: String) -> Bool {
    guard !value.isEmpty,
      value == value.trimmingCharacters(in: .whitespacesAndNewlines),
      value != ".",
      value != "..",
      !value.hasSuffix("."),
      !value.hasSuffix(" ")
    else {
      return false
    }
    let invalidCharacters = CharacterSet(charactersIn: "<>:\"/\\|?*")
    guard
      value.unicodeScalars.allSatisfy({ scalar in
        scalar.value >= 32 && !invalidCharacters.contains(scalar)
      })
    else {
      return false
    }
    let baseName =
      value.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
      .first
      .map(String.init)?
      .uppercased() ?? ""
    let reservedNames: Set<String> = [
      "CON", "PRN", "AUX", "NUL", "CONIN$", "CONOUT$",
      "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
      "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",
    ]
    return !reservedNames.contains(baseName)
  }

  private static func contains(_ candidate: URL, within root: URL) -> Bool {
    let candidateComponents = normalizedComponents(candidate)
    let rootComponents = normalizedComponents(root)
    guard candidateComponents.count >= rootComponents.count else { return false }
    return Array(candidateComponents.prefix(rootComponents.count)) == rootComponents
  }

  private static func isStrictDescendant(_ candidate: URL, of root: URL) -> Bool {
    let candidateComponents = normalizedComponents(candidate)
    let rootComponents = normalizedComponents(root)
    guard candidateComponents.count > rootComponents.count else { return false }
    return Array(candidateComponents.prefix(rootComponents.count)) == rootComponents
  }

  private static func requireRegularFile(
    _ url: URL,
    missingError: WCodeResourceLifecycleError,
    fileManager: FileManager
  ) throws {
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
      !isDirectory.boolValue
    else {
      throw missingError
    }
  }

  private static func requireDirectory(
    _ url: URL,
    missingError: WCodeResourceLifecycleError,
    fileManager: FileManager
  ) throws {
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      throw missingError
    }
  }

  private static func normalizedComponents(_ url: URL) -> [String] {
    url.standardizedFileURL.pathComponents.map { $0.lowercased() }
  }

  private static func normalizedArtifactName(_ name: String) -> String {
    name.lowercased()
  }

  private static func sameWindowsPath(_ lhs: URL, _ rhs: URL) -> Bool {
    normalizedComponents(lhs) == normalizedComponents(rhs)
  }

  private static func destinationsOverlap(_ lhs: String, _ rhs: String) -> Bool {
    let lhsComponents = normalizedComponents(URL(fileURLWithPath: lhs))
    let rhsComponents = normalizedComponents(URL(fileURLWithPath: rhs))
    let commonCount = min(lhsComponents.count, rhsComponents.count)
    return Array(lhsComponents.prefix(commonCount)) == Array(rhsComponents.prefix(commonCount))
  }

  private static func relativePath(of candidate: URL, beneath root: URL) throws -> String {
    guard contains(candidate, within: root) else {
      throw WCodeResourceLifecycleError.pathTraversal(candidate.path)
    }
    return candidate.pathComponents.dropFirst(root.pathComponents.count).joined(separator: "/")
  }

  private static func refuseSymbolicLinks(
    at source: URL,
    fileManager: FileManager
  ) throws {
    let keys: Set<URLResourceKey> = [.isSymbolicLinkKey]
    if try source.resourceValues(forKeys: keys).isSymbolicLink == true {
      throw WCodeResourceLifecycleError.symbolicLinkNotAllowed(source.path)
    }
    guard
      let enumerator = fileManager.enumerator(
        at: source,
        includingPropertiesForKeys: Array(keys),
        options: [],
        errorHandler: nil
      )
    else {
      return
    }
    for case let child as URL in enumerator {
      if try child.resourceValues(forKeys: keys).isSymbolicLink == true {
        throw WCodeResourceLifecycleError.symbolicLinkNotAllowed(child.path)
      }
    }
  }
}
