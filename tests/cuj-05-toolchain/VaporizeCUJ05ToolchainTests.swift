import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-05 parses Xcode-selected Swift toolchain invocation")
func parsesXcodeSelectedSwiftToolchainInvocation() throws {
  let request = try XcodeToolchainRequest(arguments: ["--", "swift", "test", "--filter", "VaporizeCUJ05ToolchainTests"])

  #expect(request.tool == .swift)
  #expect(request.arguments == ["test", "--filter", "VaporizeCUJ05ToolchainTests"])
  #expect(request.xcrunArguments == ["swift", "test", "--filter", "VaporizeCUJ05ToolchainTests"])
}

@Test("CUJ-05 parses Swift toolchain invocation without leading separator")
func parsesSwiftToolchainInvocationWithoutLeadingSeparator() throws {
  let request = try XcodeToolchainRequest(arguments: ["swift", "--version"])

  #expect(request.tool == .swift)
  #expect(request.arguments == ["--version"])
  #expect(request.xcrunArguments == ["swift", "--version"])
}

@Test("CUJ-05 tolerates repeated leading separators")
func toolchainModeToleratesRepeatedLeadingSeparators() throws {
  let request = try XcodeToolchainRequest(arguments: ["--", "--", "swift", "--", "test"])

  #expect(request.tool == .swift)
  #expect(request.arguments == ["test"])
}

@Test("CUJ-05 rejects unsupported Xcode toolchain tools")
func rejectsUnsupportedXcodeToolchainTools() {
  #expect(throws: Error.self) {
    _ = try XcodeToolchainRequest(arguments: ["--", "xcodebuild", "-version"])
  }
}

@Test("CUJ-05 rejects empty Xcode toolchain invocation")
func rejectsEmptyXcodeToolchainInvocation() {
  #expect(throws: Error.self) {
    _ = try XcodeToolchainRequest(arguments: ["--", "--"])
  }
}

@Test("CUJ-05 toolchain receipt records developer-dir boundary")
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
