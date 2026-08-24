import XcodeProjectDefinitionCore
import Foundation
import Testing
import VaporizeTestSupport

@Test("XcodeProjectDefinitionCore materializes an external project that xcrun builds")
func materializesPortablePklProjectThroughXcrun() async throws {
  let packageRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
  let fixtureRoot = packageRoot
    .appendingPathComponent("tests/proving-grounds/pkl-project-generation/portable-local-package-build-variants")
  let outputDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("xcode-project-definition-cli-xcrun-output-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: outputDirectory) }

  let outputProject = outputDirectory.appendingPathComponent("PortableGenerated.xcodeproj")
  let receipt = try await XcodeProjectGenerator.generate(
    pklURL: fixtureRoot.appendingPathComponent("project.pkl"),
    outputURL: outputProject,
    requestId: "xcode-project-definition-core-xcrun-materialization"
  )

  #expect(receipt.receiptKind == "vaporize-pkl-xcodeproj-generation")
  #expect(receipt.outputPath == outputProject.path)
  #expect(FileManager.default.fileExists(atPath: outputProject.appendingPathComponent("project.pbxproj").path))

  let dogfoodSettings = try await runXcrun(
    [
      "xcodebuild",
      "-project", outputProject.path,
      "-scheme", "PortableBuildVariantApp",
      "-configuration", "Dogfood",
      "-sdk", "macosx",
      "-showBuildSettings",
      "CODE_SIGNING_ALLOWED=NO",
    ]
  )
  #expect(dogfoodSettings.exitCode == 0)
  #expect(dogfoodSettings.stdout.contains("PORTABLE_VARIANT = dogfood"))

  let build = try await runXcrun(
    [
      "xcodebuild",
      "-project", outputProject.path,
      "-scheme", "PortableBuildVariantApp",
      "-configuration", "Dogfood",
      "-sdk", "macosx",
      "-derivedDataPath", outputDirectory.appendingPathComponent("DerivedData").path,
      "CODE_SIGNING_ALLOWED=NO",
      "CODE_SIGNING_REQUIRED=NO",
      "build",
    ]
  )

  #expect(build.exitCode == 0)
  #expect(build.stdout.contains("** BUILD SUCCEEDED **"))
}

private func runXcrun(_ arguments: [String]) async throws -> VaporizeTestCommandOutput {
  try await VaporizeTestCommand.run(
    executablePath: "/usr/bin/xcrun",
    arguments: arguments,
    sourceTag: "xcode-project-definition-core-xcrun-materialization"
  )
}
