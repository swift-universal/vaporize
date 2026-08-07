import ArgumentParser
import Foundation
import Testing

@testable import VaporizeCLI

private func homebrewFixtureDirectory() throws -> URL {
  let root = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("vaporize-cuj31-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(
    at: root.appendingPathComponent("Formula"), withIntermediateDirectories: true)
  try FileManager.default.createDirectory(
    at: root.appendingPathComponent("Manifests/clia-assistants"), withIntermediateDirectories: true)
  return root
}

private func writeFixture(_ text: String, to url: URL) throws {
  try Data(text.utf8).write(to: url)
}

private let brewInfoFixture = Data(
  """
  {
    "formulae": [{
      "name": "clia-assistants",
      "full_name": "clia-org/tap/clia-assistants",
      "versions": { "stable": "0.0.1" },
      "urls": { "stable": { "checksum": "artifact-sha" } },
      "revision": 0,
      "version_scheme": 2,
      "installed": [{ "version": "0.0.1" }],
      "linked_keg": "0.0.1",
      "tap_git_head": "tap-sha",
      "ruby_source_checksum": { "sha256": "formula-sha" }
    }]
  }
  """.utf8
)

@Test("CUJ-31 parses homebrew-status with exact formula and tap refs")
func parsesHomebrewStatus() throws {
  let command = try VaporizeCLI.parse([
    "homebrew-status",
    "--homebrew-formula", "clia-assistants",
    "--homebrew-tap-root", "/tmp/clia-tap",
    "--format", "json",
  ])
  #expect(command.mode == .homebrewStatus)
  #expect(command.homebrewFormula == "clia-assistants")
  #expect(command.homebrewTapRoot == "/tmp/clia-tap")
  #expect(command.vaporOutputFormat == .json)
}

@Test("CUJ-31 joins formula, manifest build, and brew install without confusing formula revision for build")
func joinsRecordedHomebrewBuild() throws {
  let root = try homebrewFixtureDirectory()
  defer { try? FileManager.default.removeItem(at: root) }
  try writeFixture(
    """
    class CliaAssistants < Formula
      url "https://example.test/clia.zip"
      version "0.0.1"
      sha256 "artifact-sha"
      version_scheme 2
    end
    """,
    to: root.appendingPathComponent("Formula/clia-assistants.rb")
  )
  try writeFixture(
    """
    {
      "version": "0.0.1",
      "build": {
        "buildNumber": "20260806",
        "sourceRevision": "source-sha",
        "sourceDirty": false
      },
      "artifact": { "sha256": "artifact-sha" }
    }
    """,
    to: root.appendingPathComponent("Manifests/clia-assistants/0.0.1.json")
  )

  let receipt = try HomebrewStatusScanner().receipt(
    formulaName: "clia-assistants",
    tapRoot: root,
    brewInfoData: brewInfoFixture,
    capturedAt: Date(timeIntervalSince1970: 0)
  )
  #expect(receipt.versionCoherence == .coherent)
  #expect(receipt.buildRecording == .recorded)
  #expect(receipt.manifest?.buildNumber == "20260806")
  #expect(receipt.brew.formulaRevision == 0)
  #expect(receipt.artifactCoherence == .coherent)
  #expect(HomebrewStatusRenderer.renderText(receipt).contains("build=20260806"))
}

@Test("CUJ-31 keeps a legacy Homebrew release build unrecorded")
func doesNotInventLegacyHomebrewBuild() throws {
  let root = try homebrewFixtureDirectory()
  defer { try? FileManager.default.removeItem(at: root) }
  try writeFixture(
    """
    class CliaAssistants < Formula
      version "0.0.1"
      sha256 "artifact-sha"
    end
    """,
    to: root.appendingPathComponent("Formula/clia-assistants.rb")
  )
  try writeFixture(
    """
    {
      "version": "0.0.1",
      "build": { "sourceRevision": "source-sha" },
      "artifact": { "sha256": "artifact-sha" }
    }
    """,
    to: root.appendingPathComponent("Manifests/clia-assistants/0.0.1.json")
  )

  let receipt = try HomebrewStatusScanner().receipt(
    formulaName: "clia-assistants",
    tapRoot: root,
    brewInfoData: brewInfoFixture
  )
  #expect(receipt.versionCoherence == .coherent)
  #expect(receipt.buildRecording == .unrecorded)
  #expect(receipt.manifest?.buildNumber == nil)
  #expect(HomebrewStatusRenderer.renderText(receipt).contains("build=unrecorded"))
}
