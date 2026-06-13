import ArgumentParser
import CommonShell
import Foundation

public struct SwiftAppInstaller: Sendable {
  public enum Configuration: String, CaseIterable, ExpressibleByArgument, Sendable {
    case debug
    case release
  }

  public struct Request: Sendable {
    public var packagePath: String
    public var product: String
    public var appBundleName: String?
    public var configuration: Configuration
    public var destination: String
    public var forceReinstall: Bool
    public var skipBuild: Bool
    public var launch: Bool
    public var xcodeProject: String?
    public var xcodeWorkspace: String?
    public var xcodeScheme: String?
    public var derivedDataPath: String?
    public var xcodeProductCacheWorkspace: String?
    public var xcodeProductCacheDerivedDataPath: String?
    public var xcodeDestinations: [String]
    public var xcodeSDK: String?
    public var xcodeResultBundlePath: String?
    public var xcodeBuildSettings: [String]

    public init(
      packagePath: String,
      product: String,
      appBundleName: String? = nil,
      configuration: Configuration = .release,
      destination: String = "/Applications",
      forceReinstall: Bool = false,
      skipBuild: Bool = false,
      launch: Bool = false,
      xcodeProject: String? = nil,
      xcodeWorkspace: String? = nil,
      xcodeScheme: String? = nil,
      derivedDataPath: String? = nil,
      xcodeProductCacheWorkspace: String? = nil,
      xcodeProductCacheDerivedDataPath: String? = nil,
      xcodeDestinations: [String] = [],
      xcodeSDK: String? = nil,
      xcodeResultBundlePath: String? = nil,
      xcodeBuildSettings: [String] = []
    ) {
      self.packagePath = packagePath
      self.product = product
      self.appBundleName = appBundleName
      self.configuration = configuration
      self.destination = destination
      self.forceReinstall = forceReinstall
      self.skipBuild = skipBuild
      self.launch = launch
      self.xcodeProject = xcodeProject
      self.xcodeWorkspace = xcodeWorkspace
      self.xcodeScheme = xcodeScheme
      self.derivedDataPath = derivedDataPath
      self.xcodeProductCacheWorkspace = xcodeProductCacheWorkspace
      self.xcodeProductCacheDerivedDataPath = xcodeProductCacheDerivedDataPath
      self.xcodeDestinations = xcodeDestinations
      self.xcodeSDK = xcodeSDK
      self.xcodeResultBundlePath = xcodeResultBundlePath
      self.xcodeBuildSettings = xcodeBuildSettings
    }
  }

  struct XcodeBuildInvocation: Equatable, Sendable {
    var arguments: [String]
  }

  private let request: Request
  private var shell: CommonShell

  public init(request: Request, shell: CommonShell = .init()) {
    self.request = request
    self.shell = shell
  }

  public func run() async throws {
    if !request.skipBuild {
      try await buildApp()
    }
    let builtApp = try locateBuiltApp()
    let destinationApp = URL(fileURLWithPath: request.destination)
      .appendingPathComponent("\(request.product).app")
    try installApp(from: builtApp, to: destinationApp, force: request.forceReinstall)
    try await launchIfRequested(appPath: destinationApp)
  }

  public func buildOnly() async throws {
    try await buildApp()
  }

  // MARK: - Build

  private func buildApp() async throws {
    if try cachedBuiltApp() != nil {
      return
    }

    var localShell = shell
    localShell.logOptions = .init(
      exposure: .summary,
      tags: ["source": "swift-app-installer", "level": "L1"]
    )
    if request.hasXcodeBuildConfiguration {
      let invocation = try request.xcodeBuildInvocation()
      _ = try await localShell.run(
        host: .direct,
        executable: .name("xcodebuild"),
        arguments: invocation.arguments,
        runnerKind: .auto
      )
    } else {
      _ = try await localShell.run(
        host: .direct,
        executable: .name("swift"),
        arguments: [
          "build",
          "--package-path", request.packagePath,
          "-c", request.configuration.rawValue,
          "--product", request.product,
          "--build-system", "xcode"  // ensures app bundle generation on Apple platforms
        ],
        runnerKind: .auto
      )
    }
  }

  // MARK: - Locate artifact

  func locateBuiltApp() throws -> URL {
    let fm = FileManager.default
    try request.validateXcodeProductCacheConfiguration()
    let packageRoot = URL(fileURLWithPath: request.packagePath)
    let candidates = buildCandidates(
      for: packageRoot,
      configuration: request.configuration,
      product: request.locatedAppBundleName
    )
    for url in candidates where fm.fileExists(atPath: url.path) {
      return url
    }
    throw InstallerError.appBundleNotFound(candidates.map(\.path))
  }

  func buildCandidates(for root: URL, configuration: Configuration, product: String) -> [URL] {
    var candidates: [URL] = []
    if let cachedProduct = request.xcodeProductCacheAppCandidate(
      configuration: configuration,
      product: product
    ) {
      candidates.append(cachedProduct)
    }
    if let dd = request.derivedDataPath {
      let ddRoot = URL(fileURLWithPath: dd)
      candidates.append(
        ddRoot.appendingPathComponent("Build/Products/\(configuration.rawValue.capitalized)/\(product).app"))
    }
    candidates += [
      root.appendingPathComponent(
        ".build/apple/Products/\(configuration.rawValue.capitalized)/\(product).app"),
      root.appendingPathComponent(
        ".build/\(configuration.rawValue.capitalized)/\(product).app"),
      root.appendingPathComponent(
        ".build/\(configuration.rawValue)/\(product).app"),
    ]
    return candidates
  }

  func cachedBuiltApp() throws -> URL? {
    try request.validateXcodeProductCacheConfiguration()
    guard let candidate = request.xcodeProductCacheAppCandidate(
      configuration: request.configuration,
      product: request.locatedAppBundleName
    ) else {
      return nil
    }
    return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
  }

  // MARK: - Install

  private func installApp(from source: URL, to destination: URL, force: Bool) throws {
    let fm = FileManager.default
    if fm.fileExists(atPath: destination.path) {
      if force {
        try fm.removeItem(at: destination)
      } else {
        throw InstallerError.appAlreadyInstalled(destination.path)
      }
    }
    try fm.createDirectory(
      at: destination.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try fm.copyItem(at: source, to: destination)
  }

  // MARK: - Launch

  private func launchIfRequested(appPath: URL) async throws {
    guard request.launch else { return }
    #if os(macOS)
    var localShell = shell
    localShell.logOptions = .init(
      exposure: .summary,
      tags: ["source": "swift-app-installer", "action": "launch"]
    )
    _ = try await localShell.run(
      host: .direct,
      executable: .name("open"),
      arguments: [appPath.path],
      runnerKind: .auto
    )
    #else
    _ = appPath
    #endif
  }

  // MARK: - Xcode invocation

  public static let defaultXcodeDestination = "platform=macOS,arch=arm64"
}

extension SwiftAppInstaller.Request {
  var locatedAppBundleName: String {
    appBundleName ?? product
  }

  var hasXcodeBuildConfiguration: Bool {
    xcodeProject != nil
      || xcodeWorkspace != nil
      || xcodeScheme != nil
      || derivedDataPath != nil
      || xcodeProductCacheWorkspace != nil
      || xcodeProductCacheDerivedDataPath != nil
      || !xcodeDestinations.isEmpty
      || xcodeSDK != nil
      || xcodeResultBundlePath != nil
      || !xcodeBuildSettings.isEmpty
  }

  func xcodeBuildInvocation() throws -> SwiftAppInstaller.XcodeBuildInvocation {
    try validateXcodeProductCacheConfiguration()

    guard let scheme = xcodeScheme, !scheme.isEmpty else {
      throw InstallerError.invalidXcodeBuildConfiguration(
        "xcodebuild requires --scheme when any Xcode build option is provided."
      )
    }

    if xcodeProductCacheWorkspace == nil {
      switch (xcodeProject, xcodeWorkspace) {
      case (.some, .some):
        throw InstallerError.invalidXcodeBuildConfiguration(
          "xcodebuild accepts exactly one of --xcode-project or --xcode-workspace."
        )
      case (.none, .none):
        throw InstallerError.invalidXcodeBuildConfiguration(
          "xcodebuild requires --xcode-project or --xcode-workspace."
        )
      case (.some, .none), (.none, .some):
        break
      }
    }

    try validateXcodeBuildSettings()

    var args: [String] = []
    if let cacheWorkspace = xcodeProductCacheWorkspace {
      args += ["-workspace", cacheWorkspace]
    } else if let project = xcodeProject {
      args += ["-project", project]
    } else if let workspace = xcodeWorkspace {
      args += ["-workspace", workspace]
    }

    args += [
      "-scheme", scheme,
      "-configuration", configuration.rawValue.capitalized,
    ]

    let destinations = xcodeDestinations.isEmpty
      ? [SwiftAppInstaller.defaultXcodeDestination]
      : xcodeDestinations
    for destination in destinations {
      args += ["-destination", destination]
    }

    if let sdk = xcodeSDK {
      args += ["-sdk", sdk]
    }
    if let cacheDerivedDataPath = xcodeProductCacheDerivedDataPath {
      args += ["-derivedDataPath", cacheDerivedDataPath]
    } else if let derivedDataPath {
      args += ["-derivedDataPath", derivedDataPath]
    }
    if let resultBundlePath = xcodeResultBundlePath {
      args += ["-resultBundlePath", resultBundlePath]
    }

    args += xcodeBuildSettings
    args.append("build")
    return .init(arguments: args)
  }

  private func validateXcodeBuildSettings() throws {
    for setting in xcodeBuildSettings {
      let parts = setting.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
      guard parts.count == 2, !parts[0].isEmpty else {
        throw InstallerError.invalidXcodeBuildSetting(setting)
      }
    }
  }

  func validateXcodeProductCacheConfiguration() throws {
    switch (xcodeProductCacheWorkspace, xcodeProductCacheDerivedDataPath) {
    case (.none, .none), (.some, .some):
      return
    case (.some, .none):
      throw InstallerError.invalidXcodeBuildConfiguration(
        "--xcode-product-cache-workspace requires --xcode-product-cache-derived-data-path."
      )
    case (.none, .some):
      throw InstallerError.invalidXcodeBuildConfiguration(
        "--xcode-product-cache-derived-data-path requires --xcode-product-cache-workspace."
      )
    }
  }

  func xcodeProductCacheAppCandidate(
    configuration: SwiftAppInstaller.Configuration,
    product: String
  ) -> URL? {
    guard let xcodeProductCacheDerivedDataPath else { return nil }
    return URL(fileURLWithPath: xcodeProductCacheDerivedDataPath)
      .appendingPathComponent("Build/Products/\(configuration.rawValue.capitalized)/\(product).app")
  }
}

public enum InstallerError: Error, CustomStringConvertible {
  case appBundleNotFound([String])
  case appAlreadyInstalled(String)
  case invalidXcodeBuildConfiguration(String)
  case invalidXcodeBuildSetting(String)

  public var description: String {
    switch self {
    case .appBundleNotFound(let candidates):
      return "App bundle not found; checked: \(candidates.joined(separator: ", "))"
    case .appAlreadyInstalled(let path):
      return "App already installed at \(path). Re-run with --force to replace."
    case .invalidXcodeBuildConfiguration(let reason):
      return reason
    case .invalidXcodeBuildSetting(let setting):
      return "Invalid xcode build setting '\(setting)'. Use KEY=VALUE."
    }
  }
}
