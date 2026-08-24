import ArgumentParser
import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-05 removes the former overloaded toolchain mode")
func rejectsFormerToolchainMode() {
  #expect(throws: Error.self) {
    _ = try VaporizeCLI.parse(["toolchain", "swift", "--", "use", "6.4"])
  }
}

#if os(macOS)
  @Test("CUJ-05 parses Xcode selection through Vaporize")
  func parsesToolchainSelectionThroughVaporize() throws {
    let command = try VaporizeCLI.parse([
      "toolchain-selection", "xcode", "--", "select", "--print-path",
    ])

    #expect(command.mode == .toolchainSelection)
    #expect(command.forwardedArguments == ["xcode", "select", "--print-path"])
  }

  @Test("CUJ-05 exposes only the Xcode selection provider")
  func exposesOnlyXcodeSelectionProvider() {
    #expect(ToolchainSelectionRequest.Provider.allCases == [.xcode])
    #expect(ToolchainSelectionRequest.Provider(rawValue: "swift") == nil)
    #expect(VaporizeCLI.toolchainSelectionDiscussion.contains("toolchain-selection xcode"))
    #expect(VaporizeCLI.toolchainSelectionDiscussion.contains("Temper owns Swift"))
  }

  @Test("CUJ-05 requires the explicit Xcode selection provider")
  func rejectsSelectionWithoutProvider() {
    #expect(throws: Error.self) {
      _ = try ToolchainSelectionRequest(arguments: ["select", "--print-path"])
    }
  }

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

#if !os(macOS)
  @Test("CUJ-05 omits toolchain selection where Vaporize has no platform provider")
  func omitsToolchainSelectionWithoutPlatformProvider() {
    #expect(throws: Error.self) {
      _ = try VaporizeCLI.parse([
        "toolchain-selection", "swift", "--", "use", "6.4",
      ])
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
