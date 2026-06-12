import AppleProjectSpecCore
import Foundation
import Testing

@Test("Comparator reports targeted mismatch sections")
func comparatorReportsTargetedMismatchSections() throws {
  let ymlSpec = try decodeAppleProjectYML(
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
  let pklSpec = try decodeAppleProjectYML(
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

  let receipt = AppleProjectSpecComparator.receipt(
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

@Test("Comparator normalizes multi-line scripts")
func comparatorNormalizesMultiLineScripts() throws {
  let ymlSpec = try decodeAppleProjectYML(
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
  let pklSpec = try decodeAppleProjectYML(
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

  let receipt = AppleProjectSpecComparator.receipt(
    ymlSpec: ymlSpec,
    pklSpec: pklSpec,
    ymlPath: "fixture/project.yml",
    pklPath: "fixture/project.pkl",
    requestId: "script-normalization-test"
  )

  #expect(receipt.matched == true)
  #expect(receipt.mismatchCount == 0)
}
