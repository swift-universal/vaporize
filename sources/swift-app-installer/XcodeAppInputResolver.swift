import Foundation

/// Pure routing decision for vaporize app mode.
///
/// Given the explicit Xcode flags, whether the package directory is a Swift
/// package, and which Xcode projects/workspaces live there, decide which build
/// inputs to hand to `SwiftAppInstaller.Request`. Kept filesystem-free so the
/// decision is unit-testable across its whole option space — the CLI supplies
/// the filesystem facts (`hasPackageSwift`, `entries`), this type makes the
/// call. This is what stops app mode from silently running `swift build`
/// against a non-SPM `.xcodeproj` app.
public enum XcodeAppInputResolver {

  /// Resolved build inputs for the app installer request.
  public struct Inputs: Equatable, Sendable {
    public var project: String?
    public var workspace: String?
    public var scheme: String?
    public init(project: String?, workspace: String?, scheme: String?) {
      self.project = project
      self.workspace = workspace
      self.scheme = scheme
    }
  }

  /// Thrown when the package directory is neither a Swift package nor a place
  /// with a unique Xcode project/workspace to build — the loud alternative to a
  /// silent, wrong-builder fallback.
  public struct NoBuildableProject: Error, Equatable, CustomStringConvertible {
    public let packageDirectory: String
    public let workspaceCount: Int
    public let projectCount: Int

    public init(packageDirectory: String, workspaceCount: Int, projectCount: Int) {
      self.packageDirectory = packageDirectory
      self.workspaceCount = workspaceCount
      self.projectCount = projectCount
    }

    public var description: String {
      "vaporize app mode: '\(packageDirectory)' is not a Swift package (no Package.swift) "
        + "and no unique .xcodeproj/.xcworkspace was found there "
        + "(workspaces: \(workspaceCount), projects: \(projectCount)). "
        + "Pass --xcode-project or --xcode-workspace with --scheme, or point "
        + "--package-path at the app's project directory."
    }
  }

  /// - Parameters:
  ///   - packageDirectory: the `--package-path` directory.
  ///   - explicitProject/explicitWorkspace/explicitScheme: user-supplied flags.
  ///   - hasPackageSwift: whether a `Package.swift` exists at `packageDirectory`.
  ///   - entries: the directory listing of `packageDirectory` (names only).
  ///   - product: the `--product` value; the default scheme when none is given.
  ///
  /// Precedence: explicit flags win; then a Swift package keeps the SwiftPM
  /// path (`project`/`workspace` nil); then a unique `.xcworkspace` (preferred)
  /// or `.xcodeproj` is selected, disambiguating by product name when several
  /// exist; otherwise `NoBuildableProject` is thrown.
  public static func resolve(
    packageDirectory: String,
    explicitProject: String?,
    explicitWorkspace: String?,
    explicitScheme: String?,
    hasPackageSwift: Bool,
    entries: [String],
    product: String
  ) throws -> Inputs {
    if explicitProject != nil || explicitWorkspace != nil {
      return Inputs(project: explicitProject, workspace: explicitWorkspace, scheme: explicitScheme)
    }
    if hasPackageSwift {
      return Inputs(project: nil, workspace: nil, scheme: explicitScheme)
    }

    let workspaces = entries.filter { $0.hasSuffix(".xcworkspace") }.sorted()
    let projects = entries.filter { $0.hasSuffix(".xcodeproj") }.sorted()

    // A single candidate is unambiguous; when several exist, disambiguate by the
    // one whose basename matches the product name.
    func pick(_ candidates: [String]) -> String? {
      if candidates.count == 1 { return candidates[0] }
      return candidates.first { ($0 as NSString).deletingPathExtension == product }
    }

    let scheme = explicitScheme ?? product
    let base = URL(fileURLWithPath: packageDirectory, isDirectory: true)
    if let workspace = pick(workspaces) {
      return Inputs(
        project: nil, workspace: base.appendingPathComponent(workspace).path, scheme: scheme)
    }
    if let project = pick(projects) {
      return Inputs(
        project: base.appendingPathComponent(project).path, workspace: nil, scheme: scheme)
    }
    throw NoBuildableProject(
      packageDirectory: packageDirectory,
      workspaceCount: workspaces.count,
      projectCount: projects.count)
  }
}
