import Foundation
import Testing

@testable import VaporizeCLI

@Test("Parses Xcode-selected Swift toolchain invocation")
func parsesXcodeSelectedSwiftToolchainInvocation() throws {
  let request = try XcodeToolchainRequest(arguments: ["--", "swift", "test", "--filter", "VaporizeCLITests"])

  #expect(request.tool == .swift)
  #expect(request.arguments == ["test", "--filter", "VaporizeCLITests"])
  #expect(request.xcrunArguments == ["swift", "test", "--filter", "VaporizeCLITests"])
}

@Test("Parses Swift toolchain invocation without leading separator")
func parsesSwiftToolchainInvocationWithoutLeadingSeparator() throws {
  let request = try XcodeToolchainRequest(arguments: ["swift", "--version"])

  #expect(request.tool == .swift)
  #expect(request.arguments == ["--version"])
  #expect(request.xcrunArguments == ["swift", "--version"])
}

@Test("Toolchain mode tolerates repeated leading separators")
func toolchainModeToleratesRepeatedLeadingSeparators() throws {
  let request = try XcodeToolchainRequest(arguments: ["--", "--", "swift", "--", "test"])

  #expect(request.tool == .swift)
  #expect(request.arguments == ["test"])
}

@Test("Rejects unsupported Xcode toolchain tools")
func rejectsUnsupportedXcodeToolchainTools() {
  #expect(throws: Error.self) {
    _ = try XcodeToolchainRequest(arguments: ["--", "xcodebuild", "-version"])
  }
}

@Test("Rejects empty Xcode toolchain invocation")
func rejectsEmptyXcodeToolchainInvocation() {
  #expect(throws: Error.self) {
    _ = try XcodeToolchainRequest(arguments: ["--", "--"])
  }
}
