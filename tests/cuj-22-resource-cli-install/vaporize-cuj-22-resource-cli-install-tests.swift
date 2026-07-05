import ArgumentParser
import Foundation
import Testing
import VaporizeTestSupport

@testable import VaporizeCLI

@Suite(.serialized)
struct VaporizeCUJ22ResourceCLIInstallTests {
  @Test("cuj-22 proving ground manifest covers installed resource simulations")
  func provingGroundManifestCoversResourceSimulationScenarios() throws {
    let manifest = Self.provingGroundManifest

    #expect(manifest.kind == "simulation-proving-ground-test")
    #expect(manifest.slug == "vaporize-cuj-22-resource-cli-install")
    #expect(manifest.scenarios.map(\.slug) == [
      "processed-text-resource",
      "copied-directory-resource",
      "processed-json-resource",
      "processed-byte-count-resource",
      "stale-resource-reinstall",
      "checked-in-resource-vault-cli",
      "legacy-resource-cli-product-gate",
    ])
    #expect(manifest.scenarios.map(\.fixtureKind) == [
      "generated-swiftpm-cli",
      "generated-swiftpm-cli",
      "generated-swiftpm-cli",
      "generated-swiftpm-cli",
      "generated-swiftpm-cli",
      "checked-in-swiftpm-cli",
      "existing-swiftpm-cli",
    ])
    #expect(manifest.scenarios.allSatisfy { !$0.isolationRequirements.isEmpty })
    #expect(manifest.scenarios.allSatisfy { !$0.cleanupRequirements.isEmpty })

    let receipts = manifest.scenarios.map { scenario in
      simulatedReceipt(for: scenario, status: "pass")
    }
    let audit = VaporizeSimulationProvingGroundCoverageGate.audit(
      manifest: manifest,
      receipts: receipts
    )

    #expect(audit.coverageStatus == "pass")
    #expect(audit.requiredScenarioSlugs == manifest.scenarios.map(\.slug).sorted())
    #expect(audit.uncoveredScenarioSlugs.isEmpty)
    #expect(audit.unknownScenarioSlugs.isEmpty)
    #expect(audit.failingScenarioSlugs.isEmpty)

    let missingAudit = VaporizeSimulationProvingGroundCoverageGate.audit(
      manifest: manifest,
      receipts: Array(receipts.dropLast())
    )
    #expect(missingAudit.coverageStatus == "fail")
    #expect(missingAudit.uncoveredScenarioSlugs == ["legacy-resource-cli-product-gate"])
  }

  @Test("cuj-22 proving grounds installs processed text resources")
  func installedCLIWithProcessedResourcesRunsAwayFromBuildProducts() async throws {
    let scenario = Self.scenario(slug: "processed-text-resource")
    let fixture = try makeResourceProbePackage(
      mode: .processedDirectory,
      contentKind: .text,
      payload: "process-ok"
    )
    defer { fixture.cleanup() }

    let receipt = try await installAndRunAwayFromBuildProducts(fixture, scenario: scenario)

    #expect(receipt.status == "pass", "stderr: \(receipt.stderr)")
    #expect(receipt.exitCode == 0, "stderr: \(receipt.stderr)")
    #expect(receipt.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "resource:process-ok")
    #expect(receipt.buildProductsHiddenDuringExecution)
    #expect(receipt.installedResourceBundleNames.isEmpty == false)
  }

  @Test("cuj-22 proving grounds installs copied resource directories")
  func installedCLIWithCopiedResourceDirectoryRunsAwayFromBuildProducts() async throws {
    let scenario = Self.scenario(slug: "copied-directory-resource")
    let fixture = try makeResourceProbePackage(
      mode: .copiedDirectory,
      contentKind: .text,
      payload: "copy-ok"
    )
    defer { fixture.cleanup() }

    let receipt = try await installAndRunAwayFromBuildProducts(fixture, scenario: scenario)

    #expect(receipt.status == "pass", "stderr: \(receipt.stderr)")
    #expect(receipt.exitCode == 0, "stderr: \(receipt.stderr)")
    #expect(receipt.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "resource:copy-ok")
    #expect(receipt.buildProductsHiddenDuringExecution)
    #expect(receipt.installedResourceBundleNames.isEmpty == false)
  }

  @Test("cuj-22 proving grounds installs decoded json resources")
  func installedCLIWithDecodedJSONResourceRunsAwayFromBuildProducts() async throws {
    let scenario = Self.scenario(slug: "processed-json-resource")
    let fixture = try makeResourceProbePackage(
      mode: .processedDirectory,
      contentKind: .json,
      payload: "json-ok"
    )
    defer { fixture.cleanup() }

    let receipt = try await installAndRunAwayFromBuildProducts(fixture, scenario: scenario)

    #expect(receipt.status == "pass", "stderr: \(receipt.stderr)")
    #expect(receipt.exitCode == 0, "stderr: \(receipt.stderr)")
    #expect(receipt.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "json:json-ok:7")
    #expect(receipt.buildProductsHiddenDuringExecution)
    #expect(receipt.installedResourceBundleNames.isEmpty == false)
  }

  @Test("cuj-22 proving grounds installs larger byte-count resources")
  func installedCLIWithLargerResourceRunsAwayFromBuildProducts() async throws {
    let scenario = Self.scenario(slug: "processed-byte-count-resource")
    let payload = String(repeating: "0123456789abcdef", count: 1024)
    let fixture = try makeResourceProbePackage(
      mode: .processedDirectory,
      contentKind: .byteCount,
      payload: payload
    )
    defer { fixture.cleanup() }

    let receipt = try await installAndRunAwayFromBuildProducts(fixture, scenario: scenario)

    #expect(receipt.status == "pass", "stderr: \(receipt.stderr)")
    #expect(receipt.exitCode == 0, "stderr: \(receipt.stderr)")
    #expect(receipt.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "bytes:16384")
    #expect(receipt.buildProductsHiddenDuringExecution)
    #expect(receipt.installedResourceBundleNames.isEmpty == false)
  }

  @Test("cuj-22 proving grounds replaces stale installed resource bundles")
  func reinstallReplacesStaleInstalledResourceBundle() async throws {
    let scenario = Self.scenario(slug: "stale-resource-reinstall")
    let fixture = try makeResourceProbePackage(
      mode: .processedDirectory,
      contentKind: .text,
      payload: "stale"
    )
    defer { fixture.cleanup() }

    let staleReceipt = try await installAndRunAwayFromBuildProducts(fixture, scenario: scenario)
    #expect(staleReceipt.status == "fail", "first run should prove the stale payload before refresh")
    #expect(staleReceipt.exitCode == 0, "stderr: \(staleReceipt.stderr)")
    #expect(staleReceipt.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "resource:stale")

    try fixture.writePayload("fresh")

    let freshReceipt = try await installAndRunAwayFromBuildProducts(fixture, scenario: scenario)
    #expect(freshReceipt.status == "pass", "stderr: \(freshReceipt.stderr)")
    #expect(freshReceipt.exitCode == 0, "stderr: \(freshReceipt.stderr)")
    #expect(freshReceipt.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "resource:fresh")
    #expect(freshReceipt.installedResourceBundleNames == staleReceipt.installedResourceBundleNames)
  }

  @Test("cuj-22 proving grounds installs a checked-in resource vault cli")
  func installedCheckedInResourceVaultCLIRunsAwayFromBuildProducts() async throws {
    let scenario = Self.scenario(slug: "checked-in-resource-vault-cli")
    let fixture = try CheckedInResourceVaultFixture(packageRoot: Self.resourceVaultPackageRoot())
    defer { fixture.cleanupInstalledArtifacts() }

    let receipt = try await installAndRunCheckedInResourceVault(fixture, scenario: scenario)

    #expect(receipt.status == "pass", "stderr: \(receipt.stderr)")
    #expect(receipt.exitCode == 0, "stderr: \(receipt.stderr)")
    #expect(
      receipt.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        == "vault:resource-vault:2:8:installed-vault-ok:processed-text,copied-payload"
    )
    #expect(receipt.buildProductsHiddenDuringExecution)
    #expect(receipt.installedResourceBundleNames.isEmpty == false)
  }

  @Test("cuj-22 proving grounds records legacy resource cli product gates")
  func legacyResourceCLIProductGateIsCaptured() async throws {
    let scenario = Self.scenario(slug: "legacy-resource-cli-product-gate")
    let probe = try LegacyResourceCLIProbe.zshift(from: Self.wrkstrmCoreRoot())

    let receipt = try await captureLegacyResourceCLIProductGate(probe, scenario: scenario)

    #expect(receipt.status == "pass", "stderr: \(receipt.stderr)")
    #expect(receipt.exitCode == 0, "stderr: \(receipt.stderr)")
    #expect(receipt.stderr.contains("vaporize product validation failed"))
    #expect(receipt.stderr.contains("noncanonical CLI product name 'zshift@wrkstrm-core.clia.sh'"))
    #expect(receipt.stderr.contains("suggested 'zshift.cli@wrkstrm-core.clia.sh'"))
    #expect(receipt.installedResourceBundleNames.isEmpty)
  }

  private static var provingGroundManifest: VaporizeSimulationProvingGroundManifest {
    VaporizeSimulationProvingGroundManifest(
      slug: "vaporize-cuj-22-resource-cli-install",
      title: "vaporize cuj-22 resource cli install simulations",
      owningToolRef: "tool://wrkstrm-core/vaporize.cli@wrkstrm-core.clia.sh",
      scenarios: [
        VaporizeSimulationProvingGroundScenario(
          slug: "processed-text-resource",
          title: "processed text resource",
          fixtureKind: "generated-swiftpm-cli",
          resourceMode: "processed-directory",
          expectedStdout: "resource:process-ok",
          isolationRequirements: Self.isolationRequirements,
          cleanupRequirements: Self.cleanupRequirements,
          proofCommandRefs: Self.proofCommandRefs
        ),
        VaporizeSimulationProvingGroundScenario(
          slug: "copied-directory-resource",
          title: "copied resource directory",
          fixtureKind: "generated-swiftpm-cli",
          resourceMode: "copied-directory",
          expectedStdout: "resource:copy-ok",
          isolationRequirements: Self.isolationRequirements,
          cleanupRequirements: Self.cleanupRequirements,
          proofCommandRefs: Self.proofCommandRefs
        ),
        VaporizeSimulationProvingGroundScenario(
          slug: "processed-json-resource",
          title: "processed json resource decode",
          fixtureKind: "generated-swiftpm-cli",
          resourceMode: "processed-directory",
          expectedStdout: "json:json-ok:7",
          isolationRequirements: Self.isolationRequirements,
          cleanupRequirements: Self.cleanupRequirements,
          proofCommandRefs: Self.proofCommandRefs
        ),
        VaporizeSimulationProvingGroundScenario(
          slug: "processed-byte-count-resource",
          title: "processed byte-count resource",
          fixtureKind: "generated-swiftpm-cli",
          resourceMode: "processed-directory",
          expectedStdout: "bytes:16384",
          isolationRequirements: Self.isolationRequirements,
          cleanupRequirements: Self.cleanupRequirements,
          proofCommandRefs: Self.proofCommandRefs
        ),
        VaporizeSimulationProvingGroundScenario(
          slug: "stale-resource-reinstall",
          title: "stale resource bundle replacement",
          fixtureKind: "generated-swiftpm-cli",
          resourceMode: "processed-directory",
          expectedStdout: "resource:fresh",
          isolationRequirements: Self.isolationRequirements,
          cleanupRequirements: Self.cleanupRequirements,
          proofCommandRefs: Self.proofCommandRefs
        ),
        VaporizeSimulationProvingGroundScenario(
          slug: "checked-in-resource-vault-cli",
          title: "checked-in resource vault cli",
          fixtureKind: "checked-in-swiftpm-cli",
          resourceMode: "copied-nested-resource-vault",
          expectedStdout: "vault:resource-vault:2:8:installed-vault-ok:processed-text,copied-payload",
          isolationRequirements: Self.resourceVaultIsolationRequirements,
          cleanupRequirements: Self.resourceVaultCleanupRequirements,
          proofCommandRefs: Self.resourceVaultProofCommandRefs
        ),
        VaporizeSimulationProvingGroundScenario(
          slug: "legacy-resource-cli-product-gate",
          title: "legacy resource cli product gate",
          fixtureKind: "existing-swiftpm-cli",
          resourceMode: "processed-directory",
          expectedStdout: "noncanonical CLI product name",
          isolationRequirements: Self.legacyResourceCLIIsolationRequirements,
          cleanupRequirements: Self.legacyResourceCLICleanupRequirements,
          proofCommandRefs: Self.legacyResourceCLIProofCommandRefs
        ),
      ],
      metadata: [
        "cuj": "22",
        "simulationFamily": "swiftpm-cli-resource-install",
      ]
    )
  }

  private static var isolationRequirements: [String] {
    [
      "use a temporary generated swiftpm package",
      "run installed executable from a temporary directory",
      "hide package .build before executable launch",
    ]
  }

  private static var cleanupRequirements: [String] {
    [
      "remove installed executable",
      "remove installed resource bundles",
      "remove installed metadata plist",
      "remove temporary package root",
    ]
  }

  private static var proofCommandRefs: [String] {
    [
      "vaporize install --package-path <fixture> --product <generated-product> --configuration debug",
    ]
  }

  private static var resourceVaultIsolationRequirements: [String] {
    [
      "use the checked-in lowercase proving-ground resource-vault package",
      "run installed executable from a temporary directory",
      "hide package .build before executable launch",
    ]
  }

  private static var resourceVaultCleanupRequirements: [String] {
    [
      "remove installed executable",
      "remove installed resource bundles",
      "remove installed metadata plist",
      "preserve checked-in proving-ground source files",
    ]
  }

  private static var resourceVaultProofCommandRefs: [String] {
    [
      "vaporize install --package-path tests/proving-grounds/resource-vault-cli --product resource-vault.cli@vaporize-tests.clia.sh --configuration debug",
      "~/.swiftpm/bin/resource-vault.cli@vaporize-tests.clia.sh catalog",
    ]
  }

  private static var legacyResourceCLIIsolationRequirements: [String] {
    [
      "use an existing resource-bearing swiftpm cli package",
      "stop at vaporize product validation before swiftpm build",
      "do not mutate installed products",
    ]
  }

  private static var legacyResourceCLICleanupRequirements: [String] {
    [
      "no installed executable is created",
      "no installed resource bundle is created",
      "no installed metadata sidecar is created",
    ]
  }

  private static var legacyResourceCLIProofCommandRefs: [String] {
    [
      "vaporize install --package-path private/universal/domains/tooling/spm/configs/zshift --product zshift@wrkstrm-core.clia.sh --configuration debug",
    ]
  }

  private static func scenario(slug: String) -> VaporizeSimulationProvingGroundScenario {
    provingGroundManifest.scenarios.first { $0.slug == slug }!
  }

  private static func resourceVaultPackageRoot() throws -> URL {
    try vaporizePackageRoot()
      .appendingPathComponent("tests", isDirectory: true)
      .appendingPathComponent("proving-grounds", isDirectory: true)
      .appendingPathComponent("resource-vault-cli", isDirectory: true)
  }

  private static func vaporizePackageRoot() throws -> URL {
    try ancestor(named: "vaporize@wrkstrm-core.cli", from: URL(fileURLWithPath: #filePath))
  }

  private static func wrkstrmCoreRoot() throws -> URL {
    try ancestor(named: "wrkstrm-core", from: URL(fileURLWithPath: #filePath))
  }

  private static func ancestor(named name: String, from start: URL) throws -> URL {
    var candidate = start
    while candidate.path != "/" {
      if candidate.lastPathComponent == name {
        return candidate
      }
      candidate.deleteLastPathComponent()
    }
    throw ProvingGroundPathError.missingAncestor(name)
  }

  private func installAndRunAwayFromBuildProducts(
    _ fixture: ResourceProbeFixture,
    scenario: VaporizeSimulationProvingGroundScenario
  ) async throws -> VaporizeSimulationProvingGroundReceipt {
    var command = try VaporizeCLI.parse([
      "install",
      "--package-path", fixture.packageRoot.path,
      "--product", fixture.product,
      "--configuration", "debug",
    ])
    try await command.run()

    let installedResourceBundleNames = fixture.installedResourceBundleNames()
    let output = try fixture.runInstalledProductAwayFromBuildProducts()
    let trimmedStdout = output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let status = output.exitCode == 0 && trimmedStdout == scenario.expectedStdout ? "pass" : "fail"

    return VaporizeSimulationProvingGroundReceipt(
      provingGroundSlug: Self.provingGroundManifest.slug,
      scenarioSlug: scenario.slug,
      fixtureKind: scenario.fixtureKind,
      resourceMode: scenario.resourceMode,
      product: fixture.product,
      installedExecutablePath: fixture.installedExecutableURL().path,
      installedResourceBundleNames: installedResourceBundleNames,
      buildProductsHiddenDuringExecution: true,
      exitCode: output.exitCode,
      stdout: output.stdout,
      stderr: output.stderr,
      status: status
    )
  }

  private func installAndRunCheckedInResourceVault(
    _ fixture: CheckedInResourceVaultFixture,
    scenario: VaporizeSimulationProvingGroundScenario
  ) async throws -> VaporizeSimulationProvingGroundReceipt {
    var command = try VaporizeCLI.parse([
      "install",
      "--package-path", fixture.packageRoot.path,
      "--product", fixture.product,
      "--configuration", "debug",
    ])
    try await command.run()

    let installedResourceBundleNames = fixture.installedResourceBundleNames()
    let output = try fixture.runInstalledProductAwayFromBuildProducts()
    let trimmedStdout = output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let status = output.exitCode == 0 && trimmedStdout == scenario.expectedStdout ? "pass" : "fail"

    return VaporizeSimulationProvingGroundReceipt(
      provingGroundSlug: Self.provingGroundManifest.slug,
      scenarioSlug: scenario.slug,
      fixtureKind: scenario.fixtureKind,
      resourceMode: scenario.resourceMode,
      product: fixture.product,
      installedExecutablePath: fixture.installedExecutableURL().path,
      installedResourceBundleNames: installedResourceBundleNames,
      buildProductsHiddenDuringExecution: true,
      exitCode: output.exitCode,
      stdout: output.stdout,
      stderr: output.stderr,
      status: status
    )
  }

  private func captureLegacyResourceCLIProductGate(
    _ probe: LegacyResourceCLIProbe,
    scenario: VaporizeSimulationProvingGroundScenario
  ) async throws -> VaporizeSimulationProvingGroundReceipt {
    var stderr = ""
    var status = "fail"

    var command = try VaporizeCLI.parse([
      "install",
      "--package-path", probe.packageRoot.path,
      "--product", probe.product,
      "--configuration", "debug",
    ])

    do {
      try await command.run()
      stderr = "expected vaporize product validation to reject \(probe.product)"
    } catch {
      stderr = String(describing: error)
      if probe.expectedErrorSubstrings.allSatisfy({ stderr.contains($0) }) {
        status = "pass"
      }
    }

    return VaporizeSimulationProvingGroundReceipt(
      provingGroundSlug: Self.provingGroundManifest.slug,
      scenarioSlug: scenario.slug,
      fixtureKind: scenario.fixtureKind,
      resourceMode: scenario.resourceMode,
      product: probe.product,
      installedExecutablePath: "",
      installedResourceBundleNames: [],
      buildProductsHiddenDuringExecution: false,
      exitCode: status == "pass" ? 0 : 1,
      stdout: "",
      stderr: stderr,
      status: status
    )
  }

  private func makeResourceProbePackage(
    mode: ResourceMode,
    contentKind: ResourceContentKind,
    payload: String
  ) throws -> ResourceProbeFixture {
    let fileManager = FileManager.default
    let suffix = UUID().uuidString.lowercased().prefix(8)
    let product = "resource-probe-\(suffix).cli@vaporize-tests.clia.sh"
    let packageRoot = fileManager.temporaryDirectory
      .appendingPathComponent("vaporize-resource-cli-\(UUID().uuidString.lowercased())", isDirectory: true)
    let sourceRoot = packageRoot.appendingPathComponent("sources/resourceprobecli", isDirectory: true)
    let resourceRoot = sourceRoot.appendingPathComponent("resources", isDirectory: true)

    try fileManager.createDirectory(at: resourceRoot, withIntermediateDirectories: true)

    let fixture = ResourceProbeFixture(
      product: product,
      packageRoot: packageRoot,
      sourceRoot: sourceRoot,
      resourceRoot: resourceRoot,
      mode: mode,
      contentKind: contentKind
    )

    try fixture.writeManifest()
    try fixture.writeMain()
    try fixture.writePayload(payload)

    return fixture
  }
}

private enum ResourceMode {
  case processedDirectory
  case copiedDirectory

  var manifestResourceRule: String {
    switch self {
    case .processedDirectory:
      return #".process("resources")"#
    case .copiedDirectory:
      return #".copy("resources")"#
    }
  }

  func bundleLookupArguments(for contentKind: ResourceContentKind) -> String {
    switch self {
    case .processedDirectory:
      return #"forResource: "probe", withExtension: "\#(contentKind.fileExtension)""#
    case .copiedDirectory:
      return #"forResource: "probe", withExtension: "\#(contentKind.fileExtension)", subdirectory: "resources""#
    }
  }
}

private enum ResourceContentKind {
  case text
  case json
  case byteCount

  var fileExtension: String {
    switch self {
    case .text:
      return "txt"
    case .json:
      return "json"
    case .byteCount:
      return "dat"
    }
  }

  func resourcePayload(_ marker: String) -> String {
    switch self {
    case .text:
      return "\(marker)\n"
    case .json:
      return """
      {"message":"\(marker)","count":7}
      """
    case .byteCount:
      return marker
    }
  }

  func mainSource(lookupArguments: String) -> String {
    switch self {
    case .text:
      return #"""
      import Darwin
      import Foundation

      guard let url = Bundle.module.url($LOOKUP_ARGUMENTS) else {
        fputs("missing resource URL\n", stderr)
        exit(42)
      }

      do {
        let text = try String(contentsOf: url, encoding: .utf8)
        print("resource:\(text.trimmingCharacters(in: .whitespacesAndNewlines))")
      } catch {
        fputs("resource read failed: \(error)\n", stderr)
        exit(43)
      }
      """#.replacingOccurrences(of: "$LOOKUP_ARGUMENTS", with: lookupArguments)
    case .json:
      return #"""
      import Darwin
      import Foundation

      struct Payload: Decodable {
        var message: String
        var count: Int
      }

      guard let url = Bundle.module.url($LOOKUP_ARGUMENTS) else {
        fputs("missing resource URL\n", stderr)
        exit(42)
      }

      do {
        let data = try Data(contentsOf: url)
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        print("json:\(payload.message):\(payload.count)")
      } catch {
        fputs("resource decode failed: \(error)\n", stderr)
        exit(44)
      }
      """#.replacingOccurrences(of: "$LOOKUP_ARGUMENTS", with: lookupArguments)
    case .byteCount:
      return #"""
      import Darwin
      import Foundation

      guard let url = Bundle.module.url($LOOKUP_ARGUMENTS) else {
        fputs("missing resource URL\n", stderr)
        exit(42)
      }

      do {
        let data = try Data(contentsOf: url)
        print("bytes:\(data.count)")
      } catch {
        fputs("resource byte read failed: \(error)\n", stderr)
        exit(45)
      }
      """#.replacingOccurrences(of: "$LOOKUP_ARGUMENTS", with: lookupArguments)
    }
  }
}

private struct ResourceProbeFixture {
  var product: String
  var packageRoot: URL
  var sourceRoot: URL
  var resourceRoot: URL
  var mode: ResourceMode
  var contentKind: ResourceContentKind

  func writeManifest() throws {
    try writeText(
      """
      // swift-tools-version: 6.4
      import PackageDescription

      let package = Package(
        name: "resource-probe-package",
        platforms: [.macOS(.v15)],
        products: [
          .executable(name: "\(product)", targets: ["resourceprobecli"]),
        ],
        targets: [
          .executableTarget(
            name: "resourceprobecli",
            path: "sources/resourceprobecli",
            resources: [\(mode.manifestResourceRule)]
          ),
        ]
      )
      """,
      to: packageRoot.appendingPathComponent("Package.swift")
    )
  }

  func writeMain() throws {
    try writeText(
      contentKind.mainSource(lookupArguments: mode.bundleLookupArguments(for: contentKind)),
      to: sourceRoot.appendingPathComponent("main.swift")
    )
  }

  func writePayload(_ payload: String) throws {
    try writeText(
      contentKind.resourcePayload(payload),
      to: resourceRoot.appendingPathComponent("probe.\(contentKind.fileExtension)")
    )
  }

  func runInstalledProductAwayFromBuildProducts() throws -> ProcessOutput {
    let hiddenBuild = packageRoot.appendingPathComponent(".build-hidden-\(UUID().uuidString)", isDirectory: true)
    try moveBuildDirectory(to: hiddenBuild)
    defer { try? restoreBuildDirectory(from: hiddenBuild) }

    return try runInstalledProduct()
  }

  func runInstalledProduct() throws -> ProcessOutput {
    let process = Process()
    process.executableURL = installedExecutableURL()
    process.currentDirectoryURL = FileManager.default.temporaryDirectory

    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr

    try process.run()
    process.waitUntilExit()

    return ProcessOutput(
      exitCode: process.terminationStatus,
      stdout: String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
      stderr: String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    )
  }

  func installedExecutableURL() -> URL {
    installedBinDirectory().appendingPathComponent(product)
  }

  func installedResourceBundleNames() -> [String] {
    let fileManager = FileManager.default
    let bin = installedBinDirectory()
    return builtBundleNames()
      .filter { fileManager.fileExists(atPath: bin.appendingPathComponent($0, isDirectory: true).path) }
      .sorted()
  }

  func cleanup() {
    let fileManager = FileManager.default
    let bin = installedBinDirectory()
    try? fileManager.removeItem(at: bin.appendingPathComponent(product))
    try? fileManager.removeItem(at: bin.appendingPathComponent("\(product).metadata", isDirectory: true))

    for bundleName in builtBundleNames() {
      try? fileManager.removeItem(at: bin.appendingPathComponent(bundleName, isDirectory: true))
    }

    try? fileManager.removeItem(at: packageRoot)
  }

  private func moveBuildDirectory(to hiddenBuild: URL) throws {
    let build = packageRoot.appendingPathComponent(".build", isDirectory: true)
    if FileManager.default.fileExists(atPath: hiddenBuild.path) {
      try FileManager.default.removeItem(at: hiddenBuild)
    }
    guard FileManager.default.fileExists(atPath: build.path) else { return }
    try FileManager.default.moveItem(at: build, to: hiddenBuild)
  }

  private func restoreBuildDirectory(from hiddenBuild: URL) throws {
    let build = packageRoot.appendingPathComponent(".build", isDirectory: true)
    if FileManager.default.fileExists(atPath: build.path) {
      try FileManager.default.removeItem(at: build)
    }
    guard FileManager.default.fileExists(atPath: hiddenBuild.path) else { return }
    try FileManager.default.moveItem(at: hiddenBuild, to: build)
  }

  private func builtBundleNames() -> [String] {
    let fileManager = FileManager.default
    let buildRoot = packageRoot.appendingPathComponent(".build", isDirectory: true)
    guard let enumerator = fileManager.enumerator(
      at: buildRoot,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    var names: [String] = []
    for case let candidate as URL in enumerator where candidate.lastPathComponent.hasSuffix(".bundle") {
      names.append(candidate.lastPathComponent)
      enumerator.skipDescendants()
    }
    return names
  }

  private func installedBinDirectory() -> URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".swiftpm", isDirectory: true)
      .appendingPathComponent("bin", isDirectory: true)
  }
}

private struct CheckedInResourceVaultFixture {
  var packageRoot: URL
  let product = "resource-vault.cli@vaporize-tests.clia.sh"

  init(packageRoot: URL) throws {
    let manifest = packageRoot.appendingPathComponent("Package.swift")
    guard FileManager.default.fileExists(atPath: manifest.path) else {
      throw ProvingGroundPathError.missingPackageManifest(manifest.path)
    }
    self.packageRoot = packageRoot
  }

  func runInstalledProductAwayFromBuildProducts() throws -> ProcessOutput {
    let hiddenBuild = packageRoot.appendingPathComponent(".build-hidden-\(UUID().uuidString)", isDirectory: true)
    try moveBuildDirectory(to: hiddenBuild)
    defer { try? restoreBuildDirectory(from: hiddenBuild) }

    return try runInstalledProduct()
  }

  func runInstalledProduct() throws -> ProcessOutput {
    let process = Process()
    process.executableURL = installedExecutableURL()
    process.arguments = ["catalog"]
    process.currentDirectoryURL = FileManager.default.temporaryDirectory

    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr

    try process.run()
    process.waitUntilExit()

    return ProcessOutput(
      exitCode: process.terminationStatus,
      stdout: String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
      stderr: String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    )
  }

  func installedExecutableURL() -> URL {
    installedBinDirectory().appendingPathComponent(product)
  }

  func installedResourceBundleNames() -> [String] {
    let fileManager = FileManager.default
    let bin = installedBinDirectory()
    return builtBundleNames()
      .filter { fileManager.fileExists(atPath: bin.appendingPathComponent($0, isDirectory: true).path) }
      .sorted()
  }

  func cleanupInstalledArtifacts() {
    let fileManager = FileManager.default
    let bin = installedBinDirectory()
    try? fileManager.removeItem(at: bin.appendingPathComponent(product))
    try? fileManager.removeItem(at: bin.appendingPathComponent("\(product).metadata", isDirectory: true))

    for bundleName in builtBundleNames() {
      try? fileManager.removeItem(at: bin.appendingPathComponent(bundleName, isDirectory: true))
    }
  }

  private func moveBuildDirectory(to hiddenBuild: URL) throws {
    let build = packageRoot.appendingPathComponent(".build", isDirectory: true)
    if FileManager.default.fileExists(atPath: hiddenBuild.path) {
      try FileManager.default.removeItem(at: hiddenBuild)
    }
    guard FileManager.default.fileExists(atPath: build.path) else { return }
    try FileManager.default.moveItem(at: build, to: hiddenBuild)
  }

  private func restoreBuildDirectory(from hiddenBuild: URL) throws {
    let build = packageRoot.appendingPathComponent(".build", isDirectory: true)
    if FileManager.default.fileExists(atPath: build.path) {
      try FileManager.default.removeItem(at: build)
    }
    guard FileManager.default.fileExists(atPath: hiddenBuild.path) else { return }
    try FileManager.default.moveItem(at: hiddenBuild, to: build)
  }

  private func builtBundleNames() -> [String] {
    let fileManager = FileManager.default
    let buildRoot = packageRoot.appendingPathComponent(".build", isDirectory: true)
    guard let enumerator = fileManager.enumerator(
      at: buildRoot,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    var names: [String] = []
    for case let candidate as URL in enumerator where candidate.lastPathComponent.hasSuffix(".bundle") {
      names.append(candidate.lastPathComponent)
      enumerator.skipDescendants()
    }
    return names
  }

  private func installedBinDirectory() -> URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".swiftpm", isDirectory: true)
      .appendingPathComponent("bin", isDirectory: true)
  }
}

private struct LegacyResourceCLIProbe {
  var product: String
  var packageRoot: URL
  var expectedErrorSubstrings: [String]

  static func zshift(from wrkstrmCoreRoot: URL) throws -> LegacyResourceCLIProbe {
    let packageRoot = wrkstrmCoreRoot
      .appendingPathComponent("private", isDirectory: true)
      .appendingPathComponent("universal", isDirectory: true)
      .appendingPathComponent("domains", isDirectory: true)
      .appendingPathComponent("tooling", isDirectory: true)
      .appendingPathComponent("spm", isDirectory: true)
      .appendingPathComponent("configs", isDirectory: true)
      .appendingPathComponent("zshift", isDirectory: true)

    let manifest = packageRoot.appendingPathComponent("Package.swift")
    guard FileManager.default.fileExists(atPath: manifest.path) else {
      throw ProvingGroundPathError.missingPackageManifest(manifest.path)
    }

    return LegacyResourceCLIProbe(
      product: "zshift@wrkstrm-core.clia.sh",
      packageRoot: packageRoot,
      expectedErrorSubstrings: [
        "vaporize product validation failed",
        "noncanonical CLI product name 'zshift@wrkstrm-core.clia.sh'",
        "suggested 'zshift.cli@wrkstrm-core.clia.sh'",
      ]
    )
  }
}

private enum ProvingGroundPathError: Error, CustomStringConvertible {
  case missingAncestor(String)
  case missingPackageManifest(String)

  var description: String {
    switch self {
    case .missingAncestor(let name):
      return "missing ancestor \(name)"
    case .missingPackageManifest(let path):
      return "missing package manifest at \(path)"
    }
  }
}

private struct ProcessOutput {
  var exitCode: Int32
  var stdout: String
  var stderr: String
}

private func simulatedReceipt(
  for scenario: VaporizeSimulationProvingGroundScenario,
  status: String
) -> VaporizeSimulationProvingGroundReceipt {
  VaporizeSimulationProvingGroundReceipt(
    provingGroundSlug: "vaporize-cuj-22-resource-cli-install",
    scenarioSlug: scenario.slug,
    fixtureKind: scenario.fixtureKind,
    resourceMode: scenario.resourceMode,
    product: "simulated.cli@vaporize-tests.clia.sh",
    installedExecutablePath: "/tmp/simulated.cli@vaporize-tests.clia.sh",
    installedResourceBundleNames: ["ResourceProbeCLI_ResourceProbeCLI.bundle"],
    buildProductsHiddenDuringExecution: true,
    exitCode: status == "pass" ? 0 : 1,
    stdout: scenario.expectedStdout,
    stderr: "",
    status: status
  )
}

private func writeText(_ text: String, to url: URL) throws {
  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try text.write(to: url, atomically: true, encoding: .utf8)
}
