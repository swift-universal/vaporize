import Testing

@testable import VaporizeCLI

// Bead: bug-vaporize-windows-release-swift-testing-wmo-2026-08-28
@Suite("Windows release Swift Testing policy")
struct WindowsReleaseSwiftTestingPolicyTests {
  @Test("release tests disable WMO on Windows")
  func releaseTestsDisableWMOOnWindows() {
    #expect(
      VaporizeWindowsSwiftTestingPolicy.testArguments(
        configuration: "release",
        isWindowsHost: true
      ) == ["-Xswiftc", "-no-whole-module-optimization"]
    )
  }

  @Test("debug tests keep the default compilation model")
  func debugTestsKeepDefaultCompilationModel() {
    #expect(
      VaporizeWindowsSwiftTestingPolicy.testArguments(
        configuration: "debug",
        isWindowsHost: true
      ).isEmpty
    )
  }

  @Test("non-Windows release tests keep WMO")
  func nonWindowsReleaseTestsKeepWMO() {
    #expect(
      VaporizeWindowsSwiftTestingPolicy.testArguments(
        configuration: "release",
        isWindowsHost: false
      ).isEmpty
    )
  }
}
