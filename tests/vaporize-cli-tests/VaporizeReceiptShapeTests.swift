import Foundation
import Testing

@testable import VaporizeCLI

@Test("Pass-through receipt encodes stable execution evidence")
func passThroughReceiptEncodesStableExecutionEvidence() throws {
  let receipt = PassThroughReceipt(
    tool: "swift",
    executableName: "swift",
    arguments: ["test", "--filter", "VaporizeCLITests"],
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
  #expect(decoded.arguments == ["test", "--filter", "VaporizeCLITests"])
  #expect(decoded.exitCode == 0)
  #expect(decoded.stdoutBytes == 128)
}

@Test("Toolchain receipt records developer-dir boundary")
func toolchainReceiptRecordsDeveloperDirBoundary() throws {
  let receipt = ToolchainReceipt(
    tool: "swift",
    arguments: ["--version"],
    workingDirectory: "/workspace/pkg",
    requestId: "vaporize-toolchain-test",
    runnerKind: "auto",
    developerDirectorySet: true,
    succeeded: true,
    exitCode: 0,
    signal: nil,
    stdoutBytes: 42,
    stderrBytes: 0,
    processIdentifier: "pid-2"
  )
  let data = try JSONEncoder().encode(receipt)
  let decoded = try JSONDecoder().decode(ToolchainReceipt.self, from: data)

  #expect(decoded.schemaVersion == "0.1.0")
  #expect(decoded.receiptKind == "vaporize-toolchain")
  #expect(decoded.developerDirectorySet)
  #expect(decoded.arguments == ["--version"])
  #expect(decoded.succeeded)
}

@Test("Use receipt records CommonProcess invocation shape")
func useReceiptRecordsCommonProcessInvocationShape() throws {
  let receipt = UseReceipt(
    specSource: "spec.json",
    executableRef: "name:echo",
    argumentCount: 1,
    workingDirectory: "/workspace/pkg",
    requestId: "vaporize-use-test",
    runnerKind: "foundation",
    streamingMode: "buffered",
    succeeded: true,
    exitCode: 0,
    signal: nil,
    stdoutBytes: 6,
    stderrBytes: 0,
    processIdentifier: "pid-3"
  )
  let data = try JSONEncoder().encode(receipt)
  let decoded = try JSONDecoder().decode(UseReceipt.self, from: data)

  #expect(decoded.schemaVersion == "0.1.0")
  #expect(decoded.receiptKind == "vaporize-use-common-process")
  #expect(decoded.specSource == "spec.json")
  #expect(decoded.executableRef == "name:echo")
  #expect(decoded.argumentCount == 1)
  #expect(decoded.streamingMode == "buffered")
}
