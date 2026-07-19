import ArgumentParser
import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-05 parses Swift selection with the embedded Swiftly use grammar")
func parsesSwiftSelection() throws {
  let request = try ToolchainSelectionRequest(arguments: [
    "--", "swift", "--", "use", "--global-default", "6.4",
  ])

  #expect(request.operation == .swiftUse(["--global-default", "6.4"]))
}

@Test("CUJ-05 permits reporting the active Swift selection")
func parsesSwiftSelectionLookup() throws {
  let request = try ToolchainSelectionRequest(arguments: ["swift", "use"])

  #expect(request.operation == .swiftUse([]))
}

@Test("CUJ-05 parses toolchain-selection through Vaporize")
func parsesToolchainSelectionThroughVaporize() throws {
  let command = try VaporizeCLI.parse([
    "toolchain-selection", "swift", "--", "use", "--print-location",
  ])

  #expect(command.mode == .toolchainSelection)
  #expect(command.forwardedArguments == ["swift", "use", "--print-location"])
}

@Test("CUJ-05 removes the former overloaded toolchain mode")
func rejectsFormerToolchainMode() {
  #expect(throws: Error.self) {
    _ = try VaporizeCLI.parse(["toolchain", "swift", "--", "use", "6.4"])
  }
}

@Test("CUJ-05 exposes only selection providers compiled for the host platform")
func exposesOnlyCompiledSelectionProviders() {
  #if os(macOS)
    #expect(ToolchainSelectionRequest.Provider.allCases == [.swift, .xcode])
    #expect(ToolchainSelectionRequest.Provider(rawValue: "xcode") == .xcode)
    #expect(VaporizeCLI.toolchainSelectionDiscussion.contains("toolchain-selection xcode"))
  #else
    #expect(ToolchainSelectionRequest.Provider.allCases == [.swift])
    #expect(ToolchainSelectionRequest.Provider(rawValue: "xcode") == nil)
    #expect(!VaporizeCLI.toolchainSelectionDiscussion.contains("xcode"))
  #endif
}

@Test("CUJ-05 requires an explicit compiled selection provider")
func rejectsSelectionWithoutProvider() {
  #expect(throws: Error.self) {
    _ = try ToolchainSelectionRequest(arguments: ["use", "6.4"])
  }
}

@Test(
  "CUJ-05 rejects Swift lifecycle inspection and execution from selection",
  arguments: [
    ["swift", "install", "6.4"],
    ["swift", "list"],
    ["swift", "update"],
    ["swift", "uninstall", "6.3.2"],
    ["swift", "run", "swift", "--version"],
    ["swift", "swift", "test"],
    ["swift", "docc", "convert", "Product.docc"],
  ]
)
func rejectsNonSelectionSwiftOperations(arguments: [String]) {
  #expect(throws: Error.self) {
    _ = try ToolchainSelectionRequest(arguments: arguments)
  }
}

@Test("CUJ-05 rejects Xcode as a Swift selection")
func rejectsXcodeAsSwiftSelection() {
  #expect(throws: Error.self) {
    _ = try ToolchainSelectionRequest(arguments: [
      "swift", "use", "--global-default", "xcode",
    ])
  }
}

@Test("CUJ-05 distinguishes Vaporize commands from embedded Swiftly proxy links")
func distinguishesVaporizeCommandsFromLinkedToolchainProxies() {
  #expect(!VaporizeInvocation.isToolchainProxy(arguments: [
    "/opt/wrkstrm/bin/vaporize.cli@wrkstrm-core.clia.sh"
  ]))
  #expect(!VaporizeInvocation.isToolchainProxy(arguments: ["vaporize"]))
  #expect(VaporizeInvocation.isToolchainProxy(arguments: ["/tmp/toolchain-bin/swift"]))
  #expect(VaporizeInvocation.isToolchainProxy(arguments: ["clang"]))
}

@Test("CUJ-05 resolves a relative Vaporize executable for Swiftly proxy links")
func resolvesRelativeVaporizeExecutableForProxyLinks() {
  let path = VaporizeInvocation.executablePath(
    arguments: ["build/vaporize.cli@wrkstrm-core.clia.sh"],
    currentDirectory: "/tmp/vaporize-host",
    environmentPath: nil
  )

  #expect(path == "/tmp/vaporize-host/build/vaporize.cli@wrkstrm-core.clia.sh")
}

#if os(macOS)
  @Test("CUJ-05 routes Xcode selection-state lookup through xcode-select")
  func routesXcodeSelectionLookup() throws {
    let request = try ToolchainSelectionRequest(arguments: [
      "xcode", "select", "--print-path",
    ])

    guard case .xcodeSelect(let xcodeRequest) = request.operation else {
      Issue.record("expected Xcode selection request")
      return
    }
    let invocation = xcodeRequest.invocation()
    switch invocation.executable.ref {
    case .path(let path):
      #expect(path == "/usr/bin/xcode-select")
    default:
      Issue.record("expected the fixed macOS xcode-select path")
    }
    #expect(invocation.arguments == ["--print-path"])
    #expect(invocation.executableRef == "path:/usr/bin/xcode-select")
    #expect(invocation.resolver == "xcode-select")
  }

  @Test("CUJ-05 routes Xcode selection mutation without executing it")
  func routesXcodeSelectionSwitch() throws {
    let request = try XcodeSelectionRequest(arguments: [
      "--switch", "/Applications/Xcode.app/Contents/Developer",
    ])

    #expect(request.arguments == [
      "--switch", "/Applications/Xcode.app/Contents/Developer",
    ])
    #expect(request.invocation().executableRef == "path:/usr/bin/xcode-select")
  }

  @Test("CUJ-05 accepts reset as an Xcode selection mutation")
  func routesXcodeSelectionReset() throws {
    let request = try XcodeSelectionRequest(arguments: ["--reset"])

    #expect(request.arguments == ["--reset"])
  }

  @Test(
    "CUJ-05 rejects Xcode lifecycle inspection and execution from selection",
    arguments: [
      ["xcode", "version"],
      ["xcode", "swift", "--version"],
      ["xcode", "docc", "--help"],
      ["xcode", "select", "--version"],
      ["xcode", "select", "--install"],
      ["xcode", "select"],
    ]
  )
  func rejectsNonSelectionXcodeOperations(arguments: [String]) {
    #expect(throws: Error.self) {
      _ = try ToolchainSelectionRequest(arguments: arguments)
    }
  }
#endif

@Test("CUJ-05 selection receipt records provider and resolver boundaries")
func selectionReceiptRecordsProviderBoundary() throws {
  let receipt = ToolchainSelectionReceipt(
    provider: "xcode",
    operation: "select",
    arguments: ["--print-path"],
    workingDirectory: "/workspace/pkg",
    requestId: "vaporize-toolchain-selection-test",
    runnerKind: "auto",
    executableRef: "path:/usr/bin/xcode-select",
    resolver: "xcode-select",
    outputCapture: "buffered",
    succeeded: true,
    exitCode: 0,
    signal: nil,
    stdoutBytes: 42,
    stderrBytes: 0,
    processIdentifier: "pid-2"
  )
  let data = try JSONEncoder().encode(receipt)
  let decoded = try JSONDecoder().decode(ToolchainSelectionReceipt.self, from: data)

  #expect(decoded.schemaVersion == "0.1.0")
  #expect(decoded.receiptKind == "vaporize-toolchain-selection")
  #expect(decoded.provider == "xcode")
  #expect(decoded.operation == "select")
  #expect(decoded.executableRef == "path:/usr/bin/xcode-select")
  #expect(decoded.resolver == "xcode-select")
  #expect(decoded.outputCapture == "buffered")
  #expect(decoded.arguments == ["--print-path"])
  #expect(decoded.succeeded)
}
