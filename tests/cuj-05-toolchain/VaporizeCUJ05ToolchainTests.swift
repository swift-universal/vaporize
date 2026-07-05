import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-05 parses Swift toolchain invocation with leading separator")
func parsesSwiftToolchainInvocationWithLeadingSeparator() throws {
  let request = try SwiftToolchainRequest(arguments: ["--", "swift", "test", "--filter", "VaporizeCUJ05ToolchainTests"])

  #expect(request.tool == .swift)
  #expect(request.arguments == ["test", "--filter", "VaporizeCUJ05ToolchainTests"])
  #expect(request.xcrunArguments == ["swift", "test", "--filter", "VaporizeCUJ05ToolchainTests"])
}

@Test("CUJ-05 parses Swift toolchain invocation without leading separator")
func parsesSwiftToolchainInvocationWithoutLeadingSeparator() throws {
  let request = try SwiftToolchainRequest(arguments: ["swift", "--version"])

  #expect(request.tool == .swift)
  #expect(request.arguments == ["--version"])
  #expect(request.xcrunArguments == ["swift", "--version"])
}

@Test("CUJ-05 parses DocC toolchain conversion")
func parsesDocCToolchainConversion() throws {
  let request = try SwiftToolchainRequest(arguments: [
    "--",
    "docc",
    "convert",
    "Product.docc",
    "--output-path",
    "/tmp/Product.doccarchive",
  ])

  #expect(request.tool == .docc)
  #expect(request.arguments == [
    "convert",
    "Product.docc",
    "--output-path",
    "/tmp/Product.doccarchive",
  ])
  #expect(request.xcrunArguments == [
    "docc",
    "convert",
    "Product.docc",
    "--output-path",
    "/tmp/Product.doccarchive",
  ])
}

@Test("CUJ-05 tolerates repeated leading separators")
func toolchainModeToleratesRepeatedLeadingSeparators() throws {
  let request = try SwiftToolchainRequest(arguments: ["--", "--", "swift", "--", "test"])

  #expect(request.tool == .swift)
  #expect(request.arguments == ["test"])
}

@Test("CUJ-05 resolves explicit toolchain bin path")
func resolvesExplicitToolchainBinPath() throws {
  let request = try SwiftToolchainRequest(arguments: ["docc", "convert", "Product.docc"])
  let invocation = try request.invocation(toolchainBinPath: "/opt/swift-toolchain/usr/bin")

  switch invocation.executable.ref {
  case .path(let path):
    #expect(path == "/opt/swift-toolchain/usr/bin/docc")
  default:
    Issue.record("expected explicit toolchain path")
  }
  #expect(invocation.arguments == ["convert", "Product.docc"])
  #expect(invocation.executableRef == "path:/opt/swift-toolchain/usr/bin/docc")
  #expect(invocation.resolver == "toolchain-bin-path")
}

@Test("CUJ-05 resolves platform default toolchain")
func resolvesPlatformDefaultToolchain() throws {
  let request = try SwiftToolchainRequest(arguments: ["docc", "convert", "Product.docc"])
  let invocation = try request.invocation(toolchainBinPath: nil)

  #if os(macOS)
    switch invocation.executable.ref {
    case .name(let name):
      #expect(name == "xcrun")
    default:
      Issue.record("expected xcrun on macOS")
    }
    #expect(invocation.arguments == ["docc", "convert", "Product.docc"])
    #expect(invocation.executableRef == "name:xcrun")
    #expect(invocation.resolver == "xcrun")
  #else
    switch invocation.executable.ref {
    case .name(let name):
      #expect(name == "docc")
    default:
      Issue.record("expected direct docc lookup outside macOS")
    }
    #expect(invocation.arguments == ["convert", "Product.docc"])
    #expect(invocation.executableRef == "name:docc")
    #expect(invocation.resolver == "path")
  #endif
}

@Test("CUJ-05 rejects unsupported Swift toolchain tools")
func rejectsUnsupportedSwiftToolchainTools() {
  #expect(throws: Error.self) {
    _ = try SwiftToolchainRequest(arguments: ["--", "xcodebuild", "-version"])
  }
}

@Test("CUJ-05 rejects empty Swift toolchain invocation")
func rejectsEmptySwiftToolchainInvocation() {
  #expect(throws: Error.self) {
    _ = try SwiftToolchainRequest(arguments: ["--", "--"])
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
    toolchainBinPathSet: true,
    executableRef: "path:/opt/swift-toolchain/usr/bin/docc",
    resolver: "toolchain-bin-path",
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
  #expect(decoded.toolchainBinPathSet)
  #expect(decoded.executableRef == "path:/opt/swift-toolchain/usr/bin/docc")
  #expect(decoded.resolver == "toolchain-bin-path")
  #expect(decoded.arguments == ["--version"])
  #expect(decoded.succeeded)
}
