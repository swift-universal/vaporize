import Foundation
import Testing

@testable import SwiftAppInstaller

/// Proving ground for the app-mode build routing decision
/// (`XcodeAppInputResolver`) — the fix for
/// BUG-VAPORIZE-APP-MODE-SILENT-SWIFT-BUILD-FALLBACK-2026-07-09, where app mode
/// silently ran `swift build` against an `.xcodeproj` app instead of routing to
/// xcodebuild. Sweeps the option space (explicit flags × Package.swift presence
/// × directory contents × product-name disambiguation) rather than one happy
/// path, and pins the loud-failure branch that replaces the silent fallback.

private let dir = "/workspace/app"

/// A `.swiftPackage` directory keeps the SwiftPM build path: no project/workspace.
@Test("Package.swift present → SwiftPM path (no xcode inputs)")
func packageSwiftKeepsSwiftBuild() throws {
  let inputs = try XcodeAppInputResolver.resolve(
    packageDirectory: dir,
    explicitProject: nil, explicitWorkspace: nil, explicitScheme: nil,
    hasPackageSwift: true,
    entries: ["Package.swift", "Sources", "Tests"],
    product: "Whatever")
  #expect(inputs == .init(project: nil, workspace: nil, scheme: nil))
}

/// Explicit flags always win, untouched, regardless of directory contents.
@Test("explicit --xcode-project wins over discovery")
func explicitProjectWins() throws {
  let inputs = try XcodeAppInputResolver.resolve(
    packageDirectory: dir,
    explicitProject: "/w/A.xcodeproj", explicitWorkspace: nil, explicitScheme: "AScheme",
    hasPackageSwift: false,
    entries: ["Other.xcodeproj", "Package.swift"],
    product: "A")
  #expect(inputs == .init(project: "/w/A.xcodeproj", workspace: nil, scheme: "AScheme"))
}

/// The core fix: no Package.swift + a single `.xcodeproj` → xcodebuild inputs,
/// scheme defaulting to the product name.
@Test("no Package.swift + one .xcodeproj → xcode project, scheme = product")
func singleProjectRoutesToXcodebuild() throws {
  let inputs = try XcodeAppInputResolver.resolve(
    packageDirectory: dir,
    explicitProject: nil, explicitWorkspace: nil, explicitScheme: nil,
    hasPackageSwift: false,
    entries: ["collective.xcodeproj", "project.yml", "Sources"],
    product: "collective")
  #expect(inputs == .init(project: "\(dir)/collective.xcodeproj", workspace: nil, scheme: "collective"))
}

/// A workspace is preferred over a project when both exist.
@Test("no Package.swift + workspace and project → workspace preferred")
func workspacePreferredOverProject() throws {
  let inputs = try XcodeAppInputResolver.resolve(
    packageDirectory: dir,
    explicitProject: nil, explicitWorkspace: nil, explicitScheme: nil,
    hasPackageSwift: false,
    entries: ["App.xcworkspace", "App.xcodeproj"],
    product: "App")
  #expect(inputs == .init(project: nil, workspace: "\(dir)/App.xcworkspace", scheme: "App"))
}

/// Explicit scheme overrides the product-name default.
@Test("explicit --scheme overrides the product-name default")
func explicitSchemeOverridesProductDefault() throws {
  let inputs = try XcodeAppInputResolver.resolve(
    packageDirectory: dir,
    explicitProject: nil, explicitWorkspace: nil, explicitScheme: "CustomScheme",
    hasPackageSwift: false,
    entries: ["collective.xcodeproj"],
    product: "collective")
  #expect(inputs.scheme == "CustomScheme")
}

/// Multiple projects disambiguate by the one whose basename matches the product.
@Test("multiple .xcodeproj → the one matching the product name is chosen")
func multipleProjectsDisambiguateByProduct() throws {
  let inputs = try XcodeAppInputResolver.resolve(
    packageDirectory: dir,
    explicitProject: nil, explicitWorkspace: nil, explicitScheme: nil,
    hasPackageSwift: false,
    entries: ["Helper.xcodeproj", "collective.xcodeproj", "Extra.xcodeproj"],
    product: "collective")
  #expect(inputs.project == "\(dir)/collective.xcodeproj")
}

/// The loud-failure branch that replaces the silent `swift build` fallback:
/// neither a Swift package nor any Xcode project/workspace.
@Test("no Package.swift + no project/workspace → throws NoBuildableProject (loud)")
func neitherPackageNorProjectFailsLoud() throws {
  #expect(throws: XcodeAppInputResolver.NoBuildableProject.self) {
    try XcodeAppInputResolver.resolve(
      packageDirectory: dir,
      explicitProject: nil, explicitWorkspace: nil, explicitScheme: nil,
      hasPackageSwift: false,
      entries: ["README.md", "Sources"],
      product: "ghost")
  }
}

/// Multiple projects with NONE matching the product is ambiguous → loud failure,
/// never a silent guess.
@Test("multiple non-matching .xcodeproj → throws (ambiguous, no silent guess)")
func ambiguousProjectsFailLoud() throws {
  #expect(throws: XcodeAppInputResolver.NoBuildableProject.self) {
    try XcodeAppInputResolver.resolve(
      packageDirectory: dir,
      explicitProject: nil, explicitWorkspace: nil, explicitScheme: nil,
      hasPackageSwift: false,
      entries: ["Alpha.xcodeproj", "Beta.xcodeproj"],
      product: "collective")
  }
}

/// The loud error names both counts so the operator can see what was found.
@Test("NoBuildableProject message reports the workspace/project counts")
func loudErrorReportsCounts() throws {
  let error = XcodeAppInputResolver.NoBuildableProject(
    packageDirectory: dir, workspaceCount: 0, projectCount: 2)
  #expect(error.description.contains("workspaces: 0"))
  #expect(error.description.contains("projects: 2"))
  #expect(error.description.contains("not a Swift package"))
}
