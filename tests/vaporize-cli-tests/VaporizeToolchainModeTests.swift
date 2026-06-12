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

@Test("Rejects unsupported Xcode toolchain tools")
func rejectsUnsupportedXcodeToolchainTools() {
  #expect(throws: Error.self) {
    _ = try XcodeToolchainRequest(arguments: ["--", "xcodebuild", "-version"])
  }
}

