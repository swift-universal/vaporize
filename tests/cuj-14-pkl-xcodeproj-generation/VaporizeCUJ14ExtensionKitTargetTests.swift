import XcodeProjectDefinitionCore
import Foundation
import Testing
import VaporizeTestSupport

@Test("CUJ-14 generates an embedded ExtensionKit extension from Pkl")
func generatesEmbeddedExtensionKitExtensionFromPkl() async throws {
  let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-extensionkit-xcodeproj-\(UUID().uuidString)")
  let outputDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-extensionkit-xcodeproj-output-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
  defer { try? FileManager.default.removeItem(at: outputDirectory) }

  let appSourceDirectory = temporaryDirectory.appendingPathComponent("Sources/App")
  let extensionSourceDirectory = temporaryDirectory.appendingPathComponent("Sources/StatusExtension")
  try FileManager.default.createDirectory(at: appSourceDirectory, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: extensionSourceDirectory, withIntermediateDirectories: true)
  try Data("import SwiftUI\n@main struct HostApp: App { var body: some Scene { WindowGroup { Text(\"Host\") } } }\n".utf8)
    .write(to: appSourceDirectory.appendingPathComponent("HostApp.swift"))
  try Data("import ExtensionFoundation\nstruct StatusExtension {}\n".utf8)
    .write(to: extensionSourceDirectory.appendingPathComponent("StatusExtension.swift"))

  let projectPkl = temporaryDirectory.appendingPathComponent("project.pkl")
  let schemaAmendsPath = relativePathForPklAmends(
    from: temporaryDirectory,
    to: xcodeProjectDefinitionPklSchemaURL
  )
  try Data(
    """
    amends "\(schemaAmendsPath)"

    name = "extensionkit-pkl-app"

    targets = new {
      ["HostApp"] = new {
        type = "application"
        platform = "macOS"
        sources = new {
          new { path = "Sources/App" }
        }
        settings = new {
          base = new {
            ["GENERATE_INFOPLIST_FILE"] = true
            ["PRODUCT_BUNDLE_IDENTIFIER"] = "com.wrkstrm.extensionkit-host"
            ["PRODUCT_NAME"] = "HostApp"
            ["SWIFT_VERSION"] = 6.4
          }
        }
        dependencies = new {
          new { target = "StatusExtension"; embed = true }
        }
      }
      ["StatusExtension"] = new {
        type = "extensionkit-extension"
        platform = "macOS"
        sources = new {
          new { path = "Sources/StatusExtension" }
        }
        settings = new {
          base = new {
            ["GENERATE_INFOPLIST_FILE"] = true
            ["PRODUCT_BUNDLE_IDENTIFIER"] = "com.wrkstrm.extensionkit-status"
            ["PRODUCT_NAME"] = "StatusExtension"
            ["SWIFT_VERSION"] = 6.4
          }
        }
        dependencies = new {
          new { sdk = "ExtensionFoundation.framework" }
          new { sdk = "ExtensionKit.framework" }
        }
      }
    }
    """.utf8
  ).write(to: projectPkl)

  let outputURL = outputDirectory.appendingPathComponent("ExtensionKitGenerated.xcodeproj")
  let receipt = try await XcodeProjectGenerator.generate(
    pklURL: projectPkl,
    outputURL: outputURL,
    requestId: "extensionkit-pkl-xcodeproj-generation"
  )
  let pbxproj = try String(
    contentsOf: outputURL.appendingPathComponent("project.pbxproj"),
    encoding: .utf8
  )

  #expect(receipt.targetNames == ["HostApp", "StatusExtension"])
  #expect(pbxproj.contains("productType = \"com.apple.product-type.extensionkit-extension\";"))
  #expect(pbxproj.contains("explicitFileType = \"wrapper.extensionkit-extension\";"))
  #expect(pbxproj.contains("StatusExtension.appex"))
  #expect(pbxproj.contains("Embed ExtensionKit Extensions"))
  #expect(pbxproj.contains("dstPath = \"$(EXTENSIONS_FOLDER_PATH)\";"))
  #expect(pbxproj.contains("dstSubfolderSpec = 16;"))
  #expect(pbxproj.contains("StatusExtension.appex in Embed ExtensionKit Extensions"))
  #expect(pbxproj.contains("ATTRIBUTES = (RemoveHeadersOnCopy, );"))
  #expect(pbxproj.contains("ExtensionFoundation.framework in Frameworks"))
  #expect(pbxproj.contains("ExtensionKit.framework in Frameworks"))
}
