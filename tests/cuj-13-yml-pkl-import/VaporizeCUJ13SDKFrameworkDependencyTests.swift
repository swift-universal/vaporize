import XcodeProjectDefinitionCore
import Foundation
import Testing
import VaporizeTestSupport

@Test("CUJ-13 preserves SDK framework dependencies through YAML-to-Pkl parity")
func preservesSDKFrameworkDependenciesThroughYMLToPklParity() async throws {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-sdk-framework-yml-pkl-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

  try FileManager.default.createDirectory(
    at: temporaryDirectory,
    withIntermediateDirectories: true
  )
  let ymlURL = temporaryDirectory.appendingPathComponent("project.yml")
  let pklURL = temporaryDirectory.appendingPathComponent("project.pkl")
  try Data(
    """
    name: sdk-framework-parity
    targets:
      status-extension:
        type: extensionkit-extension
        platform: macOS
        dependencies:
          - sdk: ExtensionFoundation.framework
          - sdk: ExtensionKit.framework
    """.utf8
  ).write(to: ymlURL)

  let receipt = try XcodeProjectDefinitionPklImporter.generate(
    ymlURL: ymlURL,
    outputURL: pklURL,
    schemaAmendsPath: relativePathForPklAmends(
      from: temporaryDirectory,
      to: xcodeProjectDefinitionPklSchemaURL
    ),
    requestId: "sdk-framework-yml-pkl-parity"
  )
  let ymlSpec = try XcodeProjectYMLReader.load(url: ymlURL)
  let pklSpec = try await XcodeProjectPklLoader.load(url: pklURL)
  let comparison = XcodeProjectDefinitionComparator.receipt(
    ymlSpec: ymlSpec,
    pklSpec: pklSpec,
    ymlPath: ymlURL.path,
    pklPath: pklURL.path,
    requestId: "sdk-framework-yml-pkl-comparison"
  )
  let renderedPkl = try String(contentsOf: pklURL, encoding: .utf8)

  #expect(receipt.projectName == "sdk-framework-parity")
  #expect(comparison.matched == true)
  #expect(comparison.mismatchCount == 0)
  #expect(
    pklSpec.targets["status-extension"]?.dependencies?.compactMap(\.sdk)
      == ["ExtensionFoundation.framework", "ExtensionKit.framework"]
  )
  #expect(renderedPkl.contains("sdk = \"ExtensionFoundation.framework\""))
  #expect(renderedPkl.contains("sdk = \"ExtensionKit.framework\""))
}
