import AppleProjectSpecCore
import Foundation

/// Inputs for resolving the app-bundle identity associated with an Xcode
/// project emitted from an AppleProjectSpec Pkl record.
///
/// `sourceRootPath` is the resolved source root for the generated project. In
/// Vaporize app mode it is the required `--package-path`, so a generated
/// `.xcodeproj` may live outside that source root without reintroducing a
/// `project.yml` dependency.
struct XcodeAppBundleIdentityResolutionRequest {
  var explicitPklPath: String?
  var xcodeProjectPath: String?
  var xcodeWorkspacePath: String?
  var sourceRootPath: String?
  var targetName: String
  var configuration: String
  var workingDirectoryURL: URL
}

/// Resolves a built app's wrapper name from Pkl first, then preserves the
/// legacy XcodeGen YAML path as a compatibility fallback.
enum XcodeAppBundleIdentityResolver {
  static func resolve(_ request: XcodeAppBundleIdentityResolutionRequest) async -> String? {
    let fileManager = FileManager.default

    for url in candidateProjectPklURLs(for: request)
    where fileManager.fileExists(atPath: url.path) {
      guard let spec = try? await AppleProjectPklLoader.load(url: url) else {
        continue
      }
      if let bundleName = AppleProjectAppBundleNameResolver.appBundleName(
        in: spec,
        targetName: request.targetName,
        configuration: request.configuration
      ) {
        return bundleName
      }
    }

    for url in candidateProjectYMLURLs(for: request)
    where fileManager.fileExists(atPath: url.path) {
      guard let spec = try? AppleProjectYMLReader.load(url: url) else {
        continue
      }
      if let bundleName = AppleProjectAppBundleNameResolver.appBundleName(
        in: spec,
        targetName: request.targetName,
        configuration: request.configuration
      ) {
        return bundleName
      }
    }

    return nil
  }

  static func candidateProjectPklURLs(
    for request: XcodeAppBundleIdentityResolutionRequest
  ) -> [URL] {
    var candidates: [URL] = []
    appendPath(request.explicitPklPath, named: "project.pkl", request: request, to: &candidates)
    appendSiblingSpec(
      nextTo: request.xcodeProjectPath,
      named: "project.pkl",
      request: request,
      to: &candidates
    )
    appendSiblingSpec(
      nextTo: request.xcodeWorkspacePath,
      named: "project.pkl",
      request: request,
      to: &candidates
    )
    appendSourceRootSpec(named: "project.pkl", request: request, to: &candidates)
    return deduplicated(candidates)
  }

  static func candidateProjectYMLURLs(
    for request: XcodeAppBundleIdentityResolutionRequest
  ) -> [URL] {
    var candidates: [URL] = []
    if let explicitPklPath = request.explicitPklPath, !explicitPklPath.isEmpty {
      candidates.append(
        absoluteURL(for: explicitPklPath, request: request)
          .deletingLastPathComponent()
          .appendingPathComponent("project.yml")
      )
    }
    appendSiblingSpec(
      nextTo: request.xcodeProjectPath,
      named: "project.yml",
      request: request,
      to: &candidates
    )
    appendSiblingSpec(
      nextTo: request.xcodeWorkspacePath,
      named: "project.yml",
      request: request,
      to: &candidates
    )
    appendSourceRootSpec(named: "project.yml", request: request, to: &candidates)
    return deduplicated(candidates)
  }

  private static func appendPath(
    _ path: String?,
    named defaultFileName: String,
    request: XcodeAppBundleIdentityResolutionRequest,
    to candidates: inout [URL]
  ) {
    guard let path, !path.isEmpty else { return }
    let url = absoluteURL(for: path, request: request)
    candidates.append(
      url.lastPathComponent == defaultFileName ? url : url.appendingPathComponent(defaultFileName))
  }

  private static func appendSiblingSpec(
    nextTo path: String?,
    named fileName: String,
    request: XcodeAppBundleIdentityResolutionRequest,
    to candidates: inout [URL]
  ) {
    guard let path, !path.isEmpty else { return }
    candidates.append(
      absoluteURL(for: path, request: request)
        .deletingLastPathComponent()
        .appendingPathComponent(fileName)
    )
  }

  private static func appendSourceRootSpec(
    named fileName: String,
    request: XcodeAppBundleIdentityResolutionRequest,
    to candidates: inout [URL]
  ) {
    guard let sourceRootPath = request.sourceRootPath, !sourceRootPath.isEmpty else { return }
    candidates.append(
      absoluteURL(for: sourceRootPath, request: request).appendingPathComponent(fileName)
    )
  }

  private static func absoluteURL(
    for path: String,
    request: XcodeAppBundleIdentityResolutionRequest
  ) -> URL {
    if path.hasPrefix("/") {
      return URL(fileURLWithPath: path).standardizedFileURL
    }
    return request.workingDirectoryURL.appendingPathComponent(path).standardizedFileURL
  }

  private static func deduplicated(_ candidates: [URL]) -> [URL] {
    var seen: Set<String> = []
    return candidates.filter { url in
      let path = url.standardizedFileURL.path
      return seen.insert(path).inserted
    }
  }
}
