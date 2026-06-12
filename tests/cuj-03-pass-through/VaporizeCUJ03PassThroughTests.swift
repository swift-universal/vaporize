import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-03 strips explicit Swift tool and separator")
func passModeStripsExplicitSwiftToolAndSeparator() throws {
  let request = try PassThroughRequest(arguments: ["--", "swift", "--", "test", "--filter", "VaporizeCUJ03PassThroughTests"])

  #expect(request.tool == .swift)
  #expect(request.executableName == "swift")
  #expect(request.arguments == ["test", "--filter", "VaporizeCUJ03PassThroughTests"])
}

@Test("CUJ-03 defaults to Swift when the tool name is omitted")
func passModeDefaultsToSwiftWhenToolNameIsOmitted() throws {
  let request = try PassThroughRequest(arguments: ["build", "--package-path", "/workspace/pkg", "--product", "vaporize@wrkstrm-core.cli"])

  #expect(request.tool == .swift)
  #expect(request.executableName == "swift")
  #expect(request.arguments == ["build", "--package-path", "/workspace/pkg", "--product", "vaporize@wrkstrm-core.cli"])
}

@Test("CUJ-03 tolerates repeated leading separators")
func passModeToleratesRepeatedLeadingSeparators() throws {
  let request = try PassThroughRequest(arguments: ["--", "--", "swift", "package", "describe"])

  #expect(request.tool == .swift)
  #expect(request.arguments == ["package", "describe"])
}

@Test("CUJ-03 pass-through receipt encodes stable execution evidence")
func passThroughReceiptEncodesStableExecutionEvidence() throws {
  let receipt = PassThroughReceipt(
    tool: "swift",
    executableName: "swift",
    arguments: ["test", "--filter", "VaporizeCUJ03PassThroughTests"],
    workingDirectory: "/workspace/pkg",
    requestId: "vaporize-pass-test",
    runnerKind: "auto",
    succeeded: true,
    exitCode: 0,
    signal: nil,
    stdoutBytes: 128,
    stderrBytes: 0,
    processIdentifier: "pid-1"
  )
  let data = try JSONEncoder().encode(receipt)
  let decoded = try JSONDecoder().decode(PassThroughReceipt.self, from: data)

  #expect(decoded.schemaVersion == "0.1.0")
  #expect(decoded.receiptKind == "vaporize-pass-through")
  #expect(decoded.tool == "swift")
  #expect(decoded.arguments == ["test", "--filter", "VaporizeCUJ03PassThroughTests"])
  #expect(decoded.exitCode == 0)
  #expect(decoded.stdoutBytes == 128)
}
