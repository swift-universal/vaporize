import AppleProjectSpecCore
import Foundation
import Testing

@Test("Compares Concourse project.yml with the Pkl parity specimen")
func comparesConcourseProjectYMLWithPklSpecimen() async throws {
  let ymlSpec = try AppleProjectYMLReader.load(url: concourseProjectYMLURL)
  let pklSpec = try await AppleProjectPklLoader.load(url: concourseProjectPklURL)
  let receipt = AppleProjectSpecComparator.receipt(
    ymlSpec: ymlSpec,
    pklSpec: pklSpec,
    ymlPath: concourseProjectYMLURL.path,
    pklPath: concourseProjectPklURL.path,
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
    pklURL: concourseProjectPklURL,
    outputURL: generatedYML,
    requestId: "concourse-project-yml-generation-test"
  )
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

@Test("Pkl loader wraps evaluation failures with the source path")
func pklLoaderWrapsEvaluationFailuresWithSourcePath() async throws {
  let missingPkl = FileManager.default.temporaryDirectory
    .appendingPathComponent("missing-\(UUID().uuidString).pkl")

  do {
    _ = try await AppleProjectPklLoader.load(url: missingPkl)
    Issue.record("Expected Pkl load to fail for missing file.")
  } catch let error as AppleProjectPklLoaderError {
    #expect(String(describing: error).contains(missingPkl.path))
  } catch {
    Issue.record("Expected AppleProjectPklLoaderError, got \(error).")
  }
}
