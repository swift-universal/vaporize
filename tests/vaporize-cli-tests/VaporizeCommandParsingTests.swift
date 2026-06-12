import ArgumentParser
import Foundation
import Testing

@testable import VaporizeCLI

@Test("Exposes the canonical Vaporize command identity")
func exposesCanonicalVaporizeCommandIdentity() {
  #expect(VaporizeCLI.configuration.commandName == "vaporize@wrkstrm-core.cli")
}

@Test("Parses SwiftPM CLI build mode")
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

@Test("Parses app install mode with Xcode build options")
func parsesAppInstallModeWithXcodeBuildOptions() throws {
  let command = try VaporizeCLI.parse([
    "install",
    "--artifact",
    "app",
    "--package-path",
    "/workspace/app",
    "--product",
    "Concourse",
    "--app-bundle-name",
    "ConcourseDebug",
    "--destination",
    "/tmp/Applications",
    "--launch",
    "--xcode-project",
    "/workspace/app/Concourse.xcodeproj",
    "--scheme",
    "Concourse",
    "--derived-data-path",
    "/workspace/app/.derived-data",
    "--xcode-destination",
    "platform=macOS,arch=arm64",
    "--xcode-sdk",
    "macosx",
    "--xcode-build-setting",
    "CODE_SIGNING_ALLOWED=NO",
  ])

  #expect(command.mode == .install)
  #expect(command.artifact == .app)
  #expect(command.packagePath == "/workspace/app")
  #expect(command.product == "Concourse")
  #expect(command.appBundleName == "ConcourseDebug")
  #expect(command.destination == "/tmp/Applications")
  #expect(command.launch)
  #expect(command.xcodeProject == "/workspace/app/Concourse.xcodeproj")
  #expect(command.xcodeScheme == "Concourse")
  #expect(command.derivedDataPath == "/workspace/app/.derived-data")
  #expect(command.xcodeDestinations == ["platform=macOS,arch=arm64"])
  #expect(command.xcodeSDK == "macosx")
  #expect(command.xcodeBuildSettings == ["CODE_SIGNING_ALLOWED=NO"])
}

@Test("Parses status mode with JSON output")
func parsesStatusModeWithJSONOutput() throws {
  let command = try VaporizeCLI.parse([
    "status",
    "--path",
    "/tmp/vaporware",
    "--format",
    "json",
  ])

  #expect(command.mode == .status)
  #expect(command.vaporScanPath == "/tmp/vaporware")
  #expect(command.vaporOutputFormat == .json)
  #expect(command.vaporOutputFormat.rendererFormat == .json)
}

@Test("Parses inventory as the warehouse compatibility alias")
func parsesInventoryCompatibilityAlias() throws {
  let command = try VaporizeCLI.parse([
    "inventory",
    "--path",
    "/tmp/vaporware",
    "--receipt-path",
    "/tmp/receipt.json",
  ])

  #expect(command.mode == .inventory)
  #expect(command.vaporScanPath == "/tmp/vaporware")
  #expect(command.receiptPath == "/tmp/receipt.json")
}

@Test("Parses deprecated cli and app install spellings")
func parsesDeprecatedInstallSpellings() throws {
  let cli = try VaporizeCLI.parse([
    "cli",
    "--package-path",
    "/workspace/pkg",
    "--product",
    "tool",
  ])
  let app = try VaporizeCLI.parse([
    "app",
    "--package-path",
    "/workspace/app",
    "--product",
    "SceneLab",
    "--launch",
  ])

  #expect(cli.mode == .cli)
  #expect(cli.artifact == .cli)
  #expect(app.mode == .app)
  #expect(app.artifact == .cli)
  #expect(app.launch)
}

@Test("Parses graph forwarded arguments without interpreting them")
func parsesGraphForwardedArgumentsWithoutInterpretingThem() throws {
  let command = try VaporizeCLI.parse([
    "graph",
    "--package-path",
    "/workspace/package-graph",
    "--",
    "impact",
    "--format",
    "json",
  ])

  #expect(command.mode == .graph)
  #expect(command.packagePath == "/workspace/package-graph")
  #expect(command.forwardedArguments == ["impact", "--format", "json"])
}
