import XcodeProjectDefinitionCore
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
    "xcode",
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

@Test("CUJ-02 parses a Pkl-driven Xcode app test without a SwiftPM app package")
func parsesPklDrivenXcodeAppTestWithoutSwiftPMPackage() throws {
  let command = try VaporizeCLI.parse([
    "test",
    "xcode",
    "--artifact", "app",
    "--pkl-path", "/workspace/app/project.pkl",
    "--xcode-project", "/workspace/app/App.xcodeproj",
    "--scheme", "App",
    "--configuration", "debug",
    "--xcode-build-setting", "CODE_SIGNING_ALLOWED=NO",
  ])

  #expect(command.mode == .test)
  #expect(command.artifact == .app)
  #expect(command.packagePath == nil)
  #expect(command.pklPath == "/workspace/app/project.pkl")
  #expect(command.xcodeProject == "/workspace/app/App.xcodeproj")
  #expect(command.xcodeScheme == "App")
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
  #expect(
    installer.buildCandidates(
      for: tmp, configuration: request.configuration, product: request.product
    ).first?.path == applePath.path)
  #expect(try installer.locateBuiltApp().path == applePath.path)
}

@Test("CUJ-02 verifies the source-resolved version/build pair in an app bundle")
func verifiesBuiltAppIdentity() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: root) }

  let app = root.appendingPathComponent("Disk Cleaner.app")
  let contents = app.appendingPathComponent("Contents")
  try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
  let plist: [String: String] = [
    "CFBundleShortVersionString": "0.0.3",
    "CFBundleVersion": "4",
  ]
  let plistData = try PropertyListSerialization.data(
    fromPropertyList: plist,
    format: .xml,
    options: 0
  )
  try plistData.write(to: contents.appendingPathComponent("Info.plist"))

  let request = SwiftAppInstaller.Request(
    packagePath: root.path,
    product: "Disk Cleaner",
    skipBuild: true,
    expectedMarketingVersion: "0.0.3",
    expectedBuildNumber: "4"
  )
  let installer = SwiftAppInstaller(request: request)
  try installer.verifyAppIdentity(at: app)

  let wrongBuild = SwiftAppInstaller(
    request: .init(
      packagePath: root.path,
      product: "Disk Cleaner",
      skipBuild: true,
      expectedMarketingVersion: "0.0.3",
      expectedBuildNumber: "5"
    )
  )
  #expect(throws: InstallerError.self) {
    try wrongBuild.verifyAppIdentity(at: app)
  }
}

@Test("CUJ-02 app auto-increment advances the Pkl carrier only with explicit dirty policy")
func preparesAutoIncrementedAppBuildIdentity() async throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: root) }

  let git = try await VaporizeTestCommand.run(
    executablePath: "/usr/bin/git",
    arguments: ["init", root.path],
    sourceTag: "vaporize-cuj-02-git-init"
  )
  #expect(git.exitCode == 0)

  let pkl = root.appendingPathComponent("project.pkl")
  try """
  module diskCleaner
  settings = new {
    base = new {
      [\"CURRENT_PROJECT_VERSION\"] = 3
      [\"MARKETING_VERSION\"] = \"0.0.3\"
    }
  }
  """.write(to: pkl, atomically: true, encoding: .utf8)

  let baseArguments = [
    "build",
    "--artifact", "app",
    "--package-path", root.path,
    "--product", "Disk Cleaner",
    "--pkl-path", pkl.path,
    "--auto-increment-build",
  ]
  let blocked = try VaporizeCLI.parse(baseArguments)
  do {
    _ = try await blocked.prepareAppBuildNumberIdentity(for: .build)
    Issue.record("Expected a dirty source worktree to require explicit policy.")
  } catch is ValidationError {
    // Expected: this temporary Pkl is intentionally untracked.
  }

  let allowed = try VaporizeCLI.parse(baseArguments + ["--allow-dirty-build-number-source"])
  let identity = try await allowed.prepareAppBuildNumberIdentity(for: .build)
  #expect(identity?.marketingVersion == "0.0.3")
  #expect(identity?.buildNumber == 4)
  #expect(identity?.receipt.previousBuildNumber == 3)
  #expect(identity?.receipt.nextBuildNumber == 4)
  #expect(try String(contentsOf: pkl, encoding: .utf8).contains("CURRENT_PROJECT_VERSION\"] = 4"))
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
  #expect(
    installer.buildCandidates(
      for: tmp, configuration: request.configuration, product: request.product
    ).first?.path == derivedProduct.path)
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

  #expect(
    try request.xcodeBuildInvocation().arguments == [
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

@Test("CUJ-02 builds typed Xcode app-test invocation without SwiftPM semantics")
func buildsTypedXcodeAppTestInvocation() throws {
  let request = SwiftAppInstaller.Request(
    packagePath: "/workspace/App",
    product: "Launch Review",
    configuration: .debug,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true,
    xcodeProject: "/workspace/App/LaunchReview.xcodeproj",
    xcodeScheme: "launch-review-viewer",
    derivedDataPath: "/workspace/App/.derived-data",
    xcodeDestinations: ["platform=macOS,arch=arm64"],
    xcodeBuildSettings: ["CODE_SIGNING_ALLOWED=NO"]
  )

  #expect(
    try request.xcodeTestArguments() == [
      "-project", "/workspace/App/LaunchReview.xcodeproj",
      "-scheme", "launch-review-viewer",
      "-configuration", "Debug",
      "-destination", "platform=macOS,arch=arm64",
      "-derivedDataPath", "/workspace/App/.derived-data",
      "CODE_SIGNING_ALLOWED=NO",
      "test",
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

  #expect(
    try request.xcodeBuildInvocation().arguments == [
      "-workspace", "/workspace/App/CreativeSelection.xcworkspace",
      "-scheme", "CreativeSelection",
      "-configuration", "Release",
      "-destination", SwiftAppInstaller.defaultXcodeDestination,
      "-derivedDataPath", "/workspace/App/.build/vaporize-xcode-derived-data",
      "build",
    ])
}

@Test(
  "CUJ-02 synthesizes a package-local derived data path when none is provided for an Xcode build")
func synthesizesDerivedDataPathForXcodeBuildWithoutExplicitPath() throws {
  let request = SwiftAppInstaller.Request(
    packagePath: "/workspace/App",
    product: "CreativeSelection",
    configuration: .debug,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: false,
    xcodeProject: "/workspace/App/CreativeSelection.xcodeproj",
    xcodeScheme: "CreativeSelection"
  )

  // The xcodebuild invocation must pin an explicit -derivedDataPath so a
  // successful build lands in a directory the locator also searches.
  #expect(
    try request.xcodeBuildInvocation().arguments == [
      "-project", "/workspace/App/CreativeSelection.xcodeproj",
      "-scheme", "CreativeSelection",
      "-configuration", "Debug",
      "-destination", SwiftAppInstaller.defaultXcodeDestination,
      "-derivedDataPath", "/workspace/App/.build/vaporize-xcode-derived-data",
      "build",
    ])
  #expect(
    request.resolvedXcodeDerivedDataPath == "/workspace/App/.build/vaporize-xcode-derived-data")
}

@Test("CUJ-02 locates the Xcode-built app under the synthesized derived data directory")
func locatesXcodeBuiltAppUnderSynthesizedDerivedData() throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tmp) }

  // Mirror what xcodebuild writes under the pinned -derivedDataPath.
  let builtApp =
    tmp
    .appendingPathComponent(SwiftAppInstaller.Request.defaultXcodeDerivedDataDirectoryName)
    .appendingPathComponent("Build/Products/Debug/CreativeSelection.app")
  try FileManager.default.createDirectory(at: builtApp, withIntermediateDirectories: true)

  let request = SwiftAppInstaller.Request(
    packagePath: tmp.path,
    product: "CreativeSelection",
    configuration: .debug,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true,
    xcodeProject: tmp.appendingPathComponent("CreativeSelection.xcodeproj").path,
    xcodeScheme: "CreativeSelection"
  )

  let installer = SwiftAppInstaller(request: request)
  #expect(try installer.locateBuiltApp().path == builtApp.path)
}

@Test("CUJ-02 SwiftPM layout is still located when no Xcode build is configured")
func swiftPMLayoutStillLocatedWithoutXcodeBuild() throws {
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tmp) }

  let swiftPMApp = tmp.appendingPathComponent(".build/apple/Products/Debug/PlainApp.app")
  try FileManager.default.createDirectory(at: swiftPMApp, withIntermediateDirectories: true)

  let request = SwiftAppInstaller.Request(
    packagePath: tmp.path,
    product: "PlainApp",
    configuration: .debug,
    destination: "/Applications",
    forceReinstall: false,
    skipBuild: true
  )

  // No Xcode build → no synthesized derived data candidate; SwiftPM path wins.
  #expect(request.resolvedXcodeDerivedDataPath == nil)
  #expect(try SwiftAppInstaller(request: request).locateBuiltApp().path == swiftPMApp.path)
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

  let builtPath = tmp.appendingPathComponent(
    ".build/apple/Products/Debug/CreativeSelectionDebug.app")
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
  let spec = try XcodeProjectYMLReader.load(url: concourseProjectYMLURL)

  #expect(
    XcodeProjectAppBundleNameResolver.appBundleName(
      in: spec, targetName: "concourse", configuration: "Debug") == "concourse-0.0.1-debug")
  #expect(
    XcodeProjectAppBundleNameResolver.appBundleName(
      in: spec, targetName: "concourse", configuration: "Release") == "concourse-0.0.1-testflight")
}

@Test(
  "CUJ-02 resolves Pkl wrapper identity from the source root for an out-of-tree generated project")
func resolvesPklWrapperIdentityFromSourceRootForOutOfTreeGeneratedProject() async throws {
  let fixture = try makeAppBundleIdentityFixture(
    pklWrapperName: "pkl-debug",
    ymlWrapperName: "legacy-debug"
  )
  defer { try? FileManager.default.removeItem(at: fixture.temporaryDirectory) }

  let command = try VaporizeCLI.parse([
    "build",
    "xcode",
    "--artifact",
    "app",
    "--package-path",
    fixture.sourceRoot.path,
    "--product",
    "PklApp",
    "--xcode-project",
    fixture.generatedProject.path,
    "--scheme",
    "PklApp",
    "--configuration",
    "debug",
  ])

  #expect(await command.resolvedAppBundleName(product: "PklApp") == "pkl-debug")
}

@Test("CUJ-02 project-adjacent Pkl is checked before the generated project's source root")
func projectAdjacentPklIsCheckedBeforeSourceRoot() throws {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-app-bundle-identity-\(UUID().uuidString)")
  let projectDirectory = temporaryDirectory.appendingPathComponent("generated")
  let sourceRoot = temporaryDirectory.appendingPathComponent("source")
  let projectURL = projectDirectory.appendingPathComponent("PklApp.xcodeproj")
  let request = XcodeAppBundleIdentityResolutionRequest(
    explicitPklPath: nil,
    xcodeProjectPath: projectURL.path,
    xcodeWorkspacePath: nil,
    sourceRootPath: sourceRoot.path,
    targetName: "PklApp",
    configuration: "Debug",
    workingDirectoryURL: temporaryDirectory
  )

  let candidates = XcodeAppBundleIdentityResolver.candidateProjectPklURLs(for: request)

  #expect(
    candidates.map(\.path) == [
      projectDirectory.appendingPathComponent("project.pkl").path,
      sourceRoot.appendingPathComponent("project.pkl").path,
    ])
}

@Test("CUJ-02 retains project.yml wrapper discovery when no Pkl record is present")
func retainsLegacyYMLWrapperDiscoveryWhenNoPklIsPresent() async throws {
  let fixture = try makeAppBundleIdentityFixture(
    pklWrapperName: nil,
    ymlWrapperName: "legacy-debug"
  )
  defer { try? FileManager.default.removeItem(at: fixture.temporaryDirectory) }

  let command = try VaporizeCLI.parse([
    "build",
    "xcode",
    "--artifact",
    "app",
    "--package-path",
    fixture.sourceRoot.path,
    "--product",
    "PklApp",
    "--xcode-project",
    fixture.generatedProject.path,
    "--scheme",
    "PklApp",
    "--configuration",
    "debug",
  ])

  #expect(await command.resolvedAppBundleName(product: "PklApp") == "legacy-debug")
}

@Test("CUJ-02 bundle resolver uses case-insensitive configuration names")
func bundleResolverUsesCaseInsensitiveConfigurationNames() throws {
  let spec = try decodeXcodeProjectYML(
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

  #expect(
    XcodeProjectAppBundleNameResolver.appBundleName(
      in: spec, targetName: "mac", configuration: "debug") == "mac-debug")
}

@Test("CUJ-02 bundle resolver falls back to the single target")
func bundleResolverFallsBackToSingleTarget() throws {
  let spec = try decodeXcodeProjectYML(
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

  #expect(
    XcodeProjectAppBundleNameResolver.appBundleName(
      in: spec, targetName: "missing", configuration: "Release") == "only")
}

@Test("CUJ-02 bundle resolver rejects unresolved wrapper placeholders")
func bundleResolverRejectsUnresolvedWrapperPlaceholders() throws {
  let spec = try decodeXcodeProjectYML(
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

  #expect(
    XcodeProjectAppBundleNameResolver.appBundleName(
      in: spec, targetName: "mac", configuration: "Debug") == nil)
}

private struct AppBundleIdentityFixture {
  var temporaryDirectory: URL
  var sourceRoot: URL
  var generatedProject: URL
}

private func makeAppBundleIdentityFixture(
  pklWrapperName: String?,
  ymlWrapperName: String
) throws -> AppBundleIdentityFixture {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-app-bundle-identity-\(UUID().uuidString)")
  let sourceRoot = temporaryDirectory.appendingPathComponent("source")
  let generatedProject =
    temporaryDirectory
    .appendingPathComponent("generated")
    .appendingPathComponent("PklApp.xcodeproj")
  try FileManager.default.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: generatedProject, withIntermediateDirectories: true)

  let yml = appBundleIdentityYML(wrapperName: ymlWrapperName)
  try Data(yml.utf8).write(to: sourceRoot.appendingPathComponent("project.yml"))

  if let pklWrapperName {
    let spec = try decodeXcodeProjectYML(appBundleIdentityYML(wrapperName: pklWrapperName))
    let pkl = XcodeProjectPklRenderer.renderData(
      spec: spec,
      schemaAmendsPath: relativePathForPklAmends(
        from: sourceRoot,
        to: xcodeProjectDefinitionPklSchemaURL
      ),
      sourcePath: "project.yml"
    )
    try pkl.write(to: sourceRoot.appendingPathComponent("project.pkl"))
  }

  return AppBundleIdentityFixture(
    temporaryDirectory: temporaryDirectory,
    sourceRoot: sourceRoot,
    generatedProject: generatedProject
  )
}

private func appBundleIdentityYML(wrapperName: String) -> String {
  """
  name: pkl-wrapper-app
  targets:
    PklApp:
      type: application
      platform: macOS
      settings:
        base:
          PRODUCT_NAME: PklApp
        configs:
          Debug:
            WRAPPER_NAME: \(wrapperName).app
  """
}
