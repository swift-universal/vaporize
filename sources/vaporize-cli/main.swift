import ArgumentParser
import CommonProcess
import CommonProcessExecutionKit
import CommonShell
import Foundation
import SwiftAppInstaller
import SwiftCLIInstaller

@main
struct VaporizeCLI: AsyncParsableCommand {
  /// Hard-coded for Phase 0 - see ``FR-CRAZE-VAPORWARE-AWARENESS`` Phase 0 scope.
  /// Phase 1+ will derive this from Package.swift via a build-time plugin.
  static let vaporizeVersion = "0.1.0"

  static let configuration = CommandConfiguration(
    commandName: "vaporize@wrkstrm-core.cli",
    abstract: """
      Substrate-canonical vaporware-collapse gate. vaporize transmutes typed \
      substrate-vaporware into world-state: binaries land, .app installs, \
      processes run, receipts emit. Modes: install, uninstall, build, run, \
      pass, setup. Vaporware-awareness modes: status + warehouse enumerate and \
      store vaporware at a path per the `x-vaporize-collapse-path` annotation \
      convention. Legacy `inventory` and `x-craze-collapse-path` remain \
      compatibility aliases during migration.
      """
  )

  enum Mode: String, ExpressibleByArgument {
    case install
    case uninstall
    case build
    case run
    case pass
    case setup

    // Phase 0 vaporware-awareness modes.
    case status
    case warehouse
    case inventory

    /// Substrate package-graph subfunction. Forwards remaining arguments to
    /// `package-graph@wrkstrm.cli` (a sibling SPM binary at
    /// `wrkstrm/.../domain/build/spm/package-graph/`) so vaporize is the
    /// single canonical surface for inventory / impact / render / compare /
    /// executables / rank / workspace-packages / workspace-projects /
    /// owned-packages / workspace-owned-diff / workspace-project-diff.
    case graph

    // Deprecated compatibility spellings from the original installer shape.
    case cli
    case app
  }

  enum ArtifactKind: String, ExpressibleByArgument {
    case cli
    case app
  }

  @Argument(help: "Mode: install, uninstall, build, run, pass, setup, status, warehouse, inventory, or graph (forwards to package-graph@wrkstrm.cli).")
  var mode: Mode

  @Option(name: .customLong("artifact"), help: "Artifact kind: cli or app.")
  var artifact: ArtifactKind = .cli

  @Option(name: .customLong("package-path"), help: "Path to the Swift package.")
  var packagePath: String?

  @Option(name: .customLong("product"), help: "Product name (binary or app bundle).")
  var product: String?

  @Option(
    name: .customLong("app-bundle-name"),
    help: "Built .app bundle name when it differs from --product (app mode).")
  var appBundleName: String?

  @Option(name: .customLong("configuration"), help: "Build configuration.")
  var configuration: SwiftAppInstaller.Configuration = .release

  // App-only
  @Option(
    name: .customLong("destination"),
    help: "Destination directory for app install (default /Applications).")
  var destination: String = "/Applications"

  @Flag(name: .customLong("force"), help: "Replace existing install.")
  var forceReinstall: Bool = false

  @Flag(name: .customLong("skip-build"), help: "Skip build (app mode only).")
  var skipBuild: Bool = false

  @Flag(name: .customLong("skip-install"), help: "Skip the default install step for build or run mode.")
  var skipInstall: Bool = false

  @Flag(name: .customLong("launch"), help: "Launch app after install (app mode).")
  var launch: Bool = false

  @Option(
    name: .customLong("xcode-project"),
    help: "Path to .xcodeproj when building with xcodebuild (app mode).")
  var xcodeProject: String?

  @Option(
    name: .customLong("xcode-workspace"),
    help: "Path to .xcworkspace when building with xcodebuild (app mode).")
  var xcodeWorkspace: String?

  @Option(
    name: .customLong("scheme"),
    help: "Scheme to build with xcodebuild (requires --xcode-project or --xcode-workspace).")
  var xcodeScheme: String?

  @Option(
    name: .customLong("derived-data-path"),
    help: "Derived data path to use with xcodebuild; also searched for the built .app bundle.")
  var derivedDataPath: String?

  @Option(
    name: .customLong("xcode-destination"),
    help: "Typed xcodebuild destination. Repeat for multiple destinations. Defaults to macOS arm64 when using xcodebuild.")
  var xcodeDestinations: [String] = []

  @Option(
    name: .customLong("xcode-sdk"),
    help: "SDK passed to xcodebuild with -sdk.")
  var xcodeSDK: String?

  @Option(
    name: .customLong("xcode-result-bundle-path"),
    help: "Result bundle path passed to xcodebuild with -resultBundlePath.")
  var xcodeResultBundlePath: String?

  @Option(
    name: .customLong("xcode-build-setting"),
    help: "Build setting passed to xcodebuild as KEY=VALUE. Repeat for multiple settings.")
  var xcodeBuildSettings: [String] = []

  @Flag(
    name: .customLong("analyze"),
    help: "Emit a JSON CommonProcess receipt for pass mode.")
  var analyzePassThrough: Bool = false

  @Option(
    name: .customLong("receipt-path"),
    help: "Write the pass-through JSON receipt to this path.")
  var receiptPath: String?

  @Option(
    name: .customLong("working-directory"),
    help: "Working directory for pass mode. Defaults to the current directory.")
  var passWorkingDirectory: String?

  @Option(
    name: .customLong("xcode-component"),
    help: "Xcode component to download in setup mode, for example MetalToolchain.")
  var xcodeComponent: String?

  @Option(
    name: .customLong("path"),
    help: "Directory to scan for vaporware annotations (status, warehouse modes).")
  var vaporScanPath: String?

  @Option(
    name: .customLong("format"),
    help: "Output format for status mode: text (default) or json.")
  var vaporOutputFormat: VaporOutputFormatArgument = .text

  @Argument(parsing: .remaining, help: "Arguments forwarded to run or pass mode.")
  var forwardedArguments: [String] = []

  mutating func run() async throws {
    switch mode {
    case .install:
      try await installArtifact(launchApp: launch)
    case .uninstall:
      try await uninstallArtifact()
    case .build:
      try await buildArtifact()
    case .run:
      try await runArtifact()
    case .pass:
      try await passThrough()
    case .setup:
      try await setup()
    case .status:
      try await runVaporStatus()
    case .warehouse:
      try await runVaporWarehouse()
    case .inventory:
      try await runVaporWarehouse()
    case .graph:
      try await runGraph()
    case .cli:
      try await installCLI()
    case .app:
      try await installApp(launchApp: launch)
    }
  }

  private func installArtifact(launchApp: Bool) async throws {
    switch artifact {
    case .cli:
      try await installCLI()
    case .app:
      try await installApp(launchApp: launchApp)
    }
  }

  private func uninstallArtifact() async throws {
    switch artifact {
    case .cli:
      try await uninstallCLI()
    case .app:
      try uninstallApp()
    }
  }

  private func buildArtifact() async throws {
    switch artifact {
    case .cli:
      try await runSwift(arguments: try swiftBuildArguments())
      if !skipInstall {
        try await installCLI()
      }
    case .app:
      if skipInstall {
        try await buildAppOnly()
      } else {
        try await installApp(launchApp: launch)
      }
    }
  }

  private func runArtifact() async throws {
    switch artifact {
    case .cli:
      if !skipInstall {
        try await installCLI()
      }
      try await runInstalledCLI()
    case .app:
      if !skipInstall {
        try await installApp(launchApp: true)
      } else {
        try await openInstalledApp()
      }
    }
  }

  private func installCLI() async throws {
    let packagePath = try requirePackagePath()
    let product = try requireProduct()
    let request = SwiftCLIInstaller.Request(
      packagePath: packagePath,
      product: product,
      configuration: .init(rawValue: configuration.rawValue) ?? .release,
      forceReinstall: forceReinstall
    )
    try await SwiftCLIInstaller(request: request).run()
  }

  private func installApp(launchApp: Bool) async throws {
    let packagePath = try requirePackagePath()
    let product = try requireProduct()
    let request = SwiftAppInstaller.Request(
      packagePath: packagePath,
      product: product,
      appBundleName: appBundleName,
      configuration: configuration,
      destination: destination,
      forceReinstall: forceReinstall,
      skipBuild: skipBuild,
      launch: launchApp,
      xcodeProject: xcodeProject,
      xcodeWorkspace: xcodeWorkspace,
      xcodeScheme: xcodeScheme,
      derivedDataPath: derivedDataPath,
      xcodeDestinations: xcodeDestinations,
      xcodeSDK: xcodeSDK,
      xcodeResultBundlePath: xcodeResultBundlePath,
      xcodeBuildSettings: xcodeBuildSettings
    )
    try await SwiftAppInstaller(request: request).run()
  }

  private func uninstallCLI() async throws {
    let packagePath = try requirePackagePath()
    let product = try requireProduct()
    try await runSwiftPackage(arguments: [
      "package",
      "--package-path", packagePath,
      "experimental-uninstall",
      product,
    ])
  }

  private func uninstallApp() throws {
    let product = try requireProduct()
    let installedApp = installedAppURL(product: product)
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: installedApp.path) else { return }
    try fileManager.removeItem(at: installedApp)
  }

  private func buildAppOnly() async throws {
    let packagePath = try requirePackagePath()
    let product = try requireProduct()
    let request = SwiftAppInstaller.Request(
      packagePath: packagePath,
      product: product,
      appBundleName: appBundleName,
      configuration: configuration,
      destination: destination,
      forceReinstall: forceReinstall,
      skipBuild: false,
      launch: false,
      xcodeProject: xcodeProject,
      xcodeWorkspace: xcodeWorkspace,
      xcodeScheme: xcodeScheme,
      derivedDataPath: derivedDataPath,
      xcodeDestinations: xcodeDestinations,
      xcodeSDK: xcodeSDK,
      xcodeResultBundlePath: xcodeResultBundlePath,
      xcodeBuildSettings: xcodeBuildSettings
    )
    try await SwiftAppInstaller(request: request).buildOnly()
  }

  private func runInstalledCLI() async throws {
    let product = try requireProduct()
    try await runExecutable(
      executable: .path(installedCLIPath(product: product)),
      arguments: forwardedArguments,
      sourceTag: "vaporize-run-cli"
    )
  }

  private func openInstalledApp() async throws {
    let product = try requireProduct()
    try await runExecutable(
      executable: .name("open"),
      arguments: [installedAppURL(product: product).path],
      sourceTag: "vaporize-open-app"
    )
  }

  private func installedCLIPath(product: String) -> String {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".swiftpm/bin")
      .appendingPathComponent(product)
      .path
  }

  private func installedAppURL(product: String) -> URL {
    URL(fileURLWithPath: destination).appendingPathComponent("\(product).app")
  }

  private func swiftBuildArguments() throws -> [String] {
    let packagePath = try requirePackagePath()
    let product = try requireProduct()
    return [
      "build",
      "--package-path", packagePath,
      "-c", configuration.rawValue,
      "--product", product,
    ]
  }

  private func requirePackagePath() throws -> String {
    guard let packagePath, !packagePath.isEmpty else {
      throw ValidationError("--package-path is required for \(mode.rawValue) mode.")
    }
    return packagePath
  }

  private func requireProduct() throws -> String {
    guard let product, !product.isEmpty else {
      throw ValidationError("--product is required for \(mode.rawValue) mode.")
    }
    return product
  }

  private func passThrough() async throws {
    let request = try PassThroughRequest(arguments: forwardedArguments)
    let requestId = "vaporize-pass-\(UUID().uuidString)"
    let workingDirectory = passWorkingDirectory ?? FileManager.default.currentDirectoryPath
    let command = CommandSpec(
      executable: .name(request.executableName),
      args: request.arguments,
      env: .inherit(updating: nil),
      workingDirectory: workingDirectory,
      logOptions: .init(
        exposure: .none,
        tags: [
          "source": "vaporize-pass",
          "canonicalSource": "vaporize-pass",
          "tool": request.tool.rawValue,
        ]
      ),
      requestId: requestId,
      runnerKind: .auto,
      streamingMode: .buffered
    )
    try command.validateOrThrow()

    let output = try await RunnerControllerFactory.run(command: command)
    FileHandle.standardOutput.write(output.stdout)
    FileHandle.standardError.write(output.stderr)

    let receipt = PassThroughReceipt(
      tool: request.tool.rawValue,
      executableName: request.executableName,
      arguments: request.arguments,
      workingDirectory: workingDirectory,
      requestId: requestId,
      runnerKind: "auto",
      succeeded: output.isSuccess,
      exitCode: output.exitStatus.exitCode,
      signal: output.exitStatus.signal,
      stdoutBytes: output.stdout.count,
      stderrBytes: output.stderr.count,
      processIdentifier: output.processIdentifier
    )
    try emitReceiptIfRequested(receipt)

    guard output.isSuccess else {
      if let exitCode = output.exitStatus.exitCode {
        throw ExitCode(Int32(exitCode))
      }
      throw ExitCode.failure
    }
  }

  private func setup() async throws {
    guard let xcodeComponent, !xcodeComponent.isEmpty else {
      throw ValidationError("--xcode-component is required for setup mode.")
    }
    try await runExecutable(
      executable: .name("xcodebuild"),
      arguments: ["-downloadComponent", xcodeComponent],
      sourceTag: "vaporize-xcode-component"
    )
  }

  // MARK: - Phase 0 vapor-awareness modes

  private func runVaporStatus() async throws {
    let scanResult = try scanForVapor()
    switch vaporOutputFormat {
    case .text:
      print(VaporInventoryRenderer.renderText(scanResult))
    case .json:
      let data = try VaporInventoryRenderer.renderJSON(
        scanResult,
        vaporizeVersion: Self.vaporizeVersion
      )
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }
  }

  private func runVaporWarehouse() async throws {
    let scanResult = try scanForVapor()
    let scanner = VaporInventoryScanner()
    let receipt = scanner.receipt(from: scanResult, vaporizeVersion: Self.vaporizeVersion)
    let data = try VaporInventoryRenderer.makeJSONEncoder().encode(receipt)

    if let receiptPath {
      let url = URL(fileURLWithPath: receiptPath)
      try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try data.write(to: url)
    } else {
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }
  }

  // MARK: - Package-graph subfunction

  /// Forwards remaining arguments to the substrate-canonical
  /// `package-graph@wrkstrm.cli`. The substrate intent (operator OD-N
  /// 2026-06-11) is that vaporize is the single canonical surface for
  /// substrate modifications, and package-graph's graph-aware impact
  /// analysis is exposed here rather than as an independent CLI.
  ///
  /// Resolution order for the package-graph package path:
  /// 1. `--package-path` (when the operator wants to point at a specific clone)
  /// 2. `$VAPORIZE_PACKAGE_GRAPH_PATH` environment variable
  /// 3. Substrate-default sibling layout (resolved relative to this binary's
  ///    expected mono-root: `<mono>/private/universal/substrate/collectives/
  ///    wrkstrm/private/universal/domain/build/spm/package-graph`).
  private func runGraph() async throws {
    let packageGraphPath = try resolvePackageGraphPath()
    var swiftArgs: [String] = [
      "run",
      "--package-path", packageGraphPath,
      "package-graph@wrkstrm.cli",
    ]
    swiftArgs.append(contentsOf: forwardedArguments)
    try await runSwift(arguments: swiftArgs)
  }

  /// Resolve where the substrate-canonical `package-graph@wrkstrm.cli` SPM
  /// package lives. Honors `--package-path`, then a typed environment hint,
  /// then a substrate-default sibling-collective path. Throws when none of
  /// those resolve to an existing directory.
  private func resolvePackageGraphPath() throws -> String {
    if let packagePath, !packagePath.isEmpty,
      FileManager.default.fileExists(atPath: packagePath)
    {
      return packagePath
    }
    if let envPath = ProcessInfo.processInfo.environment["VAPORIZE_PACKAGE_GRAPH_PATH"],
      !envPath.isEmpty,
      FileManager.default.fileExists(atPath: envPath)
    {
      return envPath
    }
    let monoRoot = monoRootFromCurrentDirectory()
    let substrateDefault = monoRoot.appendingPathComponent(
      "private/universal/substrate/collectives/wrkstrm/private/universal/domain/build/spm/package-graph"
    )
    if FileManager.default.fileExists(atPath: substrateDefault.path) {
      return substrateDefault.path
    }
    throw ValidationError(
      "graph mode could not resolve package-graph@wrkstrm.cli. Pass --package-path, "
        + "set VAPORIZE_PACKAGE_GRAPH_PATH, or run from a tree where "
        + "private/universal/substrate/collectives/wrkstrm/private/universal/domain/build/spm/package-graph exists."
    )
  }

  /// Walk up from the current directory looking for a `private/universal`
  /// marker — that's the substrate mono-root convention. Falls back to the
  /// current directory when no marker is found.
  private func monoRootFromCurrentDirectory() -> URL {
    let fm = FileManager.default
    var current = URL(fileURLWithPath: fm.currentDirectoryPath)
    while current.path != "/" {
      let marker = current.appendingPathComponent("private/universal")
      if fm.fileExists(atPath: marker.path) {
        return current
      }
      current.deleteLastPathComponent()
    }
    return URL(fileURLWithPath: fm.currentDirectoryPath)
  }

  private func scanForVapor() throws -> VaporScanResult {
    guard let vaporScanPath, !vaporScanPath.isEmpty else {
      throw ValidationError("--path is required for \(mode.rawValue) mode.")
    }
    let scanner = VaporInventoryScanner()
    return try scanner.scan(path: vaporScanPath)
  }

  private func emitReceiptIfRequested(_ receipt: PassThroughReceipt) throws {
    guard analyzePassThrough || receiptPath != nil else { return }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(receipt)

    if let receiptPath {
      let url = URL(fileURLWithPath: receiptPath)
      try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try data.write(to: url)
    }

    if analyzePassThrough {
      FileHandle.standardError.write(data)
      FileHandle.standardError.write(Data("\n".utf8))
    }
  }

  private func runSwift(arguments: [String]) async throws {
    try await runExecutable(
      executable: .name("swift"),
      arguments: arguments,
      sourceTag: "vaporize-swift"
    )
  }

  private func runSwiftPackage(arguments: [String]) async throws {
    try await runExecutable(
      executable: .name("swift"),
      arguments: arguments,
      sourceTag: "vaporize-swift-package"
    )
  }

  private func runExecutable(
    executable: Executable,
    arguments: [String],
    sourceTag: String
  ) async throws {
    var shell = CommonShell()
    shell.logOptions = .init(
      exposure: .summary,
      tags: ["source": sourceTag, "level": "L1"]
    )
    let output = try await shell.run(
      host: .direct,
      executable: executable,
      arguments: arguments,
      runnerKind: .auto
    )
    guard !output.isEmpty else { return }
    print(output, terminator: output.hasSuffix("\n") ? "" : "\n")
  }
}

/// ArgumentParser surface for ``VaporOutputFormat`` - kept distinct so the
/// renderer module can stay free of ArgumentParser as a dependency.
enum VaporOutputFormatArgument: String, ExpressibleByArgument {
  case text
  case json

  var rendererFormat: VaporOutputFormat {
    switch self {
    case .text: return .text
    case .json: return .json
    }
  }
}

private enum PassThroughTool: String, Codable {
  case swift

  var executableName: String { rawValue }
}

private struct PassThroughRequest {
  var tool: PassThroughTool
  var executableName: String
  var arguments: [String]

  init(arguments rawArguments: [String]) throws {
    var tokens = rawArguments
    while tokens.first == "--" {
      tokens.removeFirst()
    }

    let tool: PassThroughTool
    if tokens.first == PassThroughTool.swift.rawValue {
      tool = .swift
      tokens.removeFirst()
      if tokens.first == "--" {
        tokens.removeFirst()
      }
    } else {
      tool = .swift
    }

    self.tool = tool
    self.executableName = tool.executableName
    self.arguments = tokens
  }
}

private struct PassThroughReceipt: Codable, Equatable {
  var schemaVersion = "0.1.0"
  var receiptKind = "vaporize-pass-through"
  var tool: String
  var executableName: String
  var arguments: [String]
  var workingDirectory: String
  var requestId: String
  var runnerKind: String
  var succeeded: Bool
  var exitCode: Int?
  var signal: Int?
  var stdoutBytes: Int
  var stderrBytes: Int
  var processIdentifier: String?
}
