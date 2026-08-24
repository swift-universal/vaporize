import XcodeProjectDefinitionCore
import Foundation
import Testing
import VaporizeTestSupport

@Test("CUJ-14 emits Concourse SnapshotTesting as a remote Swift package from Pkl")
func emitsConcourseSnapshotTestingRemotePackageReference() async throws {
  let outputDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-concourse-remote-package-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: outputDirectory) }

  let outputURL = outputDirectory.appendingPathComponent("ConcourseGenerated.xcodeproj")
  let receipt = try await XcodeProjectGenerator.generate(
    pklURL: concourseProjectPklURL,
    outputURL: outputURL,
    requestId: "cuj-14-concourse-remote-snapshot-testing"
  )
  let pbxproj = try String(
    contentsOf: outputURL.appendingPathComponent("project.pbxproj"),
    encoding: .utf8
  )
  let remoteReferenceDeclaration = try #require(
    pbxproj
      .split(separator: "\n")
      .map(String.init)
      .first {
        $0.contains("XCRemoteSwiftPackageReference \"https://github.com/pointfreeco/swift-snapshot-testing\"")
          && $0.contains("= {")
      }
  )
  let remoteReferenceID = try #require(
    remoteReferenceDeclaration
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .split(separator: " ")
      .first
      .map(String.init)
  )

  #expect(receipt.packageNames.contains("swift-snapshot-testing"))
  #expect(pbxproj.contains("/* Begin XCRemoteSwiftPackageReference section */"))
  #expect(pbxproj.contains("isa = XCRemoteSwiftPackageReference;"))
  #expect(pbxproj.contains("repositoryURL = \"https://github.com/pointfreeco/swift-snapshot-testing\";"))
  #expect(pbxproj.contains("kind = upToNextMajorVersion;"))
  #expect(pbxproj.contains("minimumVersion = 1.17.0;"))
  #expect(pbxproj.contains("package = \(remoteReferenceID) /* XCRemoteSwiftPackageReference \"https://github.com/pointfreeco/swift-snapshot-testing\" */;"))
  #expect(pbxproj.contains("productName = SnapshotTesting;"))
}

@Test("CUJ-14 rejects a remote Swift package without a requirement")
func rejectsRemotePackageWithoutRequirement() throws {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-unpinned-remote-package-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
  let sourceDirectory = temporaryDirectory.appendingPathComponent("Sources/RemoteApp")
  try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
  try Data("import Foundation\nprint(\"remote\")\n".utf8)
    .write(to: sourceDirectory.appendingPathComponent("main.swift"))

  let spec = try decodeXcodeProjectYML("""
  name: unpinned-remote-package
  packages:
    UnpinnedRemote:
      url: https://example.com/unpinned-remote.git
  targets:
    RemoteApp:
      type: tool
      platform: macOS
      sources:
        - path: Sources/RemoteApp
      dependencies:
        - package: UnpinnedRemote
          product: UnpinnedRemote
  """)

  do {
    _ = try XcodeProjectRenderer.render(
      spec: spec,
      projectDirectory: temporaryDirectory
    )
    Issue.record("Expected an unpinned remote package to be rejected.")
  } catch XcodeProjectGenerationError.unsupportedRemotePackageRequirement(let packageName) {
    #expect(packageName == "UnpinnedRemote")
  } catch {
    Issue.record("Unexpected error: \(error)")
  }
}
