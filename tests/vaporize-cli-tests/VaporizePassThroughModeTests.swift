import Foundation
import Testing

@testable import VaporizeCLI

@Test("Pass mode strips explicit Swift tool and separator")
func passModeStripsExplicitSwiftToolAndSeparator() throws {
  let request = try PassThroughRequest(arguments: [
    "--",
    "swift",
    "--",
    "test",
    "--filter",
    "VaporizeCLITests",
  ])

  #expect(request.tool == .swift)
  #expect(request.executableName == "swift")
  #expect(request.arguments == ["test", "--filter", "VaporizeCLITests"])
}

@Test("Pass mode defaults to Swift when the tool name is omitted")
func passModeDefaultsToSwiftWhenToolNameIsOmitted() throws {
  let request = try PassThroughRequest(arguments: [
    "build",
    "--package-path",
    "/workspace/pkg",
    "--product",
    "vaporize@wrkstrm-core.cli",
  ])

  #expect(request.tool == .swift)
  #expect(request.executableName == "swift")
  #expect(request.arguments == [
    "build",
    "--package-path",
    "/workspace/pkg",
    "--product",
    "vaporize@wrkstrm-core.cli",
  ])
}

@Test("Pass mode tolerates repeated leading separators")
func passModeToleratesRepeatedLeadingSeparators() throws {
  let request = try PassThroughRequest(arguments: [
    "--",
    "--",
    "swift",
    "package",
    "describe",
  ])

  #expect(request.tool == .swift)
  #expect(request.arguments == ["package", "describe"])
}
