import XcodeProjectDefinitionCore
import Foundation
import Testing
import VaporizeTestSupport

@Test("CUJ-11 generates transitional XcodeProjectDefinition YAML from Concourse project.pkl")
func generatesTransitionalProjectYMLFromPklSpecimen() async throws {
  let (receipt, _, _) = try await generateConcourseYMLFixture(requestId: "concourse-project-yml-generation-test")

  #expect(receipt.receiptKind == "vaporize-pkl-project-yml-generation")
  #expect(receipt.generationPhase == "pkl-to-transitional-xcode-project-definition-yaml")
  #expect(receipt.generatorStatus == "transitional-yaml-only")
  #expect(receipt.buildableWorldStateGenerated == false)
  #expect(receipt.xcodeProjectGenerated == false)
  #expect(receipt.generatedByteCount > 0)
  #expect(receipt.targetNames == expectedConcourseTargetNames)
}

@Test("CUJ-11 generated YAML compares back to Pkl")
func generatedYMLComparesBackToPkl() async throws {
  let (_, generatedYML, temporaryDirectory) = try await generateConcourseYMLFixture(
    requestId: "concourse-generated-yml-comparison-test"
  )
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

  let generatedSpec = try XcodeProjectYMLReader.load(url: generatedYML)
  let pklSpec = try await XcodeProjectPklLoader.load(url: concourseProjectPklURL)
  let comparison = XcodeProjectDefinitionComparator.receipt(
    ymlSpec: generatedSpec,
    pklSpec: pklSpec,
    ymlPath: generatedYML.path,
    pklPath: concourseProjectPklURL.path,
    requestId: "concourse-generated-yml-pkl-comparison-test"
  )

  #expect(FileManager.default.fileExists(atPath: generatedYML.path))
  #expect(comparison.matched == true)
  #expect(comparison.mismatchCount == 0)
}

@Test("CUJ-11 renderer output decodes back into XcodeProjectDefinition")
func rendererOutputDecodesBackIntoXcodeProjectDefinition() throws {
  let spec = try decodeXcodeProjectYML(
    """
    name: render-fixture
    settings:
      base:
        SWIFT_VERSION: "6.4"
    targets:
      app:
        type: application
        platform: macOS
        settings:
          base:
            GENERATE_INFOPLIST_FILE: false
    """
  )
  let rendered = try XcodeProjectYMLRenderer.renderData(spec: spec)
  let decoded = try XcodeProjectYMLReader.decode(data: rendered)

  #expect(decoded == spec)
  #expect(String(decoding: rendered, as: UTF8.self).contains("SWIFT_VERSION: '6.4'"))
}

private func generateConcourseYMLFixture(
  requestId: String
) async throws -> (PklProjectGenerationReceipt, URL, URL) {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-pkl-yml-generation-\(UUID().uuidString)")
  let generatedYML = temporaryDirectory.appendingPathComponent("concourse.generated.project.yml")
  try FileManager.default.createDirectory(
    at: temporaryDirectory,
    withIntermediateDirectories: true
  )
  let receipt = try await XcodeProjectDefinitionYMLGenerator.generate(
    pklURL: concourseProjectPklURL,
    outputURL: generatedYML,
    requestId: requestId
  )
  return (receipt, generatedYML, temporaryDirectory)
}
