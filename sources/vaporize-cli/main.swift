import ArgumentParser
import AppleProjectSpecCore
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
      processes run, receipts emit. Modes: install, uninstall, build, test, run, \
      pass, use, toolchain, setup. Vaporware-awareness modes: status + warehouse enumerate and \
      store vaporware at a path per the `x-vaporize-collapse-path` annotation \
      convention. Project-generation bridge mode: inspect-project-yml reads \
      legacy XcodeGen YAML into an owned Swift model without rewriting it; \
      compare-project-yml-pkl compares that model with a Pkl parity specimen; \
      generate-project-yml emits transitional AppleProjectSpec YAML from Pkl \
      with a generation receipt. \
      Legacy `inventory` and `x-craze-collapse-path` remain compatibility \
      aliases during migration.
      """
  )

  enum Mode: String, ExpressibleByArgument {
    case install
    case uninstall
    case build
    case test
    case run
    case pass
    case use
    case toolchain
    case setup

    // Phase 0 vaporware-awareness modes.
    case status
    case warehouse
    case validateJSON = "validate-json"
    case inspectProjectYML = "inspect-project-yml"
    case compareProjectYMLPkl = "compare-project-yml-pkl"
    case generateProjectYML = "generate-project-yml"
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

  @Argument(help: "Mode: install, uninstall, build, test, run, pass, use, toolchain, setup, status, warehouse, validate-json, inspect-project-yml, compare-project-yml-pkl, generate-project-yml, inventory, or graph (forwards to package-graph@wrkstrm.cli).")
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
    help: "Emit a JSON execution receipt for pass or use mode.")
  var analyzeExecution: Bool = false

  @Option(
    name: .customLong("receipt-path"),
    help: "Write the pass-through or use JSON receipt to this path.")
  var receiptPath: String?

  @Option(
    name: .customLong("working-directory"),
    help: "Working directory for pass mode. Defaults to the current directory.")
  var passWorkingDirectory: String?

  @Option(
    name: .customLong("common-process-spec"),
    help: "Path to a CommonProcess CommandSpec JSON for use mode. Use '-' for stdin.")
  var commonProcessSpecPath: String?

  @Option(
    name: .customLong("developer-dir"),
    help: "DEVELOPER_DIR override for toolchain mode.")
  var developerDirectory: String?

  @Option(
    name: .customLong("xcode-component"),
    help: "Xcode component to download in setup mode, for example MetalToolchain.")
  var xcodeComponent: String?

  @Option(
    name: .customLong("path"),
    help: "Path for status, warehouse, validate-json, inspect-project-yml, or compare-project-yml-pkl modes.")
  var vaporScanPath: String?

  @Option(
    name: .customLong("pkl-path"),
    help: "Path to an AppleProjectSpec Pkl record for compare-project-yml-pkl or generate-project-yml mode.")
  var pklPath: String?

  @Option(
    name: .customLong("output-path"),
    help: "Output path for generate-project-yml mode.")
  var generatedOutputPath: String?

  @Option(
    name: .customLong("format"),
    help: "Output format for status, inspect-project-yml, compare-project-yml-pkl, or generate-project-yml mode: text (default) or json.")
  var vaporOutputFormat: VaporOutputFormatArgument = .text

  @Argument(parsing: .remaining, help: "Arguments forwarded to test, run, pass, or toolchain mode.")
  var forwardedArguments: [String] = []

  mutating func run() async throws {
    switch mode {
    case .install:
      try await installArtifact(launchApp: launch)
    case .uninstall:
      try await uninstallArtifact()
    case .build:
      try await buildArtifact()
    case .test:
      try await testArtifact()
    case .run:
      try await runArtifact()
    case .pass:
      try await passThrough()
    case .use:
      try await useCommonProcessSpec()
    case .toolchain:
      try await runToolchain()
    case .setup:
      try await setup()
    case .status:
      try await runVaporStatus()
    case .warehouse:
      try await runVaporWarehouse()
    case .validateJSON:
      try await validateJSON()
    case .inspectProjectYML:
      try await inspectProjectYML()
    case .compareProjectYMLPkl:
      try await compareProjectYMLPkl()
    case .generateProjectYML:
      try await generateProjectYML()
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

  private func testArtifact() async throws {
    switch artifact {
    case .cli:
      try await runSwift(arguments: try swiftTestArguments())
    case .app:
      throw ValidationError("test mode currently supports SwiftPM package tests only; use --artifact cli.")
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
      appBundleName: resolvedAppBundleName(product: product),
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
      appBundleName: resolvedAppBundleName(product: product),
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

  private func resolvedAppBundleName(product: String) -> String? {
    if let appBundleName, !appBundleName.isEmpty {
      return appBundleName
    }
    guard xcodeProject != nil || xcodeWorkspace != nil else {
      return nil
    }

    for url in candidateProjectYMLURLs() where FileManager.default.fileExists(atPath: url.path) {
      guard let spec = try? AppleProjectYMLReader.load(url: url) else {
        continue
      }
      let targetName = xcodeScheme ?? product
      if let resolved = AppleProjectAppBundleNameResolver.appBundleName(
        in: spec,
        targetName: targetName,
        configuration: configuration.rawValue.capitalized
      ) {
        return resolved
      }
    }

    return nil
  }

  private func candidateProjectYMLURLs() -> [URL] {
    var candidates: [URL] = []
    if let xcodeProject {
      candidates.append(projectYMLURL(nextTo: xcodeProject))
    }
    if let xcodeWorkspace {
      candidates.append(projectYMLURL(nextTo: xcodeWorkspace))
    }
    if let packagePath {
      candidates.append(absoluteURL(for: packagePath).appendingPathComponent("project.yml"))
    }
    var seen: Set<String> = []
    return candidates.filter { url in
      let path = url.standardizedFileURL.path
      if seen.contains(path) { return false }
      seen.insert(path)
      return true
    }
  }

  private func projectYMLURL(nextTo path: String) -> URL {
    absoluteURL(for: path)
      .deletingLastPathComponent()
      .appendingPathComponent("project.yml")
  }

  private func absoluteURL(for path: String) -> URL {
    if path.hasPrefix("/") {
      return URL(fileURLWithPath: path).standardizedFileURL
    }
    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent(path)
      .standardizedFileURL
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

  func swiftTestArguments() throws -> [String] {
    let packagePath = try requirePackagePath()
    var arguments = [
      "test",
      "--package-path", packagePath,
      "-c", configuration.rawValue,
    ]
    arguments.append(contentsOf: forwardedArguments)
    return arguments
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

  private func useCommonProcessSpec() async throws {
    guard let commonProcessSpecPath, !commonProcessSpecPath.isEmpty else {
      throw ValidationError("--common-process-spec is required for use mode.")
    }

    let command = try CommonProcessSpecLoader.load(path: commonProcessSpecPath)
    let output = try await RunnerControllerFactory.run(command: command)
    FileHandle.standardOutput.write(output.stdout)
    FileHandle.standardError.write(output.stderr)

    let receipt = UseReceipt(
      specSource: commonProcessSpecPath,
      executableRef: executableRefDescription(command.executable),
      argumentCount: command.args.count,
      workingDirectory: command.workingDirectory,
      requestId: command.requestId,
      runnerKind: runnerKindName(command.runnerKind),
      streamingMode: command.streamingMode.rawValue,
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

  private func runToolchain() async throws {
    let request = try XcodeToolchainRequest(arguments: forwardedArguments)
    let requestId = "vaporize-toolchain-\(UUID().uuidString)"
    let workingDirectory = passWorkingDirectory ?? FileManager.default.currentDirectoryPath
    let environmentUpdates = developerDirectory.map { ["DEVELOPER_DIR": $0] }
    let command = CommandSpec(
      executable: .name("xcrun"),
      args: request.xcrunArguments,
      env: .inherit(updating: environmentUpdates),
      workingDirectory: workingDirectory,
      logOptions: .init(
        exposure: .none,
        tags: [
          "source": "vaporize-toolchain",
          "canonicalSource": "vaporize-toolchain",
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

    let receipt = ToolchainReceipt(
      tool: request.tool.rawValue,
      arguments: request.arguments,
      workingDirectory: workingDirectory,
      requestId: requestId,
      runnerKind: "auto",
      developerDirectorySet: developerDirectory != nil,
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

  private func validateJSON() async throws {
    guard let vaporScanPath, !vaporScanPath.isEmpty else {
      throw ValidationError("--path is required for validate-json mode.")
    }

    let requestId = "vaporize-validate-json-\(UUID().uuidString)"
    let data = try Data(contentsOf: URL(fileURLWithPath: vaporScanPath))
    do {
      let receipt = try JSONValidation.validate(
        data: data,
        path: vaporScanPath,
        requestId: requestId
      )
      try emitReceiptIfRequested(receipt)
      print("valid JSON: \(vaporScanPath)")
    } catch {
      let receipt = JSONValidationReceipt(
        path: vaporScanPath,
        requestId: requestId,
        valid: false,
        byteCount: data.count,
        errorMessage: String(describing: error)
      )
      try emitReceiptIfRequested(receipt)
      throw ValidationError("invalid JSON at \(vaporScanPath): \(error)")
    }
  }

  private func inspectProjectYML() async throws {
    guard let vaporScanPath, !vaporScanPath.isEmpty else {
      throw ValidationError("--path is required for inspect-project-yml mode.")
    }

    let requestId = "vaporize-inspect-project-yml-\(UUID().uuidString)"
    let spec = try AppleProjectYMLReader.load(url: URL(fileURLWithPath: vaporScanPath))
    let receipt = AppleProjectYMLReader.receipt(
      for: spec,
      path: vaporScanPath,
      requestId: requestId
    )
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      print(
        "project.yml: \(receipt.projectName) targets=\(receipt.targetCount) packages=\(receipt.packageCount) schemes=\(receipt.schemeCount)"
      )
    case .json:
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(receipt)
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }
  }

  private func compareProjectYMLPkl() async throws {
    guard let vaporScanPath, !vaporScanPath.isEmpty else {
      throw ValidationError("--path is required for compare-project-yml-pkl mode.")
    }
    guard let pklPath, !pklPath.isEmpty else {
      throw ValidationError("--pkl-path is required for compare-project-yml-pkl mode.")
    }

    let requestId = "vaporize-compare-project-yml-pkl-\(UUID().uuidString)"
    let ymlSpec = try AppleProjectYMLReader.load(url: URL(fileURLWithPath: vaporScanPath))
    let pklSpec = try await AppleProjectPklLoader.load(url: URL(fileURLWithPath: pklPath))
    let receipt = AppleProjectSpecComparator.receipt(
      ymlSpec: ymlSpec,
      pklSpec: pklSpec,
      ymlPath: vaporScanPath,
      pklPath: pklPath,
      requestId: requestId
    )
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      let status = receipt.matched ? "matched" : "mismatched"
      print("project.yml <-> project.pkl: \(status) mismatches=\(receipt.mismatchCount)")
      if !receipt.mismatches.isEmpty {
        let joinedMismatches = receipt.mismatches.joined(separator: ", ")
        print("mismatches: \(joinedMismatches)")
      }
    case .json:
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(receipt)
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }

    guard receipt.matched else {
      let joinedMismatches = receipt.mismatches.joined(separator: ", ")
      throw ValidationError("project.yml and project.pkl differ: \(joinedMismatches)")
    }
  }

  private func generateProjectYML() async throws {
    guard let pklPath, !pklPath.isEmpty else {
      throw ValidationError("--pkl-path is required for generate-project-yml mode.")
    }
    guard let generatedOutputPath, !generatedOutputPath.isEmpty else {
      throw ValidationError("--output-path is required for generate-project-yml mode.")
    }

    let requestId = "vaporize-generate-project-yml-\(UUID().uuidString)"
    let receipt = try await AppleProjectSpecYMLGenerator.generate(
      pklURL: URL(fileURLWithPath: pklPath),
      outputURL: URL(fileURLWithPath: generatedOutputPath),
      requestId: requestId
    )
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      print(
        "project.pkl -> project.yml: \(receipt.projectName) targets=\(receipt.targetCount) packages=\(receipt.packageCount) bytes=\(receipt.generatedByteCount)"
      )
      print(receipt.boundary)
    case .json:
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(receipt)
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }
  }

  private func emitReceiptIfRequested(_ receipt: some Encodable) throws {
    guard analyzeExecution || receiptPath != nil else { return }
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

    if analyzeExecution {
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

enum CommonProcessSpecLoader {
  static func load(path: String) throws -> CommandSpec {
    let data: Data
    if path == "-" {
      data = FileHandle.standardInput.readDataToEndOfFile()
    } else {
      data = try Data(contentsOf: URL(fileURLWithPath: path))
    }
    return try decode(data: data)
  }

  static func decode(data: Data) throws -> CommandSpec {
    let command = try JSONDecoder().decode(CommandSpec.self, from: data)
    try command.validateOrThrow()
    return command
  }
}

enum XcodeToolchainTool: String, Codable, Equatable {
  case swift
}

struct XcodeToolchainRequest: Equatable {
  var tool: XcodeToolchainTool
  var arguments: [String]

  var xcrunArguments: [String] {
    [tool.rawValue] + arguments
  }

  init(arguments rawArguments: [String]) throws {
    var tokens = rawArguments
    while tokens.first == "--" {
      tokens.removeFirst()
    }
    guard let rawTool = tokens.first, !rawTool.isEmpty else {
      throw ValidationError("toolchain mode requires an Xcode tool, for example: vaporize toolchain -- swift --version.")
    }
    guard let tool = XcodeToolchainTool(rawValue: rawTool) else {
      throw ValidationError("toolchain mode currently supports swift only; got \(rawTool).")
    }
    tokens.removeFirst()
    if tokens.first == "--" {
      tokens.removeFirst()
    }
    self.tool = tool
    self.arguments = tokens
  }
}

enum JSONValidation {
  static func validate(data: Data, path: String, requestId: String) throws -> JSONValidationReceipt {
    _ = try JSONSerialization.jsonObject(with: data)
    return JSONValidationReceipt(
      path: path,
      requestId: requestId,
      valid: true,
      byteCount: data.count,
      errorMessage: nil
    )
  }
}

private func executableRefDescription(_ executable: Executable) -> String {
  switch executable.ref {
  case .name(let name):
    return "name:\(name)"
  case .path(let path):
    return "path:\(path)"
  case .none:
    return "argv"
  }
}

private func runnerKindName(_ runnerKind: ProcessRunnerKind?) -> String {
  switch runnerKind ?? .auto {
  case .auto:
    return "auto"
  case .foundation:
    return "foundation"
  case .subprocess:
    return "subprocess"
  case .tscbasic:
    return "tscbasic"
  case .seatbelt:
    return "seatbelt"
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

enum PassThroughTool: String, Codable {
  case swift

  var executableName: String { rawValue }
}

struct PassThroughRequest {
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

struct PassThroughReceipt: Codable, Equatable {
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

struct ToolchainReceipt: Codable, Equatable {
  var schemaVersion = "0.1.0"
  var receiptKind = "vaporize-toolchain"
  var tool: String
  var arguments: [String]
  var workingDirectory: String
  var requestId: String
  var runnerKind: String
  var developerDirectorySet: Bool
  var succeeded: Bool
  var exitCode: Int?
  var signal: Int?
  var stdoutBytes: Int
  var stderrBytes: Int
  var processIdentifier: String?
}

struct UseReceipt: Codable, Equatable {
  var schemaVersion = "0.1.0"
  var receiptKind = "vaporize-use-common-process"
  var specSource: String
  var executableRef: String
  var argumentCount: Int
  var workingDirectory: String?
  var requestId: String
  var runnerKind: String
  var streamingMode: String
  var succeeded: Bool
  var exitCode: Int?
  var signal: Int?
  var stdoutBytes: Int
  var stderrBytes: Int
  var processIdentifier: String?
}

struct JSONValidationReceipt: Codable, Equatable {
  var schemaVersion = "0.1.0"
  var receiptKind = "vaporize-json-validation"
  var path: String
  var requestId: String
  var valid: Bool
  var byteCount: Int
  var errorMessage: String?
}
