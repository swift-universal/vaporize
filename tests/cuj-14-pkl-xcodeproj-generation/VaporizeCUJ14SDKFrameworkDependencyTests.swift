import AppleProjectSpecCore
import Foundation
import Testing
import VaporizeTestSupport

@Test("CUJ-14 links SDK framework dependencies in generated Xcode world-state")
func linksSDKFrameworkDependenciesInGeneratedXcodeWorldState() async throws {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-sdk-framework-xcodeproj-\(UUID().uuidString)")
  let outputDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-sdk-framework-xcodeproj-output-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
  defer { try? FileManager.default.removeItem(at: outputDirectory) }

  let sourceDirectory = temporaryDirectory.appendingPathComponent("Sources/App")
  try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
  try Data("import Foundation\nstruct SDKFrameworkFixture {}\n".utf8)
    .write(to: sourceDirectory.appendingPathComponent("SDKFrameworkFixture.swift"))

  let projectPkl = temporaryDirectory.appendingPathComponent("project.pkl")
  let schemaAmendsPath = relativePathForPklAmends(
    from: temporaryDirectory,
    to: appleProjectSpecPklSchemaURL
  )
  try Data(
    """
    amends "\(schemaAmendsPath)"

    name = "sdk-framework-pkl-app"

    targets = new {
      ["SDKApp"] = new {
        type = "application"
        platform = "macOS"
        sources = new {
          new { path = "Sources/App" }
        }
        dependencies = new {
          new { sdk = "ExtensionFoundation.framework" }
          new { sdk = "ExtensionKit.framework" }
        }
      }
    }
    """.utf8
  ).write(to: projectPkl)

  let outputURL = outputDirectory.appendingPathComponent("SDKFrameworkGenerated.xcodeproj")
  let receipt = try await AppleProjectXcodeProjectGenerator.generate(
    pklURL: projectPkl,
    outputURL: outputURL,
    requestId: "sdk-framework-pkl-xcodeproj-generation"
  )
  let pbxproj = try String(
    contentsOf: outputURL.appendingPathComponent("project.pbxproj"),
    encoding: .utf8
  )

  #expect(receipt.targetNames == ["SDKApp"])
  #expect(
    receipt.pklSignature.targets["SDKApp"]?.dependencies.compactMap(\.sdk)
      == ["ExtensionFoundation.framework", "ExtensionKit.framework"]
  )
  #expect(pbxproj.contains("ExtensionFoundation.framework in Frameworks"))
  #expect(pbxproj.contains("ExtensionKit.framework in Frameworks"))
  #expect(
    pbxproj.contains(
      "path = \"System/Library/Frameworks/ExtensionFoundation.framework\"; sourceTree = SDKROOT;"
    )
  )
  #expect(
    pbxproj.contains(
      "path = \"System/Library/Frameworks/ExtensionKit.framework\"; sourceTree = SDKROOT;"
    )
  )
}
