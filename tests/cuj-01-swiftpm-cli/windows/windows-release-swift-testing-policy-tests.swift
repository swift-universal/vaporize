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
      ) == ["--jobs", "1", "-Xswiftc", "-no-whole-module-optimization"]
    )
  }

  @Test("debug tests serialize Windows SwiftPM work")
  func debugTestsSerializeWindowsSwiftPMWork() {
    #expect(
      VaporizeWindowsSwiftTestingPolicy.testArguments(
        configuration: "debug",
        isWindowsHost: true
      ) == ["--jobs", "1"]
    )
  }

  @Test("explicit job counts override the Windows default")
  func explicitJobCountsOverrideWindowsDefault() {
    #expect(
      VaporizeWindowsSwiftTestingPolicy.testArguments(
        configuration: "debug",
        isWindowsHost: true,
        forwardedArguments: ["--jobs", "4", "--filter", "FocusedTests"]
      ).isEmpty
    )
    #expect(
      VaporizeWindowsSwiftTestingPolicy.testArguments(
        configuration: "release",
        isWindowsHost: true,
        forwardedArguments: ["-j", "2"]
      ) == ["-Xswiftc", "-no-whole-module-optimization"]
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
