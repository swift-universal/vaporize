import ArgumentParser
import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-20 parses list-schemes CLI arguments")
func parsesListSchemesCLIArguments() throws {
  let command = try VaporizeCLI.parse([
    "list-schemes",
    "--xcode-workspace",
    "/workspace/substrate.xcworkspace",
    "--format",
    "json",
    "--receipt-path",
    "/tmp/substrate-schemes.receipt.json",
  ])

  #expect(command.mode == .listSchemes)
  #expect(command.xcodeWorkspace == "/workspace/substrate.xcworkspace")
  #expect(command.vaporOutputFormat == .json)
  #expect(command.receiptPath == "/tmp/substrate-schemes.receipt.json")
}

@Test("CUJ-20 builds xcodebuild workspace scheme list arguments")
func buildsXcodebuildWorkspaceSchemeListArguments() throws {
  let request = try XcodeWorkspaceSchemeListRequest(
    workspacePath: "/workspace/substrate.xcworkspace"
  )

  #expect(request.xcodebuildArguments == [
    "-list",
    "-json",
    "-workspace",
    "/workspace/substrate.xcworkspace",
  ])
}

@Test("CUJ-20 parses xcodebuild workspace scheme JSON")
func parsesXcodebuildWorkspaceSchemeJSON() throws {
  let data = Data(
    """
    {
      "workspace": {
        "name": "substrate",
        "schemes": [
          "creative-selection-v0.2",
          "concourse",
          "vaporize.cli@wrkstrm-core.clia.sh"
        ]
      }
    }
    """.utf8
  )

  let parsed = try XcodeWorkspaceSchemeListParser.parse(data: data)

  #expect(parsed.workspaceName == "substrate")
  #expect(parsed.schemes == [
    "creative-selection-v0.2",
    "concourse",
    "vaporize.cli@wrkstrm-core.clia.sh",
  ])
}

@Test("CUJ-20 rejects non-workspace paths")
func rejectsNonWorkspacePaths() {
  #expect(throws: XcodeWorkspaceSchemeListError.self) {
    _ = try XcodeWorkspaceSchemeListRequest(workspacePath: "/workspace/substrate.xcodeproj")
  }
}

@Test("CUJ-20 receipt records workspace scheme listing boundary")
func receiptRecordsWorkspaceSchemeListingBoundary() throws {
  let receipt = XcodeWorkspaceSchemeListReceipt(
    workspacePath: "/workspace/substrate.xcworkspace",
    workspaceName: "substrate",
    schemes: ["creative-selection-v0.2", "concourse"],
    xcodebuildArguments: ["-list", "-json", "-workspace", "/workspace/substrate.xcworkspace"],
    workingDirectory: "/workspace",
    requestId: "vaporize-list-schemes-test",
    runnerKind: "auto",
    developerDirectorySet: false,
    succeeded: true,
    exitCode: 0,
    signal: nil,
    stdoutBytes: 128,
    stderrBytes: 0,
    processIdentifier: "pid-20"
  )

  let data = try JSONEncoder().encode(receipt)
  let decoded = try JSONDecoder().decode(XcodeWorkspaceSchemeListReceipt.self, from: data)

  #expect(decoded.receiptKind == "vaporize-xcode-workspace-scheme-list")
  #expect(decoded.schemeCount == 2)
  #expect(decoded.schemes == ["creative-selection-v0.2", "concourse"])
  #expect(decoded.boundaries.contains("Uses xcodebuild -list -json -workspace as the workspace graph authority."))
}
