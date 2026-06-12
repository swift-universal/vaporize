import ArgumentParser
import CommonProcess
import CommonShell

public struct SwiftCLIInstaller: Sendable {
  public enum Configuration: String, CaseIterable, ExpressibleByArgument, Sendable {
    case debug
    case release
  }

  public struct Request: Sendable {
    public var packagePath: String
    public var product: String
    public var configuration: Configuration
    public var forceReinstall: Bool

    public init(
      packagePath: String,
      product: String,
      configuration: Configuration,
      forceReinstall: Bool
    ) {
      self.packagePath = packagePath
      self.product = product
      self.configuration = configuration
      self.forceReinstall = forceReinstall
    }
  }

  private let request: Request
  private let shell: CommonShell

  public init(request: Request, shell: CommonShell = .init()) {
    self.request = request
    self.shell = shell
  }

  public func run() async throws {
    if request.forceReinstall {
      try await uninstallIfPresent()
      try await install()
      return
    }

    do {
      try await install()
    } catch let error as ProcessError where InstallMessageMatcher.isAlreadyInstalled(error.error) {
      try await uninstallIfPresent()
      try await install()
    }
  }

  private func uninstallIfPresent() async throws {
    do {
      try await runSwiftPackage(arguments: uninstallArguments())
    } catch let error as ProcessError where InstallMessageMatcher.isNotInstalled(error.error) {
      return
    }
  }

  private func install() async throws {
    try await runSwiftPackage(arguments: installArguments())
  }

  private func runSwiftPackage(arguments: [String]) async throws {
    var shell = shell
    shell.logOptions = .init(
      exposure: .summary,
      tags: [
        "source": "swift-cli-installer",
        "level": "L1",
      ]
    )
    _ = try await shell.run(
      host: .direct,
      executable: .name("swift"),
      arguments: arguments,
      runnerKind: .auto
    )
  }

  func installArguments() -> [String] {
    let args: [String] = [
      "package",
      "--package-path",
      request.packagePath,
      "experimental-install",
      "-c",
      request.configuration.rawValue,
      "--product",
      request.product,
    ]
    return args
  }

  func uninstallArguments() -> [String] {
    [
      "package",
      "--package-path",
      request.packagePath,
      "experimental-uninstall",
      request.product,
    ]
  }
}

enum InstallMessageMatcher {
  static func isAlreadyInstalled(_ message: String) -> Bool {
    normalized(message).contains("already installed")
  }

  static func isNotInstalled(_ message: String) -> Bool {
    let msg = normalized(message)
    return msg.contains("not installed")
      || msg.contains("no such installed executable")
  }

  private static func normalized(_ message: String) -> String {
    message.lowercased()
  }
}
