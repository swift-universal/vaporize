import ArgumentParser
import AppleProjectSpecCore
import CommonProcess
import CommonProcessExecutionKit
import CommonShell
import Foundation
import SwiftAppInstaller
import SwiftCLIInstaller
import SwiftJSONFormatter

@main
struct VaporizeCLI: AsyncParsableCommand {
  /// Hard-coded for Phase 0 - see ``FR-CRAZE-VAPORWARE-AWARENESS`` Phase 0 scope.
  /// Phase 1+ will derive this from Package.swift via a build-time plugin.
  static let vaporizeVersion = "0.1.0"
  static let buildIdentifier = ProcessInfo.processInfo.environment["VAPORIZE_BUILD_NUMBER"]
    ?? ProcessInfo.processInfo.environment["VAPORIZE_BUILD_ID"]
    ?? "local"
  static let buildSha = ProcessInfo.processInfo.environment["VAPORIZE_BUILD_SHA"]
  static let buildDate = ProcessInfo.processInfo.environment["VAPORIZE_BUILD_DATE"]

  static let configuration = CommandConfiguration(
    commandName: "vaporize.cli@wrkstrm-core.clia.sh",
    abstract: """
      Substrate-canonical vaporware-collapse gate. vaporize transmutes typed \
      substrate-vaporware into world-state: binaries land, .app installs, \
      processes run, receipts emit. Modes: install, uninstall, build, test, run, \
      pass, use, toolchain, setup. Toolchain mode bridges Swift toolchain tools \
      such as swift and docc through the owned Vaporize receipt boundary. \
      Vaporware-awareness modes: status + warehouse enumerate and \
      store vaporware at a path per the `x-vaporize-collapse-path` annotation \
      convention. Project-generation bridge mode: inspect-project-yml reads \
      legacy XcodeGen YAML into an owned Swift model without rewriting it; \
      compare-project-yml-pkl compares that model with a Pkl parity specimen; \
      import-project-yml emits a Pkl parity specimen from legacy YAML; \
      generate-project-yml emits transitional AppleProjectSpec YAML from Pkl \
      with receipts; generate-xcodeproj emits first-slice .xcodeproj \
      world-state from evaluated AppleProjectSpec Pkl; list-targets discovers \
      project targets, packages, and schemes for parity/build routing; \
      list-schemes asks xcodebuild for live .xcworkspace schemes; \
      release-doctor audits the release spine before claims are trusted. \
      `inventory` discovers Package.swift, .xcodeproj, .xcworkspace, \
      project.yml, and project.pkl surfaces by domain, product line, and \
      ownership scope. `cuj-audit` inventories CUJ definitions, proof \
      bindings, canonical product homes, and active-owned implementation \
      coverage without conflating fixtures, matrices, receipts, or tests; \
      `--proof-ledger-path` writes the canonical cross-portfolio proof index \
      while executable tests and green receipts remain in their owning homes. \
      `domains` lists available tool domains from the tools collection. \
      Legacy `x-craze-collapse-path` remains a compatibility alias during migration.
      Target feature inspection mode: inspect-target-features reads a project.yml \
      target, its configFiles wiring, release-features.json, generated xcconfigs, \
      and ReleaseFeatures.swift provenance.
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
    case validateJSONSchema = "validate-json-schema"
    case inspectProjectYML = "inspect-project-yml"
    case inspectTargetFeatures = "inspect-target-features"
    case compareProjectYMLPkl = "compare-project-yml-pkl"
    case importProjectYML = "import-project-yml"
    case upgradeProjectYMLToPkl = "upgrade-project-yml-to-pkl"
    case generateProjectYML = "generate-project-yml"
    case generateXcodeProject = "generate-xcodeproj"
    case listTargets = "list-targets"
    case listSchemes = "list-schemes"
    case releaseDoctor = "release-doctor"
    case inventory
    case cujAudit = "cuj-audit"

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
    case domains

    /// Self-maintenance.
    case selfUpdate = "self-update"
  }

  enum ArtifactKind: String, ExpressibleByArgument {
    case cli
    case app
  }

  enum ExpectOutcome: String, ExpressibleByArgument {
    case pass
    case fail
  }

  @Argument(help: "Mode: install, uninstall, build, test, run, pass, use, toolchain, setup, status, warehouse, validate-json, validate-json-schema, inspect-project-yml, inspect-target-features, compare-project-yml-pkl, import-project-yml, generate-project-yml, generate-xcodeproj, list-targets, list-schemes, release-doctor, inventory, cuj-audit, domains, self-update, or graph (forwards to package-graph@wrkstrm.cli).")
  var mode: Mode?

  @Flag(help: "Prints the tool name, version, and build metadata and exits.")
  var version: Bool = false

  @Option(name: .customLong("artifact"), help: "Artifact kind: cli or app.")
  var artifact: ArtifactKind = .cli

  @Option(name: .customLong("package-path"), help: "Path to the Swift package.")
  var packagePath: String?

  @Option(name: .customLong("product"), help: "Product name (binary or app bundle).")
  var product: String?

  @Option(
    name: .customLong("product-version"),
    help: "Version recorded as CFBundleShortVersionString in the installed CLI metadata Info.plist.")
  var productVersion: String?

  @Option(
    name: .customLong("product-build"),
    help: "Build recorded as CFBundleVersion in the installed CLI metadata Info.plist.")
  var productBuild: String?

  @Option(
    name: .customLong("product-build-sha"),
    help: "Source revision recorded in the installed CLI metadata Info.plist.")
  var productBuildSha: String?

  @Option(
    name: .customLong("product-build-date"),
    help: "Build date recorded in the installed CLI metadata Info.plist.")
  var productBuildDate: String?

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
    help: "Path to .xcworkspace when building with xcodebuild (app mode) or listing workspace schemes.")
  var xcodeWorkspace: String?

  @Option(
    name: .customLong("scheme"),
    help: "Scheme to build with xcodebuild (requires --xcode-project or --xcode-workspace).")
  var xcodeScheme: String?

  @Option(
    name: .customLong("target"),
    help: "Target name for inspect-target-features mode.")
  var targetName: String?

  @Option(
    name: .customLong("derived-data-path"),
    help: "Derived data path to use with xcodebuild; also searched for the built .app bundle.")
  var derivedDataPath: String?

  @Option(
    name: .customLong("xcode-product-cache-workspace"),
    help: "Shared .xcworkspace whose warm product cache should be queried before per-project app build outputs.")
  var xcodeProductCacheWorkspace: String?

  @Option(
    name: .customLong("xcode-product-cache-derived-data-path"),
    help: "DerivedData root for --xcode-product-cache-workspace; Vaporize searches Build/Products/<configuration>/<app>.app there first.")
  var xcodeProductCacheDerivedDataPath: String?

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
    help: "Write the pass-through, use, inventory, or CUJ audit JSON receipt to this path.")
  var receiptPath: String?

  @Option(
    name: .customLong("report-path"),
    help: "Write the CUJ audit Markdown report to this path.")
  var reportPath: String?

  @Option(
    name: .customLong("proof-ledger-path"),
    help: "Write the canonical CUJ automated-proof ledger to this path.")
  var proofLedgerPath: String?

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
    help: "DEVELOPER_DIR override for toolchain mode and SwiftPM CLI build/install/test.")
  var developerDirectory: String?

  @Option(
    name: .customLong("xcode-component"),
    help: "Xcode component to download in setup mode, for example MetalToolchain.")
  var xcodeComponent: String?

  @Option(
    name: .customLong("path"),
    help: "Path for status, warehouse, inventory, cuj-audit, validate-json, inspect-project-yml, inspect-target-features, compare-project-yml-pkl, import-project-yml, or list-targets modes.")
  var vaporScanPath: String?

  @Option(
    name: .customLong("schema"),
    help: "JSON Schema file path for validate-json-schema mode.")
  var jsonSchemaPath: String?

  @Option(
    name: .customLong("fixture"),
    help: "Fixture JSON instance path validated against --schema in validate-json-schema mode.")
  var jsonSchemaFixturePath: String?

  @Option(
    name: .customLong("expect"),
    help: "Expected validate-json-schema outcome: pass or fail. Exit is nonzero when the actual outcome differs.")
  var jsonSchemaExpectedOutcome: ExpectOutcome?

  @Option(
    name: .customLong("pkl-path"),
    help: "Path to an AppleProjectSpec Pkl record for compare-project-yml-pkl, generate-project-yml, generate-xcodeproj, or list-targets mode.")
  var pklPath: String?

  @Option(
    name: .customLong("pkl-schema-path"),
    help: "Path to AppleProjectSpec.pkl for import-project-yml mode. Defaults to Vaporize's package schema when discoverable.")
  var pklSchemaPath: String?

  @Option(
    name: .customLong("output-path"),
    help: "Output path for import-project-yml, generate-project-yml, or generate-xcodeproj mode.")
  var generatedOutputPath: String?

  @Flag(
    name: .customLong("apply"),
    help: "For upgrade-project-yml-to-pkl mode: retire the project.yml after a parity-verified upgrade. Without it the upgrade is a dry-run preview.")
  var applyUpgrade: Bool = false

  @Option(
    name: .customLong("format"),
    help: "Output format for status, inventory, cuj-audit, domains, inspect-project-yml, inspect-target-features, compare-project-yml-pkl, import-project-yml, generate-project-yml, generate-xcodeproj, list-targets, list-schemes, or release-doctor mode: text (default) or json.")
  var vaporOutputFormat: VaporOutputFormatArgument = .text

  @Option(name: .customLong("domain"), help: "Tool domain for install/uninstall/run and domain path shaping (for example build).")
  var toolDomain: String?

  @Option(name: .customLong("tools-collection"), help: "Kura tools collection directory for domains mode.")
  var toolsCollectionPath: String?

  @Argument(parsing: .remaining, help: "Arguments forwarded to test, run, pass, or toolchain mode.")
  var forwardedArguments: [String] = []

  mutating func run() async throws {
    if version {
      printVersionMetadata()
      return
    }

    guard let mode else {
      throw ValidationError(
        "missing expected argument <mode>. Run with --help for valid modes, or --version to print build metadata."
      )
    }

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
    case .validateJSONSchema:
      try await validateJSONSchema()
    case .inspectProjectYML:
      try await inspectProjectYML()
    case .inspectTargetFeatures:
      try await inspectTargetFeatures()
    case .compareProjectYMLPkl:
      try await compareProjectYMLPkl()
    case .importProjectYML:
      try await importProjectYML()
    case .upgradeProjectYMLToPkl:
      try await upgradeProjectYMLToPkl()
    case .generateProjectYML:
      try await generateProjectYML()
    case .generateXcodeProject:
      try await generateXcodeProject()
    case .listTargets:
      try await listTargets()
    case .listSchemes:
      try await listSchemes()
    case .releaseDoctor:
      try await releaseDoctor()
    case .inventory:
      try await runOwnedSurfaceInventory()
    case .cujAudit:
      try await runCUJPortfolioAudit()
    case .domains:
      try await runDomains()
    case .selfUpdate:
      try await selfUpdate()
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

  private func selfUpdate() async throws {
    let packagePath = try requireSelfUpdatePackagePath()
    let product = "vaporize.cli@wrkstrm-core.clia.sh"
    let updateDomain = inferredDomain(for: product, packagePath: packagePath)
    let request = SwiftCLIInstaller.Request(
      packagePath: packagePath,
      product: product,
      configuration: .init(rawValue: configuration.rawValue) ?? .release,
      forceReinstall: true,
      productVersion: Self.vaporizeVersion,
      productBuild: Self.buildIdentifier,
      productBuildSha: Self.buildSha,
      productBuildDate: Self.buildDate,
      installerVersion: Self.vaporizeVersion,
      installerBuild: Self.buildIdentifier,
      developerDirectory: developerDirectory
    )
    try await SwiftCLIInstaller(request: request).run()
    try publishInstalledCLI(toDomain: updateDomain, product: product)
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
    let product = try requireCLIProduct()
    let installDomain = inferredDomain(for: product, packagePath: packagePath)
    let request = SwiftCLIInstaller.Request(
      packagePath: packagePath,
      product: product,
      configuration: .init(rawValue: configuration.rawValue) ?? .release,
      forceReinstall: forceReinstall,
      productVersion: resolvedProductVersion(for: product),
      productBuild: resolvedProductBuild(for: product),
      productBuildSha: resolvedProductBuildSha(for: product),
      productBuildDate: resolvedProductBuildDate(for: product),
      installerVersion: Self.vaporizeVersion,
      installerBuild: Self.buildIdentifier,
      developerDirectory: developerDirectory
    )
    try await SwiftCLIInstaller(request: request).run()
    // Post-install presence check: the installer must have landed an executable at the
    // flat install path. `swift package experimental-install` removes any prior binary
    // before writing the new one, so an aborted/failed copy leaves the destination
    // MISSING while the command still returns success — the "removed but not replaced"
    // failure mode that left savepoint.cli@kura-org.clia.sh as a lone .bak with no live
    // binary (BUG-SAVEPOINT-CLI-MISSING-FROM-SWIFTPM-BIN-2026-07-08). Fail loudly here
    // instead of reporting a silent success with no installed tool.
    let installedPath = installedCLIPath(product: product)
    guard FileManager.default.isExecutableFile(atPath: installedPath) else {
      throw ValidationError(
        """
        Install reported success but no executable landed for product `\(product)`.
        Expected an executable at:
          \(installedPath)
        This guards the remove-then-copy failure mode where the prior binary is removed
        but the new one is never written (leaving nothing, or only a stale .bak). Re-run
        the build; if it recurs, inspect the `swift package experimental-install` copy step.
        """
      )
    }
    try publishInstalledCLI(toDomain: installDomain, product: product)
    // Positive presence confirmation: name the verified path so a multi-binary suite
    // reinstall (one invocation per product) emits one confirmation each — any single
    // missing binary surfaces immediately rather than hiding behind a silent success.
    print("vaporize: verified \(product) installed at \(installedPath)")
  }

  /// Resolve the Xcode build inputs for app mode so an Xcode-project app builds
  /// through the xcodebuild path instead of the SwiftPM builder.
  ///
  /// - Explicit `--xcode-project` / `--xcode-workspace` always win untouched.
  /// - A real Swift package (a `Package.swift` at the package path) keeps the
  ///   existing `swift build` path.
  /// - Otherwise the path is treated as an Xcode-project app: discover a unique
  ///   `.xcworkspace` (preferred) or `.xcodeproj` there and default the scheme
  ///   to the product name, so `vaporize --artifact app --package-path <app> run`
  ///   works without hand-fed flags.
  /// - If the path is neither a Swift package nor a unique Xcode
  ///   project/workspace, fail LOUD rather than silently invoking `swift build`
  ///   against a non-SPM directory (the silent-fallback-to-wrong-state failure
  ///   this method exists to kill).
  private func resolvedXcodeAppInputs(packagePath: String, product: String) throws
    -> (project: String?, workspace: String?, scheme: String?)
  {
    // Gather the filesystem facts here; the routing decision itself lives in the
    // filesystem-free XcodeAppInputResolver so it can be swept in the proving
    // ground (Tests/cuj-02-mac-app).
    let fileManager = FileManager.default
    let root = URL(fileURLWithPath: packagePath, isDirectory: true)
    let hasPackageSwift = fileManager.fileExists(
      atPath: root.appendingPathComponent("Package.swift").path)
    let entries = (try? fileManager.contentsOfDirectory(atPath: packagePath)) ?? []
    do {
      let inputs = try XcodeAppInputResolver.resolve(
        packageDirectory: packagePath,
        explicitProject: xcodeProject,
        explicitWorkspace: xcodeWorkspace,
        explicitScheme: xcodeScheme,
        hasPackageSwift: hasPackageSwift,
        entries: entries,
        product: product)
      return (inputs.project, inputs.workspace, inputs.scheme)
    } catch let error as XcodeAppInputResolver.NoBuildableProject {
      throw ValidationError(error.description)
    }
  }

  private func installApp(launchApp: Bool) async throws {
    let packagePath = try requirePackagePath()
    let product = try requireProduct()
    let xcodeInputs = try resolvedXcodeAppInputs(packagePath: packagePath, product: product)
    let request = SwiftAppInstaller.Request(
      packagePath: packagePath,
      product: product,
      appBundleName: resolvedAppBundleName(product: product),
      configuration: configuration,
      destination: destination,
      forceReinstall: forceReinstall,
      skipBuild: skipBuild,
      launch: launchApp,
      xcodeProject: xcodeInputs.project,
      xcodeWorkspace: xcodeInputs.workspace,
      xcodeScheme: xcodeInputs.scheme,
      derivedDataPath: derivedDataPath,
      xcodeProductCacheWorkspace: xcodeProductCacheWorkspace,
      xcodeProductCacheDerivedDataPath: xcodeProductCacheDerivedDataPath,
      xcodeDestinations: xcodeDestinations,
      xcodeSDK: xcodeSDK,
      xcodeResultBundlePath: xcodeResultBundlePath,
      xcodeBuildSettings: xcodeBuildSettings
    )
    try await SwiftAppInstaller(request: request).run()
  }

  private func uninstallCLI() async throws {
    let packagePath = try requirePackagePath()
    let product = try requireCLIProduct()
    let uninstallDomain = inferredDomain(for: product, packagePath: packagePath)
    try await runSwiftPackage(arguments: [
      "package",
      "--package-path", packagePath,
      "experimental-uninstall",
      product,
    ])
    try removePublishedCLI(fromDomain: uninstallDomain, product: product)
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
    let xcodeInputs = try resolvedXcodeAppInputs(packagePath: packagePath, product: product)
    let request = SwiftAppInstaller.Request(
      packagePath: packagePath,
      product: product,
      appBundleName: resolvedAppBundleName(product: product),
      configuration: configuration,
      destination: destination,
      forceReinstall: forceReinstall,
      skipBuild: false,
      launch: false,
      xcodeProject: xcodeInputs.project,
      xcodeWorkspace: xcodeInputs.workspace,
      xcodeScheme: xcodeInputs.scheme,
      derivedDataPath: derivedDataPath,
      xcodeProductCacheWorkspace: xcodeProductCacheWorkspace,
      xcodeProductCacheDerivedDataPath: xcodeProductCacheDerivedDataPath,
      xcodeDestinations: xcodeDestinations,
      xcodeSDK: xcodeSDK,
      xcodeResultBundlePath: xcodeResultBundlePath,
      xcodeBuildSettings: xcodeBuildSettings
    )
    try await SwiftAppInstaller(request: request).buildOnly()
  }

  private func runInstalledCLI() async throws {
    let product = try requireCLIProduct()
    let executablePath = try installedCLIExecutablePath(product: product)
    try await runExecutable(
      executable: .path(executablePath),
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

  private func installedCLIBinDirectory() -> URL {
    FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".swiftpm/bin")
  }

  private func installedCLIPath(product: String) -> String {
    installedCLIBinDirectory().appendingPathComponent(product).path
  }

  func installedCLIExecutablePath(product: String) throws -> String {
    let candidates = installedCLIExecutableCandidatePaths(product: product)
    for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
      return path
    }
    throw ValidationError(
      """
      Executable product `\(product)` is not installed or is not executable.
      Checked:
      \(candidates.map { "  - \($0)" }.joined(separator: "\n"))
      """
    )
  }

  func installedCLIExecutableCandidatePaths(product: String) -> [String] {
    var candidates: [String] = []
    var seen: Set<String> = []

    func append(_ path: String?) {
      guard let path, !path.isEmpty, !seen.contains(path) else { return }
      seen.insert(path)
      candidates.append(path)
    }

    if let packagePath,
       let domain = inferredDomain(for: product, packagePath: packagePath)
    {
      append(domainSpecificCLIPath(product: product, domain: domain))
    }
    if let domain = inferredDomainValue() {
      append(domainSpecificCLIPath(product: product, domain: domain))
    }
    for path in discoveredDomainCLIPaths(product: product) {
      append(path)
    }
    append(installedCLIPath(product: product))

    return candidates
  }

  private func inferredDomain(for product: String, packagePath: String) -> String? {
    if let explicitDomain = inferredDomainValue(), !explicitDomain.isEmpty {
      return explicitDomain
    }
    if let inferredDomain = domainFromPackagePath(packagePath) {
      return inferredDomain
    }
    return nil
  }

  private func inferredDomainValue() -> String? {
    let trimmed = toolDomain?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? nil : trimmed
  }

  private func domainFromPackagePath(_ packagePath: String) -> String? {
    let normalized = absoluteURL(for: packagePath).path
    let components = normalized.split(separator: "/").map(String.init)
    guard let index = components.firstIndex(of: "domain"), index + 1 < components.count else {
      return nil
    }
    let domain = components[index + 1]
    let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private func domainSpecificCLIPath(product: String, domain: String) -> String? {
    let components = safeDomainPathComponents(domain)
    guard !components.isEmpty else { return nil }
    return domainPath(forComponents: components).appendingPathComponent(product).path
  }

  private func discoveredDomainCLIPaths(product: String) -> [String] {
    let base = installedCLIBinDirectory().appendingPathComponent("domain", isDirectory: true)
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: base.path) else { return [] }
    guard let enumerator = fileManager.enumerator(
      at: base,
      includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    var matches: [String] = []
    for case let url as URL in enumerator where url.lastPathComponent == product {
      let path = url.standardizedFileURL.path
      if fileManager.isExecutableFile(atPath: path) {
        matches.append(path)
      }
    }
    return matches.sorted()
  }

  private func domainPath(forComponents components: [String]) -> URL {
    components.reduce(installedCLIBinDirectory().appendingPathComponent("domain")) { path, component in
      path.appendingPathComponent(sanitizePathComponent(component), isDirectory: true)
    }
  }

  private func sanitizePathComponent(_ value: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
    let sanitized = value.unicodeScalars.map { scalar in
      allowed.contains(scalar) ? Character(scalar) : "_"
    }
    return String(sanitized)
  }

  private func safeDomainPathComponents(_ domain: String) -> [String] {
    domain
      .split(separator: "/")
      .map(String.init)
      .compactMap { sanitizePathComponent($0).isEmpty ? nil : sanitizePathComponent($0) }
  }

  private func publishInstalledCLI(toDomain domain: String?, product: String) throws {
    guard let domain, !domain.isEmpty else { return }
    let domainComponents = safeDomainPathComponents(domain)
    guard !domainComponents.isEmpty else { return }

    let fileManager = FileManager.default
    let target = URL(fileURLWithPath: installedCLIPath(product: product))
    let link = domainPath(forComponents: domainComponents).appendingPathComponent(product)

    if fileManager.fileExists(atPath: link.path) {
      try fileManager.removeItem(at: link)
    }
    try fileManager.createDirectory(
      at: link.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try fileManager.createSymbolicLink(at: link, withDestinationURL: target)
  }

  private func removePublishedCLI(fromDomain domain: String?, product: String) throws {
    if let domain {
      try removeDomainCLI(product: product, domain: domain)
      return
    }

    let base = installedCLIBinDirectory().appendingPathComponent("domain")
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: base.path) else { return }
    guard let enumerator = fileManager.enumerator(at: base, includingPropertiesForKeys: [.isRegularFileKey]) else {
      return
    }
    for case let url as URL in enumerator {
      guard url.lastPathComponent == product else { continue }
      do {
        try removeDomainCLI(at: url)
      } catch {
        continue
      }
    }
  }

  private func removeDomainCLI(product: String, domain: String) throws {
    guard let domainPath = domainSpecificCLIPath(product: product, domain: domain) else {
      return
    }
    let link = URL(fileURLWithPath: domainPath)
    guard FileManager.default.fileExists(atPath: link.path) else {
      return
    }
    try removeDomainCLI(at: link)
  }

  private func removeDomainCLI(at url: URL) throws {
    try FileManager.default.removeItem(at: url)
  }

  private func installedAppURL(product: String) -> URL {
    URL(fileURLWithPath: destination).appendingPathComponent("\(product).app")
  }

  func swiftBuildArguments() throws -> [String] {
    let packagePath = try requirePackagePath()
    let product = try requireCLIProduct()
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

  func developerDirectoryEnvironment() -> [String: String]? {
    guard let developerDirectory, !developerDirectory.isEmpty else { return nil }
    return ["DEVELOPER_DIR": developerDirectory]
  }

  private func requirePackagePath() throws -> String {
    guard let packagePath, !packagePath.isEmpty else {
      throw ValidationError("--package-path is required for operation mode.")
    }
    return packagePath
  }

  private func requireSelfUpdatePackagePath() throws -> String {
    if let packagePath, !packagePath.isEmpty {
      return packagePath
    }

    let currentDirectory = FileManager.default.currentDirectoryPath
    let manifestPath = URL(fileURLWithPath: currentDirectory)
      .appendingPathComponent("Package.swift")
      .path
    guard FileManager.default.fileExists(atPath: manifestPath) else {
      throw ValidationError(
        "--package-path is required for self-update unless run from a package root."
      )
    }

    return currentDirectory
  }

  private func requireProduct() throws -> String {
    guard let product, !product.isEmpty else {
      throw ValidationError("--product is required for operation mode.")
    }
    return product
  }

  private func requireCLIProduct() throws -> String {
    let product = try requireProduct()
    do {
      try SwiftCLIProductName.validate(product)
    } catch let error as SwiftCLIProductNameError {
      throw ValidationError(
        VaporizeCLIActionability.productValidationMessage(
          errorDescription: error.description,
          product: product
        )
      )
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

  private func resolvedProductVersion(for product: String) -> String? {
    productVersion ?? (product == Self.configuration.commandName ? Self.vaporizeVersion : nil)
  }

  private func resolvedProductBuild(for product: String) -> String? {
    productBuild ?? (product == Self.configuration.commandName ? Self.buildIdentifier : nil)
  }

  private func resolvedProductBuildSha(for product: String) -> String? {
    productBuildSha ?? (product == Self.configuration.commandName ? Self.buildSha : nil)
  }

  private func resolvedProductBuildDate(for product: String) -> String? {
    productBuildDate ?? (product == Self.configuration.commandName ? Self.buildDate : nil)
  }

  private func printVersionMetadata() {
    print("vaporize.cli@wrkstrm-core.clia.sh \(Self.vaporizeVersion) (build \(Self.buildIdentifier))")
    if let buildSha = Self.buildSha {
      print("build-sha: \(buildSha)")
    }
    if let buildDate = Self.buildDate {
      print("build-date: \(buildDate)")
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
    let request = try SwiftToolchainRequest(arguments: forwardedArguments)
    let requestId = "vaporize-toolchain-\(UUID().uuidString)"
    let workingDirectory = passWorkingDirectory ?? FileManager.default.currentDirectoryPath
    let environmentUpdates = developerDirectory.map { ["DEVELOPER_DIR": $0] }
    let invocation = try request.invocation()
    let command = CommandSpec(
      executable: invocation.executable,
      args: invocation.arguments,
      env: .inherit(updating: environmentUpdates),
      workingDirectory: workingDirectory,
      logOptions: .init(
        exposure: .none,
        tags: [
          "source": "vaporize-toolchain",
          "canonicalSource": "vaporize-toolchain",
          "tool": request.tool.rawValue,
          "toolchainResolver": invocation.resolver,
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
      executableRef: invocation.executableRef,
      resolver: invocation.resolver,
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

  private func runOwnedSurfaceInventory() async throws {
    let scanPath = try ownedSurfaceInventoryPath()
    let result = try OwnedSurfaceInventoryScanner().scan(path: scanPath)
    let data = try OwnedSurfaceInventoryRenderer.renderJSON(
      result,
      vaporizeVersion: Self.vaporizeVersion
    )

    if let receiptPath {
      let url = URL(fileURLWithPath: receiptPath)
      try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try data.write(to: url)
    }

    switch vaporOutputFormat {
    case .text:
      print(OwnedSurfaceInventoryRenderer.renderText(result))
    case .json:
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }
  }

  private func ownedSurfaceInventoryPath() throws -> String {
    if let vaporScanPath, !vaporScanPath.isEmpty {
      return vaporScanPath
    }

    let monoRoot = monoRootFromCurrentDirectory()
    let substrateRoot = monoRoot.appendingPathComponent("private/universal/substrate")
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: substrateRoot.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    {
      return substrateRoot.path
    }
    return FileManager.default.currentDirectoryPath
  }

  private func runCUJPortfolioAudit() async throws {
    let scanPath = try ownedSurfaceInventoryPath()
    let result = try CUJPortfolioAuditScanner().scan(path: scanPath)
    let generatedAt = Date()
    let data = try CUJPortfolioAuditRenderer.renderJSON(
      result,
      vaporizeVersion: Self.vaporizeVersion,
      scannedAt: generatedAt
    )
    let report = CUJPortfolioAuditRenderer.renderMarkdown(result)
    let proofLedger = try CUJAutomatedProofLedgerRenderer.renderJSON(
      result,
      vaporizeVersion: Self.vaporizeVersion,
      generatedAt: generatedAt
    )

    if let receiptPath {
      try writeCUJAudit(Data(data), to: receiptPath)
    }
    if let reportPath {
      try writeCUJAudit(Data(report.utf8), to: reportPath)
    }
    if let proofLedgerPath {
      try writeCUJAudit(proofLedger, to: proofLedgerPath)
    }

    switch vaporOutputFormat {
    case .text:
      print(report, terminator: "")
    case .json:
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }
  }

  private func writeCUJAudit(_ data: Data, to path: String) throws {
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try data.write(to: url, options: .atomic)
  }

  private func runDomains() async throws {
    let collectionPath = try resolveToolsCollectionPath()
    let manifests = try loadToolManifests(from: collectionPath)
    let domains = Set(
      manifests.compactMap(\.domain)
    )
    let sortedDomains = domains.sorted { lhs, rhs in
      lhs.localizedStandardCompare(rhs) == .orderedAscending
    }
    switch vaporOutputFormat {
    case .text:
      for domain in sortedDomains {
        print(domain)
      }
    case .json:
      let payload = DomainsPayload(
        collectionPath: collectionPath.path,
        domains: sortedDomains,
        count: sortedDomains.count
      )
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(payload)
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }
  }

  private func resolveToolsCollectionPath() throws -> URL {
    if let toolsCollectionPath, !toolsCollectionPath.isEmpty {
      return absoluteURL(for: toolsCollectionPath)
    }
    if let envPath = ProcessInfo.processInfo.environment["VAPORIZE_TOOLS_COLLECTION_PATH"],
      !envPath.isEmpty
    {
      return absoluteURL(for: envPath)
    }

    let defaultCollection = monoRootFromCurrentDirectory().appendingPathComponent(
      "private/universal/substrate/collectives/wrkstrm-core/private/universal/kura-spaces/collections/tools"
    )
    guard FileManager.default.fileExists(atPath: defaultCollection.path) else {
      throw ValidationError(
        "could not resolve tool collection path for domains mode. Pass --tools-collection or run from a mono root."
      )
    }
    return defaultCollection
  }

  private func loadToolManifests(from collectionPath: URL) throws -> [ToolManifestRecord] {
    let fileManager = FileManager.default
    guard let enumerator = fileManager.enumerator(
      at: collectionPath,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }
    return enumerator.compactMap { item in
      guard let url = item as? URL, url.path.hasSuffix(".cli.tool.json") else {
        return nil
      }
      do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ToolManifestRecord.self, from: data)
      } catch {
        return nil
      }
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
      throw ValidationError("--path is required for this operation.")
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

  private func validateJSONSchema() async throws {
    guard let jsonSchemaPath, !jsonSchemaPath.isEmpty else {
      throw ValidationError("--schema is required for validate-json-schema mode.")
    }
    guard let jsonSchemaFixturePath, !jsonSchemaFixturePath.isEmpty else {
      throw ValidationError("--fixture is required for validate-json-schema mode.")
    }

    let requestId = "vaporize-validate-json-schema-\(UUID().uuidString)"
    let expectedLabel = jsonSchemaExpectedOutcome?.rawValue

    let outcome: JSONSchemaValidation.Outcome
    do {
      outcome = try JSONSchemaValidation.validate(
        schemaPath: jsonSchemaPath,
        fixturePath: jsonSchemaFixturePath
      )
    } catch let engineError as JSONSchemaValidation.EngineError {
      let message = VaporizeCLIActionability.schemaValidationMessage(
        errorDescription: String(describing: engineError),
        schemaPath: jsonSchemaPath,
        fixturePath: jsonSchemaFixturePath,
        expected: expectedLabel,
        actual: "fail",
        diagnostics: [String(describing: engineError)]
      )
      let receipt = JSONSchemaValidationReceipt(
        schemaPath: jsonSchemaPath,
        fixturePath: jsonSchemaFixturePath,
        requestId: requestId,
        expected: expectedLabel,
        actual: "fail",
        matched: expectedLabel == nil ? nil : false,
        diagnostics: [String(describing: engineError)],
        nextSteps: Self.schemaValidationFailureNextSteps
      )
      try emitReceiptIfRequested(receipt)
      throw ValidationError(message)
    }

    let (actual, matched) = JSONSchemaValidation.expectationOutcome(
      expected: expectedLabel,
      valid: outcome.valid
    )
    let succeeded = matched ?? outcome.valid
    let receipt = JSONSchemaValidationReceipt(
      schemaPath: jsonSchemaPath,
      fixturePath: jsonSchemaFixturePath,
      requestId: requestId,
      expected: expectedLabel,
      actual: actual,
      matched: matched,
      diagnostics: outcome.diagnostics,
      nextSteps: succeeded
        ? ["No action required: actual outcome '\(actual)' matches the declared expectation."]
        : Self.schemaValidationFailureNextSteps
    )
    try emitReceiptIfRequested(receipt)

    if succeeded {
      let expectationSuffix = expectedLabel.map { " (expected \($0))" } ?? ""
      print(
        "schema validation \(actual)\(expectationSuffix): \(jsonSchemaFixturePath) against \(jsonSchemaPath)"
      )
      return
    }

    let errorDescription: String
    if let expectedLabel, matched == false {
      errorDescription =
        "actual outcome '\(actual)' did not match --expect \(expectedLabel)"
    } else {
      errorDescription = "fixture failed JSON Schema validation"
    }
    throw ValidationError(
      VaporizeCLIActionability.schemaValidationMessage(
        errorDescription: errorDescription,
        schemaPath: jsonSchemaPath,
        fixturePath: jsonSchemaFixturePath,
        expected: expectedLabel,
        actual: actual,
        diagnostics: outcome.diagnostics
      )
    )
  }

  private static let schemaValidationFailureNextSteps: [String] = [
    "Inspect each diagnostic's instance path in the fixture and fix the fixture, the schema, or the declared --expect value.",
    "If a diagnostic names an unresolvable or remote $ref, repair the schema's $ref target; remote http(s) refs are unsupported by design.",
    "Rerun the validate-json-schema command after the fix.",
    "If still blocked, capture the full error text and bring it to Digikoma via the digikoma-command in the error message.",
  ]

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

  private func inspectTargetFeatures() async throws {
    guard let vaporScanPath, !vaporScanPath.isEmpty else {
      throw ValidationError("--path is required for inspect-target-features mode.")
    }

    let requestId = "vaporize-inspect-target-features-\(UUID().uuidString)"
    let receipt = try VaporizeTargetFeaturesInspector.inspect(
      projectYMLURL: URL(fileURLWithPath: vaporScanPath),
      targetName: targetName,
      requestId: requestId
    )
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      let configs = receipt.declaredBuildConfigurations.map(\.name).joined(separator: ", ")
      print(
        "target features: \(receipt.targetName) status=\(receipt.overallStatus) configs=[\(configs)] tiers=\(receipt.releaseFeatureManifest.tierCount)"
      )
      for minimum in receipt.minimums where minimum.status != "pass" {
        print("\(minimum.status): \(minimum.name) - \(minimum.detail)")
      }
    case .json:
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(receipt)
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }

    guard receipt.overallStatus == "pass" else {
      throw ValidationError("target feature inspection failed for \(receipt.targetName).")
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

  private func importProjectYML() async throws {
    guard let vaporScanPath, !vaporScanPath.isEmpty else {
      throw ValidationError("--path is required for import-project-yml mode.")
    }
    guard let generatedOutputPath, !generatedOutputPath.isEmpty else {
      throw ValidationError("--output-path is required for import-project-yml mode.")
    }

    let outputURL = URL(fileURLWithPath: generatedOutputPath).standardizedFileURL
    let schemaURL = try resolvedAppleProjectSpecSchemaURL()
    let schemaAmendsPath = relativePath(
      from: outputURL.deletingLastPathComponent(),
      to: schemaURL
    )
    let requestId = "vaporize-import-project-yml-\(UUID().uuidString)"
    let receipt = try AppleProjectSpecPklImporter.generate(
      ymlURL: URL(fileURLWithPath: vaporScanPath).standardizedFileURL,
      outputURL: outputURL,
      schemaAmendsPath: schemaAmendsPath,
      requestId: requestId
    )
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      print(
        "project.yml -> project.pkl: \(receipt.projectName) targets=\(receipt.targetCount) packages=\(receipt.packageCount) bytes=\(receipt.generatedByteCount)"
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

  /// Upgrade an app from legacy project.yml to a project.pkl project: import the
  /// yml to a sibling project.pkl, parity-gate by loading the pkl back and
  /// comparing to the yml, and — only on a clean parity with --apply — retire the
  /// project.yml. Dry-run (preview) by default. The retire-or-keep decision is the
  /// filesystem-free AppleProjectPklUpgradePlanner (see its proving ground).
  private func upgradeProjectYMLToPkl() async throws {
    guard let vaporScanPath, !vaporScanPath.isEmpty else {
      throw ValidationError("--path is required for upgrade-project-yml-to-pkl mode (the project.yml).")
    }
    let ymlURL = URL(fileURLWithPath: vaporScanPath).standardizedFileURL
    guard FileManager.default.fileExists(atPath: ymlURL.path) else {
      throw ValidationError("upgrade-project-yml-to-pkl: no project.yml at \(ymlURL.path).")
    }
    // Default the pkl output beside the yml (project.pkl) unless --output-path given.
    let pklURL: URL = {
      if let generatedOutputPath, !generatedOutputPath.isEmpty {
        return URL(fileURLWithPath: generatedOutputPath).standardizedFileURL
      }
      return ymlURL.deletingLastPathComponent().appendingPathComponent("project.pkl")
    }()
    let requestId = "vaporize-upgrade-project-yml-to-pkl-\(UUID().uuidString)"

    // 1. Import: project.yml -> project.pkl.
    let schemaURL = try resolvedAppleProjectSpecSchemaURL()
    let schemaAmendsPath = relativePath(from: pklURL.deletingLastPathComponent(), to: schemaURL)
    let importReceipt = try AppleProjectSpecPklImporter.generate(
      ymlURL: ymlURL,
      outputURL: pklURL,
      schemaAmendsPath: schemaAmendsPath,
      requestId: requestId
    )

    // 2. Parity gate: load the generated pkl back and compare to the yml.
    let ymlSpec = try AppleProjectYMLReader.load(url: ymlURL)
    let pklSpec = try await AppleProjectPklLoader.load(url: pklURL)
    let comparison = AppleProjectSpecComparator.receipt(
      ymlSpec: ymlSpec,
      pklSpec: pklSpec,
      ymlPath: ymlURL.path,
      pklPath: pklURL.path,
      requestId: requestId
    )

    // 3. Decide (pure), then act.
    let decision = AppleProjectPklUpgradePlanner.decide(
      parityMatched: comparison.matched,
      mismatches: comparison.mismatches,
      apply: applyUpgrade
    )
    switch decision {
    case .blockedByParity(let mismatches):
      // Leave the unverified pkl for inspection; never retire the yml on a mismatch.
      throw ValidationError(
        "upgrade-project-yml-to-pkl: parity check failed for \(ymlURL.lastPathComponent) — "
          + "project.yml kept. Inspect \(pklURL.lastPathComponent) against these fields: "
          + mismatches.joined(separator: ", ") + "."
      )
    case .previewed:
      print(
        "upgrade preview: \(importReceipt.projectName) -> \(pklURL.lastPathComponent) "
          + "(targets=\(importReceipt.targetCount) packages=\(importReceipt.packageCount)); parity matched. "
          + "Re-run with --apply to retire \(ymlURL.lastPathComponent)."
      )
    case .upgraded(let retireYml):
      if retireYml {
        try FileManager.default.removeItem(at: ymlURL)
      }
      print(
        "upgraded: \(importReceipt.projectName) is now a project.pkl project "
          + "(\(pklURL.lastPathComponent)); retired \(ymlURL.lastPathComponent)."
      )
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

  private func generateXcodeProject() async throws {
    guard let pklPath, !pklPath.isEmpty else {
      throw ValidationError("--pkl-path is required for generate-xcodeproj mode.")
    }
    guard let generatedOutputPath, !generatedOutputPath.isEmpty else {
      throw ValidationError("--output-path is required for generate-xcodeproj mode.")
    }

    let requestId = "vaporize-generate-xcodeproj-\(UUID().uuidString)"
    let receipt = try await AppleProjectXcodeProjectGenerator.generate(
      pklURL: URL(fileURLWithPath: pklPath),
      outputURL: URL(fileURLWithPath: generatedOutputPath),
      requestId: requestId
    )
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      print(
        "project.pkl -> xcodeproj: \(receipt.projectName) targets=\(receipt.targetCount) sources=\(receipt.sourceFileCount) resources=\(receipt.resourceFileCount) bytes=\(receipt.generatedByteCount)"
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

  private func listTargets() async throws {
    let requestId = "vaporize-list-targets-\(UUID().uuidString)"
    let productCacheOptions = AppleProjectProductCacheDiscoveryOptions(
      workspacePath: xcodeProductCacheWorkspace,
      derivedDataPath: xcodeProductCacheDerivedDataPath,
      configurationName: configuration.rawValue.capitalized
    )
    let receipt: AppleProjectTargetDiscoveryReceipt
    if let pklPath, !pklPath.isEmpty {
      receipt = try await AppleProjectTargetDiscovery.discover(
        pklURL: URL(fileURLWithPath: pklPath),
        requestId: requestId,
        productCacheOptions: productCacheOptions
      )
    } else if let vaporScanPath, !vaporScanPath.isEmpty {
      receipt = try await AppleProjectTargetDiscovery.discover(
        path: vaporScanPath,
        requestId: requestId,
        productCacheOptions: productCacheOptions
      )
    } else if let packagePath, !packagePath.isEmpty {
      receipt = try await AppleProjectTargetDiscovery.discover(
        projectDirectoryURL: URL(fileURLWithPath: packagePath),
        requestId: requestId,
        productCacheOptions: productCacheOptions
      )
    } else {
      throw ValidationError("--path, --pkl-path, or --package-path is required for list-targets mode.")
    }
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      print(
        "targets: \(receipt.projectName) input=\(receipt.inputKind) targets=\(receipt.targetCount) buildable=\(receipt.buildableTargetNames.count) schemes=\(receipt.schemeCount) packages=\(receipt.packageCount)"
      )
      for target in receipt.targets {
        let buildable = target.isBuildableCandidate ? " buildable" : ""
        print("- \(target.name): type=\(target.type ?? "<nil>") platform=\(target.platform ?? "<nil>") product=\(target.productName)\(buildable)")
      }
      if receipt.productCacheCandidateCount > 0 {
        print(
          "product-cache: candidates=\(receipt.productCacheCandidateCount) warm=\(receipt.warmProductCacheCandidateCount) configuration=\(receipt.productCacheConfigurationName ?? "<nil>")"
        )
        for candidate in receipt.productCacheCandidates {
          print("- cache \(candidate.status): \(candidate.targetName) -> \(candidate.appBundlePath)")
        }
      }
      print(receipt.boundaries[0])
    case .json:
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(receipt)
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }
  }

  private func listSchemes() async throws {
    guard let xcodeWorkspace, !xcodeWorkspace.isEmpty else {
      throw ValidationError("--xcode-workspace is required for list-schemes mode.")
    }

    let request = try XcodeWorkspaceSchemeListRequest(workspacePath: xcodeWorkspace)
    let requestId = "vaporize-list-schemes-\(UUID().uuidString)"
    let workingDirectory = passWorkingDirectory ?? FileManager.default.currentDirectoryPath
    let environmentUpdates = developerDirectory.map { ["DEVELOPER_DIR": $0] }
    let command = CommandSpec(
      executable: .name("xcodebuild"),
      args: request.xcodebuildArguments,
      env: .inherit(updating: environmentUpdates),
      workingDirectory: workingDirectory,
      logOptions: .init(
        exposure: .none,
        tags: [
          "source": "vaporize-list-schemes",
          "canonicalSource": "vaporize-list-schemes",
          "tool": "xcodebuild",
        ]
      ),
      requestId: requestId,
      runnerKind: .auto,
      streamingMode: .buffered
    )
    try command.validateOrThrow()

    let output = try await RunnerControllerFactory.run(command: command)
    guard output.isSuccess else {
      let receipt = XcodeWorkspaceSchemeListReceipt(
        workspacePath: request.standardizedWorkspacePath,
        workspaceName: nil,
        schemes: [],
        xcodebuildArguments: request.xcodebuildArguments,
        workingDirectory: workingDirectory,
        requestId: requestId,
        runnerKind: "auto",
        developerDirectorySet: developerDirectory != nil,
        succeeded: false,
        exitCode: output.exitStatus.exitCode,
        signal: output.exitStatus.signal,
        stdoutBytes: output.stdout.count,
        stderrBytes: output.stderr.count,
        processIdentifier: output.processIdentifier
      )
      try emitReceiptIfRequested(receipt)
      FileHandle.standardError.write(output.stderr)
      if let exitCode = output.exitStatus.exitCode {
        throw ExitCode(Int32(exitCode))
      }
      throw ExitCode.failure
    }

    let parsed = try XcodeWorkspaceSchemeListParser.parse(data: output.stdout)
    let receipt = XcodeWorkspaceSchemeListReceipt(
      workspacePath: request.standardizedWorkspacePath,
      workspaceName: parsed.workspaceName,
      schemes: parsed.schemes,
      xcodebuildArguments: request.xcodebuildArguments,
      workingDirectory: workingDirectory,
      requestId: requestId,
      runnerKind: "auto",
      developerDirectorySet: developerDirectory != nil,
      succeeded: true,
      exitCode: output.exitStatus.exitCode,
      signal: output.exitStatus.signal,
      stdoutBytes: output.stdout.count,
      stderrBytes: output.stderr.count,
      processIdentifier: output.processIdentifier
    )
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      print("workspace schemes: \(receipt.workspaceName ?? "<unknown>") schemes=\(receipt.schemeCount)")
      for scheme in receipt.schemes {
        print("- \(scheme)")
      }
      print(receipt.boundaries[0])
    case .json:
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(receipt)
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }
  }

  private func releaseDoctor() async throws {
    let inspectedPath = vaporScanPath ?? FileManager.default.currentDirectoryPath
    let requestId = "vaporize-release-doctor-\(UUID().uuidString)"
    let receipt = try VaporizeReleaseDoctor.inspect(
      path: inspectedPath,
      requestId: requestId
    )
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      print(
        "release doctor: \(receipt.subjectAppSlug) \(receipt.subjectReleaseSlug) status=\(receipt.overallStatus) checks=\(receipt.passedCheckCount)/\(receipt.checkCount)"
      )
      for check in receipt.checks where check.status != "pass" {
        print("\(check.status): \(check.name) - \(check.detail)")
      }
    case .json:
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(receipt)
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }

    guard receipt.overallStatus == "pass" else {
      throw ValidationError("release doctor failed with \(receipt.failedCheckCount) failing checks.")
    }
  }

  private func resolvedAppleProjectSpecSchemaURL() throws -> URL {
    let fileManager = FileManager.default

    if let pklSchemaPath, !pklSchemaPath.isEmpty {
      let url = URL(fileURLWithPath: pklSchemaPath).standardizedFileURL
      guard fileManager.fileExists(atPath: url.path) else {
        throw ValidationError("--pkl-schema-path does not exist: \(pklSchemaPath)")
      }
      return url
    }

    var candidates: [URL] = []
    if let packagePath, !packagePath.isEmpty {
      candidates.append(
        URL(fileURLWithPath: packagePath)
          .appendingPathComponent("Pkl/AppleProjectSpec.pkl")
          .standardizedFileURL
      )
    }

    candidates.append(
      URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Pkl/AppleProjectSpec.pkl")
        .standardizedFileURL
    )

    let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    candidates.append(currentDirectory.appendingPathComponent("Pkl/AppleProjectSpec.pkl").standardizedFileURL)

    for candidate in candidates where fileManager.fileExists(atPath: candidate.path) {
      return candidate
    }

    throw ValidationError(
      "--pkl-schema-path is required for import-project-yml mode when Vaporize cannot locate Pkl/AppleProjectSpec.pkl."
    )
  }

  private func relativePath(from baseDirectory: URL, to target: URL) -> String {
    let baseComponents = baseDirectory.standardizedFileURL.pathComponents
    let targetComponents = target.standardizedFileURL.pathComponents

    var commonPrefixCount = 0
    while commonPrefixCount < baseComponents.count,
      commonPrefixCount < targetComponents.count,
      baseComponents[commonPrefixCount] == targetComponents[commonPrefixCount]
    {
      commonPrefixCount += 1
    }

    guard commonPrefixCount > 0 else {
      return target.standardizedFileURL.path
    }

    let up = Array(repeating: "..", count: baseComponents.count - commonPrefixCount)
    let down = Array(targetComponents.dropFirst(commonPrefixCount))
    let components = up + down
    return components.isEmpty ? "." : components.joined(separator: "/")
  }

  private struct ToolManifestRecord: Decodable {
    let domain: String?
  }

  private struct DomainsPayload: Encodable {
    let collectionPath: String
    let domains: [String]
    let count: Int
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
    try await validateXcodeSelectedSwiftCompatibility(arguments: arguments)
    try await runExecutable(
      executable: .name("xcrun"),
      arguments: Self.xcodeSelectedSwiftArguments(arguments),
      sourceTag: "vaporize-swift",
      environment: developerDirectoryEnvironment()
    )
  }

  private func runSwiftPackage(arguments: [String]) async throws {
    try await validateXcodeSelectedSwiftCompatibility(arguments: arguments)
    try await runExecutable(
      executable: .name("xcrun"),
      arguments: Self.xcodeSelectedSwiftArguments(arguments),
      sourceTag: "vaporize-swift-package",
      environment: developerDirectoryEnvironment()
    )
  }

  static func xcodeSelectedSwiftArguments(_ arguments: [String]) -> [String] {
    ["swift"] + arguments
  }

  private func validateXcodeSelectedSwiftCompatibility(arguments: [String]) async throws {
    guard let packagePath = Self.swiftPackagePath(in: arguments),
      let requiredVersion = try Self.swiftToolsVersion(packagePath: packagePath)
    else { return }

    let command = CommandSpec(
      executable: .name("xcrun"),
      args: Self.xcodeSelectedSwiftArguments(["--version"]),
      env: .inherit(updating: developerDirectoryEnvironment()),
      logOptions: .init(
        exposure: .none,
        tags: [
          "source": "vaporize-swift-toolchain-preflight",
          "canonicalSource": "vaporize-swift-toolchain-preflight",
          "tool": "swift",
        ]
      ),
      requestId: "vaporize-swift-toolchain-preflight-\(UUID().uuidString)",
      runnerKind: .auto,
      streamingMode: .buffered
    )
    try command.validateOrThrow()

    let output = try await RunnerControllerFactory.run(command: command)
    let versionOutput = (String(data: output.stdout, encoding: .utf8) ?? "")
      + (String(data: output.stderr, encoding: .utf8) ?? "")
    guard output.isSuccess else {
      throw ValidationError("Vaporize could not resolve Xcode-selected Swift via `xcrun swift --version`: \(versionOutput)")
    }
    guard let actualVersion = Self.swiftCompilerVersion(from: versionOutput) else {
      throw ValidationError("Vaporize could not parse Xcode-selected Swift version from: \(versionOutput)")
    }
    guard actualVersion >= requiredVersion else {
      throw ValidationError(
        "Vaporize resolved Swift \(actualVersion), but package at \(packagePath) requires Swift tools \(requiredVersion). Select a Swift \(requiredVersion) or newer Xcode toolchain before running Vaporize."
      )
    }
  }

  static func swiftPackagePath(in arguments: [String]) -> String? {
    for index in arguments.indices where arguments[index] == "--package-path" {
      let next = arguments.index(after: index)
      guard next < arguments.endIndex else { return nil }
      return arguments[next]
    }
    return nil
  }

  static func swiftToolsVersion(packagePath: String) throws -> SwiftToolchainVersion? {
    let manifest = URL(fileURLWithPath: packagePath)
      .appendingPathComponent("Package.swift")
    guard FileManager.default.fileExists(atPath: manifest.path) else { return nil }
    let text = try String(contentsOf: manifest, encoding: .utf8)
    return swiftToolsVersion(fromPackageManifest: text)
  }

  static func swiftToolsVersion(fromPackageManifest text: String) -> SwiftToolchainVersion? {
    guard let markerRange = text.range(of: "swift-tools-version:") else { return nil }
    let tail = text[markerRange.upperBound...].trimmingCharacters(in: .whitespaces)
    let version = tail.prefix { character in
      character.isNumber || character == "."
    }
    return SwiftToolchainVersion(String(version))
  }

  static func swiftCompilerVersion(from versionOutput: String) -> SwiftToolchainVersion? {
    guard let markerRange = versionOutput.range(of: "Swift version ") else { return nil }
    let tail = versionOutput[markerRange.upperBound...].trimmingCharacters(in: .whitespaces)
    let version = tail.prefix { character in
      character.isNumber || character == "."
    }
    return SwiftToolchainVersion(String(version))
  }

  private func runExecutable(
    executable: Executable,
    arguments: [String],
    sourceTag: String,
    environment: [String: String]? = nil
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
      environment: environment,
      runnerKind: .auto
    )
    guard !output.isEmpty else { return }
    print(output, terminator: output.hasSuffix("\n") ? "" : "\n")
  }
}

struct SwiftToolchainVersion: Comparable, CustomStringConvertible, Equatable, Sendable {
  var major: Int
  var minor: Int
  var patch: Int

  init?(_ rawValue: String) {
    let parts = rawValue
      .split(separator: ".", omittingEmptySubsequences: false)
      .prefix(3)
      .map(String.init)
    guard parts.count >= 2,
      let major = Int(parts[0]),
      let minor = Int(parts[1])
    else { return nil }
    self.major = major
    self.minor = minor
    self.patch = parts.count >= 3 ? (Int(parts[2]) ?? 0) : 0
  }

  var description: String {
    patch == 0 ? "\(major).\(minor)" : "\(major).\(minor).\(patch)"
  }

  static func < (lhs: SwiftToolchainVersion, rhs: SwiftToolchainVersion) -> Bool {
    if lhs.major != rhs.major { return lhs.major < rhs.major }
    if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
    return lhs.patch < rhs.patch
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

enum SwiftToolchainTool: String, Codable, Equatable {
  case swift
  case docc
}

struct SwiftToolchainRequest: Equatable {
  var tool: SwiftToolchainTool
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
      throw ValidationError("toolchain mode requires a Swift toolchain tool, for example: vaporize toolchain -- swift --version.")
    }
    guard let tool = SwiftToolchainTool(rawValue: rawTool) else {
      throw ValidationError("toolchain mode currently supports swift and docc; got \(rawTool).")
    }
    tokens.removeFirst()
    if tokens.first == "--" {
      tokens.removeFirst()
    }
    self.tool = tool
    self.arguments = tokens
  }

  func invocation(
    environment: ToolchainResolutionEnvironment = .current()
  ) throws -> ToolchainInvocation {
    if tool == .docc, let swiftToolchainDocCPath = environment.swiftToolchainDocCPath {
      return ToolchainInvocation(
        executable: .path(swiftToolchainDocCPath),
        arguments: arguments,
        executableRef: "path:\(swiftToolchainDocCPath)",
        resolver: "swift-toolchain"
      )
    }

    if environment.platform == .macOS {
      return ToolchainInvocation(
        executable: .name("xcrun"),
        arguments: xcrunArguments,
        executableRef: "name:xcrun",
        resolver: "xcrun"
      )
    }

    return ToolchainInvocation(
      executable: .name(tool.rawValue),
      arguments: arguments,
      executableRef: "name:\(tool.rawValue)",
      resolver: "path"
    )
  }
}

struct ToolchainResolutionEnvironment: Equatable {
  enum Platform: Equatable {
    case macOS
    case other
  }

  var platform: Platform
  var swiftToolchainDocCPath: String?

  static func current(
    fileManager: FileManager = .default,
    environment: [String: String] = ProcessInfo.processInfo.environment
  ) -> ToolchainResolutionEnvironment {
    let homeDirectory = environment["HOME"] ?? NSHomeDirectory()
    let knownSwiftToolchainDocCPath = URL(fileURLWithPath: homeDirectory)
      .appendingPathComponent(".swiftly/bin/docc")
      .path

    #if os(macOS)
      let platform = Platform.macOS
    #else
      let platform = Platform.other
    #endif

    return ToolchainResolutionEnvironment(
      platform: platform,
      swiftToolchainDocCPath: fileManager.isExecutableFile(atPath: knownSwiftToolchainDocCPath)
        ? knownSwiftToolchainDocCPath
        : nil
    )
  }
}

struct ToolchainInvocation {
  var executable: Executable
  var arguments: [String]
  var executableRef: String
  var resolver: String
}

enum VaporizeCLIActionability {
  static let policyRef = "private/universal/substrate/collectives/spaces-universal/private/universal/kura-spaces/policies/cli-error-actionability/v0.1.0/cli-error-actionability.policy.su.json"
  static let procedureRef = "private/universal/substrate/collectives/spaces-universal/private/universal/kura-spaces/operating-protocols/cli-error-actionability/v0.1.0/cli-error-actionability.operating-protocol.su.json"
  static let digikomaRef = "private/universal/substrate/collectives/spaces-universal/private/universal/kura-spaces/digikoma/specs/digikoma-cli-error-triage.spec.json"
  static let digikomaPackagePath = "private/universal/substrate/collectives/kura-org/private/universal/domain/tooling/digikoma/cli-error-triage.digikoma.clia"

  static func productValidationMessage(errorDescription: String, product: String) -> String {
    """
    vaporize product validation failed.
    error: \(errorDescription)
    reason: --product must use the canonical Swift CLI product shape \(SwiftCLIProductName.canonicalShape).
    policy: \(policyRef)
    procedure: \(procedureRef)
    digikoma: \(digikomaRef)
    digikoma-command: \(productValidationDigikomaCommand(product: product))
    next:
      1. Replace --product with a canonical product like <tool>.cli@<collective>.clia.sh.
      2. Rerun the original vaporize command with the corrected --product value.
      3. If the product name is generated by a manifest or tool record, repair that source record before retrying.
      4. If still blocked, capture the full error text and run the digikoma-command above.
    """
  }

  static func schemaValidationMessage(
    errorDescription: String,
    schemaPath: String,
    fixturePath: String,
    expected: String?,
    actual: String,
    diagnostics: [String]
  ) -> String {
    let expectation = expected ?? "none declared"
    let diagnosticLines =
      diagnostics.isEmpty
      ? "  (none)"
      : diagnostics.map { "  - \($0)" }.joined(separator: "\n")
    let rerunExpectSuffix = expected.map { " --expect \($0)" } ?? ""
    return """
      vaporize JSON Schema validation failed.
      error: \(errorDescription)
      schema: \(schemaPath)
      fixture: \(fixturePath)
      expected: \(expectation)
      actual: \(actual)
      diagnostics:
      \(diagnosticLines)
      policy: \(policyRef)
      procedure: \(procedureRef)
      digikoma: \(digikomaRef)
      digikoma-command: \(schemaValidationDigikomaCommand(schemaPath: schemaPath, fixturePath: fixturePath, expected: expected))
      next:
        1. Inspect each diagnostic's instance path in the fixture and fix the fixture, the schema, or the declared --expect value.
        2. If a diagnostic names an unresolvable or remote $ref, repair the schema's $ref target; remote http(s) refs are unsupported by design.
        3. Rerun: vaporize.cli@wrkstrm-core.clia.sh validate-json-schema --schema \(schemaPath) --fixture \(fixturePath)\(rerunExpectSuffix)
        4. If still blocked, capture the full error text and bring it to Digikoma by running the digikoma-command above.
      """
  }

  private static func schemaValidationDigikomaCommand(
    schemaPath: String,
    fixturePath: String,
    expected: String?
  ) -> String {
    let expectSuffix = expected.map { " --expect \($0)" } ?? ""
    let originalCommand = shellSingleQuoted(
      "vaporize.cli@wrkstrm-core.clia.sh validate-json-schema --schema \(schemaPath) --fixture \(fixturePath)\(expectSuffix)"
    )
    return "vaporize.cli@wrkstrm-core.clia.sh run --package-path \(digikomaPackagePath) --product cli-error-triage.digikoma@kura-org.clia.sh --configuration debug -- --error-file <path-to-full-error.txt> --command \(originalCommand) --working-directory <repo-root>"
  }

  private static func productValidationDigikomaCommand(product: String) -> String {
    let originalCommand = shellSingleQuoted(
      "vaporize.cli@wrkstrm-core.clia.sh run --product \(product)"
    )
    return "vaporize.cli@wrkstrm-core.clia.sh run --package-path \(digikomaPackagePath) --product cli-error-triage.digikoma@kura-org.clia.sh --configuration debug -- --error-file <path-to-full-error.txt> --command \(originalCommand) --working-directory <repo-root>"
  }

  private static func shellSingleQuoted(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "'\"'\"'"))'"
  }
}

enum JSONValidation {
  static func validate(data: Data, path: String, requestId: String) throws -> JSONValidationReceipt {
    _ = try SwiftJSONFormatter.parseJSONObject(from: data)
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
  var executableRef: String
  var resolver: String
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

struct JSONSchemaValidationReceipt: Codable, Equatable {
  var schemaVersion = "0.1.0"
  var receiptKind = "vaporize-json-schema-validation"
  var schemaPath: String
  var fixturePath: String
  var requestId: String
  /// Declared expectation from --expect (pass or fail), when provided.
  var expected: String?
  /// Actual engine outcome: "pass" or "fail".
  var actual: String
  /// Whether actual matched the declared expectation; nil when no --expect.
  var matched: Bool?
  var diagnostics: [String]
  var nextSteps: [String]
}
