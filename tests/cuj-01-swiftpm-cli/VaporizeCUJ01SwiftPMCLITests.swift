import ArgumentParser
import Testing

@testable import SwiftCLIInstaller
@testable import VaporizeCLI

@Test("CUJ-01 exposes the canonical Vaporize command identity")
func exposesCanonicalVaporizeCommandIdentity() {
  #expect(VaporizeCLI.configuration.commandName == "vaporize@wrkstrm-core.cli")
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
    "tool@org.cli",
    "--configuration",
    "debug",
    "--skip-install",
  ])

  #expect(command.mode == .build)
  #expect(command.artifact == .cli)
  #expect(command.packagePath == "/workspace/tool")
  #expect(command.product == "tool@org.cli")
  #expect(command.configuration == .debug)
  #expect(command.skipInstall)
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
      product: "tool@org.cli",
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
    "tool@org.cli",
  ])
}

@Test("CUJ-01 builds Swift package uninstall arguments")
func buildsSwiftPackageUninstallArguments() {
  let installer = SwiftCLIInstaller(
    request: .init(
      packagePath: "/workspace/tool",
      product: "tool@org.cli",
      configuration: .debug,
      forceReinstall: true
    )
  )

  #expect(installer.uninstallArguments() == [
    "package",
    "--package-path",
    "/workspace/tool",
    "experimental-uninstall",
    "tool@org.cli",
  ])
}
