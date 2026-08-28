// bead: [[bug-vaporize-i18n-nested-owner-home-windows-2026-08-27]]

#if os(Windows)
import Foundation
import Testing

@testable import VaporizeCLI

@Test("Vaporize reconciles a nested package through its repository-owned Bead home on Windows")
func sourceGateUsesTheCommonOwningHomeForNestedWindowsPackages() async throws {
  let repository = FileManager.default.temporaryDirectory.appendingPathComponent(
    "vaporize-nested-owner-\(UUID().uuidString)",
    isDirectory: true
  )
  defer { try? FileManager.default.removeItem(at: repository) }

  let product = repository.appendingPathComponent(
    "private/universal/tools/example-cli",
    isDirectory: true
  )
  let kuraSpace = repository.appendingPathComponent(
    "private/universal/kura-spaces",
    isDirectory: true
  )
  try FileManager.default.createDirectory(
    at: product.appendingPathComponent("Sources/App", isDirectory: true),
    withIntermediateDirectories: true
  )
  try FileManager.default.createDirectory(
    at: kuraSpace.appendingPathComponent("beads", isDirectory: true),
    withIntermediateDirectories: true
  )
  try FileManager.default.createDirectory(
    at: repository.appendingPathComponent(".git", isDirectory: true),
    withIntermediateDirectories: true
  )
  try """
  import Foundation

  print("Hello")
  """.write(
    to: product.appendingPathComponent("Sources/App/main.swift"),
    atomically: true,
    encoding: .utf8
  )

  #expect(
    VaporizeI18nSourceGate.commonOwningHome(
      productDirectory: product,
      kuraSpace: kuraSpace
    ) == repository.appendingPathComponent("private/universal", isDirectory: true)
      .resolvingSymlinksInPath().standardizedFileURL
  )

  do {
    _ = try await VaporizeI18nSourceGate.enforce(
      productDirectory: product,
      productName: "App",
      surfaceKind: .cli,
      enforcement: .release
    )
    Issue.record("Expected the loose-copy source gate to block after Bead reconciliation.")
  } catch let error as VaporizeI18nSourceGateError {
    if case .blocked(let report, let receipt, _, _) = error {
      #expect(receipt.summary.created > 0)
      #expect(
        report.findings.first?.location.file
          == "tools/example-cli/Sources/App/main.swift"
      )
    } else {
      Issue.record("Expected a normal source-gate block, received: \(error)")
    }
  }
}
#endif
