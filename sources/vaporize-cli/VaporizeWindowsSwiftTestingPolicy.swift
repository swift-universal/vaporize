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
    isWindowsHost: Bool,
    forwardedArguments: [String] = []
  ) -> [String] {
    guard isWindowsHost else { return [] }

    var arguments: [String] = []
    if !containsExplicitJobCount(forwardedArguments) {
      // Large Windows SwiftPM test graphs can schedule duplicate incremental
      // dependency writes and fail with NSCocoaErrorDomain 512. Serialize by
      // default while preserving an explicit caller-selected job count.
      arguments += ["--jobs", "1"]
    }
    if configuration == "release" {
      arguments += ["-Xswiftc", "-no-whole-module-optimization"]
    }
    return arguments
  }

  private static func containsExplicitJobCount(_ arguments: [String]) -> Bool {
    arguments.contains { argument in
      argument == "--jobs" || argument == "-j"
        || argument.hasPrefix("--jobs=") || argument.hasPrefix("-j=")
    }
  }
}
