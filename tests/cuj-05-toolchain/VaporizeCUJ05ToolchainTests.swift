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

@Test("CUJ-05 resolves Swift toolchain DocC when available")
func resolvesSwiftToolchainDocCWhenAvailable() throws {
  let request = try SwiftToolchainRequest(arguments: ["docc", "convert", "Product.docc"])
  let invocation = try request.invocation(
    environment: ToolchainResolutionEnvironment(
      platform: .macOS,
      swiftToolchainDocCPath: "/Users/example/.swiftly/bin/docc"
    )
  )

  switch invocation.executable.ref {
  case .path(let path):
    #expect(path == "/Users/example/.swiftly/bin/docc")
  default:
    Issue.record("expected Swift toolchain DocC path")
  }
  #expect(invocation.arguments == ["convert", "Product.docc"])
  #expect(invocation.executableRef == "path:/Users/example/.swiftly/bin/docc")
  #expect(invocation.resolver == "swift-toolchain")
}

@Test("CUJ-05 resolves macOS DocC fallback through xcrun")
func resolvesMacOSDocCFallbackThroughXcrun() throws {
  let request = try SwiftToolchainRequest(arguments: ["docc", "convert", "Product.docc"])
  let invocation = try request.invocation(
    environment: ToolchainResolutionEnvironment(platform: .macOS, swiftToolchainDocCPath: nil)
  )

  switch invocation.executable.ref {
  case .name(let name):
    #expect(name == "xcrun")
  default:
    Issue.record("expected xcrun on macOS")
  }
  #expect(invocation.arguments == ["docc", "convert", "Product.docc"])
  #expect(invocation.executableRef == "name:xcrun")
  #expect(invocation.resolver == "xcrun")
}

@Test("CUJ-05 resolves non-macOS DocC by tool name")
func resolvesNonMacOSDocCByToolName() throws {
  let request = try SwiftToolchainRequest(arguments: ["docc", "convert", "Product.docc"])
  let invocation = try request.invocation(
    environment: ToolchainResolutionEnvironment(platform: .other, swiftToolchainDocCPath: nil)
  )

  switch invocation.executable.ref {
  case .name(let name):
    #expect(name == "docc")
  default:
    Issue.record("expected direct docc lookup outside macOS")
  }
  #expect(invocation.arguments == ["convert", "Product.docc"])
  #expect(invocation.executableRef == "name:docc")
  #expect(invocation.resolver == "path")
}

@Test("CUJ-05 keeps macOS Swift on xcrun lane")
func keepsMacOSSwiftOnXcrunLane() throws {
  let request = try SwiftToolchainRequest(arguments: ["swift", "--version"])
  let invocation = try request.invocation(
    environment: ToolchainResolutionEnvironment(
      platform: .macOS,
      swiftToolchainDocCPath: "/Users/example/.swiftly/bin/docc"
    )
  )

  switch invocation.executable.ref {
  case .name(let name):
    #expect(name == "xcrun")
  default:
    Issue.record("expected xcrun for Swift on macOS")
  }
  #expect(invocation.arguments == ["swift", "--version"])
  #expect(invocation.executableRef == "name:xcrun")
  #expect(invocation.resolver == "xcrun")
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
    executableRef: "path:/Users/example/.swiftly/bin/docc",
    resolver: "swift-toolchain",
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
  #expect(decoded.executableRef == "path:/Users/example/.swiftly/bin/docc")
  #expect(decoded.resolver == "swift-toolchain")
  #expect(decoded.arguments == ["--version"])
  #expect(decoded.succeeded)
}
