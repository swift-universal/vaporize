import AppleProjectSpecCore
import Foundation
import Testing
import VaporizeTestSupport

@Test("CUJ-08 reads Concourse project.yml into AppleProjectSpec")
func readsConcourseProjectYML() throws {
  let spec = try AppleProjectYMLReader.load(url: concourseProjectYMLURL)
  let receipt = AppleProjectYMLReader.receipt(
    for: spec,
    path: concourseProjectYMLURL.path,
    requestId: "concourse-project-yml-test"
  )

  #expect(spec.name == "concourse")
  #expect(spec.options?.minimumXcodeGenVersion == "2.39.0")
  #expect(spec.settings?.base?["INSTALL_PATH"]?.stringValue == "/Applications/categories/developer-tools")
  #expect(spec.settings?.base?["SWIFT_VERSION"]?.stringValue == "6.4")
  #expect(spec.packages.keys.sorted() == ["WrkstrmOnboarding", "WrkstrmWalkthrough", "common-terminal"])
  #expect(spec.targets["concourse"]?.type == "application")
  #expect(spec.targets["concourse"]?.platform == "macOS")
  #expect(spec.targets["concourse"]?.sources?.map(\.path) == ["Sources/mac-app"])
  #expect(spec.targets["concourse"]?.dependencies?.count == 3)
  #expect(spec.targets["concourse"]?.postBuildScripts?.first?.name == "Deploy to Applications")
  #expect(receipt.receiptKind == "vaporize-apple-project-yml-inspection")
  #expect(receipt.bridgeStatus == "legacy-xcodegen-yaml-read-only")
  #expect(receipt.targetCount == 1)
  #expect(receipt.packageCount == 3)
}

@Test("CUJ-08 reads multi-target YAML shapes without requiring generation")
func readsMultiTargetProjectYMLShape() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: parity-fixture
    options:
      minimumXcodeGenVersion: 2.39.0
      useBaseInternationalization: true
      createIntermediateGroups: true
    settings:
      base:
        SWIFT_VERSION: 6.4
    packages:
      FixtureKit:
        path: packages/fixture-kit
    targets:
      fixture-helper:
        type: application
        platform: macOS
        sources:
          - helper/Sources
      fixture-app:
        type: application
        platform: iOS
        deploymentTarget: "26.0"
        sources:
          - path: app/Sources
            excludes:
              - "**/*.md"
        info:
          path: app/Info.plist
          properties:
            UIApplicationSupportsMultipleScenes: true
        settings:
          base:
            PRODUCT_BUNDLE_IDENTIFIER: com.example.fixture
            PRODUCT_NAME: fixture-app
            MARKETING_VERSION: 2.5.0
            TARGETED_DEVICE_FAMILY: "1,2"
          configs:
            Debug:
              WRAPPER_NAME: "$(PRODUCT_NAME)-$(MARKETING_VERSION)-dev.app"
        dependencies:
          - package: FixtureKit
            product: FixtureKit
          - target: fixture-helper
            embed: true
        preBuildScripts:
          - name: Audit
            script: echo audit
    schemes:
      fixture-app:
        shared: true
        build:
          targets:
            fixture-app: all
        run:
          config: Debug
    """
  )
  let receipt = AppleProjectYMLReader.receipt(
    for: spec,
    path: "fixture/project.yml",
    requestId: "multi-target-project-yml-test"
  )

  #expect(spec.name == "parity-fixture")
  #expect(spec.targets.keys.sorted() == ["fixture-app", "fixture-helper"])
  #expect(spec.targets["fixture-helper"]?.sources?.map(\.path) == ["helper/Sources"])
  #expect(spec.targets["fixture-app"]?.sources?.first?.path == "app/Sources")
  #expect(spec.targets["fixture-app"]?.sources?.first?.excludes == ["**/*.md"])
  #expect(spec.targets["fixture-app"]?.dependencies?.first?.package == "FixtureKit")
  #expect(spec.targets["fixture-app"]?.dependencies?.last?.target == "fixture-helper")
  #expect(spec.targets["fixture-app"]?.dependencies?.last?.embed == true)
  #expect(spec.targets["fixture-app"]?.preBuildScripts?.first?.name == "Audit")
  #expect(spec.schemes["fixture-app"]?.shared == true)
  #expect(receipt.targetCount == 2)
  #expect(receipt.schemeCount == 1)
  #expect(receipt.targetSummaries.first { $0.name == "fixture-app" }?.hasPreBuildScripts == true)
}

@Test("CUJ-08 AppleProjectValue decodes scalar and container values")
func appleProjectValueDecodesScalarAndContainerValues() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: value-fixture
    settings:
      base:
        BOOL_VALUE: true
        INT_VALUE: 7
        DOUBLE_VALUE: 6.4
        STRING_VALUE: "6.4"
        ARRAY_VALUE:
          - one
          - 2
        OBJECT_VALUE:
          nested: yes
    targets:
      app:
        type: application
        platform: macOS
    """
  )

  let base = try #require(spec.settings?.base)
  #expect(base["BOOL_VALUE"]?.boolValue == true)
  #expect(base["INT_VALUE"]?.stringValue == "7")
  #expect(base["DOUBLE_VALUE"]?.stringValue == "6.4")
  #expect(base["STRING_VALUE"]?.stringValue == "6.4")
  #expect(base["ARRAY_VALUE"]?.stringValue == nil)
  #expect(base["OBJECT_VALUE"]?.stringValue == nil)
}

@Test("CUJ-08 source entries decode from string shorthand")
func sourceEntriesDecodeFromStringShorthand() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: source-fixture
    targets:
      app:
        type: application
        platform: macOS
        sources:
          - Sources/App
    """
  )

  #expect(spec.targets["app"]?.sources?.map(\.path) == ["Sources/App"])
}

@Test("CUJ-08 inspection receipt carries the read-only migration boundary")
func inspectionReceiptCarriesReadOnlyMigrationBoundary() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: receipt-fixture
    targets:
      app:
        type: application
        platform: macOS
    """
  )
  let receipt = AppleProjectYMLReader.receipt(
    for: spec,
    path: "fixture/project.yml",
    requestId: "inspection-boundary-test"
  )

  #expect(receipt.receiptKind == "vaporize-apple-project-yml-inspection")
  #expect(receipt.bridgeStatus == "legacy-xcodegen-yaml-read-only")
  #expect(receipt.targetNames == ["app"])
}
