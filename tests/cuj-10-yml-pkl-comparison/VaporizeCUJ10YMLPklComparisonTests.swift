import XcodeProjectDefinitionCore
import Foundation
import Testing
import VaporizeTestSupport

@Test("CUJ-10 compares Concourse project.yml with the Pkl parity specimen")
func comparesConcourseProjectYMLWithPklSpecimen() async throws {
  let ymlSpec = try XcodeProjectYMLReader.load(url: concourseProjectYMLURL)
  let pklSpec = try await XcodeProjectPklLoader.load(url: concourseProjectPklURL)
  let receipt = XcodeProjectDefinitionComparator.receipt(
    ymlSpec: ymlSpec,
    pklSpec: pklSpec,
    ymlPath: concourseProjectYMLURL.path,
    pklPath: concourseProjectPklURL.path,
    requestId: "concourse-project-yml-pkl-comparison-test"
  )

  #expect(receipt.receiptKind == "vaporize-xcode-project-yml-pkl-comparison")
  #expect(receipt.matched == true)
  #expect(receipt.mismatchCount == 0)
  #expect(receipt.pklSignature.projectName == "concourse")
  #expect(receipt.pklSignature.targets["concourse"]?.settingConfigs["Debug"]?["WRAPPER_NAME"] == "concourse-$(MARKETING_VERSION)-debug.app")
}

@Test("CUJ-10 compares checked-in XcodeGen-to-Pkl parity proving grounds")
func comparesCheckedInXcodeGenToPklParityProvingGrounds() async throws {
  #expect(xcodeGenToPklParityProvingGrounds.count >= 5)

  for ground in xcodeGenToPklParityProvingGrounds {
    let ymlSpec = try XcodeProjectYMLReader.load(url: ground.projectYMLURL)
    let pklSpec = try await XcodeProjectPklLoader.load(url: ground.projectPklURL)
    let receipt = XcodeProjectDefinitionComparator.receipt(
      ymlSpec: ymlSpec,
      pklSpec: pklSpec,
      ymlPath: ground.projectYMLURL.path,
      pklPath: ground.projectPklURL.path,
      requestId: "xcodegen-to-pkl-parity-\(ground.slug)"
    )

    #expect(receipt.receiptKind == "vaporize-xcode-project-yml-pkl-comparison")
    #expect(receipt.matched == true)
    #expect(receipt.mismatchCount == 0)
    #expect(receipt.pklSignature.projectName == ground.expectedProjectName)
    #expect(receipt.pklSignature.targets.keys.sorted() == ground.expectedTargetNames)
    #expect(receipt.pklSignature.packages.keys.sorted() == ground.expectedPackageNames)
    #expect(receipt.pklSignature.schemes.keys.sorted() == ground.expectedSchemeNames)
    #expect(FileManager.default.fileExists(atPath: ground.projectYMLURL.path))
    #expect(FileManager.default.fileExists(atPath: ground.projectPklURL.path))
  }
}

@Test("CUJ-10 Pkl loader wraps evaluation failures with the source path")
func pklLoaderWrapsEvaluationFailuresWithSourcePath() async throws {
  let missingPkl = FileManager.default.temporaryDirectory
    .appendingPathComponent("missing-\(UUID().uuidString).pkl")

  do {
    _ = try await XcodeProjectPklLoader.load(url: missingPkl)
    Issue.record("Expected Pkl load to fail for missing file.")
  } catch let error as XcodeProjectPklLoaderError {
    #expect(String(describing: error).contains(missingPkl.path))
  } catch {
    Issue.record("Expected XcodeProjectPklLoaderError, got \(error).")
  }
}

@Test("CUJ-10 comparator reports targeted mismatch sections")
func comparatorReportsTargetedMismatchSections() throws {
  let ymlSpec = try decodeXcodeProjectYML(
    """
    name: app-a
    options:
      minimumXcodeGenVersion: 2.39.0
    settings:
      base:
        SWIFT_VERSION: "6.4"
    packages:
      SharedKit:
        path: packages/shared-kit
    targets:
      app:
        type: application
        platform: macOS
        sources:
          - Sources/App
    """
  )
  let pklSpec = try decodeXcodeProjectYML(
    """
    name: app-b
    options:
      minimumXcodeGenVersion: 2.40.0
    settings:
      base:
        SWIFT_VERSION: "6.5"
    packages:
      SharedKit:
        path: packages/shared-kit-v2
    targets:
      app:
        type: application
        platform: iOS
        sources:
          - Sources/App
    """
  )

  let receipt = XcodeProjectDefinitionComparator.receipt(
    ymlSpec: ymlSpec,
    pklSpec: pklSpec,
    ymlPath: "fixture/project.yml",
    pklPath: "fixture/project.pkl",
    requestId: "comparator-mismatch-test"
  )

  #expect(receipt.matched == false)
  #expect(receipt.mismatchCount == 5)
  #expect(receipt.mismatches == ["projectName", "options", "settingsBase", "packages", "targets"])
}

@Test("CUJ-10 comparator normalizes multi-line scripts")
func comparatorNormalizesMultiLineScripts() throws {
  let ymlSpec = try decodeXcodeProjectYML(
    """
    name: script-app
    targets:
      app:
        type: application
        platform: macOS
        sources:
          - Sources/App
        postBuildScripts:
          - name: Deploy
            script: |
              echo start

                echo done
    """
  )
  let pklSpec = try decodeXcodeProjectYML(
    """
    name: script-app
    targets:
      app:
        type: application
        platform: macOS
        sources:
          - Sources/App
        postBuildScripts:
          - name: Deploy
            script: "echo start\\necho done"
    """
  )

  let receipt = XcodeProjectDefinitionComparator.receipt(
    ymlSpec: ymlSpec,
    pklSpec: pklSpec,
    ymlPath: "fixture/project.yml",
    pklPath: "fixture/project.pkl",
    requestId: "script-normalization-test"
  )

  #expect(receipt.matched == true)
  #expect(receipt.mismatchCount == 0)
}
