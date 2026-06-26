import ArgumentParser
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
    #expect(String(describing: error).contains("suggested 'git.cli@swift-universal.clia.sh'"))
  } catch {
    Issue.record("Unexpected error: \(error).")
  }
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
    "--package-path",
    "/workspace/tool",
    "experimental-install",
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
    "--package-path",
    "/workspace/tool",
    "experimental-uninstall",
    "tool.cli@org.clia.sh",
  ])
}
