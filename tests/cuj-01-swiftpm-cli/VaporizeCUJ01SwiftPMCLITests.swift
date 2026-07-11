import ArgumentParser
import Foundation
import Testing

@testable import SwiftCLIInstaller
@testable import VaporizeCLI

@Test("CUJ-01 exposes the canonical Vaporize command identity")
func exposesCanonicalVaporizeCommandIdentity() {
  #expect(VaporizeCLI.configuration.commandName == "vaporize.cli@wrkstrm-core.clia.sh")
}

@Test("CUJ-01 parses SwiftPM CLI build mode")
func parsesSwiftPMCLIBuildMode() throws {
  let command = try VaporizeCLI.parse([
    "build",
    "--artifact",
    "cli",
    "--package-path",
    "/workspace/tool",
    "--product",
    "tool.cli@org.clia.sh",
    "--configuration",
    "debug",
    "--skip-install",
  ])

  #expect(command.mode == .build)
  #expect(command.artifact == .cli)
  #expect(command.packagePath == "/workspace/tool")
  #expect(command.product == "tool.cli@org.clia.sh")
  #expect(command.configuration == .debug)
  #expect(command.skipInstall)
}

@Test("CUJ-01 builds SwiftPM package build arguments")
func buildsSwiftPMPackageBuildArguments() throws {
  let command = try VaporizeCLI.parse([
    "build",
    "--artifact",
    "cli",
    "--package-path",
    "/workspace/tool",
    "--product",
    "tool.cli@org.clia.sh",
    "--configuration",
    "debug",
  ])

  #expect(try command.swiftBuildArguments() == [
    "build",
    "--package-path",
    "/workspace/tool",
    "-c",
    "debug",
    "--product",
    "tool.cli@org.clia.sh",
  ])
}

@Test("CUJ-01 rejects noncanonical SwiftPM CLI build products")
func rejectsNoncanonicalSwiftPMCLIBuildProducts() throws {
  let command = try VaporizeCLI.parse([
    "build",
    "--artifact",
    "cli",
    "--package-path",
    "/workspace/tool",
    "--product",
    "git@swift-universal.clia.sh",
    "--configuration",
    "release",
  ])

  do {
    _ = try command.swiftBuildArguments()
    Issue.record("Expected noncanonical CLI product name to throw.")
  } catch let error as ValidationError {
    let message = String(describing: error)
    #expect(message.contains("suggested 'git.cli@swift-universal.clia.sh'"))
    assertActionableVaporizeProductValidationError(message)
  } catch {
    Issue.record("Unexpected error: \(error).")
  }
}

@Test("CUJ-01 includes actionability on invalid product canary failures")
func invalidProductCanaryFailuresIncludeActionability() throws {
  let message = try productValidationMessage(for: "definitely-not-a-product")

  #expect(message.contains("expected exactly one @ separator"))
  #expect(
    message.contains(
      "vaporize.cli@wrkstrm-core.clia.sh run --product definitely-not-a-product"
    )
  )
  assertActionableVaporizeProductValidationError(message)
}

@Test("CUJ-01 parses domains mode")
func parsesSwiftPMCLIDomainsMode() throws {
  let command = try VaporizeCLI.parse(["domains", "--tools-collection", "/tmp/tools", "--format", "json"])
  #expect(command.mode == .domains)
  #expect(command.toolsCollectionPath == "/tmp/tools")
  #expect(command.vaporOutputFormat == .json)
}

@Test("CUJ-01 parses domain flag")
func parsesDomainFlagForInstallMode() throws {
  let command = try VaporizeCLI.parse([
    "install",
    "--package-path",
    "/workspace/domain/build/spm/tool",
    "--product",
    "build-tool.cli@domain.clia.sh",
    "--domain",
    "build",
  ])
  #expect(command.mode == .install)
  #expect(command.toolDomain == "build")
  #expect(command.packagePath == "/workspace/domain/build/spm/tool")
  #expect(command.product == "build-tool.cli@domain.clia.sh")
}

@Test("CUJ-01 parses installed CLI product metadata flags")
func parsesInstalledCLIProductMetadataFlags() throws {
  let command = try VaporizeCLI.parse([
    "install",
    "--artifact",
    "cli",
    "--package-path",
    "/workspace/tool",
    "--product",
    "tool.cli@org.clia.sh",
    "--product-version",
    "1.2.3",
    "--product-build",
    "42",
    "--product-build-sha",
    "abc123",
    "--product-build-date",
    "2026-07-03T00:00:00Z",
  ])

  #expect(command.mode == .install)
  #expect(command.productVersion == "1.2.3")
  #expect(command.productBuild == "42")
  #expect(command.productBuildSha == "abc123")
  #expect(command.productBuildDate == "2026-07-03T00:00:00Z")
}

@Test("CUJ-01 forwards developer directory to SwiftPM CLI operations")
func forwardsDeveloperDirectoryToSwiftPMCLIOperations() throws {
  let command = try VaporizeCLI.parse([
    "install",
    "--artifact",
    "cli",
    "--package-path",
    "/workspace/tool",
    "--product",
    "tool.cli@org.clia.sh",
    "--developer-dir",
    "/Applications/Xcode.app/Contents/Developer",
  ])

  #expect(command.developerDirectoryEnvironment() == [
    "DEVELOPER_DIR": "/Applications/Xcode.app/Contents/Developer",
  ])
}

@Test("CUJ-01 orders installed CLI candidates by inferred domain before flat bin")
func ordersInstalledCLICandidatesByInferredDomainBeforeFlatBin() throws {
  let command = try VaporizeCLI.parse([
    "run",
    "--package-path",
    "/workspace/private/universal/domain/scm/tools/savepoint.cli",
    "--product",
    "savepoint.cli@kura-org.clia.sh",
    "--skip-install",
  ])

  let candidates = command.installedCLIExecutableCandidatePaths(
    product: "savepoint.cli@kura-org.clia.sh"
  )

  #expect(candidates.contains { $0.hasSuffix("/.swiftpm/bin/domain/scm/savepoint.cli@kura-org.clia.sh") })
  #expect(candidates.last?.hasSuffix("/.swiftpm/bin/savepoint.cli@kura-org.clia.sh") == true)
}

@Test("CUJ-01 orders explicit domain candidate before flat bin")
func ordersExplicitDomainCandidateBeforeFlatBin() throws {
  let command = try VaporizeCLI.parse([
    "run",
    "--package-path",
    "/workspace/tool",
    "--product",
    "tool.cli@org.clia.sh",
    "--domain",
    "domain/scm",
    "--skip-install",
  ])

  let candidates = command.installedCLIExecutableCandidatePaths(product: "tool.cli@org.clia.sh")

  #expect(candidates.first?.hasSuffix("/.swiftpm/bin/domain/domain/scm/tool.cli@org.clia.sh") == true)
  #expect(candidates.last?.hasSuffix("/.swiftpm/bin/tool.cli@org.clia.sh") == true)
}

@Test("CUJ-01 parses self-update mode")
func parsesSelfUpdateMode() throws {
  let command = try VaporizeCLI.parse([
    "self-update",
    "--package-path",
    "/workspace/vaporize",
  ])

  #expect(command.mode == .selfUpdate)
  #expect(command.packagePath == "/workspace/vaporize")
}

@Test("CUJ-01 parses version flag")
func parsesVersionFlag() throws {
  let command = try VaporizeCLI.parse(["--version"])

  #expect(command.version)
  #expect(command.mode == nil)
}

@Test("CUJ-01 builds SwiftPM package test arguments")
func buildsSwiftPMPackageTestArguments() throws {
  let command = try VaporizeCLI.parse([
    "test",
    "--package-path",
    "/workspace/tool",
    "--configuration",
    "debug",
    "--",
    "--filter",
    "IdentityProfileType",
  ])

  #expect(command.mode == .test)
  #expect(try command.swiftTestArguments() == [
    "test",
    "--package-path",
    "/workspace/tool",
    "-c",
    "debug",
    "--filter",
    "IdentityProfileType",
  ])
}

@Test("CUJ-01 routes SwiftPM package commands through Xcode-selected Swift")
func routesSwiftPMPackageCommandsThroughXcodeSelectedSwift() {
  #expect(VaporizeCLI.xcodeSelectedSwiftArguments([
    "test",
    "--package-path",
    "/workspace/tool",
  ]) == [
    "swift",
    "test",
    "--package-path",
    "/workspace/tool",
  ])
}

@Test("CUJ-01 parses Swift tools and compiler versions for 6.4 preflight")
func parsesSwiftToolsAndCompilerVersionsForPreflight() {
  #expect(VaporizeCLI.swiftPackagePath(in: [
    "test",
    "--package-path",
    "/workspace/tool",
    "-c",
    "release",
  ]) == "/workspace/tool")
  #expect(VaporizeCLI.swiftToolsVersion(
    fromPackageManifest: "// swift-tools-version:6.4\nimport PackageDescription"
  ) == SwiftToolchainVersion("6.4"))
  #expect(VaporizeCLI.swiftCompilerVersion(
    from: "swift-driver version: 1.167 Apple Swift version 6.4 (swiftlang-6.4.0.20.104 clang-2100.3.20.102)"
  ) == SwiftToolchainVersion("6.4"))
  #expect(VaporizeCLI.swiftCompilerVersion(
    from: "Apple Swift version 6.3.2 (swift-6.3.2-RELEASE)"
  ) == SwiftToolchainVersion("6.3.2"))
  #expect(SwiftToolchainVersion("6.4")! > SwiftToolchainVersion("6.3.2")!)
}

@Test("CUJ-01 matches already installed error")
func matchesAlreadyInstalledError() {
  let message = "error: clia is already installed at /Users/rismay/.swiftpm/bin/clia"
  #expect(InstallMessageMatcher.isAlreadyInstalled(message))
}

@Test("CUJ-01 matches not installed error")
func matchesNotInstalledError() {
  let message = "Executable product `clia` was not installed."
  #expect(InstallMessageMatcher.isNotInstalled(message))
}

@Test("CUJ-01 builds Swift package install arguments")
func buildsSwiftPackageInstallArguments() {
  let installer = SwiftCLIInstaller(
    request: .init(
      packagePath: "/workspace/tool",
      product: "tool.cli@org.clia.sh",
      configuration: .release,
      forceReinstall: false
    )
  )

  #expect(installer.installArguments() == [
    "package",
    "experimental-install",
    "--package-path",
    "/workspace/tool",
    "-c",
    "release",
    "--product",
    "tool.cli@org.clia.sh",
  ])
}

@Test("CUJ-01 builds Swift package uninstall arguments")
func buildsSwiftPackageUninstallArguments() {
  let installer = SwiftCLIInstaller(
    request: .init(
      packagePath: "/workspace/tool",
      product: "tool.cli@org.clia.sh",
      configuration: .debug,
      forceReinstall: true
    )
  )

  #expect(installer.uninstallArguments() == [
    "package",
    "experimental-uninstall",
    "--package-path",
    "/workspace/tool",
    "tool.cli@org.clia.sh",
  ])
}

@Test("CUJ-01 raw experimental-install omits resource bundles and Vaporize carries them")
func rawExperimentalInstallOmitsResourceBundlesAndVaporizeCarriesThem() async throws {
  let fileManager = FileManager.default
  let root = fileManager.temporaryDirectory
    .appendingPathComponent("vaporize-cuj-01-resource-bundle", isDirectory: true)
    .appendingPathComponent(UUID().uuidString, isDirectory: true)
  let package = root.appendingPathComponent("fixture", isDirectory: true)
  let installBin = fileManager.homeDirectoryForCurrentUser
    .appendingPathComponent(".swiftpm", isDirectory: true)
    .appendingPathComponent("bin", isDirectory: true)
  let nonce = UUID().uuidString
    .lowercased()
    .replacingOccurrences(of: "-", with: "")
  let packageName = "resource-probe-\(nonce)"
  let target = "ResourceProbe\(nonce.prefix(8))CLI"
  let product = "\(packageName).cli@fixture.clia.sh"
  let installedBinary = installBin.appendingPathComponent(product)
  let installedMetadata = SwiftCLIInstaller.installedProductMetadataDirectory(
    in: installBin,
    product: product
  )
  let installedInfoPlist = SwiftCLIInstaller.installedProductInfoPlistURL(
    in: installBin,
    product: product
  )
  var cleanupBundleNames: [String] = []
  defer {
    try? fileManager.removeItem(at: root)
    try? fileManager.removeItem(at: installedBinary)
    try? fileManager.removeItem(at: installedMetadata)
    for bundleName in cleanupBundleNames {
      try? fileManager.removeItem(at: installBin.appendingPathComponent(bundleName, isDirectory: true))
    }
  }

  try writeResourceProbePackage(
    at: package,
    packageName: packageName,
    product: product,
    target: target
  )

  let directInstall = try runProcess(
    "/usr/bin/xcrun",
    [
      "swift",
      "package",
      "--package-path",
      package.path,
      "experimental-install",
      "-c",
      "release",
      "--product",
      product,
    ]
  )
  if directInstall.status != 0 {
    Issue.record("Direct experimental-install failed: \(directInstall.stderr)")
  }
  let buildProductsDirectory = try swiftPMBuildProductsDirectory(
    package: package,
    product: product
  )
  let builtBundleNames = try SwiftCLIInstaller.resourceBundlesToInstall(
    buildProductsDirectory: buildProductsDirectory
  )
  .map(\.lastPathComponent)
  cleanupBundleNames = builtBundleNames

  #expect(fileManager.fileExists(atPath: installedBinary.path))
  #expect(!builtBundleNames.isEmpty)
  #expect(try installedResourceBundles(in: installBin, matching: builtBundleNames).isEmpty)
  #expect(!fileManager.fileExists(atPath: installedInfoPlist.path))

  let hiddenBuild = package.appendingPathComponent(".build-hidden", isDirectory: true)
  try moveBuildDirectory(package: package, to: hiddenBuild)
  let directRuntime = try runProcess(installedBinary.path, [])
  #expect(directRuntime.status != 0)
  #expect(
    directRuntime.stderr.contains("resource bundle")
      || directRuntime.stderr.contains("resource_bundle_accessor")
      || directRuntime.stderr.contains("unable to find bundle")
  )
  try restoreBuildDirectory(package: package, from: hiddenBuild)

  let installer = SwiftCLIInstaller(
    request: .init(
      packagePath: package.path,
      product: product,
      configuration: .release,
      forceReinstall: true,
      productVersion: "9.8.7",
      productBuild: "123",
      productBuildSha: "abc123",
      productBuildDate: "2026-07-03T00:00:00Z",
      installerVersion: "0.1.0",
      installerBuild: "test"
    )
  )
  try await installer.run()
  #expect(fileManager.fileExists(atPath: installedBinary.path))
  #expect(try installedResourceBundles(in: installBin, matching: builtBundleNames).count == builtBundleNames.count)
  #expect(fileManager.fileExists(atPath: installedInfoPlist.path))

  let installedInfo = try readPlist(installedInfoPlist)
  #expect(installedInfo["CFBundleExecutable"] as? String == product)
  #expect(installedInfo["CFBundleShortVersionString"] as? String == "9.8.7")
  #expect(installedInfo["CFBundleVersion"] as? String == "123")
  #expect(installedInfo["VaporizeProductBuildSHA"] as? String == "abc123")
  #expect(installedInfo["VaporizeInstallerVersion"] as? String == "0.1.0")

  try moveBuildDirectory(package: package, to: hiddenBuild)
  let vaporizeRuntime = try runProcess(installedBinary.path, [])
  #expect(vaporizeRuntime.status == 0)
  #expect(vaporizeRuntime.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "resource-ok")
}

private struct ProcessResult {
  let status: Int32
  let stdout: String
  let stderr: String
}

private func runProcess(
  _ executable: String,
  _ arguments: [String],
  environment: [String: String] = [:]
) throws -> ProcessResult {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: executable)
  process.arguments = arguments
  var processEnvironment = ProcessInfo.processInfo.environment
  processEnvironment.merge(environment) { _, new in new }
  process.environment = processEnvironment

  let stdout = Pipe()
  let stderr = Pipe()
  process.standardOutput = stdout
  process.standardError = stderr

  try process.run()
  process.waitUntilExit()

  return ProcessResult(
    status: process.terminationStatus,
    stdout: String(decoding: stdout.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self),
    stderr: String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
  )
}

private func writeResourceProbePackage(
  at package: URL,
  packageName: String,
  product: String,
  target: String
) throws {
  try writeText(
    """
    // swift-tools-version: 6.4
    import PackageDescription

    let package = Package(
      name: "\(packageName)",
      platforms: [.macOS(.v15)],
      products: [
        .executable(name: "\(product)", targets: ["\(target)"]),
      ],
      targets: [
        .executableTarget(
          name: "\(target)",
          path: "Sources/\(target)",
          resources: [
            .process("Resources"),
          ]
        ),
      ]
    )
    """,
    to: package.appendingPathComponent("Package.swift")
  )
  try writeText(
    """
    import Foundation

    let url = Bundle.module.url(forResource: "message", withExtension: "txt")!
    let text = try String(contentsOf: url, encoding: .utf8)
    print(text.trimmingCharacters(in: .whitespacesAndNewlines))
    """,
    to: package.appendingPathComponent("Sources/\(target)/main.swift")
  )
  try writeText(
    "resource-ok\n",
    to: package.appendingPathComponent("Sources/\(target)/Resources/message.txt")
  )
}

private func swiftPMBuildProductsDirectory(package: URL, product: String) throws -> URL {
  let result = try runProcess(
    "/usr/bin/xcrun",
    [
      "swift",
      "build",
      "--package-path",
      package.path,
      "-c",
      "release",
      "--product",
      product,
      "--show-bin-path",
    ]
  )
  if result.status != 0 {
    Issue.record("swift build --show-bin-path failed: \(result.stderr)")
  }
  let path = result.stdout
    .split(whereSeparator: \.isNewline)
    .map(String.init)
    .last
  guard let path else {
    Issue.record("swift build --show-bin-path did not print a path.")
    return package.appendingPathComponent(".build", isDirectory: true)
  }
  return URL(fileURLWithPath: path)
}

private func writeText(_ text: String, to url: URL) throws {
  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try text.write(to: url, atomically: true, encoding: .utf8)
}

private func readPlist(_ url: URL) throws -> [String: Any] {
  let data = try Data(contentsOf: url)
  let object = try PropertyListSerialization.propertyList(
    from: data,
    options: [],
    format: nil
  )
  return try #require(object as? [String: Any])
}

private func installedResourceBundles(in installBin: URL, matching bundleNames: [String]) throws -> [URL] {
  guard FileManager.default.fileExists(atPath: installBin.path) else { return [] }
  let bundleNameSet = Set(bundleNames)
  return try FileManager.default.contentsOfDirectory(
    at: installBin,
    includingPropertiesForKeys: [.isDirectoryKey]
  )
  .filter { url in
    let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
    return values?.isDirectory == true && bundleNameSet.contains(url.lastPathComponent)
  }
}

private func moveBuildDirectory(package: URL, to hiddenBuild: URL) throws {
  let build = package.appendingPathComponent(".build", isDirectory: true)
  if FileManager.default.fileExists(atPath: hiddenBuild.path) {
    try FileManager.default.removeItem(at: hiddenBuild)
  }
  guard FileManager.default.fileExists(atPath: build.path) else { return }
  try FileManager.default.moveItem(at: build, to: hiddenBuild)
}

private func restoreBuildDirectory(package: URL, from hiddenBuild: URL) throws {
  let build = package.appendingPathComponent(".build", isDirectory: true)
  if FileManager.default.fileExists(atPath: build.path) {
    try FileManager.default.removeItem(at: build)
  }
  guard FileManager.default.fileExists(atPath: hiddenBuild.path) else { return }
  try FileManager.default.moveItem(at: hiddenBuild, to: build)
}

private func productValidationMessage(for product: String) throws -> String {
  let command = try VaporizeCLI.parse([
    "build",
    "--artifact",
    "cli",
    "--package-path",
    "/workspace/tool",
    "--product",
    product,
    "--configuration",
    "release",
  ])

  do {
    _ = try command.swiftBuildArguments()
    Issue.record("Expected noncanonical CLI product name to throw.")
    return ""
  } catch let error as ValidationError {
    return String(describing: error)
  } catch {
    Issue.record("Unexpected error: \(error).")
    return String(describing: error)
  }
}

private func assertActionableVaporizeProductValidationError(
  _ message: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  #expect(
    message.contains("error: noncanonical CLI product name")
      || message.contains("error: empty CLI product name"),
    sourceLocation: sourceLocation
  )
  #expect(message.contains("reason:"), sourceLocation: sourceLocation)
  #expect(message.contains("policy:"), sourceLocation: sourceLocation)
  #expect(message.contains("procedure:"), sourceLocation: sourceLocation)
  #expect(message.contains("digikoma:"), sourceLocation: sourceLocation)
  #expect(message.contains("digikoma-command:"), sourceLocation: sourceLocation)
  #expect(message.contains("next:"), sourceLocation: sourceLocation)
  #expect(
    message.contains("cli-error-actionability.policy.su.json"),
    sourceLocation: sourceLocation
  )
  #expect(
    message.contains("cli-error-actionability.operating-protocol.su.json"),
    sourceLocation: sourceLocation
  )
  #expect(
    message.contains("digikoma-cli-error-triage.spec.json"),
    sourceLocation: sourceLocation
  )
}
