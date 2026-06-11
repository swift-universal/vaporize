import Foundation
@testable import SwiftAppInstaller
import Testing

@Test
func picksAppleBuildPathFirst() throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tmp) }

  let applePath = tmp.appendingPathComponent(".build/apple/Products/Release/MyApp.app")
  try FileManager.default.createDirectory(at: applePath, withIntermediateDirectories: true)

  let request = SwiftAppInstaller.Request(
    packagePath: tmp.path,
    product: "MyApp",
    configuration: .release,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true
  )

  let installer = SwiftAppInstaller(request: request)
  #expect(FileManager.default.fileExists(atPath: applePath.path))
  let candidates = installer.buildCandidates(
    for: tmp,
    configuration: request.configuration,
    product: request.product
  )
  #expect(candidates.first?.path == applePath.path)
  #expect(try installer.locateBuiltApp().path == applePath.path)
}

@Test
func prefersDerivedDataWhenProvided() throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tmp) }

  let derivedData = tmp.appendingPathComponent(".derived")
  let derivedProduct = derivedData.appendingPathComponent("Build/Products/Release/MyApp.app")
  try FileManager.default.createDirectory(at: derivedProduct, withIntermediateDirectories: true)

  // Also create an apple build path to ensure derived data wins.
  let applePath = tmp.appendingPathComponent(".build/apple/Products/Release/MyApp.app")
  try FileManager.default.createDirectory(at: applePath, withIntermediateDirectories: true)

  let request = SwiftAppInstaller.Request(
    packagePath: tmp.path,
    product: "MyApp",
    configuration: .release,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true,
    derivedDataPath: derivedData.path
  )

  let installer = SwiftAppInstaller(request: request)
  #expect(FileManager.default.fileExists(atPath: derivedProduct.path))
  let candidates = installer.buildCandidates(
    for: tmp,
    configuration: request.configuration,
    product: request.product
  )
  #expect(candidates.first?.path == derivedProduct.path)
  #expect(try installer.locateBuiltApp().path == derivedProduct.path)
}

@Test
func buildsTypedXcodeInvocation() throws {
  let request = SwiftAppInstaller.Request(
    packagePath: "/workspace/App",
    product: "CreativeSelection",
    appBundleName: "CreativeSelectionDebug",
    configuration: .debug,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true,
    xcodeProject: "/workspace/App/CreativeSelection.xcodeproj",
    xcodeScheme: "CreativeSelection",
    derivedDataPath: "/workspace/App/.derived-data",
    xcodeDestinations: [
      "platform=macOS,arch=arm64",
      "platform=iOS Simulator,name=iPhone 16",
    ],
    xcodeSDK: "macosx",
    xcodeResultBundlePath: "/tmp/CreativeSelection.xcresult",
    xcodeBuildSettings: [
      "CODE_SIGNING_ALLOWED=NO",
      "SKIP_APPLICATION_DEPLOY=YES",
    ]
  )

  let invocation = try request.xcodeBuildInvocation()
  #expect(invocation.arguments == [
    "-project", "/workspace/App/CreativeSelection.xcodeproj",
    "-scheme", "CreativeSelection",
    "-configuration", "Debug",
    "-destination", "platform=macOS,arch=arm64",
    "-destination", "platform=iOS Simulator,name=iPhone 16",
    "-sdk", "macosx",
    "-derivedDataPath", "/workspace/App/.derived-data",
    "-resultBundlePath", "/tmp/CreativeSelection.xcresult",
    "CODE_SIGNING_ALLOWED=NO",
    "SKIP_APPLICATION_DEPLOY=YES",
    "build",
  ])
}

@Test
func defaultsXcodeDestinationWhenUsingXcodebuild() throws {
  let request = SwiftAppInstaller.Request(
    packagePath: "/workspace/App",
    product: "CreativeSelection",
    configuration: .release,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true,
    xcodeWorkspace: "/workspace/App/CreativeSelection.xcworkspace",
    xcodeScheme: "CreativeSelection"
  )

  let invocation = try request.xcodeBuildInvocation()
  #expect(invocation.arguments == [
    "-workspace", "/workspace/App/CreativeSelection.xcworkspace",
    "-scheme", "CreativeSelection",
    "-configuration", "Release",
    "-destination", SwiftAppInstaller.defaultXcodeDestination,
    "build",
  ])
}

@Test
func rejectsAmbiguousXcodeContainer() throws {
  let request = SwiftAppInstaller.Request(
    packagePath: "/workspace/App",
    product: "CreativeSelection",
    configuration: .release,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true,
    xcodeProject: "/workspace/App/CreativeSelection.xcodeproj",
    xcodeWorkspace: "/workspace/App/CreativeSelection.xcworkspace",
    xcodeScheme: "CreativeSelection"
  )

  #expect(throws: InstallerError.self) {
    try request.xcodeBuildInvocation()
  }
}

@Test
func appBundleNameControlsLocatedBundleWithoutChangingInstallProduct() throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tmp) }

  let builtPath = tmp.appendingPathComponent(".build/apple/Products/Debug/CreativeSelectionDebug.app")
  try FileManager.default.createDirectory(at: builtPath, withIntermediateDirectories: true)

  let request = SwiftAppInstaller.Request(
    packagePath: tmp.path,
    product: "CreativeSelection",
    appBundleName: "CreativeSelectionDebug",
    configuration: .debug,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true
  )

  let installer = SwiftAppInstaller(request: request)
  #expect(try installer.locateBuiltApp().path == builtPath.path)
}
