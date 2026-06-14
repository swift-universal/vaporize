import Foundation

struct XcodeWorkspaceSchemeListRequest: Equatable {
  var workspacePath: String

  var standardizedWorkspacePath: String {
    URL(fileURLWithPath: workspacePath).standardizedFileURL.path
  }

  var xcodebuildArguments: [String] {
    ["-list", "-json", "-workspace", standardizedWorkspacePath]
  }

  init(workspacePath: String) throws {
    guard !workspacePath.isEmpty else {
      throw XcodeWorkspaceSchemeListError.emptyWorkspacePath
    }
    guard workspacePath.hasSuffix(".xcworkspace") else {
      throw XcodeWorkspaceSchemeListError.invalidWorkspacePath(workspacePath)
    }
    self.workspacePath = workspacePath
  }
}

struct XcodeWorkspaceSchemeListParser {
  struct ParsedWorkspace: Equatable {
    var workspaceName: String?
    var schemes: [String]
  }

  static func parse(data: Data) throws -> ParsedWorkspace {
    let object = try JSONSerialization.jsonObject(with: data)
    guard let root = object as? [String: Any] else {
      throw XcodeWorkspaceSchemeListError.invalidXcodebuildJSON("Root JSON value is not an object.")
    }
    guard let workspace = root["workspace"] as? [String: Any] else {
      throw XcodeWorkspaceSchemeListError.invalidXcodebuildJSON("Missing workspace object.")
    }

    let name = workspace["name"] as? String
    let schemes = workspace["schemes"] as? [String] ?? []
    guard !schemes.isEmpty else {
      throw XcodeWorkspaceSchemeListError.invalidXcodebuildJSON("Workspace scheme list is empty or missing.")
    }
    return .init(workspaceName: name, schemes: schemes)
  }
}

struct XcodeWorkspaceSchemeListReceipt: Codable, Equatable {
  var schemaVersion = "0.1.0"
  var receiptKind = "vaporize-xcode-workspace-scheme-list"
  var workspacePath: String
  var workspaceName: String?
  var schemeCount: Int
  var schemes: [String]
  var xcodebuildArguments: [String]
  var workingDirectory: String
  var requestId: String
  var runnerKind: String
  var developerDirectorySet: Bool
  var succeeded: Bool
  var exitCode: Int?
  var signal: Int?
  var stdoutBytes: Int
  var stderrBytes: Int
  var processIdentifier: String?
  var boundaries: [String]

  init(
    workspacePath: String,
    workspaceName: String?,
    schemes: [String],
    xcodebuildArguments: [String],
    workingDirectory: String,
    requestId: String,
    runnerKind: String,
    developerDirectorySet: Bool,
    succeeded: Bool,
    exitCode: Int?,
    signal: Int?,
    stdoutBytes: Int,
    stderrBytes: Int,
    processIdentifier: String?
  ) {
    self.workspacePath = URL(fileURLWithPath: workspacePath).standardizedFileURL.path
    self.workspaceName = workspaceName
    self.schemeCount = schemes.count
    self.schemes = schemes
    self.xcodebuildArguments = xcodebuildArguments
    self.workingDirectory = workingDirectory
    self.requestId = requestId
    self.runnerKind = runnerKind
    self.developerDirectorySet = developerDirectorySet
    self.succeeded = succeeded
    self.exitCode = exitCode
    self.signal = signal
    self.stdoutBytes = stdoutBytes
    self.stderrBytes = stderrBytes
    self.processIdentifier = processIdentifier
    self.boundaries = [
      "Uses xcodebuild -list -json -workspace as the workspace graph authority.",
      "Lists schemes only; it does not build, install, warm caches, or prove product paths.",
      "Scheme discovery is the routing input for shared substrate workspace build/cache lanes.",
    ]
  }
}

enum XcodeWorkspaceSchemeListError: Error, CustomStringConvertible {
  case emptyWorkspacePath
  case invalidWorkspacePath(String)
  case invalidXcodebuildJSON(String)

  var description: String {
    switch self {
    case .emptyWorkspacePath:
      return "Workspace path is required."
    case .invalidWorkspacePath(let path):
      return "Expected a .xcworkspace path for list-schemes; got \(path)."
    case .invalidXcodebuildJSON(let reason):
      return "Could not parse xcodebuild workspace scheme JSON: \(reason)"
    }
  }
}
