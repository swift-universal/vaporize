import AppleProjectSpecCore
import ArgumentParser
import Foundation
import Testing
import VaporizeTestSupport

@testable import SwiftAppInstaller
@testable import VaporizeCLI

@Test("CUJ-02 parses app install mode with Xcode build options")
func parsesAppInstallModeWithXcodeBuildOptions() throws {
  let command = try VaporizeCLI.parse([
    "install",
    "--artifact",
    "app",
    "--package-path",
    "/workspace/app",
    "--product",
    "Concourse",
    "--app-bundle-name",
    "ConcourseDebug",
    "--destination",
    "/tmp/Applications",
    "--launch",
    "--xcode-project",
    "/workspace/app/Concourse.xcodeproj",
    "--scheme",
    "Concourse",
    "--derived-data-path",
    "/workspace/app/.derived-data",
    "--xcode-destination",
    "platform=macOS,arch=arm64",
    "--xcode-sdk",
    "macosx",
    "--xcode-build-setting",
    "CODE_SIGNING_ALLOWED=NO",
  ])

  #expect(command.mode == .install)
  #expect(command.artifact == .app)
  #expect(command.packagePath == "/workspace/app")
  #expect(command.product == "Concourse")
  #expect(command.appBundleName == "ConcourseDebug")
  #expect(command.destination == "/tmp/Applications")
  #expect(command.launch)
  #expect(command.xcodeProject == "/workspace/app/Concourse.xcodeproj")
  #expect(command.xcodeScheme == "Concourse")
  #expect(command.derivedDataPath == "/workspace/app/.derived-data")
  #expect(command.xcodeDestinations == ["platform=macOS,arch=arm64"])
  #expect(command.xcodeSDK == "macosx")
  #expect(command.xcodeBuildSettings == ["CODE_SIGNING_ALLOWED=NO"])
}

@Test("CUJ-02 picks Apple build path first")
func picksAppleBuildPathFirst() throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
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
  #expect(installer.buildCandidates(for: tmp, configuration: request.configuration, product: request.product).first?.path == applePath.path)
  #expect(try installer.locateBuiltApp().path == applePath.path)
}

@Test("CUJ-02 prefers derived data when provided")
func prefersDerivedDataWhenProvided() throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tmp) }

  let derivedData = tmp.appendingPathComponent(".derived")
  let derivedProduct = derivedData.appendingPathComponent("Build/Products/Release/MyApp.app")
  try FileManager.default.createDirectory(at: derivedProduct, withIntermediateDirectories: true)
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
  #expect(installer.buildCandidates(for: tmp, configuration: request.configuration, product: request.product).first?.path == derivedProduct.path)
  #expect(try installer.locateBuiltApp().path == derivedProduct.path)
}

@Test("CUJ-02 builds typed Xcode invocation")
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
    xcodeBuildSettings: ["CODE_SIGNING_ALLOWED=NO", "SKIP_APPLICATION_DEPLOY=YES"]
  )

  #expect(try request.xcodeBuildInvocation().arguments == [
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

@Test("CUJ-02 defaults Xcode destination when using xcodebuild")
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

  #expect(try request.xcodeBuildInvocation().arguments == [
    "-workspace", "/workspace/App/CreativeSelection.xcworkspace",
    "-scheme", "CreativeSelection",
    "-configuration", "Release",
    "-destination", SwiftAppInstaller.defaultXcodeDestination,
    "build",
  ])
}

@Test("CUJ-02 rejects ambiguous Xcode container")
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

  #expect(throws: InstallerError.self) { try request.xcodeBuildInvocation() }
}

@Test("CUJ-02 rejects missing Xcode scheme")
func rejectsMissingXcodeScheme() throws {
  let request = SwiftAppInstaller.Request(
    packagePath: "/workspace/App",
    product: "CreativeSelection",
    configuration: .release,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true,
    xcodeProject: "/workspace/App/CreativeSelection.xcodeproj"
  )

  #expect(throws: InstallerError.self) { try request.xcodeBuildInvocation() }
}

@Test("CUJ-02 rejects missing Xcode project or workspace")
func rejectsMissingXcodeProjectOrWorkspace() throws {
  let request = SwiftAppInstaller.Request(
    packagePath: "/workspace/App",
    product: "CreativeSelection",
    configuration: .release,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true,
    xcodeScheme: "CreativeSelection",
    xcodeSDK: "macosx"
  )

  #expect(throws: InstallerError.self) { try request.xcodeBuildInvocation() }
}

@Test("CUJ-02 rejects malformed Xcode build setting")
func rejectsMalformedXcodeBuildSetting() throws {
  let request = SwiftAppInstaller.Request(
    packagePath: "/workspace/App",
    product: "CreativeSelection",
    configuration: .release,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true,
    xcodeProject: "/workspace/App/CreativeSelection.xcodeproj",
    xcodeScheme: "CreativeSelection",
    xcodeBuildSettings: ["=NO"]
  )

  #expect(throws: InstallerError.self) { try request.xcodeBuildInvocation() }
}

@Test("CUJ-02 app bundle name controls located bundle without changing install product")
func appBundleNameControlsLocatedBundleWithoutChangingInstallProduct() throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
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

  #expect(try SwiftAppInstaller(request: request).locateBuiltApp().path == builtPath.path)
}

@Test("CUJ-02 bundle resolver expands Concourse debug and release wrapper names")
func bundleResolverExpandsConcourseWrapperNames() throws {
  let spec = try AppleProjectYMLReader.load(url: concourseProjectYMLURL)

  #expect(AppleProjectAppBundleNameResolver.appBundleName(in: spec, targetName: "concourse", configuration: "Debug") == "concourse-0.1.0-debug")
  #expect(AppleProjectAppBundleNameResolver.appBundleName(in: spec, targetName: "concourse", configuration: "Release") == "concourse-0.1.0-testflight")
}

@Test("CUJ-02 bundle resolver uses case-insensitive configuration names")
func bundleResolverUsesCaseInsensitiveConfigurationNames() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: app
    targets:
      mac:
        type: application
        platform: macOS
        settings:
          configs:
            Debug:
              WRAPPER_NAME: mac-debug.app
    """
  )

  #expect(AppleProjectAppBundleNameResolver.appBundleName(in: spec, targetName: "mac", configuration: "debug") == "mac-debug")
}

@Test("CUJ-02 bundle resolver falls back to the single target")
func bundleResolverFallsBackToSingleTarget() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: app
    targets:
      only:
        type: application
        platform: macOS
        settings:
          configs:
            Release:
              WRAPPER_NAME: only.app
    """
  )

  #expect(AppleProjectAppBundleNameResolver.appBundleName(in: spec, targetName: "missing", configuration: "Release") == "only")
}

@Test("CUJ-02 bundle resolver rejects unresolved wrapper placeholders")
func bundleResolverRejectsUnresolvedWrapperPlaceholders() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: app
    targets:
      mac:
        type: application
        platform: macOS
        settings:
          configs:
            Debug:
              WRAPPER_NAME: "$(UNKNOWN).app"
    """
  )

  #expect(AppleProjectAppBundleNameResolver.appBundleName(in: spec, targetName: "mac", configuration: "Debug") == nil)
}
