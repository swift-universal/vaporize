import ArgumentParser
import Foundation
import Testing

@testable import SwiftAppInstaller
@testable import VaporizeCLI

@Test("CUJ-15 parses Xcode workspace product cache options")
func parsesXcodeWorkspaceProductCacheOptions() throws {
  let command = try VaporizeCLI.parse([
    "install",
    "--artifact",
    "app",
    "--package-path",
    "/workspace/App",
    "--product",
    "CreativeSelection",
    "--xcode-project",
    "/workspace/App/CreativeSelection.xcodeproj",
    "--scheme",
    "CreativeSelection",
    "--xcode-product-cache-workspace",
    "/workspace/Huge/Huge.xcworkspace",
    "--xcode-product-cache-derived-data-path",
    "/workspace/Huge/.derived-data",
  ])

  #expect(command.xcodeProductCacheWorkspace == "/workspace/Huge/Huge.xcworkspace")
  #expect(command.xcodeProductCacheDerivedDataPath == "/workspace/Huge/.derived-data")
}

@Test("CUJ-15 shared workspace cache is searched before local derived data")
func sharedWorkspaceCacheIsSearchedBeforeLocalDerivedData() throws {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-xcode-product-cache-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

  let cacheDerivedData = temporaryDirectory.appendingPathComponent("huge-derived-data")
  let localDerivedData = temporaryDirectory.appendingPathComponent("local-derived-data")
  let cacheApp = cacheDerivedData.appendingPathComponent("Build/Products/Debug/CreativeSelection.app")
  let localApp = localDerivedData.appendingPathComponent("Build/Products/Debug/CreativeSelection.app")
  try FileManager.default.createDirectory(at: cacheApp, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: localApp, withIntermediateDirectories: true)

  let request = SwiftAppInstaller.Request(
    packagePath: temporaryDirectory.path,
    product: "CreativeSelection",
    configuration: .debug,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true,
    xcodeProject: "/workspace/App/CreativeSelection.xcodeproj",
    xcodeScheme: "CreativeSelection",
    derivedDataPath: localDerivedData.path,
    xcodeProductCacheWorkspace: "/workspace/Huge/Huge.xcworkspace",
    xcodeProductCacheDerivedDataPath: cacheDerivedData.path
  )
  let installer = SwiftAppInstaller(request: request)
  let candidates = installer.buildCandidates(
    for: temporaryDirectory,
    configuration: request.configuration,
    product: request.product
  )

  #expect(candidates.first?.path == cacheApp.path)
  #expect(try installer.locateBuiltApp().path == cacheApp.path)
  #expect(try installer.cachedBuiltApp()?.path == cacheApp.path)
}

@Test("CUJ-15 build invocation uses shared workspace and cache derived data")
func buildInvocationUsesSharedWorkspaceAndCacheDerivedData() throws {
  let request = SwiftAppInstaller.Request(
    packagePath: "/workspace/App",
    product: "CreativeSelection",
    configuration: .debug,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: false,
    xcodeProject: "/workspace/App/CreativeSelection.xcodeproj",
    xcodeWorkspace: "/workspace/App/CreativeSelection.xcworkspace",
    xcodeScheme: "CreativeSelection",
    derivedDataPath: "/workspace/App/.derived-data",
    xcodeProductCacheWorkspace: "/workspace/Huge/Huge.xcworkspace",
    xcodeProductCacheDerivedDataPath: "/workspace/Huge/.derived-data",
    xcodeBuildSettings: ["CODE_SIGNING_ALLOWED=NO"]
  )

  #expect(try request.xcodeBuildInvocation().arguments == [
    "-workspace", "/workspace/Huge/Huge.xcworkspace",
    "-scheme", "CreativeSelection",
    "-configuration", "Debug",
    "-destination", SwiftAppInstaller.defaultXcodeDestination,
    "-derivedDataPath", "/workspace/Huge/.derived-data",
    "CODE_SIGNING_ALLOWED=NO",
    "build",
  ])
}

@Test("CUJ-15 rejects incomplete workspace cache configuration")
func rejectsIncompleteWorkspaceCacheConfiguration() throws {
  let missingDerivedData = SwiftAppInstaller.Request(
    packagePath: "/workspace/App",
    product: "CreativeSelection",
    configuration: .debug,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: false,
    xcodeScheme: "CreativeSelection",
    xcodeProductCacheWorkspace: "/workspace/Huge/Huge.xcworkspace"
  )
  let missingWorkspace = SwiftAppInstaller.Request(
    packagePath: "/workspace/App",
    product: "CreativeSelection",
    configuration: .debug,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: false,
    xcodeScheme: "CreativeSelection",
    xcodeProductCacheDerivedDataPath: "/workspace/Huge/.derived-data"
  )

  #expect(throws: InstallerError.self) { try missingDerivedData.xcodeBuildInvocation() }
  #expect(throws: InstallerError.self) { try missingWorkspace.xcodeBuildInvocation() }
}
