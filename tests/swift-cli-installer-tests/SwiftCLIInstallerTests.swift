import Testing

@testable import SwiftCLIInstaller

@Test("Matches already installed error")
func matchesAlreadyInstalledError() {
  let message = "error: clia is already installed at /Users/rismay/.swiftpm/bin/clia"
  #expect(InstallMessageMatcher.isAlreadyInstalled(message))
}

@Test("Matches not installed error")
func matchesNotInstalledError() {
  let message = "Executable product `clia` was not installed."
  #expect(InstallMessageMatcher.isNotInstalled(message))
}
