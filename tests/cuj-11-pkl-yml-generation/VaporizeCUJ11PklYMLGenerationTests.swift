import AppleProjectSpecCore
import Foundation
import Testing
import VaporizeTestSupport

@Test("CUJ-11 generates transitional AppleProjectSpec YAML from Concourse project.pkl")
func generatesTransitionalProjectYMLFromPklSpecimen() async throws {
  let (receipt, _, _) = try await generateConcourseYMLFixture(requestId: "concourse-project-yml-generation-test")

  #expect(receipt.receiptKind == "vaporize-pkl-project-yml-generation")
  #expect(receipt.generationPhase == "pkl-to-transitional-apple-project-spec-yaml")
  #expect(receipt.generatorStatus == "transitional-yaml-only")
  #expect(receipt.buildableWorldStateGenerated == false)
  #expect(receipt.xcodeProjectGenerated == false)
  #expect(receipt.generatedByteCount > 0)
  #expect(receipt.targetNames == ["concourse"])
}

@Test("CUJ-11 generated YAML compares back to Pkl")
func generatedYMLComparesBackToPkl() async throws {
  let (_, generatedYML, temporaryDirectory) = try await generateConcourseYMLFixture(
    requestId: "concourse-generated-yml-comparison-test"
  )
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

  let generatedSpec = try AppleProjectYMLReader.load(url: generatedYML)
  let pklSpec = try await AppleProjectPklLoader.load(url: concourseProjectPklURL)
  let comparison = AppleProjectSpecComparator.receipt(
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

@Test("CUJ-11 renderer output decodes back into AppleProjectSpec")
func rendererOutputDecodesBackIntoAppleProjectSpec() throws {
  let spec = try decodeAppleProjectYML(
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
  let rendered = try AppleProjectYMLRenderer.renderData(spec: spec)
  let decoded = try AppleProjectYMLReader.decode(data: rendered)

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
  let receipt = try await AppleProjectSpecYMLGenerator.generate(
    pklURL: concourseProjectPklURL,
    outputURL: generatedYML,
    requestId: requestId
  )
  return (receipt, generatedYML, temporaryDirectory)
}
