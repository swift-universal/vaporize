import AppleProjectSpecCore
import Foundation
import Testing

@Test("Reads Concourse project.yml into AppleProjectSpec")
func readsConcourseProjectYML() throws {
  let packageRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
  let projectYML = packageRoot
    .appendingPathComponent("../../apps/concourse/project.yml")
    .standardizedFileURL

  let spec = try AppleProjectYMLReader.load(url: projectYML)
  let receipt = AppleProjectYMLReader.receipt(
    for: spec,
    path: projectYML.path,
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
  #expect(
    spec.targets["concourse"]?.settings?.configs?["Debug"]?["PRODUCT_BUNDLE_IDENTIFIER"]?.stringValue
      == "studio.laussat.concourse.macos.debug"
  )
  #expect(
    spec.targets["concourse"]?.settings?.configs?["Release"]?["WRAPPER_NAME"]?.stringValue
      == "concourse-$(MARKETING_VERSION)-testflight.app"
  )
  #expect(
    AppleProjectAppBundleNameResolver.appBundleName(
      in: spec,
      targetName: "concourse",
      configuration: "Debug"
    ) == "concourse-0.1.0-debug"
  )
  #expect(
    AppleProjectAppBundleNameResolver.appBundleName(
      in: spec,
      targetName: "concourse",
      configuration: "Release"
    ) == "concourse-0.1.0-testflight"
  )
  #expect(receipt.receiptKind == "vaporize-apple-project-yml-inspection")
  #expect(receipt.bridgeStatus == "legacy-xcodegen-yaml-read-only")
  #expect(receipt.targetCount == 1)
  #expect(receipt.packageCount == 3)
}

@Test("Reads multi-target YAML shapes without requiring generation")
func readsMultiTargetProjectYMLShape() throws {
  let yaml = """
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

  let spec = try AppleProjectYMLReader.decode(data: Data(yaml.utf8))
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
  #expect(
    AppleProjectAppBundleNameResolver.appBundleName(
      in: spec,
      targetName: "fixture-app",
      configuration: "Debug"
    ) == "fixture-app-2.5.0-dev"
  )
  #expect(spec.schemes["fixture-app"]?.shared == true)
  #expect(receipt.targetCount == 2)
  #expect(receipt.schemeCount == 1)
  #expect(receipt.targetSummaries.first { $0.name == "fixture-app" }?.hasPreBuildScripts == true)
}
