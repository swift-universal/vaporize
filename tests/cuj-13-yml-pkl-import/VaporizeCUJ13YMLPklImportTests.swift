import XcodeProjectDefinitionCore
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
    "Pkl/XcodeProjectDefinition.pkl",
    "--format",
    "json",
  ])

  #expect(command.mode == .importProjectYML)
  #expect(command.vaporScanPath == "project.yml")
  #expect(command.generatedOutputPath == "project.pkl")
  #expect(command.pklSchemaPath == "Pkl/XcodeProjectDefinition.pkl")
  #expect(command.vaporOutputFormat == .json)
}

@Test("CUJ-13 imports Concourse project.yml into an evaluable project.pkl")
func importsConcourseYMLIntoPklParitySpecimen() async throws {
  let (receipt, generatedPkl, temporaryDirectory) = try importConcoursePklFixture(
    requestId: "concourse-project-yml-import-test"
  )
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

  let generatedSpec = try await XcodeProjectPklLoader.load(url: generatedPkl)

  #expect(FileManager.default.fileExists(atPath: generatedPkl.path))
  #expect(receipt.receiptKind == "vaporize-xcode-project-yml-pkl-import")
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

  let ymlSpec = try XcodeProjectYMLReader.load(url: concourseProjectYMLURL)
  let pklSpec = try await XcodeProjectPklLoader.load(url: generatedPkl)
  let comparison = XcodeProjectDefinitionComparator.receipt(
    ymlSpec: ymlSpec,
    pklSpec: pklSpec,
    ymlPath: concourseProjectYMLURL.path,
    pklPath: generatedPkl.path,
    requestId: "concourse-imported-project-yml-pkl-comparison-test"
  )

  #expect(comparison.matched == true)
  #expect(comparison.mismatchCount == 0)
}

@Test("CUJ-13 imports every XcodeGen parity proving ground into evaluable Pkl")
func importsEveryXcodeGenParityProvingGroundIntoPkl() async throws {
  #expect(xcodeGenToPklParityProvingGrounds.count >= 5)

  for ground in xcodeGenToPklParityProvingGrounds {
    let temporaryDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("vaporize-\(ground.slug)-import-\(UUID().uuidString)")
    let generatedPkl = temporaryDirectory.appendingPathComponent("project.generated.pkl")
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

    let schemaAmendsPath = relativePathForPklAmends(
      from: generatedPkl.deletingLastPathComponent(),
      to: xcodeProjectDefinitionPklSchemaURL
    )
    let receipt = try XcodeProjectDefinitionPklImporter.generate(
      ymlURL: ground.projectYMLURL,
      outputURL: generatedPkl,
      schemaAmendsPath: schemaAmendsPath,
      requestId: "xcodegen-to-pkl-proving-ground-import-\(ground.slug)"
    )
    let ymlSpec = try XcodeProjectYMLReader.load(url: ground.projectYMLURL)
    let generatedSpec = try await XcodeProjectPklLoader.load(url: generatedPkl)
    let checkedInSpec = try await XcodeProjectPklLoader.load(url: ground.projectPklURL)
    let generatedComparison = XcodeProjectDefinitionComparator.receipt(
      ymlSpec: ymlSpec,
      pklSpec: generatedSpec,
      ymlPath: ground.projectYMLURL.path,
      pklPath: generatedPkl.path,
      requestId: "xcodegen-to-pkl-proving-ground-generated-comparison-\(ground.slug)"
    )
    let checkedInComparison = XcodeProjectDefinitionComparator.receipt(
      ymlSpec: ymlSpec,
      pklSpec: checkedInSpec,
      ymlPath: ground.projectYMLURL.path,
      pklPath: ground.projectPklURL.path,
      requestId: "xcodegen-to-pkl-proving-ground-checked-in-comparison-\(ground.slug)"
    )

    #expect(receipt.receiptKind == "vaporize-xcode-project-yml-pkl-import")
    #expect(receipt.projectName == ground.expectedProjectName)
    #expect(receipt.targetNames == ground.expectedTargetNames)
    #expect(receipt.packageNames == ground.expectedPackageNames)
    #expect(generatedComparison.matched == true)
    #expect(generatedComparison.mismatchCount == 0)
    #expect(checkedInComparison.matched == true)
    #expect(checkedInComparison.mismatchCount == 0)
  }
}

@Test("CUJ-13 Pkl renderer preserves nested values and script strings")
func pklRendererPreservesNestedValuesAndScripts() async throws {
  let spec = try decodeXcodeProjectYML(
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
    to: xcodeProjectDefinitionPklSchemaURL
  )
  let data = XcodeProjectPklRenderer.renderData(
    spec: spec,
    schemaAmendsPath: schemaAmendsPath,
    sourcePath: "fixture/project.yml"
  )
  try data.write(to: generatedPkl)

  let decoded = try await XcodeProjectPklLoader.load(url: generatedPkl)
  let comparison = XcodeProjectDefinitionComparator.receipt(
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
) throws -> (XcodeProjectYMLImportReceipt, URL, URL) {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-yml-pkl-import-\(UUID().uuidString)")
  let generatedPkl = temporaryDirectory.appendingPathComponent("concourse.imported.project.pkl")
  try FileManager.default.createDirectory(
    at: temporaryDirectory,
    withIntermediateDirectories: true
  )
  let schemaAmendsPath = relativePathForPklAmends(
    from: generatedPkl.deletingLastPathComponent(),
    to: xcodeProjectDefinitionPklSchemaURL
  )
  let receipt = try XcodeProjectDefinitionPklImporter.generate(
    ymlURL: concourseProjectYMLURL,
    outputURL: generatedPkl,
    schemaAmendsPath: schemaAmendsPath,
    requestId: requestId
  )
  return (receipt, generatedPkl, temporaryDirectory)
}
