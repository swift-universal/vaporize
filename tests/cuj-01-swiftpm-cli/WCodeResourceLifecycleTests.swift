import ArgumentParser
import Foundation
import Testing
import XcodeProjectDefinitionCore

@testable import VaporizeCLI

@Suite("CUJ-01 WCode canonical Pkl resource lifecycle")
struct WCodeResourceLifecycleTests {
  @Test("Copy resources materialize and optional missing resources remain explicit")
  func copyResourcesMaterialize() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.write("terminal-theme", to: "AppResources/theme.txt")
    try fixture.write("nested", to: "AppResources/Help/index.txt")

    let project = try fixture.project(resources: [
      XcodeProjectResource(path: "AppResources/theme.txt", mode: .copy, destination: "theme.txt"),
      XcodeProjectResource(path: "AppResources/Help", mode: .copy, destination: "Help"),
      XcodeProjectResource(path: "AppResources/missing.txt", mode: .copy, optional: true),
    ])
    let plan = try WCodeResourceLifecycle.plan(
      project: project,
      projectURL: fixture.root.appendingPathComponent("project.pkl"),
      targetName: "WrktrmlWindows",
      expectedPlatform: "Windows",
      projectRoot: fixture.root,
      product: "Wrktrml",
      buildProductsDirectory: fixture.buildProductsDirectory
    )

    #expect(plan.entries.count == 3)
    #expect(plan.entries.last?.disposition == .skipOptionalMissing)
    let receipt = try WCodeResourceLifecycle.materialize(plan)

    #expect(
      try String(contentsOf: fixture.output.appendingPathComponent("theme.txt"), encoding: .utf8)
        == "terminal-theme")
    #expect(
      try String(
        contentsOf: fixture.output.appendingPathComponent("Help/index.txt"), encoding: .utf8)
        == "nested")
    #expect(receipt.entries.map(\.disposition) == [.copied, .copied, .skippedOptionalMissing])
  }

  @Test("Source traversal and destination collisions fail before publication")
  func traversalAndCollisionFail() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.write("one", to: "Resources/one.txt")
    try fixture.write("two", to: "Resources/two.txt")

    #expect(throws: WCodeResourceLifecycleError.pathTraversal("../secret.txt")) {
      _ = try WCodeResourceLifecycle.plan(
        project: try fixture.project(resources: [
          XcodeProjectResource(path: "../secret.txt", mode: .copy)
        ]),
        projectURL: fixture.root.appendingPathComponent("project.pkl"),
        targetName: "WrktrmlWindows",
        expectedPlatform: "Windows",
        projectRoot: fixture.root,
        product: "Wrktrml",
        buildProductsDirectory: fixture.buildProductsDirectory
      )
    }

    #expect(throws: WCodeResourceLifecycleError.self) {
      _ = try WCodeResourceLifecycle.plan(
        project: try fixture.project(resources: [
          XcodeProjectResource(path: "Resources/one.txt", mode: .copy, destination: "Assets"),
          XcodeProjectResource(
            path: "Resources/two.txt", mode: .copy, destination: "Assets/two.txt"),
        ]),
        projectURL: fixture.root.appendingPathComponent("project.pkl"),
        targetName: "WrktrmlWindows",
        expectedPlatform: "Windows",
        projectRoot: fixture.root,
        product: "Wrktrml",
        buildProductsDirectory: fixture.buildProductsDirectory
      )
    }
    #expect(!FileManager.default.fileExists(atPath: fixture.output.path))
  }

  @Test("Unsupported processing and filtering never fall through to a script")
  func unsupportedSemanticsFailClosed() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.write("theme", to: "Resources/theme.json")

    #expect(
      throws: WCodeResourceLifecycleError.unsupportedMode(
        path: "Resources/theme.json", mode: .process)
    ) {
      _ = try WCodeResourceLifecycle.plan(
        project: try fixture.project(resources: [
          XcodeProjectResource(path: "Resources/theme.json", mode: .process)
        ]),
        projectURL: fixture.root.appendingPathComponent("project.pkl"),
        targetName: "WrktrmlWindows",
        expectedPlatform: "Windows",
        projectRoot: fixture.root,
        product: "Wrktrml",
        buildProductsDirectory: fixture.buildProductsDirectory
      )
    }

    #expect(throws: WCodeResourceLifecycleError.unsupportedFilters(path: "Resources/theme.json")) {
      _ = try WCodeResourceLifecycle.plan(
        project: try fixture.project(resources: [
          XcodeProjectResource(
            path: "Resources/theme.json",
            mode: .copy,
            includes: ["*.json"]
          )
        ]),
        projectURL: fixture.root.appendingPathComponent("project.pkl"),
        targetName: "WrktrmlWindows",
        expectedPlatform: "Windows",
        projectRoot: fixture.root,
        product: "Wrktrml",
        buildProductsDirectory: fixture.buildProductsDirectory
      )
    }
  }

  @Test("Target platform must match the requested WCode lane")
  func targetPlatformMustMatch() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let project = try fixture.project(
      targetName: "WrktrmlMac",
      platform: "macOS",
      resources: []
    )

    #expect(
      throws: WCodeResourceLifecycleError.platformMismatch(
        target: "WrktrmlMac", expected: "Windows", actual: "macOS")
    ) {
      _ = try WCodeResourceLifecycle.plan(
        project: project,
        projectURL: fixture.root.appendingPathComponent("project.pkl"),
        targetName: "WrktrmlMac",
        expectedPlatform: "Windows",
        projectRoot: fixture.root,
        product: "Wrktrml",
        buildProductsDirectory: fixture.buildProductsDirectory
      )
    }
  }

  @Test("Materialization replaces stale resource world-state")
  func materializationReplacesStaleState() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.write("first", to: "Resources/value.txt")
    let project = try fixture.project(resources: [
      XcodeProjectResource(path: "Resources/value.txt", mode: .copy, destination: "value.txt")
    ])
    let plan = try WCodeResourceLifecycle.plan(
      project: project,
      projectURL: fixture.root.appendingPathComponent("project.pkl"),
      targetName: "WrktrmlWindows",
      expectedPlatform: "Windows",
      projectRoot: fixture.root,
      product: "Wrktrml",
      buildProductsDirectory: fixture.buildProductsDirectory
    )
    _ = try WCodeResourceLifecycle.materialize(plan)
    try fixture.write("stale", to: "build/Wrktrml.resources/stale.txt")
    try fixture.write("second", to: "Resources/value.txt")

    _ = try WCodeResourceLifecycle.materialize(plan)

    #expect(
      try String(contentsOf: fixture.output.appendingPathComponent("value.txt"), encoding: .utf8)
        == "second"
    )
    #expect(
      !FileManager.default.fileExists(
        atPath: fixture.output.appendingPathComponent("stale.txt").path
      )
    )
  }

  @Test("Install carries executable DLLs SwiftPM bundles and canonical resources")
  func installsRuntimeClosureAndResources() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.write("exe-v1", to: "build/Wrktrml.exe")
    try fixture.write("dll", to: "build/Runtime.dll")
    try fixture.write("bundle", to: "build/Dependency.bundle/payload.txt")
    try fixture.write("swiftpm", to: "build/Package_Target.resources/value.txt")
    try fixture.write("project", to: "build/Wrktrml.resources/theme.json")
    try fixture.write("unrelated", to: "build/OtherProduct.dll")

    let layout = try WCodeResourceLifecycle.builtArtifactLayout(
      product: "Wrktrml",
      buildProductsDirectory: fixture.buildProductsDirectory,
      runtimeArtifactNames: [
        "Runtime.dll",
        "Dependency.bundle",
        "Package_Target.resources",
      ]
    )
    #expect(
      Set(layout.runtimeArtifactPaths.map { URL(fileURLWithPath: $0).lastPathComponent })
        == Set([
          "Wrktrml.exe",
          "Runtime.dll",
          "Dependency.bundle",
          "Package_Target.resources",
          "Wrktrml.resources",
        ])
    )

    #expect(!layout.runtimeArtifactPaths.contains { $0.hasSuffix("OtherProduct.dll") })

    let allowedInstallRoot = fixture.root.appendingPathComponent("install")
    let destination = allowedInstallRoot.appendingPathComponent("Wrktrml")
    let receipt = try WCodeResourceLifecycle.install(
      layout,
      destination: destination,
      allowedInstallRoot: allowedInstallRoot,
      force: false
    )
    #expect(
      try String(
        contentsOf: URL(fileURLWithPath: receipt.installedExecutablePath),
        encoding: .utf8
      ) == "exe-v1"
    )
    #expect(
      try String(
        contentsOf: URL(fileURLWithPath: receipt.installedResourceRoot)
          .appendingPathComponent("theme.json"),
        encoding: .utf8
      ) == "project"
    )
    #expect(
      FileManager.default.fileExists(
        atPath: destination.appendingPathComponent("Runtime.dll").path
      )
    )
    #expect(
      FileManager.default.fileExists(
        atPath: destination.appendingPathComponent("Dependency.bundle/payload.txt").path
      )
    )
    #expect(
      !FileManager.default.fileExists(
        atPath: destination.appendingPathComponent("OtherProduct.dll").path
      )
    )

    #expect(throws: WCodeResourceLifecycleError.installDestinationExists(destination.path)) {
      _ = try WCodeResourceLifecycle.install(
        layout,
        destination: destination,
        allowedInstallRoot: allowedInstallRoot,
        force: false
      )
    }

    try fixture.write("exe-v2", to: "build/Wrktrml.exe")
    try fixture.write("stale", to: "install/Wrktrml/stale.txt")
    _ = try WCodeResourceLifecycle.install(
      layout,
      destination: destination,
      allowedInstallRoot: allowedInstallRoot,
      force: true
    )
    #expect(
      try String(contentsOf: destination.appendingPathComponent("Wrktrml.exe"), encoding: .utf8)
        == "exe-v2"
    )
    #expect(
      !FileManager.default.fileExists(
        atPath: destination.appendingPathComponent("stale.txt").path
      )
    )

    let outsideDestination = fixture.root.appendingPathComponent("outside/Wrktrml")
    try fixture.write("preserve", to: "outside/Wrktrml/sentinel.txt")
    #expect(
      throws: WCodeResourceLifecycleError.installDestinationOutsideAllowedRoot(
        destination: outsideDestination.standardizedFileURL.path,
        allowedRoot: allowedInstallRoot.standardizedFileURL.path
      )
    ) {
      _ = try WCodeResourceLifecycle.install(
        layout,
        destination: outsideDestination,
        allowedInstallRoot: allowedInstallRoot,
        force: true
      )
    }
    #expect(
      try String(
        contentsOf: outsideDestination.appendingPathComponent("sentinel.txt"),
        encoding: .utf8
      ) == "preserve"
    )

    let materialization = WCodeResourceMaterializationReceipt(
      projectPath: fixture.root.appendingPathComponent("project.pkl").path,
      targetName: "WrktrmlWindows",
      platform: "Windows",
      resourceRoot: fixture.output.path,
      entries: []
    )
    let lifecycleReceipt = WCodeLifecycleReceipt(
      materialization: materialization,
      artifactLayout: layout,
      install: receipt
    )
    let encodedReceipt = try JSONEncoder().encode(lifecycleReceipt)
    #expect(
      try JSONDecoder().decode(WCodeLifecycleReceipt.self, from: encodedReceipt) == lifecycleReceipt
    )

    let coreReceipt = VaporizeCoreExecutionReceipt(
      operation: "install",
      executionAuthority: "wcode",
      toolchainResolver: "default-swift",
      packagePath: fixture.root.path,
      product: "Wrktrml",
      configuration: "release",
      startedAt: Date(timeIntervalSince1970: 1_700_000_000),
      finishedAt: Date(timeIntervalSince1970: 1_700_000_001),
      commandElapsedNanoseconds: 1_000_000_000,
      dependencyPreparationNanoseconds: 0,
      dependencyRestoreNanoseconds: 0,
      processExecutionNanoseconds: 500_000_000,
      succeeded: true,
      artifactPath: receipt.installedExecutablePath,
      failureDescription: nil
    )
    let combinedReceipt = WCodeCombinedCoreExecutionReceipt(
      core: coreReceipt,
      wcodeLifecycle: lifecycleReceipt
    )
    let combinedData = try JSONEncoder().encode(combinedReceipt)
    let combinedObject = try #require(
      JSONSerialization.jsonObject(with: combinedData) as? [String: Any]
    )
    #expect(combinedObject["receiptKind"] as? String == "vaporize-core-execution")
    #expect(combinedObject["core"] == nil)
    #expect(combinedObject["wcodeLifecycle"] != nil)
    #expect(
      try JSONDecoder().decode(WCodeCombinedCoreExecutionReceipt.self, from: combinedData)
        == combinedReceipt
    )
  }

  @Test("Product and runtime artifact names are fail-closed Windows components")
  func unsafeProductAndRuntimeArtifactsFailClosed() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    for unsafeProduct in ["../escape", "folder\\app", "C:app", "CON", "app.", "app "] {
      #expect(throws: WCodeResourceLifecycleError.unsafeProductName(unsafeProduct)) {
        _ = try WCodeResourceLifecycle.validateProductName(unsafeProduct)
      }
    }
    let derivedResourceRoot = try WCodeResourceLifecycle.resourceRoot(
      product: "Wrktrml",
      buildProductsDirectory: fixture.buildProductsDirectory
    )
    #expect(
      derivedResourceRoot.standardizedFileURL.path.lowercased()
        == fixture.output.standardizedFileURL.path.lowercased()
    )

    try fixture.write("exe", to: "build/Wrktrml.exe")
    try fixture.write("resource", to: "build/Wrktrml.resources/value.txt")
    try fixture.write("unsupported", to: "build/notes.txt")

    #expect(throws: WCodeResourceLifecycleError.unsafeRuntimeArtifactName("../Runtime.dll")) {
      _ = try WCodeResourceLifecycle.builtArtifactLayout(
        product: "Wrktrml",
        buildProductsDirectory: fixture.buildProductsDirectory,
        runtimeArtifactNames: ["../Runtime.dll"]
      )
    }
    let missingRuntimePath = fixture.buildProductsDirectory
      .appendingPathComponent("Missing.dll").path
    #expect(throws: WCodeResourceLifecycleError.missingRuntimeArtifact(missingRuntimePath)) {
      _ = try WCodeResourceLifecycle.builtArtifactLayout(
        product: "Wrktrml",
        buildProductsDirectory: fixture.buildProductsDirectory,
        runtimeArtifactNames: ["Missing.dll"]
      )
    }
    #expect(throws: WCodeResourceLifecycleError.unsupportedRuntimeArtifact("notes.txt")) {
      _ = try WCodeResourceLifecycle.builtArtifactLayout(
        product: "Wrktrml",
        buildProductsDirectory: fixture.buildProductsDirectory,
        runtimeArtifactNames: ["notes.txt"]
      )
    }
  }

  #if os(Windows)
    @Test("WCode resolves canonical project target and SwiftPM bin-path request")
    func resolvesCanonicalProjectAndBinPathArguments() throws {
      let fixture = try Fixture()
      defer { fixture.remove() }
      try fixture.write("// swift-tools-version: 6.2\n", to: "Package.swift")
      try fixture.write("placeholder", to: "project.pkl")
      let scratchPath = fixture.root.appendingPathComponent("scratch").path

      let command = try VaporizeCLI.parse([
        "build",
        "wcode",
        "--artifact", "app",
        "--package-path", fixture.root.path,
        "--product", "Wrktrml",
        "--target", "WrktrmlWindows",
        "--scratch-path", scratchPath,
      ])

      #expect(try command.wcodeProjectURL() == fixture.root.appendingPathComponent("project.pkl"))
      #expect(command.wcodeSelectedTargetName(product: "Wrktrml") == "WrktrmlWindows")
      let binPathArguments = try command.wcodeSwiftBinPathArguments()
      #expect(
        binPathArguments == [
          "build",
          "--scratch-path", scratchPath,
          "--package-path", fixture.root.path,
          "-c", "release",
          "--product", "Wrktrml",
          "--show-bin-path",
        ])

      let fallbackCommand = try VaporizeCLI.parse([
        "build",
        "wcode",
        "--artifact", "app",
        "--package-path", fixture.root.path,
        "--product", "Wrktrml",
      ])
      #expect(fallbackCommand.wcodeSelectedTargetName(product: "Wrktrml") == "Wrktrml")
    }
  #endif
}

private struct Fixture {
  let root: URL
  let output: URL

  var buildProductsDirectory: URL {
    root.appendingPathComponent("build", isDirectory: true)
  }

  init() throws {
    let base = FileManager.default.temporaryDirectory
      .appendingPathComponent("wcode-pkl-resources-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: false)
    self.root = base
    self.output = base.appendingPathComponent("build/Wrktrml.resources")
  }

  func write(_ value: String, to relativePath: String) throws {
    let destination = root.appendingPathComponent(relativePath)
    try FileManager.default.createDirectory(
      at: destination.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try Data(value.utf8).write(to: destination)
  }

  func project(
    targetName: String = "WrktrmlWindows",
    platform: String = "Windows",
    resources: [XcodeProjectResource]
  ) throws -> XcodeProjectDefinition {
    let data = try JSONEncoder().encode(
      FixtureProject(
        name: "wrktrml",
        targets: [targetName: FixtureTarget(platform: platform, resources: resources)]
      )
    )
    return try JSONDecoder().decode(XcodeProjectDefinition.self, from: data)
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}

private struct FixtureProject: Encodable {
  let name: String
  let targets: [String: FixtureTarget]
}

private struct FixtureTarget: Encodable {
  let platform: String
  let resources: [XcodeProjectResource]
}
