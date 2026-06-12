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

@Test("Builds Swift package install arguments")
func buildsSwiftPackageInstallArguments() {
  let installer = SwiftCLIInstaller(
    request: .init(
      packagePath: "/workspace/tool",
      product: "tool@org.cli",
      configuration: .release,
      forceReinstall: false
    )
  )

  #expect(installer.installArguments() == [
    "package",
    "--package-path",
    "/workspace/tool",
    "experimental-install",
    "-c",
    "release",
    "--product",
    "tool@org.cli",
  ])
}

@Test("Builds Swift package uninstall arguments")
func buildsSwiftPackageUninstallArguments() {
  let installer = SwiftCLIInstaller(
    request: .init(
      packagePath: "/workspace/tool",
      product: "tool@org.cli",
      configuration: .debug,
      forceReinstall: true
    )
  )

  #expect(installer.uninstallArguments() == [
    "package",
    "--package-path",
    "/workspace/tool",
    "experimental-uninstall",
    "tool@org.cli",
  ])
}
