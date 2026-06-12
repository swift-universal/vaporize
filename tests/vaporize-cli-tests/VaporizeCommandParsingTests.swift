import ArgumentParser
import Foundation
import Testing

@testable import VaporizeCLI

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
