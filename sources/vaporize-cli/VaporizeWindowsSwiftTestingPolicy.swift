enum VaporizeWindowsSwiftTestingPolicy {
  static var isWindowsHost: Bool {
    #if os(Windows)
      true
    #else
      false
    #endif
  }

  /// Swift 6.4's default Windows SwiftPM build system omits Swift Testing's
  /// registration object from release WMO test runners. Keep release
  /// optimization while compiling files independently until SwiftPM carries
  /// the registration object through WMO correctly.
  static func testArguments(
    configuration: String,
    isWindowsHost: Bool
  ) -> [String] {
    guard isWindowsHost, configuration == "release" else { return [] }
    return ["-Xswiftc", "-no-whole-module-optimization"]
  }
}
