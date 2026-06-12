import AppleProjectSpecCore
import Foundation
import Testing

private let vaporizePackageRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private let concourseProjectYML = vaporizePackageRoot
  .appendingPathComponent("../../apps/concourse/project.yml")
  .standardizedFileURL

private let concourseProjectPkl = vaporizePackageRoot
  .appendingPathComponent("../../apps/concourse/project.pkl")
  .standardizedFileURL

@Test("Compares Concourse project.yml with the Pkl parity specimen")
func comparesConcourseProjectYMLWithPklSpecimen() async throws {
  let ymlSpec = try AppleProjectYMLReader.load(url: concourseProjectYML)
  let pklSpec = try await AppleProjectPklLoader.load(url: concourseProjectPkl)
  let receipt = AppleProjectSpecComparator.receipt(
    ymlSpec: ymlSpec,
    pklSpec: pklSpec,
    ymlPath: concourseProjectYML.path,
    pklPath: concourseProjectPkl.path,
    requestId: "concourse-project-yml-pkl-comparison-test"
  )

  #expect(receipt.receiptKind == "vaporize-apple-project-yml-pkl-comparison")
  #expect(receipt.matched == true)
  #expect(receipt.mismatchCount == 0)
  #expect(receipt.pklSignature.projectName == "concourse")
  #expect(
    receipt.pklSignature.targets["concourse"]?.settingConfigs["Debug"]?["WRAPPER_NAME"]
      == "concourse-$(MARKETING_VERSION)-debug.app"
  )
}

@Test("Generates transitional AppleProjectSpec YAML from Concourse project.pkl")
func generatesTransitionalProjectYMLFromPklSpecimen() async throws {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-pkl-yml-generation-\(UUID().uuidString)")
  let generatedYML = temporaryDirectory.appendingPathComponent("concourse.generated.project.yml")

  try FileManager.default.createDirectory(
    at: temporaryDirectory,
    withIntermediateDirectories: true
  )
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

  let receipt = try await AppleProjectSpecYMLGenerator.generate(
    pklURL: concourseProjectPkl,
    outputURL: generatedYML,
    requestId: "concourse-project-yml-generation-test"
  )
  let generatedSpec = try AppleProjectYMLReader.load(url: generatedYML)
  let pklSpec = try await AppleProjectPklLoader.load(url: concourseProjectPkl)
  let comparison = AppleProjectSpecComparator.receipt(
    ymlSpec: generatedSpec,
    pklSpec: pklSpec,
    ymlPath: generatedYML.path,
    pklPath: concourseProjectPkl.path,
    requestId: "concourse-generated-yml-pkl-comparison-test"
  )

  #expect(FileManager.default.fileExists(atPath: generatedYML.path))
  #expect(receipt.receiptKind == "vaporize-pkl-project-yml-generation")
  #expect(receipt.generationPhase == "pkl-to-transitional-apple-project-spec-yaml")
  #expect(receipt.generatorStatus == "transitional-yaml-only")
  #expect(receipt.buildableWorldStateGenerated == false)
  #expect(receipt.xcodeProjectGenerated == false)
  #expect(receipt.generatedByteCount > 0)
  #expect(receipt.targetNames == ["concourse"])
  #expect(comparison.matched == true)
  #expect(comparison.mismatchCount == 0)
}
