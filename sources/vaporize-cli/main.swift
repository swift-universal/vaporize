import XcodeProjectDefinitionCore
import ArgumentParser
import BumpBuildTakumiOrgCore
import CommonProcess
import CommonProcessExecutionKit
import CommonShell
import Foundation
import SwiftAppInstaller
import SwiftCLIInstaller
import SwiftJSONFormatter
import TranslateSourceGate
import VaporizeCLICopy_v000_000_001
import VaporizeIssueReporting
import VaporizeJSONSchemaValidation

@main
enum VaporizeExecutable {
  static func main() async {
    await VaporizeCLI.main()
  }
}

struct VaporizeCLI: AsyncParsableCommand {
  /// Hard-coded for Phase 0 - see ``FR-VAPORIZE-VAPORWARE-AWARENESS-make-vaporize-the-substrate-canonical-vaporware-collapse-gate-in-code`` Phase 0 scope.
  /// Phase 1+ will derive this from Package.swift via a build-time plugin.
  static let vaporizeVersion = "0.0.1"
  static let buildIdentifier =
    ProcessInfo.processInfo.environment["VAPORIZE_BUILD_NUMBER"]
    ?? ProcessInfo.processInfo.environment["VAPORIZE_BUILD_ID"]
    ?? "local"
  static let buildSha = ProcessInfo.processInfo.environment["VAPORIZE_BUILD_SHA"]
  static let buildDate = ProcessInfo.processInfo.environment["VAPORIZE_BUILD_DATE"]
  static var reportedBuildMetadata: VaporizeRuntimeBuildMetadata {
    VaporizeBuildMetadataResolver.resolve(
      fallbackBuildNumber: buildIdentifier,
      fallbackBuildSHA: buildSha,
      fallbackBuildDate: buildDate
    )
  }
  /// The installed sidecar owns the materialized artifact version. The source
  /// fallback remains useful for an uninstalled development product.
  static var reportedVersion: String {
    reportedBuildMetadata.sidecarVersion ?? vaporizeVersion
  }
  static var reportedBuildIdentifier: String { reportedBuildMetadata.buildNumber }
  #if os(macOS)
    static let platformToolchainSelectionAbstract =
      " On macOS, the independent `toolchain-selection xcode` provider compiles in the xcode-select selection surface."
    static let coreCommandAuthorityDiscussion = """
      Core execution commands on macOS:
        vaporize build swift|xcode [options]
        vaporize test swift|xcode [options] [-- test-options]
        vaporize install swift|xcode [options]
        vaporize run swift|xcode [options] [-- product-arguments]
      The `swift` and `xcode` authorities are adjacent mirrors. `swift` resolves
      the selected Swift from PATH. `xcode` resolves Swift through xcrun and the
      active xcode-select state, with optional process-local --developer-dir.
      When one lane fails, Vaporize prints the exact sibling retry command.
      """
    static let toolchainSelectionDiscussion = """
      \(coreCommandAuthorityDiscussion)

      Toolchain selection structure:
        vaporize toolchain-selection xcode -- select <xcode-select-options>
      Vaporize owns only the macOS Xcode developer-directory selection lane.
      Temper owns Swift toolchain selection and lifecycle.
    """
  #elseif os(Windows)
    static let platformToolchainSelectionAbstract = ""
    static let coreCommandAuthorityDiscussion = """
      Core execution commands on Windows:
        vaporize install|build|run swift-win [options]
        vaporize install|build|run wcode --artifact app [options]
      `swift-win` is limited to raw SwiftPM products defined by Package.swift.
      `wcode` owns Windows application lifecycle work, including any declared
      custom PowerShell phase and app-scoped environment. WCode is not a
      SwiftPM retry lane, so Vaporize does not suggest one authority as the
      other's retry.
      """
    static let toolchainSelectionDiscussion = coreCommandAuthorityDiscussion
  #else
    static let platformToolchainSelectionAbstract = ""
    static let coreCommandAuthorityDiscussion = """
      Core execution commands on this platform are collapsed pure-Swift commands:
        vaporize build [options]
        vaporize test [options] [-- test-options]
        vaporize install [options]
        vaporize run [options] [-- product-arguments]
      No Xcode-assisted mirror or Xcode-only option is compiled into this surface.
      """
    static let toolchainSelectionDiscussion = coreCommandAuthorityDiscussion
  #endif

  static let configuration = CommandConfiguration(
    commandName: "vaporize.cli@wrkstrm-core.clia.sh",
    abstract: vaporizeCopyFill(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeSubstrateCanonicalVaporwareCollapseGateVaporize,
      ["\(platformToolchainSelectionAbstract)"]),
    discussion: toolchainSelectionDiscussion
  )

  enum Mode: String, ExpressibleByArgument, CaseIterable {
    case install
    case uninstall
    case build
    case test
    case run
    case pass
    case use
    #if os(macOS)
      case toolchainSelection = "toolchain-selection"
    #endif
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
    case generateSparkleConfig = "generate-sparkle-config"
    case listTargets = "list-targets"
    case listSchemes = "list-schemes"
    case releaseDoctor = "release-doctor"
    case versionStatus = "version-status"
    case homebrewStatus = "homebrew-status"
    case inventory
    case cujAudit = "cuj-audit"
    case maintainerDependencies = "maintainer-dependencies"

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

    /// Fleet operation: every installed bin-directory tool × sidecar version
    /// × feed currency (the Fleet Yard's data spine).
    case fleetStatus = "fleet-status"
  }

  enum ArtifactKind: String, ExpressibleByArgument {
    case cli
    case tui
    case app

    var isTerminalExecutable: Bool {
      self != .app
    }
  }

  enum ExpectOutcome: String, ExpressibleByArgument {
    case pass
    case fail
  }

  @Argument(
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeModeInstallUninstallBuildTestRun))
  var mode: Mode?

  @Flag(help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizePrintsTheToolNameVersionAnd))
  var version: Bool = false

  @Option(
    name: .customLong("log-level"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeDiagnosticExposureTraceDebugInfoNotice)
  )
  var logLevel: VaporizeLogLevel = .info

  @Option(
    name: .customLong("artifact"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeArtifactKindCliTuiOrApp))
  var artifact: ArtifactKind = .cli

  @Option(
    name: .customLong("package-path"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizePathToTheSwiftPackage))
  var packagePath: String?

  @Option(
    name: .customLong("swiftpm-config-path"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeSwiftpmConfigurationDirectoryWhenOmittedVaporize))
  var swiftPMConfigurationPathOverride: String?

  @Option(name: .customLong("scratch-path"))
  var swiftPMScratchPath: String?

  @Option(
    name: .customLong("product"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeProductNameBinaryOrAppBundle))
  var product: String?

  @Option(
    name: .customLong("product-version"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeVersionRecordedAsCfbundleshortversionstringInThe))
  var productVersion: String?

  @Option(
    name: .customLong("product-build"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeBuildRecordedAsCfbundleversionInThe)
  )
  var productBuild: String?

  @Option(
    name: .customLong("product-build-sha"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeSourceRevisionRecordedInTheInstalled))
  var productBuildSha: String?

  @Option(
    name: .customLong("product-build-date"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeBuildDateRecordedInTheInstalled))
  var productBuildDate: String?

  @Option(
    name: .customLong("su-feed-url"),
    help:
      ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeSparkleAppcastUrlRecordedAsSufeedurl))
  var suFeedURL: String?

  @Option(
    name: .customLong("su-public-ed-key"),
    help:
      ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeBase64Ed25519PublicKeyRecordedAs))
  var suPublicEDKey: String?

  @Option(
    name: .customLong("app-bundle-name"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeBuiltAppBundleNameWhenIt))
  var appBundleName: String?

  @Option(
    name: .customLong("configuration"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeBuildConfiguration))
  var configuration: SwiftAppInstaller.Configuration = .release

  // App-only
  @Option(
    name: .customLong("destination"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeDestinationDirectoryForAppInstallDefault))
  var destination: String = "/Applications"

  @Flag(
    name: .customLong("force"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeReplaceExistingInstall))
  var forceReinstall: Bool = false

  @Flag(
    name: .customLong("skip-build"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeSkipBuildAppModeOnly))
  var skipBuild: Bool = false

  @Flag(
    name: .customLong("skip-install"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeSkipTheDefaultInstallStepFor))
  var skipInstall: Bool = false

  @Flag(
    name: .customLong("launch"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeLaunchAppAfterInstallAppMode))
  var launch: Bool = false

  #if os(Windows)
    @Option(
      name: .customLong("wcode-build-script"),
      help: ArgumentHelp(
        "PowerShell lifecycle phase for a WCode app. It receives WCODE_OPERATION, WCODE_PACKAGE_PATH, WCODE_PRODUCT, WCODE_CONFIGURATION, WCODE_ARTIFACT, WCODE_ARGUMENTS_JSON, and lifecycle flags in its environment."
      )
    )
    var wcodeBuildScript: String?

    @Option(
      name: .customLong("wcode-environment"),
      help: ArgumentHelp(
        "Environment assignment NAME=VALUE applied to a WCode app lifecycle operation. Repeat for each assignment."
      )
    )
    var wcodeEnvironmentAssignments: [String] = []
  #endif

  @Option(
    name: .customLong("xcode-project"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizePathToXcodeprojWhenBuildingWith))
  var xcodeProject: String?

  @Option(
    name: .customLong("xcode-workspace"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizePathToXcworkspaceWhenBuildingWith))
  var xcodeWorkspace: String?

  @Option(
    name: .customLong("scheme"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeSchemeToBuildWithXcodebuildRequires)
  )
  var xcodeScheme: String?

  @Option(
    name: .customLong("target"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeTargetNameForInspectTargetFeatures))
  var targetName: String?

  @Option(
    name: .customLong("derived-data-path"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeDerivedDataPathToUseWith))
  var derivedDataPath: String?

  @Option(
    name: .customLong("xcode-product-cache-workspace"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeSharedXcworkspaceWhoseWarmProductCache))
  var xcodeProductCacheWorkspace: String?

  @Option(
    name: .customLong("xcode-product-cache-derived-data-path"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeDeriveddataRootForXcodeProductCache)
  )
  var xcodeProductCacheDerivedDataPath: String?

  @Option(
    name: .customLong("xcode-destination"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeTypedXcodebuildDestinationRepeatForMultiple))
  var xcodeDestinations: [String] = []

  @Option(
    name: .customLong("xcode-sdk"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeSdkPassedToXcodebuildWithSdk))
  var xcodeSDK: String?

  @Option(
    name: .customLong("xcode-result-bundle-path"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeResultBundlePathPassedToXcodebuild))
  var xcodeResultBundlePath: String?

  @Option(
    name: .customLong("xcode-build-setting"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeBuildSettingPassedToXcodebuildAs))
  var xcodeBuildSettings: [String] = []

  @Flag(name: .customLong("auto-increment-build"))
  var autoIncrementBuild: Bool = false

  @Flag(name: .customLong("allow-dirty-build-number-source"))
  var allowDirtyBuildNumberSource: Bool = false

  @Option(name: .customLong("build-number-receipt-path"))
  var buildNumberReceiptPath: String?

  @Flag(
    name: .customLong("analyze"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeEmitAJsonReceiptForTest))
  var analyzeExecution: Bool = false

  @Option(
    name: .customLong("receipt-path"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeWriteTheTestPassThroughUse))
  var receiptPath: String?

  @Option(
    name: .customLong("report-path"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeWriteTheCujAuditMarkdownReport))
  var reportPath: String?

  @Option(
    name: .customLong("proof-ledger-path"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeWriteTheCanonicalCujAutomatedProof))
  var proofLedgerPath: String?

  @Option(
    name: .customLong("project-ledger-path"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeWriteTheFineGrainedActiveOwned))
  var projectLedgerPath: String?

  @Option(
    name: .customLong("project-ledger-csv-path"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeWriteTheFineGrainedImplementationProject))
  var projectLedgerCSVPath: String?

  @Option(
    name: .customLong("working-directory"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeWorkingDirectoryForPassModeDefaults)
  )
  var passWorkingDirectory: String?

  @Option(
    name: .customLong("common-process-spec"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizePathToACommonprocessCommandspecJson)
  )
  var commonProcessSpecPath: String?

  #if os(macOS)
    @Option(
      name: .customLong("developer-dir"),
      help: ArgumentHelp(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeProcessLocalDeveloperDirOverrideFor))
    var developerDirectory: String?
  #endif

  @Option(
    name: .customLong("xcode-component"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeXcodeComponentToDownloadInSetup))
  var xcodeComponent: String?

  @Option(
    name: .customLong("path"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizePathForStatusWarehouseVersionStatus)
  )
  var vaporScanPath: String?

  @Option(
    name: .customLong("schema"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeJsonSchemaFilePathForValidate))
  var jsonSchemaPath: String?

  @Option(
    name: .customLong("fixture"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeFixtureJsonInstancePathValidatedAgainst))
  var jsonSchemaFixturePath: String?

  @Option(
    name: .customLong("expect"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeExpectedValidateJsonSchemaOutcomePass))
  var jsonSchemaExpectedOutcome: ExpectOutcome?

  @Option(
    name: .customLong("pkl-path"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizePathToAnXcodeProjectDefinitionPklRecord))
  var pklPath: String?

  @Option(
    name: .customLong("pkl-schema-path"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizePathToXcodeProjectDefinitionPklForImport))
  var pklSchemaPath: String?

  @Option(
    name: .customLong("output-path"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeOutputPathForImportProjectYml))
  var generatedOutputPath: String?

  @Option(
    name: .customLong("output"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeOutputPathForTheGeneratedSparkleconfig))
  var sparkleConfigOutputPath: String?

  @Flag(
    name: .customLong("apply"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeForUpgradeProjectYmlToPkl))
  var applyUpgrade: Bool = false

  @Option(
    name: .customLong("format"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeOutputFormatForStatusVersionStatus))
  var vaporOutputFormat: VaporOutputFormatArgument = .text

  @Option(
    name: .customLong("bin-dir"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeInstallBinDirectoryScannedByFleet))
  var fleetBinDirectory: String?

  @Option(
    name: .customLong("homebrew-formula"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeFormulaTokenInspectedByHomebrewStatus)
  )
  var homebrewFormula: String?

  @Option(
    name: .customLong("homebrew-tap-root"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeOwningHomebrewTapRootContainingFormula)
  )
  var homebrewTapRoot: String?

  @Option(
    name: .customLong("domain"),
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeToolDomainForInstallUninstallRun))
  var toolDomain: String?

  @Option(
    name: .customLong("tools-collection"),
    help: ArgumentHelp(
      VaporizeCLICopy_v000_000_001.CLI.vaporizeKuraToolsCollectionDirectoryForDomains))
  var toolsCollectionPath: String?

  @Argument(
    parsing: .remaining,
    help: ArgumentHelp(VaporizeCLICopy_v000_000_001.CLI.vaporizeArgumentsForwardedToTestRunPass))
  var forwardedArguments: [String] = []

  mutating func run() async throws {
    VaporizeLogging.configure(level: logLevel)

    if version {
      printVersionMetadata()
      return
    }

    guard let mode else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeMissingExpectedArgumentModeRunWith
      )
    }

    let coreExecutionPlan = try coreExecutionPlan(for: mode)
    try await enforceI18nSourcePolicy(for: mode)
    try enforceSwiftUIImportPolicy(for: mode)

    if let coreExecutionPlan {
      try await runCoreCommand(mode: mode, plan: coreExecutionPlan)
      return
    }

    switch mode {
    case .uninstall:
      try await uninstallArtifact()
    case .install, .build, .test, .run:
      preconditionFailure("core execution commands return before general dispatch")
    case .pass:
      try await passThrough()
    case .use:
      try await useCommonProcessSpec()
    #if os(macOS)
      case .toolchainSelection:
        try await runToolchainSelection()
    #endif
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
    case .generateSparkleConfig:
      try await generateSparkleConfig()
    case .listTargets:
      try await listTargets()
    case .listSchemes:
      try await listSchemes()
    case .releaseDoctor:
      try await releaseDoctor()
    case .versionStatus:
      try await runSourceVersionStatus()
    case .homebrewStatus:
      try await runHomebrewStatus()
    case .inventory:
      try await runOwnedSurfaceInventory()
    case .cujAudit:
      try await runCUJPortfolioAudit()
    case .maintainerDependencies:
      try await prepareMaintainerDependencies()
    case .domains:
      try await runDomains()
    case .selfUpdate:
      if product != nil {
        try await selfUpdate()
      } else {
        try await withMaintainerDependencyAuthority(
          packagePath: try requireSelfUpdatePackagePath()
        ) {
          try await selfUpdate()
        }
      }
    case .fleetStatus:
      try await fleetStatus()
    case .graph:
      try await runGraph()
    case .cli:
      try await withMaintainerDependencyAuthority(packagePath: try requirePackagePath()) {
        try await installCLI()
      }
    case .app:
      try await withMaintainerDependencyAuthority(packagePath: try requirePackagePath()) {
        try await installApp(launchApp: launch, buildIdentity: nil)
      }
    }
  }

  private func runCoreCommand(
    mode: Mode,
    plan: VaporizeCoreExecutionPlan
  ) async throws {
    let recorder = VaporizeCoreExecutionRecorder(plan: plan)
    VaporizeLogging.command.info(
      "operation=\(plan.operation.rawValue) authority=\(plan.executionAuthority.rawValue) resolver=\(plan.toolchainResolver) state=begin"
    )
    try await VaporizeCoreExecutionInstrumentation.$current.withValue(recorder) {
      do {
        try await recorder.measure(.coreCommand) {
          do {
            try validateArtifactAuthority(plan)
            let buildIdentity = try await prepareAppBuildNumberIdentity(for: mode)
            switch mode {
            case .install:
              try await withMaintainerDependencyAuthority(packagePath: try requirePackagePath()) {
                try await installArtifact(launchApp: launch, buildIdentity: buildIdentity)
              }
            case .build:
              try await withMaintainerDependencyAuthority(packagePath: try requirePackagePath()) {
                try await buildArtifact(buildIdentity: buildIdentity)
              }
            case .test:
              if artifact == .app {
                try await testArtifact()
              } else {
                try await withMaintainerDependencyAuthority(packagePath: try requirePackagePath()) {
                  try await testArtifact()
                }
              }
            case .run:
              if skipInstall {
                try await runArtifact(buildIdentity: buildIdentity)
              } else {
                try await withMaintainerDependencyAuthority(packagePath: try requirePackagePath()) {
                  try await runArtifact(buildIdentity: buildIdentity)
                }
              }
            default:
              preconditionFailure("non-core mode reached core command dispatch")
            }
            if let buildIdentity {
              try writeBuildNumberReceipt(buildIdentity.receipt)
            }
          } catch {
            if let alternate = plan.alternateCommand(invocation: CommandLine.arguments) {
              VaporizeLogging.command.warning(
                "adjacent-authority-retry command=\(VaporizeLogging.redacted(alternate))"
              )
            }
            VaporizeLogging.command.error(
              "operation=\(plan.operation.rawValue) state=failed error=\(VaporizeLogging.redacted(String(describing: error)))"
            )
            throw error
          }
        }
      } catch {
        try? await emitCoreExecutionReceipt(
          from: recorder,
          succeeded: false,
          failureDescription: String(describing: error)
        )
        try emitRetainedTestReceipt(from: recorder)
        throw error
      }
      try emitRetainedTestReceipt(from: recorder)
      try await emitCoreExecutionReceipt(from: recorder, succeeded: true, failureDescription: nil)
    }
    VaporizeLogging.command.info(
      "operation=\(plan.operation.rawValue) authority=\(plan.executionAuthority.rawValue) state=end"
    )
  }

  private func emitRetainedTestReceipt(
    from recorder: VaporizeCoreExecutionRecorder
  ) throws {
    guard let receipt = recorder.takeFinalizedTestReceipt() else { return }
    try emitReceiptIfRequested(receipt)
  }

  private func emitCoreExecutionReceipt(
    from recorder: VaporizeCoreExecutionRecorder,
    succeeded: Bool,
    failureDescription: String?
  ) async throws {
    // Tests retain their richer dedicated receipt. Build/install/run receive
    // the shared timing record requested through --analyze or --receipt-path.
    guard recorder.operation != .test else { return }
    let packagePath = try requirePackagePath()
    let product = product?.trimmingCharacters(in: .whitespacesAndNewlines)
    let artifactPath: String?
    switch artifact {
    case .cli, .tui:
      if usesIsolatedSwiftPMWorkspace, let product {
        artifactPath = sourceBuiltCLIExecutablePath(product: product)
      } else {
        artifactPath = product.map { installedCLIPath(product: $0) }
      }
    case .app:
      #if os(Windows)
        if recorder.authority == .wcode {
          // A WCode lifecycle phase may package or install to a project-specific
          // location. Do not claim an Apple .app destination in the receipt.
          artifactPath = nil
          break
        }
      #endif
      if let product {
        // SwiftAppInstaller may locate a debug-named build bundle, but it
        // installs it under the product name. The receipt must name the
        // installed runtime, never the intermediate build artifact.
        artifactPath = vaporizeInstalledAppPath(destination: destination, product: product)
      } else {
        artifactPath = nil
      }
    }
    try emitReceiptIfRequested(
      recorder.receipt(
        packagePath: packagePath,
        product: product,
        configuration: configuration.rawValue,
        succeeded: succeeded,
        artifactPath: artifactPath,
        failureDescription: failureDescription
      )
    )
  }

  func coreExecutionPlan(for mode: Mode) throws -> VaporizeCoreExecutionPlan? {
    let operation: VaporizeCoreOperation
    switch mode {
    case .install: operation = .install
    case .build: operation = .build
    case .test: operation = .test
    case .run: operation = .run
    default: return nil
    }

    let plan = try VaporizeCoreExecutionPlan.resolve(
      operation: operation,
      arguments: forwardedArguments
    )
    #if os(macOS)
      if resolvedDeveloperDirectory != nil, plan.executionAuthority != .xcode {
        throw ValidationError(
          vaporizeCopyFill(
            VaporizeCLICopy_v000_000_001.CLI.vaporizeDeveloperDirBelongsToTheA1,
            ["\(operation.rawValue)"])
        )
      }
    #endif
    return plan
  }

  private func validateArtifactAuthority(_ plan: VaporizeCoreExecutionPlan) throws {
    #if os(macOS)
      guard artifact == .app, plan.executionAuthority != .xcode else { return }
      throw ValidationError(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeAppArtifactsRequireTheXcode,
          ["\(plan.operation.rawValue)"])
      )
    #elseif os(Windows)
      if let guidance = Self.windowsArtifactAuthorityGuidance(
        operation: plan.operation,
        authority: plan.executionAuthority,
        artifact: artifact
      ) {
        throw ValidationError(guidance)
      }
    #else
      guard artifact == .app else { return }
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeAppArtifactsRequireXcodeAnd
      )
    #endif
  }

  #if os(Windows)
    static func windowsArtifactAuthorityGuidance(
      operation: VaporizeCoreOperation,
      authority: VaporizeCoreExecutionAuthority,
      artifact: ArtifactKind
    ) -> String? {
      switch (artifact, authority) {
      case (.cli, .wcode), (.tui, .wcode):
        return """
          wcode only owns Windows app artifacts; it cannot \(operation.rawValue) a \(artifact.rawValue).
          next: use `vaporize \(operation.rawValue) swift-win --artifact \(artifact.rawValue) --package-path <package> --product <product>` for a raw Package.swift product.
          """
      case (.app, .swiftWin):
        return """
          swift-win cannot \(operation.rawValue) an app artifact; swift-win is limited to raw Package.swift products.
          next: use `vaporize \(operation.rawValue) wcode --artifact app --package-path <package> --product <app-product> --configuration <debug|release>`.
          For app-specific tooling, pass `--wcode-build-script <script.ps1>`; it receives the requested WCode lifecycle operation.
          """
      case (.app, .wcode) where operation == .test:
        return """
          WCode owns Windows app build, install, and run lifecycle operations; app testing has no WCode contract yet.
          next: use `vaporize build wcode`, `vaporize install wcode`, or `vaporize run wcode` with `--artifact app` as appropriate.
          """
      default:
        return nil
      }
    }
  #endif

  /// Resolves and advances the one declared app build-number source before an
  /// Xcode build starts. The changed Pkl value, the Xcode override, and later
  /// bundle verification all use the same number.
  func prepareAppBuildNumberIdentity(for mode: Mode) async throws
    -> AppBuildNumberIdentity?
  {
    #if os(Windows)
      guard !autoIncrementBuild else {
        throw ValidationError(
          "--auto-increment-build belongs to the Xcode app lifecycle and is not available to WCode."
        )
      }
      return nil
    #else
    guard autoIncrementBuild else { return nil }
    guard artifact == .app else {
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizeAutoIncrementBuildRequiresArtifactApp)
    }
    guard !skipBuild else {
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizeAutoIncrementBuildCannotRunWithSkipBuild)
    }
    guard mode != .run || !skipInstall else {
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizeAutoIncrementBuildCannotRunWithRunSkipInstall)
    }
    let packagePath = try requirePackagePath()
    let product = try requireProduct()
    guard let pklPath, !pklPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizeAutoIncrementBuildRequiresPklPath)
    }

    let dirty = try await sourceWorktreeIsDirty(packagePath: packagePath)
    guard !dirty || allowDirtyBuildNumberSource else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeAutoIncrementBuildRequiresCleanSourceWorktree
      )
    }

    let stamped = try PklBuildVersionStamper.stamp(pklURL: absoluteURL(for: pklPath))
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let receipt = VaporizeBuildNumberReceipt(
      kind: "vaporize-app-build-number-receipt",
      schemaVersion: "0.0.1",
      capturedAt: timestamp,
      operation: mode.rawValue,
      product: product,
      configuration: configuration.rawValue,
      bundleMarketingVersion: stamped.marketingVersion,
      previousBuildNumber: stamped.previousBuild,
      nextBuildNumber: stamped.newBuild,
      sourceCarrierPath: stamped.sourcePath,
      sourceCarrierKind: "pkl-current-project-version",
      xcodeBuildSetting: "CURRENT_PROJECT_VERSION=\(stamped.newBuild)",
      dirtyWorktreePolicy: dirty ? "explicitly-allowed" : "clean",
      evidenceBoundary: "Source Pkl was advanced before build. SwiftAppInstaller verifies the expected marketing/build pair in the built and installed app bundles; this receipt is not release approval."
    )
    return AppBuildNumberIdentity(
      marketingVersion: stamped.marketingVersion,
      buildNumber: stamped.newBuild,
      sourceCarrierPath: stamped.sourcePath,
      receipt: receipt
    )
    #endif
  }

  private func sourceWorktreeIsDirty(packagePath: String) async throws -> Bool {
    var shell = CommonShell()
    shell.logOptions = .init(
      exposure: .none,
      tags: ["source": "vaporize-build-number", "action": "worktree-status"]
    )
    let output = try await measureCoreProcess {
      try await shell.run(
        host: .direct,
        executable: .name("git"),
        arguments: ["-C", packagePath, "status", "--porcelain"],
        runnerKind: .auto
      )
    }
    return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func writeBuildNumberReceipt(_ receipt: VaporizeBuildNumberReceipt) throws {
    let receiptURL: URL
    if let buildNumberReceiptPath, !buildNumberReceiptPath.isEmpty {
      receiptURL = absoluteURL(for: buildNumberReceiptPath)
    } else {
      let packagePath = try requirePackagePath()
      let safeProduct = receipt.product.replacingOccurrences(of: "/", with: "-")
      receiptURL = absoluteURL(for: packagePath)
        .appendingPathComponent(".build/vaporize/build-number-receipts/\(safeProduct).su.json")
    }
    try FileManager.default.createDirectory(
      at: receiptURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(receipt).write(to: receiptURL, options: .atomic)
  }

  private var resolvedDeveloperDirectory: String? {
    #if os(macOS)
      developerDirectory
    #else
      nil
    #endif
  }

  func selectedSwiftToolchainSource() throws -> SwiftCLIInstaller.SwiftToolchainSource {
    guard let mode, let plan = try coreExecutionPlan(for: mode) else {
      return .defaultSwift
    }
    switch plan.executionAuthority {
    case .swift:
      return .defaultSwift
    #if os(macOS)
      case .xcode:
        return .xcode
    #endif
    #if os(Windows)
      case .swiftWin, .wcode:
        return .defaultSwift
    #endif
    }
  }

  func coreForwardedArguments() throws -> [String] {
    guard let mode, let plan = try coreExecutionPlan(for: mode) else {
      return forwardedArguments
    }
    return plan.forwardedArguments
  }

  /// Fail closed before any canonical build/install/test/run dispatch reaches
  /// SwiftPM or Xcode. Both build systems consume the same i18n-owned AST gate.
  private func enforceI18nSourcePolicy(for mode: Mode) async throws {
    let selectedArtifact: ArtifactKind
    let selectedPackagePath: String
    let selectedProduct: String

    switch mode {
    case .install, .build, .run:
      selectedArtifact = artifact
      selectedPackagePath = try requirePackagePath()
      selectedProduct =
        artifact.isTerminalExecutable ? try requireCLIProduct() : try requireProduct()
    case .test:
      // A SwiftPM test run may exercise a library-only schema package. It has
      // no installable CLI product, so there is no product source gate to run.
      // When a product is supplied, retain the normal executable gate.
      guard product?.isEmpty == false else { return }
      selectedArtifact = artifact
      selectedPackagePath = try requirePackagePath()
      selectedProduct =
        artifact.isTerminalExecutable ? try requireCLIProduct() : try requireProduct()
    case .cli:
      selectedArtifact = .cli
      selectedPackagePath = try requirePackagePath()
      selectedProduct = try requireCLIProduct()
    case .app:
      selectedArtifact = .app
      selectedPackagePath = try requirePackagePath()
      selectedProduct = try requireProduct()
    case .selfUpdate:
      // With --product, self-update swaps an already-published signed binary
      // for ANOTHER tool from its appcast — no source is built here, so the
      // source-level i18n gate has nothing to inspect.
      if product != nil { return }
      selectedArtifact = .cli
      selectedPackagePath = try requireSelfUpdatePackagePath()
      selectedProduct = "vaporize.cli@wrkstrm-core.clia.sh"
    default:
      return
    }

    let gateEnforcement: TranslateSourceGateEnforcement =
      configuration.rawValue.lowercased() == "release" ? .release : .development
    let selectedSurfaceKind: TranslateSourceSurfaceKind
    switch selectedArtifact {
    case .app: selectedSurfaceKind = .app
    case .cli: selectedSurfaceKind = .cli
    case .tui: selectedSurfaceKind = .tui
    }
    let result = try await VaporizeI18nSourceGate.enforce(
      productDirectory: URL(fileURLWithPath: selectedPackagePath, isDirectory: true),
      productName: selectedProduct,
      surfaceKind: selectedSurfaceKind,
      enforcement: gateEnforcement
    )
    print(
      vaporizeCopyFill(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeA1VA2PassedFor,
        [
          "\(result.report.standard.title)", "\(result.report.standard.version)",
          "\(selectedProduct)", "\(result.receiptURL.path)",
        ])
    )
  }

  private func enforceSwiftUIImportPolicy(for mode: Mode) throws {
    let selectedPackagePath: String
    let selectedProduct: String

    switch mode {
    case .install, .build, .run:
      selectedPackagePath = try requirePackagePath()
      selectedProduct =
        artifact.isTerminalExecutable ? try requireCLIProduct() : try requireProduct()
    case .test:
      // Library-only package tests do not name or ship a SwiftUI surface.
      // Preserve the import gate whenever a product is explicitly supplied.
      guard product?.isEmpty == false else { return }
      selectedPackagePath = try requirePackagePath()
      selectedProduct =
        artifact.isTerminalExecutable ? try requireCLIProduct() : try requireProduct()
    case .cli:
      selectedPackagePath = try requirePackagePath()
      selectedProduct = try requireCLIProduct()
    case .app:
      selectedPackagePath = try requirePackagePath()
      selectedProduct = try requireProduct()
    case .selfUpdate:
      // Same skip as the i18n gate: --product updates another tool's
      // installed binary from its feed; no source build to gate.
      if product != nil { return }
      selectedPackagePath = try requireSelfUpdatePackagePath()
      selectedProduct = "vaporize.cli@wrkstrm-core.clia.sh"
    default:
      return
    }

    let enforcement =
      configuration.rawValue.lowercased() == "release" ? "release" : "development"
    // The receipt (a typed record) is the durable truth surface, and an
    // adopted-package violation throws loudly from enforce(); no console
    // logging is needed or wanted here (print is banned; CommonLog adoption
    // for the whole vaporize CLI is a separate migration at its home).
    _ = try VaporizeSwiftUIImportGate.enforce(
      packageDirectory: URL(fileURLWithPath: selectedPackagePath, isDirectory: true),
      productName: selectedProduct,
      enforcement: enforcement
    )
  }

  private func installArtifact(
    launchApp: Bool,
    buildIdentity: AppBuildNumberIdentity?
  ) async throws {
    switch artifact {
    case .cli, .tui:
      try await installCLI()
    case .app:
      #if os(Windows)
        if try usesWCodeExecutionAuthority(for: .install) {
          try await runWCodeApp(operation: .install)
          return
        }
      #endif
      try await installApp(launchApp: launchApp, buildIdentity: buildIdentity)
    }
  }

  private func uninstallArtifact() async throws {
    switch artifact {
    case .cli, .tui:
      try await uninstallCLI()
    case .app:
      try uninstallApp()
    }
  }

  private func selfUpdate() async throws {
    // Generalized verb: `vaporize self-update --product <name>` updates ANY
    // installed ~/.swiftpm/bin tool from its signed appcast via its metadata
    // sidecar (SUFeedURL/SUPublicEDKey/CFBundleShortVersionString) — download,
    // EdDSA-verify, atomic install. No re-exec: vaporize is updating another
    // tool, not itself. Refusals (missing sidecar, missing/bad signature) are
    // loud typed errors.
    if let product, !product.isEmpty {
      try await ProductSelfUpdate.run(
        product: product,
        binDirectory: installedCLIBinDirectory()
      )
      return
    }

    // Without --product: the original vaporize-updates-itself behavior,
    // preserved exactly (rebuild from source and force-reinstall).
    let packagePath = try requireSelfUpdatePackagePath()
    let product = "vaporize.cli@wrkstrm-core.clia.sh"
    let updateDomain = inferredDomain(for: product, packagePath: packagePath)
    let request = SwiftCLIInstaller.Request(
      packagePath: packagePath,
      product: product,
      configuration: .init(rawValue: configuration.rawValue) ?? .release,
      forceReinstall: true,
      productVersion: Self.reportedVersion,
      productBuild: Self.reportedBuildIdentifier,
      productBuildSha: Self.buildSha,
      productBuildDate: Self.buildDate,
      installerVersion: Self.reportedVersion,
      installerBuild: Self.reportedBuildIdentifier,
      swiftToolchainSource: try selectedSwiftToolchainSource(),
      developerDirectory: resolvedDeveloperDirectory,
      swiftPMConfigPath: try resolvedSwiftPMConfigurationPath(packagePath: packagePath),
      swiftPMScratchPath: resolvedSwiftPMScratchPath()
    )
    try await SwiftCLIInstaller(request: request).run()
    try publishInstalledCLI(toDomain: updateDomain, product: product)
  }

  private func fleetStatus() async throws {
    // The Fleet Yard's data spine: every installed tool × sidecar version ×
    // feed currency. Sidecar-less tools are LISTED (absence of update
    // identity is a finding, not a skip); per-tool degradation is a typed
    // row status, never an aborted scan.
    let binDirectory =
      fleetBinDirectory.map { absoluteURL(for: $0) } ?? installedCLIBinDirectory()
    let report = try await FleetStatus.report(binDirectory: binDirectory)
    try emitReceiptIfRequested(report)

    switch vaporOutputFormat {
    case .text:
      print(FleetStatus.renderTable(report))
    case .json:
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(report)
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }
  }

  /// Resolve the optional Sparkle self-update identity to record in the
  /// install sidecar. Both flags or neither: a lone flag is a loud error, and
  /// a malformed feed URL never silently degrades to "no identity".
  func resolvedSelfUpdateIdentity() throws -> SelfUpdateIdentity? {
    let feed = suFeedURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let key = suPublicEDKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if feed.isEmpty, key.isEmpty { return nil }
    guard !feed.isEmpty, !key.isEmpty else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeSuFeedUrlAndSuPublic
      )
    }
    guard let feedURL = URL(string: feed), feedURL.scheme != nil else {
      throw ValidationError(
        vaporizeCopyFill(VaporizeCLICopy_v000_000_001.CLI.vaporizeSuFeedUrlIsNotA, ["\(feed)"]))
    }
    return SelfUpdateIdentity(feedURL: feedURL, publicEDKeyBase64: key)
  }

  private func buildArtifact(buildIdentity: AppBuildNumberIdentity?) async throws {
    switch artifact {
    case .cli, .tui:
      try await runSwift(arguments: try swiftBuildArguments())
      if !skipInstall {
        try await installCLI()
      }
    case .app:
      #if os(Windows)
        if try usesWCodeExecutionAuthority(for: .build) {
          try await runWCodeApp(operation: .build)
          return
        }
      #endif
      if skipInstall {
        try await buildAppOnly(buildIdentity: buildIdentity)
      } else {
        try await installApp(launchApp: launch, buildIdentity: buildIdentity)
      }
    }
  }

  private func testArtifact() async throws {
    switch artifact {
    case .cli, .tui:
      try await runSwiftTests()
    case .app:
      try await runXcodeAppTests()
    }
  }

  /// Runs an Xcode app test bundle without treating the application as a
  /// SwiftPM package. `--pkl-path` is preferred as the project source root;
  /// an explicit Xcode project or workspace supplies the same root when a Pkl
  /// carrier is not relevant to the calling surface.
  private func runXcodeAppTests() async throws {
    let sourceRoot: String
    if let pklPath, !pklPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      sourceRoot = absoluteURL(for: pklPath).deletingLastPathComponent().path
    } else if let xcodeProject, !xcodeProject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      sourceRoot = absoluteURL(for: xcodeProject).deletingLastPathComponent().path
    } else if let xcodeWorkspace,
      !xcodeWorkspace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      sourceRoot = absoluteURL(for: xcodeWorkspace).deletingLastPathComponent().path
    } else if let packagePath, !packagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      // Compatibility only. This is a project directory, not a requirement
      // for Package.swift or SwiftPM app-project ownership.
      sourceRoot = absoluteURL(for: packagePath).path
    } else {
      sourceRoot = FileManager.default.currentDirectoryPath
    }

    let request = SwiftAppInstaller.Request(
      packagePath: sourceRoot,
      product: xcodeScheme ?? "xcode-app-tests",
      configuration: configuration,
      destination: destination,
      forceReinstall: false,
      skipBuild: true,
      xcodeProject: xcodeProject,
      xcodeWorkspace: xcodeWorkspace,
      xcodeScheme: xcodeScheme,
      derivedDataPath: derivedDataPath,
      xcodeProductCacheWorkspace: xcodeProductCacheWorkspace,
      xcodeProductCacheDerivedDataPath: xcodeProductCacheDerivedDataPath,
      xcodeDestinations: xcodeDestinations,
      xcodeSDK: xcodeSDK,
      xcodeResultBundlePath: xcodeResultBundlePath,
      xcodeBuildSettings: xcodeBuildSettings,
      developerDirectory: resolvedDeveloperDirectory
    )
    let arguments = try request.xcodeTestArguments()
    try await runExecutable(
      executable: .name("xcodebuild"),
      arguments: arguments,
      sourceTag: "vaporize-xcode-app-test",
      environment: developerDirectoryEnvironment(),
      additionalTags: [
        "artifact": "app",
        "projectAuthority": pklPath == nil ? "xcode" : "pkl-xcode",
        "testKind": "xcode-app",
      ]
    )
  }

  private func runArtifact(buildIdentity: AppBuildNumberIdentity?) async throws {
    switch artifact {
    case .cli, .tui:
      if usesIsolatedSwiftPMWorkspace {
        try await runSwift(arguments: try swiftBuildArguments())
        try await runSourceBuiltCLI()
        return
      }
      if !skipInstall {
        try await installCLI()
      }
      try await runInstalledCLI()
    case .app:
      #if os(Windows)
        if try usesWCodeExecutionAuthority(for: .run) {
          try await runWCodeApp(operation: .run)
          return
        }
      #endif
      if !skipInstall {
        try await installApp(launchApp: true, buildIdentity: buildIdentity)
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
      installerVersion: Self.reportedVersion,
      installerBuild: Self.reportedBuildIdentifier,
      swiftToolchainSource: try selectedSwiftToolchainSource(),
      developerDirectory: resolvedDeveloperDirectory,
      swiftPMConfigPath: try resolvedSwiftPMConfigurationPath(packagePath: packagePath),
      swiftPMScratchPath: resolvedSwiftPMScratchPath(),
      selfUpdateIdentity: try resolvedSelfUpdateIdentity()
    )
    try await measureCoreProcess {
      try await SwiftCLIInstaller(request: request).run()
    }
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
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeInstallReportedSuccessButNoExecutable,
          ["\(product)", "\(installedPath)"])
      )
    }
    try publishInstalledCLI(toDomain: installDomain, product: product)
    // Positive presence confirmation: name the verified path so a multi-binary suite
    // reinstall (one invocation per product) emits one confirmation each — any single
    // missing binary surfaces immediately rather than hiding behind a silent success.
    print(
      vaporizeCopyFill(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeVerifiedA1InstalledAtA2,
        ["\(product)", "\(installedPath)"]))
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
    -> XcodeAppInputResolver.Inputs
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
      return inputs
    } catch let error as XcodeAppInputResolver.NoBuildableProject {
      throw ValidationError(error.description)
    }
  }

  private func installApp(
    launchApp: Bool,
    buildIdentity: AppBuildNumberIdentity?
  ) async throws {
    let packagePath = try requirePackagePath()
    let product = try requireProduct()
    let xcodeInputs = try resolvedXcodeAppInputs(packagePath: packagePath, product: product)
    let request = SwiftAppInstaller.Request(
      packagePath: packagePath,
      product: product,
      appBundleName: await resolvedAppBundleName(product: product, xcodeInputs: xcodeInputs),
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
      xcodeBuildSettings: try resolvedXcodeBuildSettings(buildIdentity: buildIdentity),
      swiftPMConfigPath: try resolvedSwiftPMConfigurationPath(packagePath: packagePath),
      developerDirectory: resolvedDeveloperDirectory,
      expectedMarketingVersion: buildIdentity?.marketingVersion,
      expectedBuildNumber: buildIdentity.map { String($0.buildNumber) }
    )
    try await measureCoreProcess {
      try await SwiftAppInstaller(request: request).run()
    }
  }

  private func uninstallCLI() async throws {
    let packagePath = try requirePackagePath()
    let product = try requireCLIProduct()
    let uninstallDomain = inferredDomain(for: product, packagePath: packagePath)
    let request = SwiftCLIInstaller.Request(
      packagePath: packagePath,
      product: product,
      configuration: .init(rawValue: configuration.rawValue) ?? .release,
      forceReinstall: false,
      swiftToolchainSource: try selectedSwiftToolchainSource(),
      developerDirectory: resolvedDeveloperDirectory,
      swiftPMConfigPath: try resolvedSwiftPMConfigurationPath(packagePath: packagePath)
    )
    try await SwiftCLIInstaller(request: request).uninstall()
    try removePublishedCLI(fromDomain: uninstallDomain, product: product)
  }

  private func uninstallApp() throws {
    let product = try requireProduct()
    let installedApp = installedAppURL(product: product)
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: installedApp.path) else { return }
    try fileManager.removeItem(at: installedApp)
  }

  private func buildAppOnly(buildIdentity: AppBuildNumberIdentity?) async throws {
    let packagePath = try requirePackagePath()
    let product = try requireProduct()
    let xcodeInputs = try resolvedXcodeAppInputs(packagePath: packagePath, product: product)
    let request = SwiftAppInstaller.Request(
      packagePath: packagePath,
      product: product,
      appBundleName: await resolvedAppBundleName(product: product, xcodeInputs: xcodeInputs),
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
      xcodeBuildSettings: try resolvedXcodeBuildSettings(buildIdentity: buildIdentity),
      swiftPMConfigPath: try resolvedSwiftPMConfigurationPath(packagePath: packagePath),
      developerDirectory: resolvedDeveloperDirectory,
      expectedMarketingVersion: buildIdentity?.marketingVersion,
      expectedBuildNumber: buildIdentity.map { String($0.buildNumber) }
    )
    try await measureCoreProcess {
      try await SwiftAppInstaller(request: request).buildOnly()
    }
  }

  private func resolvedXcodeBuildSettings(buildIdentity: AppBuildNumberIdentity?) throws -> [String] {
    guard let buildIdentity else { return xcodeBuildSettings }
    let hasConflictingBuildNumber = xcodeBuildSettings.contains { setting in
      setting.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).first
        == "CURRENT_PROJECT_VERSION"
    }
    guard !hasConflictingBuildNumber else {
      #if os(Windows)
        throw ValidationError(
          "--auto-increment-build cannot be combined with a manual CURRENT_PROJECT_VERSION setting."
        )
      #else
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeAutoIncrementBuildCannotComposeManualCurrentProjectVersion
      )
      #endif
    }
    return xcodeBuildSettings + [buildIdentity.xcodeBuildSetting]
  }

  private func runInstalledCLI() async throws {
    let product = try requireCLIProduct()
    let executablePath = try installedCLIExecutablePath(product: product)
    try await runExecutable(
      executable: .path(executablePath),
      arguments: try coreForwardedArguments(),
      sourceTag: "vaporize-run-cli"
    )
  }

  private func runSourceBuiltCLI() async throws {
    let product = try requireCLIProduct()
    try await runExecutable(
      executable: .path(sourceBuiltCLIExecutablePath(product: product)),
      arguments: try coreForwardedArguments(),
      sourceTag: "vaporize-run-source-built-cli"
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

  func resolvedAppBundleName(
    product: String,
    xcodeInputs providedInputs: XcodeAppInputResolver.Inputs? = nil
  ) async -> String? {
    if let appBundleName, !appBundleName.isEmpty {
      return appBundleName
    }

    let xcodeInputs: XcodeAppInputResolver.Inputs
    if let providedInputs {
      xcodeInputs = providedInputs
    } else {
      guard let packagePath,
        let resolvedInputs = try? resolvedXcodeAppInputs(
          packagePath: packagePath,
          product: product
        )
      else {
        return nil
      }
      xcodeInputs = resolvedInputs
    }

    guard xcodeInputs.project != nil || xcodeInputs.workspace != nil else {
      return nil
    }

    return await XcodeAppBundleIdentityResolver.resolve(
      .init(
        explicitPklPath: pklPath,
        xcodeProjectPath: xcodeInputs.project,
        xcodeWorkspacePath: xcodeInputs.workspace,
        sourceRootPath: packagePath,
        targetName: xcodeInputs.scheme ?? product,
        configuration: configuration.rawValue.capitalized,
        workingDirectoryURL: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      )
    )
  }

  private func absoluteURL(for path: String) -> URL {
    VaporizeFileSystemPathResolution.absoluteURL(
      for: path,
      relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    )
  }

  private func installedCLIBinDirectory() -> URL {
    FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".swiftpm/bin")
  }

  private func installedCLIPath(product: String) -> String {
    installedCLIBinDirectory().appendingPathComponent(product).path
  }

  func sourceBuiltCLIExecutablePath(product: String) -> String {
    precondition(usesIsolatedSwiftPMWorkspace)
    let scratchPath = swiftPMScratchPath!
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return absoluteURL(for: scratchPath)
      .appendingPathComponent("out/Products/\(configuration.rawValue.capitalized)/\(product)")
      .path
  }

  func installedCLIExecutablePath(product: String) throws -> String {
    let candidates = installedCLIExecutableCandidatePaths(product: product)
    for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
      return path
    }
    throw ValidationError(
      vaporizeCopyFill(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeExecutableProductA1IsNotInstalled,
        ["\(product)", "\(candidates.map { "  - \($0)" }.joined(separator: "\n"))"])
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
    guard
      let enumerator = fileManager.enumerator(
        at: base,
        includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
        options: [.skipsHiddenFiles]
      )
    else {
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
    components.reduce(installedCLIBinDirectory().appendingPathComponent("domain")) {
      path, component in
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
    guard
      let enumerator = fileManager.enumerator(
        at: base, includingPropertiesForKeys: [.isRegularFileKey])
    else {
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
    return ["build"] + (try swiftPMWorkspaceArguments(packagePath: packagePath)) + [
      "--package-path", packagePath,
      "-c", configuration.rawValue,
      "--product", product,
    ]
  }

  #if os(Windows)
    func wcodeSwiftBuildArguments() throws -> [String] {
      let packagePath = try requirePackagePath()
      let product = try requireProduct()
      return ["build"] + (try swiftPMWorkspaceArguments(packagePath: packagePath)) + [
        "--package-path", packagePath,
        "-c", configuration.rawValue,
        "--product", product,
      ]
    }

    func wcodeSwiftRunArguments() throws -> [String] {
      let packagePath = try requirePackagePath()
      let product = try requireProduct()
      return ["run"] + (try swiftPMWorkspaceArguments(packagePath: packagePath)) + [
        "--package-path", packagePath,
        "-c", configuration.rawValue,
        product,
      ] + (try coreForwardedArguments())
    }

    func wcodeBuildEnvironment() throws -> [String: String] {
      let packagePath = try requirePackagePath()
      let product = try requireProduct()
      var environment = swiftCommandEnvironment() ?? [:]
      environment["WCODE_PACKAGE_PATH"] = absoluteURL(for: packagePath).path
      environment["WCODE_PRODUCT"] = product
      environment["WCODE_CONFIGURATION"] = configuration.rawValue
      environment["WCODE_ARTIFACT"] = artifact.rawValue
      environment["WCODE_DESTINATION"] = destination
      environment["WCODE_FORCE_REINSTALL"] = forceReinstall ? "1" : "0"
      environment["WCODE_SKIP_BUILD"] = skipBuild ? "1" : "0"
      environment["WCODE_SKIP_INSTALL"] = skipInstall ? "1" : "0"
      environment["WCODE_LAUNCH"] = launch ? "1" : "0"
      environment["WCODE_ARGUMENTS_JSON"] = String(
        decoding: try JSONEncoder().encode(try coreForwardedArguments()),
        as: UTF8.self
      )

      for assignment in wcodeEnvironmentAssignments {
        let parts = assignment.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2,
          !parts[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
          throw ValidationError("--wcode-environment must use NAME=VALUE; received '\(assignment)'.")
        }
        environment[String(parts[0])] = String(parts[1])
      }
      return environment
    }

    private func usesWCodeExecutionAuthority(for mode: Mode) throws -> Bool {
      try coreExecutionPlan(for: mode)?.executionAuthority == .wcode
    }

    private func runWCodeApp(operation: VaporizeCoreOperation) async throws {
      var environment = try wcodeBuildEnvironment()
      environment["WCODE_OPERATION"] = operation.rawValue
      let product = try requireProduct()

      if let script = wcodeBuildScript?.trimmingCharacters(in: .whitespacesAndNewlines),
        !script.isEmpty
      {
        try await runExecutable(
          executable: .name("powershell.exe"),
          arguments: [
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy", "Bypass",
            "-File", absoluteURL(for: script).path,
          ],
          sourceTag: "vaporize-wcode",
          environment: environment,
          additionalTags: [
            "artifact": "app",
            "executionAuthority": "wcode",
            "operation": operation.rawValue,
            "appPhase": "declared-script",
          ]
        )
        return
      }

      guard operation != .install else {
        throw ValidationError(
          "WCode cannot install an app without a declared lifecycle script. next: use `vaporize install wcode --artifact app --package-path <package> --product <app-product> --wcode-build-script <script.ps1>`. The script receives WCODE_OPERATION=install plus destination, reinstall, and launch flags."
        )
      }

      let arguments: [String]
      switch operation {
      case .build:
        arguments = try wcodeSwiftBuildArguments()
      case .run:
        arguments = try wcodeSwiftRunArguments()
      case .install, .test:
        throw ValidationError("WCode has no direct SwiftPM fallback for \(operation.rawValue) app execution.")
      }
      let invocation = try swiftCommandInvocation(arguments: arguments)
      try await runExecutable(
        executable: invocation.executable,
        arguments: invocation.arguments,
        sourceTag: "vaporize-wcode",
        environment: environment,
        additionalTags: [
          "artifact": "app",
          "executionAuthority": "wcode",
          "toolchainResolver": invocation.resolver,
          "product": product,
          "operation": operation.rawValue,
          "appPhase": operation == .build ? "swiftpm-app-target" : "swiftpm-app-run",
        ]
      )
    }
  #endif

  func swiftTestArguments() throws -> [String] {
    let packagePath = try requirePackagePath()
    var arguments =
      ["test"] + (try swiftPMWorkspaceArguments(packagePath: packagePath)) + [
        "--package-path", packagePath,
        "-c", configuration.rawValue,
      ]
    arguments.append(contentsOf: try coreForwardedArguments())
    return arguments
  }

  private func swiftPMConfigurationArguments(packagePath: String) throws -> [String] {
    guard let path = try resolvedSwiftPMConfigurationPath(packagePath: packagePath) else {
      return []
    }
    return ["--config-path", path]
  }

  private func swiftPMWorkspaceArguments(packagePath: String) throws -> [String] {
    var arguments = try swiftPMConfigurationArguments(packagePath: packagePath)
    if let scratchPath = resolvedSwiftPMScratchPath() {
      arguments += ["--scratch-path", scratchPath]
    }
    return arguments
  }

  private func resolvedSwiftPMScratchPath() -> String? {
    guard let swiftPMScratchPath = swiftPMScratchPath?.trimmingCharacters(in: .whitespacesAndNewlines),
      !swiftPMScratchPath.isEmpty
    else {
      return nil
    }
    return absoluteURL(for: swiftPMScratchPath).path
  }

  /// A scratch workspace is an isolated, read-only consumption of the
  /// maintainer mirror configuration.  It must not mutate the caller's
  /// Package.resolved through `swift package edit`; the mirrors already name
  /// the authoritative local upstream homes.
  var usesIsolatedSwiftPMWorkspace: Bool {
    guard let swiftPMScratchPath else { return false }
    return !swiftPMScratchPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func resolvedSwiftPMConfigurationPath(packagePath: String) throws -> String? {
    try MaintainerSwiftPMConfiguration.resolve(
      explicitPath: swiftPMConfigurationPathOverride,
      packagePath: packagePath
    )
  }

  private func withMaintainerDependencyAuthority<Result>(
    packagePath: String,
    operation: () async throws -> Result
  ) async throws -> Result {
    guard !usesIsolatedSwiftPMWorkspace else {
      return try await operation()
    }
    let dependencies = try MaintainerSwiftPMConfiguration.editableDependencies(
      packagePath: packagePath
    )
    guard !dependencies.isEmpty else {
      return try await operation()
    }

    let snapshot = try PackageResolutionSnapshot.capture(packagePath: packagePath)
    do {
      let prepare = {
        let configurationArguments = try swiftPMWorkspaceArguments(
          packagePath: packagePath
        )
        for dependency in dependencies where dependency.requiresEdit {
          try await runSwiftPackage(
            arguments: ["package"] + configurationArguments + [
              "--package-path", packagePath,
              "edit",
              "--path", dependency.checkoutPath,
              dependency.identity,
            ]
          )
        }
      }
      if let recorder = VaporizeCoreExecutionInstrumentation.current {
        try await recorder.measure(.dependencyPreparation, operation: prepare)
      } else {
        try await prepare()
      }
      let result = try await operation()
      if let recorder = VaporizeCoreExecutionInstrumentation.current {
        try await recorder.measure(.dependencyRestore) {
          try snapshot.restore()
        }
      } else {
        try snapshot.restore()
      }
      return result
    } catch {
      let operationError = error
      do {
        if let recorder = VaporizeCoreExecutionInstrumentation.current {
          try await recorder.measure(.dependencyRestore) {
            try snapshot.restore()
          }
        } else {
          try snapshot.restore()
        }
      } catch {
        throw ValidationError(
          vaporizeCopyFill(
            VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeCouldNotRestorePackageResolved,
            ["\(snapshot.url.path)", "\(error.localizedDescription)"])
        )
      }
      throw operationError
    }
  }

  private func prepareMaintainerDependencies() async throws {
    let packagePath = try requirePackagePath()
    let before = try MaintainerSwiftPMConfiguration.editableDependencies(
      packagePath: packagePath
    )
    let started = DispatchTime.now().uptimeNanoseconds
    try await withMaintainerDependencyAuthority(packagePath: packagePath) {}
    let elapsed = DispatchTime.now().uptimeNanoseconds &- started
    let active = try MaintainerSwiftPMConfiguration.editableDependencies(
      packagePath: packagePath
    )
    let receipt = MaintainerDependencyAuthorityReceipt(
      packagePath: absoluteURL(for: packagePath).standardizedFileURL.path,
      swiftPMConfigurationPath: try resolvedSwiftPMConfigurationPath(
        packagePath: packagePath
      ),
      preparedDependencyCount: before.filter(\.requiresEdit).count,
      activeDependencies: active.map {
        .init(identity: $0.identity, checkoutPath: $0.checkoutPath)
      },
      packageResolutionRestored: true,
      elapsedNanoseconds: elapsed
    )
    try emitReceiptIfRequested(receipt)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    FileHandle.standardOutput.write(try encoder.encode(receipt))
    FileHandle.standardOutput.write(Data("\n".utf8))
  }

  func developerDirectoryEnvironment() -> [String: String]? {
    guard let developerDirectory = resolvedDeveloperDirectory, !developerDirectory.isEmpty else {
      return nil
    }
    return ["DEVELOPER_DIR": developerDirectory]
  }

  private func requirePackagePath() throws -> String {
    guard let packagePath, !packagePath.isEmpty else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizePackagePathIsRequiredForOperation)
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
        VaporizeCLICopy_v000_000_001.CLI.vaporizePackagePathIsRequiredForSelf
      )
    }

    return currentDirectory
  }

  private func requireProduct() throws -> String {
    guard let product, !product.isEmpty else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeProductIsRequiredForOperationMode)
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

    let output = try await measureCoreProcess {
      try await RunnerControllerFactory.run(command: command)
    }
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
    productVersion ?? (product == Self.configuration.commandName ? Self.reportedVersion : nil)
  }

  private func resolvedProductBuild(for product: String) -> String? {
    productBuild ?? (product == Self.configuration.commandName ? Self.reportedBuildIdentifier : nil)
  }

  private func resolvedProductBuildSha(for product: String) -> String? {
    productBuildSha ?? (product == Self.configuration.commandName ? Self.buildSha : nil)
  }

  private func resolvedProductBuildDate(for product: String) -> String? {
    productBuildDate ?? (product == Self.configuration.commandName ? Self.buildDate : nil)
  }

  private func printVersionMetadata() {
    let metadata = Self.reportedBuildMetadata
    print(
      vaporizeCopyFill(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeCliWrkstrmCoreCliaSh,
        ["\(Self.reportedVersion)", "\(metadata.buildNumber)"]))
    print(
      vaporizeCopyFill(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeBuildAuthorityA1,
        ["\(metadata.authority.rawValue)"]))
    if let sidecarVersion = metadata.sidecarVersion, sidecarVersion != Self.reportedVersion {
      print(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeMetadataVersionA1DoesNotMatch,
          ["\(sidecarVersion)"]))
    }
    if let buildSha = metadata.buildSHA {
      print(vaporizeCopyFill(VaporizeCLICopy_v000_000_001.CLI.vaporizeBuildShaA1, ["\(buildSha)"]))
    }
    if let buildDate = metadata.buildDate {
      print(
        vaporizeCopyFill(VaporizeCLICopy_v000_000_001.CLI.vaporizeBuildDateA1, ["\(buildDate)"]))
    }
  }

  private func useCommonProcessSpec() async throws {
    guard let commonProcessSpecPath, !commonProcessSpecPath.isEmpty else {
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizeCommonProcessSpecIsRequiredFor)
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

  #if os(macOS)
    private func runToolchainSelection() async throws {
      guard resolvedDeveloperDirectory == nil else {
        throw ValidationError(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeDeveloperDirIsAProcessLocal
        )
      }

      let request = try ToolchainSelectionRequest(arguments: forwardedArguments)
      switch request.operation {
      case .xcodeSelect(let xcodeRequest):
        try await runXcodeToolchainSelection(xcodeRequest)
      }
    }

    private func runXcodeToolchainSelection(_ request: XcodeSelectionRequest) async throws {
      try await runToolchainSelectionInvocation(
        provider: "xcode",
        operation: "select",
        arguments: request.arguments,
        invocation: request.invocation(),
        environmentUpdates: nil
      )
    }
  #endif

  private func runToolchainSelectionInvocation(
    provider: String,
    operation: String,
    arguments: [String],
    invocation: ToolchainInvocation,
    environmentUpdates: [String: String]?
  ) async throws {
    let requestId = "vaporize-toolchain-selection-\(UUID().uuidString)"
    let workingDirectory = FileManager.default.currentDirectoryPath
    let command = CommandSpec(
      executable: invocation.executable,
      args: invocation.arguments,
      env: .inherit(updating: environmentUpdates),
      workingDirectory: workingDirectory,
      logOptions: .init(
        exposure: .none,
        tags: [
          "source": "vaporize-toolchain-selection",
          "canonicalSource": "vaporize-toolchain-selection",
          "provider": provider,
          "operation": operation,
          "selectionResolver": invocation.resolver,
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

    let receipt = ToolchainSelectionReceipt(
      provider: provider,
      operation: operation,
      arguments: arguments,
      workingDirectory: workingDirectory,
      requestId: requestId,
      runnerKind: "auto",
      executableRef: invocation.executableRef,
      resolver: invocation.resolver,
      outputCapture: "buffered",
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
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeXcodeComponentIsRequiredForSetup)
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
        vaporizeVersion: Self.reportedVersion
      )
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }
  }

  private func runVaporWarehouse() async throws {
    let scanResult = try scanForVapor()
    let scanner = VaporInventoryScanner()
    let receipt = scanner.receipt(from: scanResult, vaporizeVersion: Self.reportedVersion)
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
      vaporizeVersion: Self.reportedVersion
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

  private func runSourceVersionStatus() async throws {
    let scanPath = try ownedSurfaceInventoryPath()
    let scanner = SourceVersionStatusScanner()
    let result = try await scanner.scan(path: scanPath)
    let receipt = scanner.receipt(
      from: result,
      reporterVersion: Self.reportedVersion,
      reporterBuildNumber: Self.reportedBuildIdentifier
    )
    let data = try SourceVersionStatusRenderer.renderJSON(receipt)

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
      print(SourceVersionStatusRenderer.renderText(receipt))
    case .json:
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }
  }

  private func runHomebrewStatus() async throws {
    guard let homebrewFormula, !homebrewFormula.isEmpty else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeHomebrewFormulaIsRequiredForHomebrew)
    }
    guard let homebrewTapRoot, !homebrewTapRoot.isEmpty else {
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizeHomebrewTapRootIsRequiredFor)
    }
    let command = CommandSpec(
      executable: .name("brew"),
      args: ["info", "--json=v2", homebrewFormula],
      env: .inherit(updating: nil),
      workingDirectory: FileManager.default.currentDirectoryPath,
      logOptions: .init(exposure: .none, tags: ["source": "vaporize-homebrew-status"]),
      requestId: "vaporize-homebrew-status-\(UUID().uuidString)",
      runnerKind: .auto,
      streamingMode: .buffered
    )
    try command.validateOrThrow()
    let output = try await RunnerControllerFactory.run(command: command)
    guard output.isSuccess else {
      let detail = String(data: output.stderr, encoding: .utf8) ?? "brew info failed"
      throw ValidationError(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeHomebrewStatusCouldNotReadBrew,
          ["\(homebrewFormula)", "\(detail)"]))
    }
    let receipt = try HomebrewStatusScanner().receipt(
      formulaName: homebrewFormula,
      tapRoot: absoluteURL(for: homebrewTapRoot),
      brewInfoData: output.stdout
    )
    let data = try HomebrewStatusRenderer.renderJSON(receipt)
    if let receiptPath {
      let url = absoluteURL(for: receiptPath)
      try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try data.write(to: url)
    }
    switch vaporOutputFormat {
    case .json:
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    case .text:
      print(HomebrewStatusRenderer.renderText(receipt))
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
      vaporizeVersion: Self.reportedVersion,
      scannedAt: generatedAt
    )
    let report = CUJPortfolioAuditRenderer.renderMarkdown(result)
    let proofLedger = try CUJAutomatedProofLedgerRenderer.renderJSON(
      result,
      vaporizeVersion: Self.reportedVersion,
      generatedAt: generatedAt
    )
    let projectLedger = try CUJImplementationProjectCoverageLedgerRenderer.renderJSON(
      result,
      vaporizeVersion: Self.reportedVersion,
      generatedAt: generatedAt
    )
    let projectLedgerCSV = CUJImplementationProjectCoverageLedgerRenderer.renderCSV(
      result,
      vaporizeVersion: Self.reportedVersion,
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
    if let projectLedgerPath {
      try writeCUJAudit(projectLedger, to: projectLedgerPath)
    }
    if let projectLedgerCSVPath {
      try writeCUJAudit(Data(projectLedgerCSV.utf8), to: projectLedgerCSVPath)
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
        VaporizeCLICopy_v000_000_001.CLI.vaporizeCouldNotResolveToolCollectionPath
      )
    }
    return defaultCollection
  }

  private func loadToolManifests(from collectionPath: URL) throws -> [ToolManifestRecord] {
    let fileManager = FileManager.default
    guard
      let enumerator = fileManager.enumerator(
        at: collectionPath,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
      )
    else {
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
    try await withMaintainerDependencyAuthority(packagePath: packageGraphPath) {
      try await runSwift(arguments: swiftArgs)
    }
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
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizePathIsRequiredForThisOperation)
    }
    let scanner = VaporInventoryScanner()
    return try scanner.scan(path: vaporScanPath)
  }

  private func validateJSON() async throws {
    guard let vaporScanPath, !vaporScanPath.isEmpty else {
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizePathIsRequiredForValidateJson)
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
      print(
        vaporizeCopyFill(VaporizeCLICopy_v000_000_001.CLI.vaporizeValidJsonA1, ["\(vaporScanPath)"])
      )
    } catch {
      let receipt = JSONValidationReceipt(
        path: vaporScanPath,
        requestId: requestId,
        valid: false,
        byteCount: data.count,
        errorMessage: String(describing: error)
      )
      try emitReceiptIfRequested(receipt)
      throw ValidationError(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeInvalidJsonAtA1A2,
          ["\(vaporScanPath)", "\(error)"]))
    }
  }

  private func validateJSONSchema() async throws {
    guard let jsonSchemaPath, !jsonSchemaPath.isEmpty else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeSchemaIsRequiredForValidateJson)
    }
    guard let jsonSchemaFixturePath, !jsonSchemaFixturePath.isEmpty else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeFixtureIsRequiredForValidateJson)
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
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeSchemaValidationA1A2A3Against,
          ["\(actual)", "\(expectationSuffix)", "\(jsonSchemaFixturePath)", "\(jsonSchemaPath)"])
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
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizePathIsRequiredForInspectProject)
    }

    let requestId = "vaporize-inspect-project-yml-\(UUID().uuidString)"
    let spec = try XcodeProjectYMLReader.load(url: URL(fileURLWithPath: vaporScanPath))
    let receipt = XcodeProjectYMLReader.receipt(
      for: spec,
      path: vaporScanPath,
      requestId: requestId
    )
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      print(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeProjectYmlA1TargetsA2Packages,
          [
            "\(receipt.projectName)", "\(receipt.targetCount)", "\(receipt.packageCount)",
            "\(receipt.schemeCount)",
          ])
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
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizePathIsRequiredForInspectTarget)
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
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeTargetFeaturesA1StatusA2Configs,
          [
            "\(receipt.targetName)", "\(receipt.overallStatus)", "\(configs)",
            "\(receipt.releaseFeatureManifest.tierCount)",
          ])
      )
      for minimum in receipt.minimums where minimum.status != "pass" {
        print(
          vaporizeCopyFill(
            VaporizeCLICopy_v000_000_001.CLI.vaporizeA1A2A3,
            ["\(minimum.status)", "\(minimum.name)", "\(minimum.detail)"]))
      }
    case .json:
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(receipt)
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }

    guard receipt.overallStatus == "pass" else {
      throw ValidationError(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeTargetFeatureInspectionFailedForA1,
          ["\(receipt.targetName)"]))
    }
  }

  private func compareProjectYMLPkl() async throws {
    guard let vaporScanPath, !vaporScanPath.isEmpty else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizePathIsRequiredForCompareProject)
    }
    guard let pklPath, !pklPath.isEmpty else {
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizePklPathIsRequiredForCompare)
    }

    let requestId = "vaporize-compare-project-yml-pkl-\(UUID().uuidString)"
    let ymlSpec = try XcodeProjectYMLReader.loadForPklMigration(url: URL(fileURLWithPath: vaporScanPath))
    let pklSpec = try await XcodeProjectPklLoader.load(url: URL(fileURLWithPath: pklPath))
    let receipt = XcodeProjectDefinitionComparator.receipt(
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
      print(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeProjectYmlProjectPklA1Mismatches,
          ["\(status)", "\(receipt.mismatchCount)"]))
      if !receipt.mismatches.isEmpty {
        let joinedMismatches = receipt.mismatches.joined(separator: ", ")
        print(
          vaporizeCopyFill(
            VaporizeCLICopy_v000_000_001.CLI.vaporizeMismatchesA1, ["\(joinedMismatches)"]))
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
      throw ValidationError(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeProjectYmlAndProjectPklDiffer,
          ["\(joinedMismatches)"]))
    }
  }

  private func importProjectYML() async throws {
    guard let vaporScanPath, !vaporScanPath.isEmpty else {
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizePathIsRequiredForImportProject)
    }
    guard let generatedOutputPath, !generatedOutputPath.isEmpty else {
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizeOutputPathIsRequiredForImport)
    }

    let outputURL = URL(fileURLWithPath: generatedOutputPath).standardizedFileURL
    let schemaURL = try resolvedXcodeProjectDefinitionSchemaURL()
    let schemaAmendsPath = relativePath(
      from: outputURL.deletingLastPathComponent(),
      to: schemaURL
    )
    let requestId = "vaporize-import-project-yml-\(UUID().uuidString)"
    let receipt = try XcodeProjectDefinitionPklImporter.generate(
      ymlURL: URL(fileURLWithPath: vaporScanPath).standardizedFileURL,
      outputURL: outputURL,
      schemaAmendsPath: schemaAmendsPath,
      requestId: requestId
    )
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      print(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeProjectYmlProjectPklA1Targets,
          [
            "\(receipt.projectName)", "\(receipt.targetCount)", "\(receipt.packageCount)",
            "\(receipt.generatedByteCount)",
          ])
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
  /// filesystem-free XcodeProjectPklUpgradePlanner (see its proving ground).
  private func upgradeProjectYMLToPkl() async throws {
    guard let vaporScanPath, !vaporScanPath.isEmpty else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizePathIsRequiredForUpgradeProject)
    }
    let ymlURL = URL(fileURLWithPath: vaporScanPath).standardizedFileURL
    guard FileManager.default.fileExists(atPath: ymlURL.path) else {
      throw ValidationError(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeUpgradeProjectYmlToPklNo, ["\(ymlURL.path)"]))
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
    let schemaURL = try resolvedXcodeProjectDefinitionSchemaURL()
    let schemaAmendsPath = relativePath(from: pklURL.deletingLastPathComponent(), to: schemaURL)
    let importReceipt = try XcodeProjectDefinitionPklImporter.generate(
      ymlURL: ymlURL,
      outputURL: pklURL,
      schemaAmendsPath: schemaAmendsPath,
      requestId: requestId
    )

    // 2. Parity gate: load the generated pkl back and compare to the yml.
    let ymlSpec = try XcodeProjectYMLReader.loadForPklMigration(url: ymlURL)
    let pklSpec = try await XcodeProjectPklLoader.load(url: pklURL)
    let comparison = XcodeProjectDefinitionComparator.receipt(
      ymlSpec: ymlSpec,
      pklSpec: pklSpec,
      ymlPath: ymlURL.path,
      pklPath: pklURL.path,
      requestId: requestId
    )

    // 3. Decide (pure), then act.
    let decision = XcodeProjectPklUpgradePlanner.decide(
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
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizePklPathIsRequiredForGenerate)
    }
    guard let generatedOutputPath, !generatedOutputPath.isEmpty else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeOutputPathIsRequiredForGenerate)
    }

    let requestId = "vaporize-generate-project-yml-\(UUID().uuidString)"
    let receipt = try await XcodeProjectDefinitionYMLGenerator.generate(
      pklURL: URL(fileURLWithPath: pklPath),
      outputURL: URL(fileURLWithPath: generatedOutputPath),
      requestId: requestId
    )
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      print(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeProjectPklProjectYmlA1Targets,
          [
            "\(receipt.projectName)", "\(receipt.targetCount)", "\(receipt.packageCount)",
            "\(receipt.generatedByteCount)",
          ])
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
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizePklPathIsRequiredForGenerate2)
    }
    guard let generatedOutputPath, !generatedOutputPath.isEmpty else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeOutputPathIsRequiredForGenerate2)
    }

    let requestId = "vaporize-generate-xcodeproj-\(UUID().uuidString)"
    let receipt = try await XcodeProjectGenerator.generate(
      pklURL: URL(fileURLWithPath: pklPath),
      outputURL: URL(fileURLWithPath: generatedOutputPath),
      requestId: requestId
    )
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      print(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeProjectPklXcodeprojA1TargetsA2,
          [
            "\(receipt.projectName)", "\(receipt.targetCount)", "\(receipt.sourceFileCount)",
            "\(receipt.resourceFileCount)", "\(receipt.generatedByteCount)",
          ])
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

  /// Emit the compiled-in SparkleConfig.swift for a CLI tool target from its
  /// project.pkl releaseIdentity (the single typed source for the tool's
  /// self-update identity). Generation only — wiring the generated file into
  /// the install/run lane and the self-update verb is a separate component.
  private func generateSparkleConfig() async throws {
    guard let pklPath, !pklPath.isEmpty else {
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizePklPathIsRequiredForGenerate3)
    }
    guard let targetName, !targetName.isEmpty else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeTargetIsRequiredForGenerateSparkle)
    }
    guard let sparkleConfigOutputPath, !sparkleConfigOutputPath.isEmpty else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeOutputIsRequiredForGenerateSparkle)
    }

    let spec = try await XcodeProjectPklLoader.load(url: URL(fileURLWithPath: pklPath))
    let data = try XcodeProjectSparkleConfigRenderer.renderData(
      spec: spec,
      targetName: targetName,
      sourcePath: pklPath
    )
    let outputURL = URL(fileURLWithPath: sparkleConfigOutputPath)
    try FileManager.default.createDirectory(
      at: outputURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try data.write(to: outputURL)
    print(outputURL.path)
  }

  private func listTargets() async throws {
    let requestId = "vaporize-list-targets-\(UUID().uuidString)"
    let productCacheOptions = XcodeProjectProductCacheDiscoveryOptions(
      workspacePath: xcodeProductCacheWorkspace,
      derivedDataPath: xcodeProductCacheDerivedDataPath,
      configurationName: configuration.rawValue.capitalized
    )
    let receipt: XcodeProjectTargetDiscoveryReceipt
    if let pklPath, !pklPath.isEmpty {
      receipt = try await XcodeProjectTargetDiscovery.discover(
        pklURL: URL(fileURLWithPath: pklPath),
        requestId: requestId,
        productCacheOptions: productCacheOptions
      )
    } else if let vaporScanPath, !vaporScanPath.isEmpty {
      receipt = try await XcodeProjectTargetDiscovery.discover(
        path: vaporScanPath,
        requestId: requestId,
        productCacheOptions: productCacheOptions
      )
    } else if let packagePath, !packagePath.isEmpty {
      receipt = try await XcodeProjectTargetDiscovery.discover(
        projectDirectoryURL: URL(fileURLWithPath: packagePath),
        requestId: requestId,
        productCacheOptions: productCacheOptions
      )
    } else {
      throw ValidationError(VaporizeCLICopy_v000_000_001.CLI.vaporizePathPklPathOrPackagePath)
    }
    try emitReceiptIfRequested(receipt)

    switch vaporOutputFormat {
    case .text:
      print(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeTargetsA1InputA2TargetsA3,
          [
            "\(receipt.projectName)", "\(receipt.inputKind)", "\(receipt.targetCount)",
            "\(receipt.buildableTargetNames.count)", "\(receipt.schemeCount)",
            "\(receipt.packageCount)",
          ])
      )
      for target in receipt.targets {
        let buildable = target.isBuildableCandidate ? " buildable" : ""
        print(
          vaporizeCopyFill(
            VaporizeCLICopy_v000_000_001.CLI.vaporizeA1TypeA2PlatformA3Product,
            [
              "\(target.name)", "\(target.type ?? "<nil>")", "\(target.platform ?? "<nil>")",
              "\(target.productName)", "\(buildable)",
            ]))
      }
      if receipt.productCacheCandidateCount > 0 {
        print(
          vaporizeCopyFill(
            VaporizeCLICopy_v000_000_001.CLI.vaporizeProductCacheCandidatesA1WarmA2,
            [
              "\(receipt.productCacheCandidateCount)", "\(receipt.warmProductCacheCandidateCount)",
              "\(receipt.productCacheConfigurationName ?? "<nil>")",
            ])
        )
        for candidate in receipt.productCacheCandidates {
          print(
            vaporizeCopyFill(
              VaporizeCLICopy_v000_000_001.CLI.vaporizeCacheA1A2A3,
              ["\(candidate.status)", "\(candidate.targetName)", "\(candidate.appBundlePath)"]))
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
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeXcodeWorkspaceIsRequiredForList)
    }

    let request = try XcodeWorkspaceSchemeListRequest(workspacePath: xcodeWorkspace)
    let requestId = "vaporize-list-schemes-\(UUID().uuidString)"
    let workingDirectory = passWorkingDirectory ?? FileManager.default.currentDirectoryPath
    let environmentUpdates = resolvedDeveloperDirectory.map { ["DEVELOPER_DIR": $0] }
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
        developerDirectorySet: resolvedDeveloperDirectory != nil,
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
      developerDirectorySet: resolvedDeveloperDirectory != nil,
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
      print(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeWorkspaceSchemesA1SchemesA2,
          ["\(receipt.workspaceName ?? "<unknown>")", "\(receipt.schemeCount)"]))
      for scheme in receipt.schemes {
        print(vaporizeCopyFill(VaporizeCLICopy_v000_000_001.CLI.vaporizeA1, ["\(scheme)"]))
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
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeReleaseDoctorA1A2StatusA3,
          [
            "\(receipt.subjectAppSlug)", "\(receipt.subjectReleaseSlug)",
            "\(receipt.overallStatus)", "\(receipt.passedCheckCount)", "\(receipt.checkCount)",
          ])
      )
      for check in receipt.checks where check.status != "pass" {
        print(
          vaporizeCopyFill(
            VaporizeCLICopy_v000_000_001.CLI.vaporizeA1A2A3,
            ["\(check.status)", "\(check.name)", "\(check.detail)"]))
      }
    case .json:
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(receipt)
      FileHandle.standardOutput.write(data)
      FileHandle.standardOutput.write(Data("\n".utf8))
    }

    guard receipt.overallStatus == "pass" else {
      throw ValidationError(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeReleaseDoctorFailedWithA1Failing,
          ["\(receipt.failedCheckCount)"]))
    }
  }

  private func resolvedXcodeProjectDefinitionSchemaURL() throws -> URL {
    let fileManager = FileManager.default

    if let pklSchemaPath, !pklSchemaPath.isEmpty {
      let url = URL(fileURLWithPath: pklSchemaPath).standardizedFileURL
      guard fileManager.fileExists(atPath: url.path) else {
        throw ValidationError(
          vaporizeCopyFill(
            VaporizeCLICopy_v000_000_001.CLI.vaporizePklSchemaPathDoesNotExist, ["\(pklSchemaPath)"]
          ))
      }
      return url
    }

    var candidates: [URL] = []
    if let packagePath, !packagePath.isEmpty {
      candidates.append(
        URL(fileURLWithPath: packagePath)
          .appendingPathComponent("Pkl/XcodeProjectDefinition.pkl")
          .standardizedFileURL
      )
    }

    candidates.append(
      URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Pkl/XcodeProjectDefinition.pkl")
        .standardizedFileURL
    )

    let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    candidates.append(
      currentDirectory.appendingPathComponent("Pkl/XcodeProjectDefinition.pkl").standardizedFileURL)

    for candidate in candidates where fileManager.fileExists(atPath: candidate.path) {
      return candidate
    }

    throw ValidationError(
      VaporizeCLICopy_v000_000_001.CLI.vaporizePklSchemaPathIsRequiredFor
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
    try await validateSelectedSwiftCompatibility(arguments: arguments)
    let invocation = try swiftCommandInvocation(arguments: arguments)
    let plan = try mode.flatMap { try coreExecutionPlan(for: $0) }
    try await runExecutable(
      executable: invocation.executable,
      arguments: invocation.arguments,
      sourceTag: "vaporize-swift",
      environment: swiftCommandEnvironment(),
      additionalTags: plan.map {
        [
          "operation": $0.operation.rawValue,
          "executionAuthority": $0.executionAuthority.rawValue,
          "toolchainResolver": invocation.resolver,
        ]
      } ?? [:]
    )
  }

  private func runSwiftTests() async throws {
    let arguments = try swiftTestArguments()
    try await validateSelectedSwiftCompatibility(arguments: arguments)
    let invocation = try swiftCommandInvocation(arguments: arguments)
    guard let executionPlan = try coreExecutionPlan(for: .test) else {
      preconditionFailure("test execution requires a core execution plan")
    }

    let packagePath = try requirePackagePath()
    let product = self.product
    let requestId = "vaporize-test-\(UUID().uuidString)"
    let issueSinkURL = testIssueSinkURL(requestId: requestId)
    let preservesIssueSink = receiptPath != nil
    try prepareTestIssueSink(at: issueSinkURL)
    defer {
      if !preservesIssueSink {
        try? FileManager.default.removeItem(at: issueSinkURL)
      }
    }

    var environmentUpdates = swiftCommandEnvironment() ?? [:]
    environmentUpdates[VaporizeIssueReporting.sinkPathEnvironmentKey] = issueSinkURL.path
    environmentUpdates[VaporizeIssueReporting.requestIdEnvironmentKey] = requestId
    environmentUpdates[VaporizeIssueReporting.executionPhaseEnvironmentKey] =
      VaporizeIssueEvent.ExecutionPhase.test.rawValue

    let command = CommandSpec(
      executable: invocation.executable,
      args: invocation.arguments,
      env: .inherit(updating: environmentUpdates),
      workingDirectory: FileManager.default.currentDirectoryPath,
      logOptions: .init(
        exposure: .none,
        tags: [
          "source": "vaporize-test",
          "canonicalSource": "vaporize-test",
          "tool": "swift",
          "operation": executionPlan.operation.rawValue,
          "executionAuthority": executionPlan.executionAuthority.rawValue,
          "toolchainResolver": invocation.resolver,
        ]
      ),
      requestId: requestId,
      runnerKind: .auto,
      streamingMode: .buffered
    )
    try command.validateOrThrow()

    let output = try await measureCoreProcess {
      try await RunnerControllerFactory.run(command: command)
    }
    FileHandle.standardOutput.write(output.stdout)
    FileHandle.standardError.write(output.stderr)

    let ingestion = VaporizeTestIssueEventIngestor.ingest(from: issueSinkURL)
    let timing =
      VaporizeCoreExecutionInstrumentation.current?.snapshot()
      ?? VaporizeCoreExecutionTimingSnapshot(
        commandElapsedNanoseconds: 0,
        dependencyPreparationNanoseconds: 0,
        dependencyRestoreNanoseconds: 0,
        processExecutionNanoseconds: 0
      )
    let receipt = VaporizeTestReceipt(
      packagePath: packagePath,
      product: product,
      arguments: arguments,
      operation: executionPlan.operation.rawValue,
      executionAuthority: executionPlan.executionAuthority.rawValue,
      toolchainResolver: invocation.resolver,
      alternateCommand: executionPlan.alternateCommand(invocation: CommandLine.arguments),
      commandElapsedNanoseconds: timing.commandElapsedNanoseconds,
      dependencyPreparationNanoseconds: timing.dependencyPreparationNanoseconds,
      dependencyRestoreNanoseconds: timing.dependencyRestoreNanoseconds,
      processExecutionNanoseconds: timing.processExecutionNanoseconds,
      requestId: requestId,
      runnerKind: "auto",
      succeeded: output.isSuccess,
      exitCode: output.exitStatus.exitCode,
      signal: output.exitStatus.signal,
      stdoutBytes: output.stdout.count,
      stderrBytes: output.stderr.count,
      processIdentifier: output.processIdentifier,
      processOutcome: VaporizeTestProcessOutcome(
        succeeded: output.isSuccess,
        exitCode: output.exitStatus.exitCode,
        signal: output.exitStatus.signal
      ),
      testAssertionOutcome: VaporizeTestOutputClassifier.assertionOutcome(
        stdout: output.stdout,
        stderr: output.stderr
      ),
      issueSinkState: ingestion.state,
      issueSinkPath: preservesIssueSink ? issueSinkURL.path : nil,
      issueIngestionError: ingestion.error,
      issueEvents: ingestion.events
    )
    if let recorder = VaporizeCoreExecutionInstrumentation.current {
      recorder.retain(receipt)
    } else {
      try emitReceiptIfRequested(receipt)
    }

    guard ingestion.state != .malformed else {
      throw ValidationError(
        VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeTestIssueEvidenceWasMalformed
      )
    }
    guard output.isSuccess else {
      if let exitCode = output.exitStatus.exitCode {
        throw ExitCode(Int32(exitCode))
      }
      throw ExitCode.failure
    }
  }

  func testIssueSinkURL(requestId: String) -> URL {
    if let receiptPath, !receiptPath.isEmpty {
      return absoluteURL(for: receiptPath).appendingPathExtension("issues.jsonl")
    }
    return FileManager.default.temporaryDirectory
      .appendingPathComponent("vaporize-test-issue-events", isDirectory: true)
      .appendingPathComponent("\(requestId).jsonl")
  }

  private func prepareTestIssueSink(at url: URL) throws {
    guard FileManager.default.fileExists(atPath: url.path) else { return }
    let values = try url.resourceValues(forKeys: [.isDirectoryKey])
    guard values.isDirectory != true else {
      throw ValidationError(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeTestIssueSinkPathIs, ["\(url.path)"]))
    }
    try FileManager.default.removeItem(at: url)
  }

  private func runSwiftPackage(arguments: [String]) async throws {
    try await validateSelectedSwiftCompatibility(arguments: arguments)
    let invocation = try swiftCommandInvocation(arguments: arguments)
    let plan = try mode.flatMap { try coreExecutionPlan(for: $0) }
    try await runExecutable(
      executable: invocation.executable,
      arguments: invocation.arguments,
      sourceTag: "vaporize-swift-package",
      environment: swiftCommandEnvironment(),
      additionalTags: plan.map {
        [
          "operation": $0.operation.rawValue,
          "executionAuthority": $0.executionAuthority.rawValue,
          "toolchainResolver": invocation.resolver,
        ]
      } ?? [:]
    )
  }

  func swiftCommandInvocation(arguments: [String]) throws -> ToolchainInvocation {
    switch try selectedSwiftToolchainSource() {
    case .defaultSwift:
      return ToolchainInvocation(
        executable: .name("swift"),
        arguments: arguments,
        executableRef: "name:swift",
        resolver: "default-swift"
      )
    #if os(macOS)
      case .xcode:
        return ToolchainInvocation(
          executable: .path("/usr/bin/xcrun"),
          arguments: ["swift"] + arguments,
          executableRef: "path:/usr/bin/xcrun",
          resolver: "xcrun-xcode-select"
        )
    #endif
    }
  }

  func swiftCommandEnvironment() -> [String: String]? {
    var environment: [String: String] = [:]
    if usesIsolatedSwiftPMWorkspace {
      // The isolated workspace must consume the same local upstreams as the
      // source package, rather than resolve older remote pins.
      environment["SWIFTPM_USE_LOCAL_DEPS"] = "1"
    }
    #if os(macOS)
      if let source = try? selectedSwiftToolchainSource(), source == .xcode {
        environment.merge(developerDirectoryEnvironment() ?? [:]) { _, new in new }
      }
    #endif
    return environment.isEmpty ? nil : environment
  }

  private func validateSelectedSwiftCompatibility(arguments: [String]) async throws {
    guard let packagePath = Self.swiftPackagePath(in: arguments),
      let requiredVersion = try Self.swiftToolsVersion(packagePath: packagePath)
    else { return }

    let invocation = try swiftCommandInvocation(arguments: ["--version"])
    let command = CommandSpec(
      executable: invocation.executable,
      args: invocation.arguments,
      env: .inherit(updating: swiftCommandEnvironment()),
      logOptions: .init(
        exposure: .none,
        tags: [
          "source": "vaporize-swift-toolchain-preflight",
          "canonicalSource": "vaporize-swift-toolchain-preflight",
          "tool": "swift",
          "toolchainResolver": invocation.resolver,
        ]
      ),
      requestId: "vaporize-swift-toolchain-preflight-\(UUID().uuidString)",
      runnerKind: .auto,
      streamingMode: .buffered
    )
    try command.validateOrThrow()

    let output = try await RunnerControllerFactory.run(command: command)
    let versionOutput =
      (String(data: output.stdout, encoding: .utf8) ?? "")
      + (String(data: output.stderr, encoding: .utf8) ?? "")
    guard output.isSuccess else {
      throw ValidationError(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeCouldNotResolveSwiftVia,
          ["\(invocation.executableRef)", "\(versionOutput)"])
      )
    }
    guard let actualVersion = Self.swiftCompilerVersion(from: versionOutput) else {
      throw ValidationError(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeCouldNotParseXcodeSelected,
          ["\(versionOutput)"]))
    }
    guard actualVersion >= requiredVersion else {
      throw ValidationError(
        vaporizeCopyFill(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeResolvedSwiftA1FromA2,
          [
            "\(actualVersion)", "\(invocation.resolver)", "\(packagePath)", "\(requiredVersion)",
            "\(requiredVersion)",
          ])
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
    environment: [String: String]? = nil,
    additionalTags: [String: String] = [:]
  ) async throws {
    var shell = CommonShell()
    var tags = ["source": sourceTag, "level": "L1"]
    tags.merge(additionalTags) { _, new in new }
    shell.logOptions = .init(
      exposure: .summary,
      tags: tags
    )
    let output = try await measureCoreProcess {
      try await shell.run(
        host: .direct,
        executable: executable,
        arguments: arguments,
        environment: environment,
        runnerKind: .auto
      )
    }
    guard !output.isEmpty else { return }
    print(output, terminator: output.hasSuffix("\n") ? "" : "\n")
  }

  private func measureCoreProcess<Result>(
    _ operation: () async throws -> Result
  ) async rethrows -> Result {
    if let recorder = VaporizeCoreExecutionInstrumentation.current {
      return try await recorder.measure(.processExecution, operation: operation)
    }
    return try await operation()
  }
}

func vaporizeInstalledAppPath(destination: String, product: String) -> String {
  URL(fileURLWithPath: destination, isDirectory: true)
    .appendingPathComponent("\(product).app", isDirectory: true)
    .path
}

struct SwiftToolchainVersion: Comparable, CustomStringConvertible, Equatable, Sendable {
  var major: Int
  var minor: Int
  var patch: Int

  init?(_ rawValue: String) {
    let parts =
      rawValue
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

enum VaporizeInvocation {
  static func executablePath(
    arguments: [String] = CommandLine.arguments,
    currentDirectory: String = FileManager.default.currentDirectoryPath,
    environmentPath: String? = ProcessInfo.processInfo.environment["PATH"]
  ) -> String? {
    guard let executable = arguments.first, !executable.isEmpty else { return nil }

    if executable.contains("/") {
      return URL(
        fileURLWithPath: executable,
        relativeTo: URL(fileURLWithPath: currentDirectory, isDirectory: true)
      ).standardizedFileURL.path
    }

    for directory in (environmentPath ?? "").split(separator: ":", omittingEmptySubsequences: false)
    {
      let baseDirectory = directory.isEmpty ? currentDirectory : String(directory)
      let candidate = URL(fileURLWithPath: baseDirectory, isDirectory: true)
        .appendingPathComponent(executable)
        .standardizedFileURL.path
      if FileManager.default.isExecutableFile(atPath: candidate) {
        return candidate
      }
    }

    return Bundle.main.executableURL?.standardizedFileURL.path
  }
}

#if os(macOS)
  struct ToolchainSelectionRequest: Equatable {
    enum Provider: String, CaseIterable, Equatable {
      case xcode
    }

    enum Operation: Equatable {
      case xcodeSelect(XcodeSelectionRequest)
    }

    var operation: Operation

    init(arguments rawArguments: [String]) throws {
      var tokens = rawArguments
      while tokens.first == "--" {
        tokens.removeFirst()
      }
      guard let rawProvider = tokens.first,
        let provider = Provider(rawValue: rawProvider)
      else {
        throw ValidationError(
          vaporizeCopyFill(
            VaporizeCLICopy_v000_000_001.CLI.vaporizeToolchainSelectionRequiresAProviderCompiled,
            ["`xcode`"])
        )
      }
      tokens.removeFirst()
      while tokens.first == "--" {
        tokens.removeFirst()
      }

      switch provider {
      case .xcode:
        guard tokens.first == "select" else {
          throw ValidationError(
            VaporizeCLICopy_v000_000_001.CLI.vaporizeToolchainSelectionXcodeOwnsOnlyThe
          )
        }
        tokens.removeFirst()
        operation = .xcodeSelect(try XcodeSelectionRequest(arguments: tokens))
      }
    }
  }

  struct XcodeSelectionRequest: Equatable {
    var arguments: [String]

    init(arguments rawArguments: [String]) throws {
      var tokens = rawArguments
      while tokens.first == "--" {
        tokens.removeFirst()
      }

      let singleArgumentOperations: Set<String> = [
        "--print-path", "-p", "--reset", "-r", "--help", "-h",
      ]
      let isSingleArgumentOperation =
        tokens.count == 1
        && singleArgumentOperations.contains(tokens[0])
      let isSwitchOperation =
        tokens.count == 2
        && ["--switch", "-s"].contains(tokens[0])
        && !tokens[1].isEmpty
      guard isSingleArgumentOperation || isSwitchOperation else {
        throw ValidationError(
          VaporizeCLICopy_v000_000_001.CLI.vaporizeToolchainSelectionXcodeAcceptsSelectionState
        )
      }
      self.arguments = tokens
    }

    func invocation() -> ToolchainInvocation {
      return ToolchainInvocation(
        executable: .path("/usr/bin/xcode-select"),
        arguments: arguments,
        executableRef: "path:/usr/bin/xcode-select",
        resolver: "xcode-select"
      )
    }
  }
#endif

struct ToolchainInvocation {
  var executable: Executable
  var arguments: [String]
  var executableRef: String
  var resolver: String
}

enum VaporizeCLIActionability {
  static let policyRef =
    "private/universal/substrate/collectives/spaces-universal/private/universal/kura-spaces/policies/cli-error-actionability/v0.1.0/cli-error-actionability.policy.su.json"
  static let procedureRef =
    "private/universal/substrate/collectives/spaces-universal/private/universal/kura-spaces/operating-protocols/cli-error-actionability/v0.1.0/cli-error-actionability.operating-protocol.su.json"
  static let digikomaRef =
    "private/universal/substrate/collectives/spaces-universal/private/universal/kura-spaces/digikoma/specs/digikoma-cli-error-triage.spec.json"
  static let digikomaPackagePath =
    "private/universal/substrate/collectives/kura-org/private/universal/domain/tooling/digikoma/cli-error-triage.digikoma.clia"

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
    return
      "vaporize.cli@wrkstrm-core.clia.sh run --package-path \(digikomaPackagePath) --product cli-error-triage.digikoma@kura-org.clia.sh --configuration debug -- --error-file <path-to-full-error.txt> --command \(originalCommand) --working-directory <repo-root>"
  }

  private static func productValidationDigikomaCommand(product: String) -> String {
    let originalCommand = shellSingleQuoted(
      "vaporize.cli@wrkstrm-core.clia.sh run --product \(product)"
    )
    return
      "vaporize.cli@wrkstrm-core.clia.sh run --package-path \(digikomaPackagePath) --product cli-error-triage.digikoma@kura-org.clia.sh --configuration debug -- --error-file <path-to-full-error.txt> --command \(originalCommand) --working-directory <repo-root>"
  }

  private static func shellSingleQuoted(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "'\"'\"'"))'"
  }
}

enum JSONValidation {
  static func validate(data: Data, path: String, requestId: String) throws -> JSONValidationReceipt
  {
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

struct ToolchainSelectionReceipt: Codable, Equatable {
  var schemaVersion = "0.1.0"
  var receiptKind = "vaporize-toolchain-selection"
  var provider: String
  var operation: String
  var arguments: [String]
  var workingDirectory: String
  var requestId: String
  var runnerKind: String
  var executableRef: String
  var resolver: String
  var outputCapture: String
  var succeeded: Bool
  var exitCode: Int?
  var signal: Int?
  var stdoutBytes: Int?
  var stderrBytes: Int?
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
