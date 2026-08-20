import AppleProjectSpecCore
import Foundation
import Testing

@Test("AppleProjectSpecCore materializes an external project that xcrun builds")
func materializesPortablePklProjectThroughXcrun() async throws {
  let packageRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
  let fixtureRoot = packageRoot
    .appendingPathComponent("tests/proving-grounds/pkl-project-generation/portable-local-package-build-variants")
  let outputDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("apple-project-spec-cli-xcrun-output-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: outputDirectory) }

  let outputProject = outputDirectory.appendingPathComponent("PortableGenerated.xcodeproj")
  let receipt = try await AppleProjectXcodeProjectGenerator.generate(
    pklURL: fixtureRoot.appendingPathComponent("project.pkl"),
    outputURL: outputProject,
    requestId: "apple-project-spec-core-xcrun-materialization"
  )

  #expect(receipt.receiptKind == "vaporize-pkl-xcodeproj-generation")
  #expect(receipt.outputPath == outputProject.path)
  #expect(FileManager.default.fileExists(atPath: outputProject.appendingPathComponent("project.pbxproj").path))

  let dogfoodSettings = try runXcrun(
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
  #expect(dogfoodSettings.status == 0)
  #expect(dogfoodSettings.stdout.contains("PORTABLE_VARIANT = dogfood"))

  let build = try runXcrun(
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

  #expect(build.status == 0)
  #expect(build.stdout.contains("** BUILD SUCCEEDED **"))
}

private struct XcrunResult: Sendable {
  let status: Int32
  let stdout: String
  let stderr: String
}

private func runXcrun(_ arguments: [String]) throws -> XcrunResult {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
  process.arguments = arguments
  var environment = ProcessInfo.processInfo.environment
  environment["VAPORIZE_DISABLE_SWIFTLY"] = "1"
  process.environment = environment

  let captureDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("apple-project-spec-xcrun-capture-\(UUID().uuidString)")
  let stdoutURL = captureDirectory.appendingPathComponent("stdout.txt")
  let stderrURL = captureDirectory.appendingPathComponent("stderr.txt")
  try FileManager.default.createDirectory(at: captureDirectory, withIntermediateDirectories: true)
  FileManager.default.createFile(atPath: stdoutURL.path, contents: nil)
  FileManager.default.createFile(atPath: stderrURL.path, contents: nil)
  let stdoutHandle = try FileHandle(forWritingTo: stdoutURL)
  let stderrHandle = try FileHandle(forWritingTo: stderrURL)
  defer {
    try? stdoutHandle.close()
    try? stderrHandle.close()
    try? FileManager.default.removeItem(at: captureDirectory)
  }
  process.standardOutput = stdoutHandle
  process.standardError = stderrHandle
  try process.run()
  process.waitUntilExit()

  try stdoutHandle.close()
  try stderrHandle.close()
  let stdoutData = try Data(contentsOf: stdoutURL)
  let stderrData = try Data(contentsOf: stderrURL)
  return XcrunResult(
    status: process.terminationStatus,
    stdout: String(decoding: stdoutData, as: UTF8.self),
    stderr: String(decoding: stderrData, as: UTF8.self)
  )
}
