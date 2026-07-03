import AppleProjectSpecCore
import Foundation
import Testing
import VaporizeTestSupport

@testable import VaporizeCLI

@Test("CUJ-13 parses legacy YAML import mode")
func parsesLegacyYMLImportMode() throws {
  let command = try VaporizeCLI.parse([
    "import-project-yml",
    "--path",
    "project.yml",
    "--output-path",
    "project.pkl",
    "--pkl-schema-path",
    "Pkl/AppleProjectSpec.pkl",
    "--format",
    "json",
  ])

  #expect(command.mode == .importProjectYML)
  #expect(command.vaporScanPath == "project.yml")
  #expect(command.generatedOutputPath == "project.pkl")
  #expect(command.pklSchemaPath == "Pkl/AppleProjectSpec.pkl")
  #expect(command.vaporOutputFormat == .json)
}

@Test("CUJ-13 imports Concourse project.yml into an evaluable project.pkl")
func importsConcourseYMLIntoPklParitySpecimen() async throws {
  let (receipt, generatedPkl, temporaryDirectory) = try importConcoursePklFixture(
    requestId: "concourse-project-yml-import-test"
  )
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

  let generatedSpec = try await AppleProjectPklLoader.load(url: generatedPkl)

  #expect(FileManager.default.fileExists(atPath: generatedPkl.path))
  #expect(receipt.receiptKind == "vaporize-apple-project-yml-pkl-import")
  #expect(receipt.migrationPhase == "legacy-yaml-to-pkl-import")
  #expect(receipt.importerStatus == "pkl-parity-specimen")
  #expect(receipt.buildableWorldStateGenerated == false)
  #expect(receipt.xcodeProjectGenerated == false)
  #expect(receipt.targetNames == expectedConcourseTargetNames)
  #expect(generatedSpec.name == "concourse")
}

@Test("CUJ-13 imported Pkl compares back to its source YAML")
func importedPklComparesBackToSourceYML() async throws {
  let (_, generatedPkl, temporaryDirectory) = try importConcoursePklFixture(
    requestId: "concourse-project-yml-import-comparison-test"
  )
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

  let ymlSpec = try AppleProjectYMLReader.load(url: concourseProjectYMLURL)
  let pklSpec = try await AppleProjectPklLoader.load(url: generatedPkl)
  let comparison = AppleProjectSpecComparator.receipt(
    ymlSpec: ymlSpec,
    pklSpec: pklSpec,
    ymlPath: concourseProjectYMLURL.path,
    pklPath: generatedPkl.path,
    requestId: "concourse-imported-project-yml-pkl-comparison-test"
  )

  #expect(comparison.matched == true)
  #expect(comparison.mismatchCount == 0)
}

@Test("CUJ-13 Pkl renderer preserves nested values and script strings")
func pklRendererPreservesNestedValuesAndScripts() async throws {
  let spec = try decodeAppleProjectYML(
    """
    name: import-fixture
    targets:
      app:
        type: application
        platform: macOS
        sources:
          - path: Sources/App
            excludes:
              - Generated/**
        info:
          properties:
            CFBundleDisplayName: Import Fixture
            NSPrincipalClass: NSApplication
            Nested:
              enabled: true
              attempts: 2
        postBuildScripts:
          - name: Deploy
            basedOnDependencyAnalysis: false
            script: |
              set -euo pipefail
              echo "deploy"
    """
  )
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-yml-pkl-import-render-\(UUID().uuidString)")
  let generatedPkl = temporaryDirectory.appendingPathComponent("fixture.project.pkl")
  try FileManager.default.createDirectory(
    at: temporaryDirectory,
    withIntermediateDirectories: true
  )
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

  let schemaAmendsPath = relativePathForPklAmends(
    from: generatedPkl.deletingLastPathComponent(),
    to: appleProjectSpecPklSchemaURL
  )
  let data = AppleProjectPklRenderer.renderData(
    spec: spec,
    schemaAmendsPath: schemaAmendsPath,
    sourcePath: "fixture/project.yml"
  )
  try data.write(to: generatedPkl)

  let decoded = try await AppleProjectPklLoader.load(url: generatedPkl)
  let comparison = AppleProjectSpecComparator.receipt(
    ymlSpec: spec,
    pklSpec: decoded,
    ymlPath: "fixture/project.yml",
    pklPath: generatedPkl.path,
    requestId: "nested-render-comparison-test"
  )

  #expect(comparison.matched == true)
  #expect(String(decoding: data, as: UTF8.self).contains("postBuildScripts = new"))
}

private func importConcoursePklFixture(
  requestId: String
) throws -> (AppleProjectYMLImportReceipt, URL, URL) {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-yml-pkl-import-\(UUID().uuidString)")
  let generatedPkl = temporaryDirectory.appendingPathComponent("concourse.imported.project.pkl")
  try FileManager.default.createDirectory(
    at: temporaryDirectory,
    withIntermediateDirectories: true
  )
  let schemaAmendsPath = relativePathForPklAmends(
    from: generatedPkl.deletingLastPathComponent(),
    to: appleProjectSpecPklSchemaURL
  )
  let receipt = try AppleProjectSpecPklImporter.generate(
    ymlURL: concourseProjectYMLURL,
    outputURL: generatedPkl,
    schemaAmendsPath: schemaAmendsPath,
    requestId: requestId
  )
  return (receipt, generatedPkl, temporaryDirectory)
}
